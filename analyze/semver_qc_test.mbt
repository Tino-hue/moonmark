///|
/// SemVer 属性测试（QuickCheck）
///
/// 与 semver_test.mbt 的示例式单测互补：单测锁定关键点位，
/// 属性测试在随机输入空间上验证全域不变量 —— 全序公理（自反/反对称/传递）、
/// parse round-trip、约束语义 iff 规格。
/// 生成器将数值组件限制在小值域以提升碰撞率（相等/近邻版本更易被采样），
/// 反例经 counterexample_context 渲染为可读版本字符串（如 "1.2.3-alpha vs 1.2.3"）。

///|
/// 随机版本生成器：只产生语义合法的版本（非负组件 + 有限 prerelease 集合），
/// 保证反例可读、且 round-trip 属性中的 parse 一侧必然成功。
priv struct GenVersion {
  major : Int
  minor : Int
  patch : Int
  prerelease : String?
} derive(Debug)

///|
impl @qc.Arbitrary for GenVersion with fn arbitrary(_size, rs) {
  let tag = (rs.next_uint() % 5U).reinterpret_as_int()
  let prerelease : String? = match tag {
    0 => Some("alpha")
    1 => Some("alpha.1")
    2 => Some("beta")
    3 => Some("rc.1")
    _ => None
  }
  {
    major: (rs.next_uint() % 4U).reinterpret_as_int(),
    minor: (rs.next_uint() % 6U).reinterpret_as_int(),
    patch: (rs.next_uint() % 10U).reinterpret_as_int(),
    prerelease,
  }
}

///|
/// 空 Shrink（默认实现）：反例保持原始生成值，可读化交给 counterexample_context
impl @qc.Shrink for GenVersion

///|
/// 说明：_test.mbt 为黑盒测试，pub struct 对包外只读、不可字面量构造，
/// 故经 pub API parse_version 转换；渲染产物必然合法，Err 分支不可达。
fn GenVersion::to_version(self : GenVersion) -> Version {
  match parse_version(self.render()) {
    Ok(v) => v
    Err(_) => panic()
  }
}

///|
fn GenVersion::render(self : GenVersion) -> String {
  let base = "\{self.major}.\{self.minor}.\{self.patch}"
  match self.prerelease {
    Some(p) => base + "-" + p
    None => base
  }
}

///|
fn render_pair(pair : (GenVersion, GenVersion)) -> String {
  "\{pair.0.render()} vs \{pair.1.render()}"
}

///|
fn render_triple(triple : (GenVersion, GenVersion, GenVersion)) -> String {
  "\{triple.0.render()} vs \{triple.1.render()} vs \{triple.2.render()}"
}

///|
test "qc: compare is reflexive" {
  @qc.check(
    (g : GenVersion) => {
      let v = g.to_version()
      compare(v, v) == 0
    },
    counterexample_context=g => g.render(),
  )
}

///|
test "qc: compare is antisymmetric" {
  @qc.check(
    (pair : (GenVersion, GenVersion)) => {
      let v1 = pair.0.to_version()
      let v2 = pair.1.to_version()
      compare(v1, v2) == -compare(v2, v1)
    },
    counterexample_context=render_pair,
  )
}

///|
test "qc: compare is transitive" {
  @qc.check(
    (triple : (GenVersion, GenVersion, GenVersion)) => {
      let v1 = triple.0.to_version()
      let v2 = triple.1.to_version()
      let v3 = triple.2.to_version()
      if compare(v1, v2) < 0 && compare(v2, v3) < 0 {
        compare(v1, v3) < 0
      } else {
        true
      }
    },
    counterexample_context=render_triple,
  )
}

///|
test "qc: parse(render(v)) round-trips all fields" {
  @qc.check(
    (g : GenVersion) => {
      match parse_version(g.render()) {
        Ok(v) =>
          v.major == g.major &&
          v.minor == g.minor &&
          v.patch == g.patch &&
          v.prerelease == g.prerelease
        Err(_) => false
      }
    },
    counterexample_context=g => g.render(),
  )
}

///|
test "qc: caret constraint iff spec" {
  // ^base 的精确语义：major 锁定；base.major == 0 时退化为 minor 锁定 + patch 下界，
  // 否则按 (minor, patch) 数值字典序不低于 base（prerelease 不参与判定）
  @qc.check(
    (pair : (GenVersion, GenVersion)) => {
      let v = pair.0.to_version()
      let base = pair.1.to_version()
      let expected = if base.major == 0 {
        v.major == 0 && v.minor == base.minor && v.patch >= base.patch
      } else {
        v.major == base.major &&
        (
          v.minor > base.minor ||
          (v.minor == base.minor && v.patch >= base.patch)
        )
      }
      satisfies(v, "^\{pair.1.render()}") == expected
    },
    counterexample_context=render_pair,
  )
}

///|
test "qc: tilde constraint iff spec" {
  // ~base 的精确语义：major/minor 锁定 + patch 下界
  @qc.check(
    (pair : (GenVersion, GenVersion)) => {
      let v = pair.0.to_version()
      let base = pair.1.to_version()
      satisfies(v, "~\{pair.1.render()}") ==
      (v.major == base.major && v.minor == base.minor && v.patch >= base.patch)
    },
    counterexample_context=render_pair,
  )
}

///|
test "qc: exact constraint iff compare equal" {
  @qc.check(
    (pair : (GenVersion, GenVersion)) => {
      let v = pair.0.to_version()
      let base = pair.1.to_version()
      satisfies(v, "=\{pair.1.render()}") == (compare(v, base) == 0)
    },
    counterexample_context=render_pair,
  )
}

///|
test "qc: >= constraint iff compare greater or equal" {
  @qc.check(
    (pair : (GenVersion, GenVersion)) => {
      let v = pair.0.to_version()
      let base = pair.1.to_version()
      satisfies(v, ">=\{pair.1.render()}") == (compare(v, base) >= 0)
    },
    counterexample_context=render_pair,
  )
}
