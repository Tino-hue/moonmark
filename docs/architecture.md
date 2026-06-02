# MoonBit Depsight 架构设计

## 系统概览

MoonBit Depsight 是一个模块化的依赖健康诊断工具，采用分层架构设计，各模块职责清晰、耦合度低。

```
┌─────────────────────────────────────────────────────────────┐
│                        CLI Layer                            │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  main.mbt → cli/cli.mbt (参数解析 + 命令分发)        │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     Analysis Engine                         │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────┐   │
│  │ analyzer.mbt │ │ health_score │ │ deprecated_propagate│   │
│  │   (主控)      │ │   .mbt       │ │     .mbt          │   │
│  └──────────────┘ └──────────────┘ └──────────────────┘   │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────┐   │
│  │ semver.mbt   │ │ license.mbt  │ │    size.mbt      │   │
│  │  (版本解析)   │ │  (许可证)    │ │    (体积分析)     │   │
│  └──────────────┘ └──────────────┘ └──────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Graph Layer                            │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────┐   │
│  │  graph.mbt   │ │ builder.mbt  │ │                  │   │
│  │  (数据结构)   │ │  (图构建)    │ │                  │   │
│  └──────────────┘ └──────────────┘ └──────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     Data Layer                              │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────┐   │
│  │  parse.mbt   │ │  fetch.mbt   │ │   cache.mbt      │   │
│  │  (解析器)     │ │  (网络获取)  │ │   (缓存管理)     │   │
│  └──────────────┘ └──────────────┘ └──────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Output Layer                             │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────┐   │
│  │ reporter.mbt │ │html_reporter │ │ sarif_reporter.mbt│   │
│  │ (终端报告)    │ │   .mbt       │ │   (SARIF)        │   │
│  └──────────────┘ └──────────────┘ └──────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## 数据流

```
moon.mod.json
     │
     ▼
┌─────────────────┐
│   Parser Layer  │
│  parse_module() │
└────────┬────────┘
         │ Module { name, version, deps }
         ▼
┌─────────────────┐
│   Fetch Layer   │
│ fetch_package() │ ◄── Registry API (GitHub raw)
└────────┬────────┘
         │ Module[]
         ▼
┌─────────────────┐
│   Graph Layer   │
│ build_graph()   │ ◄── DFS + Cycle Detection
└────────┬────────┘
         │ DependencyGraph
         ▼
┌─────────────────┐
│ Analysis Layer  │
│ run_analysis()  │ ◄── 5-Dimension Scoring
└────────┬────────┘
         │ AnalysisReport
         ▼
┌─────────────────┐
│  Output Layer   │
│ render_*()      │ ◄── Terminal/HTML/JSON/SARIF
└─────────────────┘
```

## 核心模块详解

### 1. Parse Layer (`parse/`)

**职责**：解析 `moon.mod.json` 和 `.depsight.toml` 配置文件

**核心数据结构**：
```moonbit
pub struct Module {
  name : String
  version : String
  deps : Map[String, String]  // package -> version constraint
  license : String?
  repository : String?
  description : String?
}
```

**关键函数**：
- `parse_mod_json(content : String) -> Result[Module, String]`
- `parse_mod_toml(content : String) -> Result[Module, String]`
- `parse_config_toml(content : String) -> Map[String, String]`

### 2. Fetch Layer (`fetch/`)

**职责**：从 mooncakes.io / GitHub 获取包元数据

**设计模式**：可插拔 Registry 抽象

```moonbit
pub struct Registry {
  defaults : Map[String, String]  // 包名 -> GitHub 仓库映射
  cache : CacheManager?
}

impl Registry {
  pub fn fetch(
    self : Registry,
    http_get : (String) -> Result[String, String],
    name : String,
    version : String,
    offline : Bool
  ) -> Result[String, String]
}
```

**网络策略**：
1. 优先使用预定义映射（7 个官方包）
2. 智能推断：`owner/repo` 格式 → 直接作为 GitHub 仓库
3. 命名空间回退：`moonbitlang/` → `moonbit-community/`
4. 离线模式使用本地缓存
5. 所有源失败时，优雅降级为本地依赖图

### 3. Graph Layer (`graph/`)

**职责**：构建依赖图、检测循环、拓扑排序

**核心数据结构**：
```moonbit
pub struct DependencyGraph {
  nodes : Map[String, DependencyNode]
}

pub struct DependencyNode {
  name : String
  version : String
  depth : Int
  parents : Array[String]
  children : Array[String]
}
```

**关键算法**：
- **DFS 递归构建**：`GraphBuilder::build()`
- **拓扑排序**：Kahn 算法 `topological_sort()`
- **循环检测**：DFS 三色标记 `find_cycle()`

### 4. Analysis Layer (`analyze/`)

**职责**：五维健康评分 + 诊断生成

**评分模型**：
```
Total = Freshness × 25%
      + Compliance × 20%
      + DeprecatedDensity × 25%
      + SizeReasonableness × 20%
      + Activity × 10%
```

**维度打分规则**：

| 维度 | 评分规则 |
|------|----------|
| Freshness | 最新版=100, 次新版=95, 小版本差=80, 大版本差=60 |
| Compliance | 无许可证=80, 高风险=0, 其他=100 |
| DeprecatedDensity | 无废弃=100, <10%=90, <30%=70, <50%=50, >50%=20 |
| SizeReasonableness | <10KB=100, <100KB=90, <1MB=70, <5MB=50, >5MB=20 |
| Activity | ≤30天=100, ≤90天=80, ≤180天=60, ≤365天=40, >365天=20 |

### 5. Output Layer (`analyze/`)

**职责**：生成多种格式的报告

| 格式 | 函数 | 用途 |
|------|------|------|
| Terminal | `render_terminal_report()` | 终端彩色输出 |
| HTML | `render_html_report()` | 交互式 Web 报告 |
| JSON | `render_audit_json()` | CI/CD 集成 |
| SARIF | `render_sarif_report()` | GitHub Code Scanning |

### 6. CLI Layer (`cli/`)

**职责**：参数解析、命令分发、CI 退出码

**命令体系**：
```
depsight
├── tree [package]     # 依赖树可视化
├── audit              # 依赖审计
│   ├── --json         # JSON 输出
│   ├── --sarif        # SARIF 输出
│   ├── --severity     # 级别过滤
│   └── --fail-on-*    # CI 退出码
└── report             # 完整报告
    ├── --html         # HTML 报告
    └── -o <file>      # 文件输出
```

## 模块依赖关系

```
main.mbt
  └── cli/cli.mbt
        ├── parse/module.mbt
        ├── fetch/fetch.mbt
        ├── graph/graph.mbt
        │     └── graph/builder.mbt
        ├── analyze/analyzer.mbt
        │     ├── analyze/semver.mbt
        │     ├── analyze/license.mbt
        │     ├── analyze/deprecated.mbt
        │     ├── analyze/deprecated_propagate.mbt
        │     ├── analyze/size.mbt
        │     └── analyze/health_score.mbt
        ├── analyze/reporter.mbt
        ├── analyze/html_reporter.mbt
        ├── analyze/sarif_reporter.mbt
        ├── cache/cache.mbt
        └── report/diagnostic.mbt
```

## 设计原则

### 1. 单一职责
每个模块只负责一个功能领域，边界清晰。

### 2. 依赖倒置
高层模块不依赖低层模块，都依赖抽象（如 `Registry` 接口）。

### 3. 可测试性
- 核心逻辑与 I/O 分离（网络、文件系统通过 FFI 注入）
- Mock 数据支持离线测试

### 4. 可扩展性
- 新增输出格式只需添加 `*_reporter.mbt`
- 新增诊断维度只需在 `analyzer.mbt` 中添加检查

## 已知限制

1. **网络依赖**：mooncakes.io 无公开 API，当前使用 GitHub raw 回退 + 智能推断
2. **体积分析**：`self_size` 默认为 0，需编译器支持
3. **废弃 API**：基于 doc comment 正则，非 AST 解析
4. **并发限制**：MoonBit JS FFI 不支持异步，网络请求为同步阻塞
5. **包发现**：无法自动发现 mooncakes.io 上的所有包，依赖预定义映射或 GitHub 推断

## 未来演进

| 阶段 | 目标 | 依赖 |
|------|------|------|
| v0.5.0 | 接入 mooncakes.io 正式 API | 生态 API 稳定 |
| v0.6.0 | 符号级体积归因 | 编译器体积数据接口 |
| v0.7.0 | AST 级废弃 API 检测 | MoonBit parser 库 |
| v1.0.0 | 并发 fetch + 增量分析 | MoonBit async 支持 |
