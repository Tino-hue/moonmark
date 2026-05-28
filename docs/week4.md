# Week 4 验收报告 — 测试、性能与集成

> 周期：Day 22 — Day 28（2026/05/28 — 2026/06/04）

## 本周完成内容

### Day 22 — 测试框架搭建
- 建立 4 层测试金字塔：单元测试 → 集成测试 → 端到端测试 → 性能测试
- 统一测试命令：`moon test --target js`（普通 204 个）和 `moon test --target js --no-skip`（含 8 个性能测试）
- 测试数据管理：将 fixture 数据抽离到 `test/fixtures/*.json`，避免硬编码在测试代码中

### Day 23 — 生态采样与数据收集
- 构造 10 包生态采样数据（`test/ecosystem_test.mbt`）：模拟 `moonbitlang/core`、`x`、`xlsx` 等真实包
- 通过 `RegistryFetcher` mock 替换 HTTP 层，实现无网络依赖的集成测试
- 验证循环依赖检测（`CYCLE-001`）在复杂图中的准确性

### Day 24 — 性能基准测试
- 使用 JS FFI `Date.now()` 实现 `simple_bench` 微秒级计时器
- 测量 4 个阶段：Graph Build、Analysis、Report Rendering、End-to-End
- 写 `test/benchmark_test.mbt`：8 个性能测试（3 种规模 × 4 个阶段），默认 `#skip` 标记
- 写 `docs/benchmark.md`：测试环境、阈值表、瓶颈分析
- **关键发现**：HTML `escape_html` 逐字符处理为大图（200 节点）主要开销；真实网络场景下并发 fetch 为最大风险

### Day 25 — Bug 修复日
- 批量修复 11 个测试文件中 `deprecated_syntax` 警告（`inspect!` → `inspect`，`fail!` → `fail`，~181 处）
- 修复 `semver.mbt` 负数版本号 edge case
- 新增 `test/edge_case_test.mbt`：17 个测试覆盖空依赖、自依赖、8 种异常版本号
- 修复 `ecosystem_test.mbt` unused_field 和 `cli/cli.mbt` redundant_modifier 警告
- Linter 零警告

### Day 26 — 端到端集成测试
- 扩展 `cli/cli_test.mbt`：12 个 `parse_args` 测试（组合参数、顺序无关性、错误输入）
- 新建 `test/e2e_test.mbt`：13 个 E2E 测试，覆盖完整 pipeline
  - 最小/多依赖/全可选字段 `moon.mod.json` 解析 → GraphBuilder → Analysis → Report
  - 兼容性：无 deps 字段、空版本字符串
  - 离线场景：本地 registry mock
  - 报告格式验证：HTML 结构完整性、JSON schema
  - 异常路径：畸形 JSON、fetch 失败、循环依赖

### Day 27 — 跨平台测试
- 修复 `cache.mbt` 中 4 处硬编码 `/` 路径分隔符，改为 Node.js `path.join`
- 新增 `path_join`、`path_sep` JS FFI + `platform_path_sep()`、`platform_home_dir()`、`join_path()` pub API
- 新增 `test/cross_platform_test.mbt`：10 个测试覆盖路径分隔符、LF/CRLF 换行符、Unicode 编码、真实 FS 缓存操作
- Windows 本机完整 CLI 验证：`tree`、`audit`、`audit --json`、`report --html`、`-h`、`-v` 全部通过

## 测试覆盖率统计

| 层级 | 文件 | 测试数 | 说明 |
|------|------|--------|------|
| 单元测试 | `analyze/*_test.mbt` | 40+ | semver、license、health score、deprecated、size、terminal、html、audit reporter |
| 单元测试 | `graph/*_test.mbt` | 20+ | graph builder、topological sort、cycle detection |
| 单元测试 | `parse/*_test.mbt` | 12 | moon.mod.json parser edge cases |
| 单元测试 | `cache/*_test.mbt` | 4 | CacheManager set/get/clear/purge |
| 集成测试 | `test/ecosystem_test.mbt` | 6 | 10 包生态采样，完整 pipeline |
| 集成测试 | `test/edge_case_test.mbt` | 17 | 空依赖、自依赖、异常版本号 |
| 集成测试 | `test/cross_platform_test.mbt` | 10 | 路径、换行符、编码、FS 缓存 |
| E2E 测试 | `test/e2e_test.mbt` | 13 | moon.mod.json → graph → analysis → report |
| CLI 测试 | `cli/cli_test.mbt` | 24 | 参数解析、命令执行、退出码 |
| 性能测试 | `test/benchmark_test.mbt` | 8 (#skip) | 3 种规模 × 4 个阶段，阈值验证 |
| **总计** | | **214 / 204+8** | 204 默认运行，8 个性能测试 `--no-skip` 运行 |

## 性能基准结果

| 指标 | 小图 (4 节点) | 中图 (50 节点) | 大图 (200 节点) | 阈值 | 状态 |
|------|--------------|----------------|-----------------|------|------|
| Graph Build | ~50 μs | ~2 ms | ~8 ms | < 100 ms | ✅ |
| Analysis | ~30 μs | ~1 ms | ~4 ms | < 100 ms | ✅ |
| Report Render (Terminal) | ~20 μs | ~0.5 ms | ~2 ms | < 100 ms | ✅ |
| Report Render (HTML) | ~100 μs | ~5 ms | ~25 ms | < 100 ms | ✅ |
| End-to-End | ~200 μs | ~9 ms | ~40 ms | < 10 s | ✅ |

> 注：性能测试在本地 Windows + Node.js v24 上运行，结果可能因硬件而异。

## 已知问题与限制

1. **网络层未实现真实请求**：`fetch/` 包目前仅提供抽象和 mock 测试，未封装 Node.js `https`/`fetch` FFI。CLI 中 `build_mock_graph` 使用硬编码数据，尚未接入真实 mooncakes.io / GitHub raw。
2. **wasm-gc 后端编译限制**：`cache.mbt` 中的 `extern "js"` FFI 在 `wasm-gc` 后端会报错（`E4156`），因此 CI 仅测试 JS 目标。这是预期行为，因为文件系统操作需要宿主环境支持。
3. **异步操作未支持**：当前所有 fetch 和 FS 操作均为同步模拟。真实网络场景需要异步支持，MoonBit 社区正在推进相关特性。
4. **HTML 报告体积**：200 节点大图的 HTML 报告约 25KB，渲染耗时 ~25ms。`escape_html` 逐字符处理是主要开销，未来可考虑批量替换优化。

## 本地验证指南

```bash
# 普通测试（204 个，秒级完成）
moon test --target js

# 含性能测试（额外 8 个，约 30-60 秒）
moon test --target js --no-skip

# 构建 JS 产物
moon build --target js

# 运行 CLI（Windows）
node _build/js/debug/build/depsight.js tree root
node _build/js/debug/build/depsight.js audit
node _build/js/debug/build/depsight.js audit --json
node _build/js/debug/build/depsight.js report --html -o report.html
```

## 提交记录

```
69c223f feat(day26): end-to-end integration tests
fa02618 feat(day27): cross-platform path handling and CLI verification
```