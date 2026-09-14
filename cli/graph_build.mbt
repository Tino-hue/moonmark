/// 依赖图构建：读取模块、递归解析、生成 NodeMeta、mock 图。

///|
fn read_module_in_directory(dir : String) -> @parse.Module? {
  let fs = @cache.FileSystem::node_js()
  match (fs.read_file)((fs.path_join)(dir, "moon.mod")) {
    Some(content) =>
      match @parse.parse_mod_toml(content) {
        Ok(m) => return Some(m)
        Err(_) => ()
      }
    None => ()
  }
  match (fs.read_file)((fs.path_join)(dir, "moon.mod.json")) {
    Some(content) =>
      match @parse.parse_mod_json(content) {
        Ok(m) => return Some(m)
        Err(_) => ()
      }
    None => ()
  }
  None
}

///|
fn build_full_graph_for_dir(
  dir : String,
  opts : CliOptions,
) -> (@graph.DependencyGraph, String, Map[String, @analyze.NodeMeta]) {
  let root_mod = match read_module_in_directory(dir) {
    Some(m) => m
    None => {
      let g = build_mock_graph(opts.target_pkg)
      let rid = opts.target_pkg + "@1.0.0"
      return (g, rid, Map([]))
    }
  }

  let cache = resolve_cache_manager(opts)
  let registry = @fetch.Registry::new()
  let _ = registry.with_defaults()
  match cache {
    Some(cm) => {
      let _ = registry.with_cache(cm)
    }
    None => ()
  }

  let builder = @graph.GraphBuilder::new_with_max_depth(opts.depth)
  let modules : Map[String, @parse.Module] = Map([])
  let fs = @cache.FileSystem::node_js()
  // F06：离线模式下，本地 `.mooncakes/<name>@<version>/moon.mod` 作为本地 mock 注册表源，
  // 命中则直接返回 Module，完全不走网络，支持示例项目离线演示。
  let local_mooncakes_dir = ".mooncakes"

  fn fetch_cb(
    name : String,
    version : String,
  ) -> Result[@parse.Module, String] {
    if name == root_mod.name {
      let id = name + "@" + root_mod.version
      modules[id] = root_mod
      if opts.verbose {
        println(@analyze.dim("[local] " + id))
      }
      return Ok(root_mod)
    }
    if opts.verbose {
      println("[fetch] " + name + "@" + version + " ...")
    }
    // 1. 离线模式下先尝试本地 .mooncakes 目录（F06：本地 mock 注册表）
    //    先找 moon.mod.json（JSON 含完整 deps），再回退到 moon.mod（TOML）
    if opts.offline {
      let pkg_dir = (fs.path_join)(local_mooncakes_dir, name)
      let json_path = (fs.path_join)(pkg_dir, "moon.mod.json")
      let toml_path = (fs.path_join)(pkg_dir, "moon.mod")
      let local_content = match (fs.read_file)(json_path) {
        Some(c) => Some(("json", c))
        None =>
          match (fs.read_file)(toml_path) {
            Some(c) => Some(("toml", c))
            None => None
          }
      }
      match local_content {
        Some(("json", content)) =>
          match @parse.parse_mod_json(content) {
            Ok(m) => {
              let id = name + "@" + m.version
              modules[id] = m
              if opts.verbose {
                println(
                  @analyze.green(
                    "  -> [offline] " + id + " from .mooncakes (JSON)",
                  ),
                )
              }
              return Ok(m)
            }
            Err(e) =>
              if opts.verbose {
                println(
                  @analyze.yellow(
                    "  -> [offline] JSON parse fail for " + name + ": " + e,
                  ),
                )
              }
          }
        Some(("toml", content)) =>
          match @parse.parse_mod_toml(content) {
            Ok(m) => {
              let id = name + "@" + m.version
              modules[id] = m
              if opts.verbose {
                println(
                  @analyze.green(
                    "  -> [offline] " + id + " from .mooncakes (TOML)",
                  ),
                )
              }
              return Ok(m)
            }
            Err(e) =>
              if opts.verbose {
                println(
                  @analyze.yellow(
                    "  -> [offline] TOML parse fail for " + name + ": " + e,
                  ),
                )
              }
          }
        _ => ()
      }
      if opts.verbose {
        match (fs.read_file)(json_path) {
          Some(_) => ()
          None =>
            match (fs.read_file)(toml_path) {
              Some(_) => ()
              None =>
                println(
                  @analyze.dim(
                    "  -> [offline] no " + name + " in .mooncakes, skip",
                  ),
                )
            }
        }
      }
    }
    match registry.fetch(@fetch.http_get, name, version, opts.offline) {
      Ok(content) => {
        if opts.verbose {
          println(@analyze.green("  -> ok"))
        }
        match @parse.parse_mod_json(content) {
          Ok(m) => {
            let id = name + "@" + m.version
            modules[id] = m
            Ok(m)
          }
          Err(_) =>
            match @parse.parse_mod_toml(content) {
              Ok(m) => {
                let id = name + "@" + m.version
                modules[id] = m
                Ok(m)
              }
              Err(e) => {
                if opts.verbose {
                  println(@analyze.red("  -> parse error: " + e))
                }
                Err("Failed to parse " + name + "@" + version + ": " + e)
              }
            }
        }
      }
      Err(e) => {
        if opts.verbose {
          println(@analyze.yellow("  -> " + e))
        }
        if e.contains("Unknown package") {
          let m = @parse.Module::new(name, version, Map([]))
          let id = name + "@" + version
          modules[id] = m
          Ok(m)
        } else {
          Err(e)
        }
      }
    }
  }

  match builder.build(root_mod.name, root_mod.version, fetch_cb) {
    Ok(graph) => {
      // 获取每个远程 module 的 GitHub 最后提交时间（用于真实活跃度评分）
      let commit_days : Map[String, Int] = Map([])
      for pair in modules {
        let (id, mod) = pair
        match mod.repository {
          Some(repo) => {
            if opts.verbose {
              println("[activity] " + id + " ...")
            }
            match @fetch.fetch_last_commit_days(@fetch.http_get, repo) {
              Ok(days) => {
                if opts.verbose {
                  println(
                    @analyze.green("  -> " + days.to_string() + " days ago"),
                  )
                }
                commit_days[id] = days
              }
              Err(e) => if opts.verbose { println(@analyze.dim("  -> " + e)) }
            }
          }
          None => ()
        }
      }
      // build_node_metas：modules 内的 root 包也应该能拿到真实 size/API——
      //   它不在 .mooncakes/ 里，它的源文件就在 `dir`（项目目录）。
      let metas = build_node_metas(modules, commit_days, dir, root_mod.name)
      (graph, root_mod.name + "@" + root_mod.version, metas)
    }
    Err(e) => {
      println(@analyze.yellow("Warning: full graph build failed: " + e))
      println(@analyze.yellow("Falling back to local-only dependency graph."))
      let g = @graph.DependencyGraph::new()
      g.add_node(root_mod.name, root_mod.version, 0)
      for dep_name, dep_constraint in root_mod.deps {
        g.add_node(dep_name, dep_constraint, 1)
        g.add_edge(root_mod.name, root_mod.version, dep_name, dep_constraint)
      }
      let metas = build_node_metas_from_single(root_mod, dir)
      (g, root_mod.name + "@" + root_mod.version, metas)
    }
  }
}

///|
fn build_full_graph(
  opts : CliOptions,
) -> (@graph.DependencyGraph, String, Map[String, @analyze.NodeMeta]) {
  build_full_graph_for_dir(".", opts)
}

///|
fn build_node_metas(
  modules : Map[String, @parse.Module],
  commit_days : Map[String, Int],
  root_dir : String,
  root_name : String,
) -> Map[String, @analyze.NodeMeta] {
  let metas : Map[String, @analyze.NodeMeta] = Map([])
  let fs = @cache.FileSystem::node_js()
  let cache_root = ".mooncakes"
  for pair in modules {
    let (id, mod) = pair
    let days = match commit_days.get(id) {
      Some(d) => Some(d)
      None => None
    }
    let (name, _) = split_node_id(id)
    // root 包的源文件目录是项目目录（root_dir），不是 .mooncakes 缓存子目录。
    // 其它包先尝试 .mooncakes cache；命中 → 真实扫描，否则降级。
    let pkg_dir = if name == root_name {
      root_dir
    } else {
      @analyze.locate_package_dir(cache_root, name, fs)
    }
    let has_pkg_dir = match (fs.readdir)(pkg_dir) {
      Some(_) => true
      None => false
    }
    let meta = if has_pkg_dir {
      // 真实扫描：LICENSE 文件 + 实际体积 + 废弃 API + public API 数（F01）
      // F06: mod.latest_version 来自 moon.mod.json 的 _latest_version 扩展字段
      // （仅离线 mock 注册表使用，用于模拟过时依赖）
      @analyze.build_realistic_node_meta(
        pkg_dir,
        mod.license,
        fs,
        mod.latest_version,
        days,
      )
    } else {
      // 降级：仅用 moon.mod 声明
      @analyze.NodeMeta::new(
        license=mod.license,
        deprecated_apis=[],
        latest_version=None,
        self_size=0,
        last_commit_days_ago=days,
      )
    }
    metas[id] = meta
  }
  metas
}

///|
fn build_node_metas_from_single(
  root_mod : @parse.Module,
  root_dir : String,
) -> Map[String, @analyze.NodeMeta] {
  let metas : Map[String, @analyze.NodeMeta] = Map([])
  let root_id = root_mod.name + "@" + root_mod.version
  let fs = @cache.FileSystem::node_js()
  // F02 真实体积（项目目录下 .mbt 源文件字节数总和）
  // F01 真实 public API 总数 & 真实废弃 API & LICENSE
  let has_pkg_dir = match (fs.readdir)(root_dir) {
    Some(_) => true
    None => false
  }
  if has_pkg_dir {
    metas[root_id] = @analyze.build_realistic_node_meta(
      root_dir,
      root_mod.license,
      fs,
      None,
      None,
    )
  } else {
    metas[root_id] = @analyze.NodeMeta::new(
      license=root_mod.license,
      deprecated_apis=[],
      latest_version=None,
      self_size=0,
    )
  }
  metas
}

///|
fn build_mock_graph(pkg : String) -> @graph.DependencyGraph {
  let graph = @graph.DependencyGraph::new()
  graph.add_node(pkg, "1.0.0", 0)
  graph.add_node("a", "1.0.0", 1)
  graph.add_node("b", "1.0.0", 1)
  graph.add_node("c", "1.0.0", 2)

  graph.add_edge(pkg, "1.0.0", "a", "1.0.0")
  graph.add_edge(pkg, "1.0.0", "b", "1.0.0")
  graph.add_edge("a", "1.0.0", "c", "1.0.0")

  graph
}
