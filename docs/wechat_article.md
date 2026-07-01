# MoonBit Depsight：MoonBit 生态依赖健康诊断工具

> 267 个测试用例，秒级通过。用 MoonBit 构建的依赖分析利器。

---

## 前言

在现代软件开发中，依赖管理是每个项目都无法回避的问题。随着依赖层层嵌套，安全漏洞、过时版本、许可证合规等风险也随之潜入。

**MoonBit Depsight** 就是为了解决这个问题而生的——它是 MoonBit 生态下的依赖健康诊断工具，能递归分析整个传递依赖树，在风险变成问题之前提前预警。

---

## 它能做什么？

### 1. 依赖树可视化

一行命令，递归展开整个依赖树：

```bash
depsight tree
depsight tree --depth 3
```

输出清晰的 ASCII 树形结构，支持 `--depth` 控制深度，内联诊断标记。

### 2. 五维健康评分

Depsight 采用 **5 维加权模型** 对每个依赖包进行评分：

| 维度 | 权重 | 说明 |
|------|------|------|
| 版本新鲜度 | 25% | 是否使用了最新版本 |
| 许可证合规 | 20% | 是否有高风险 copyleft 许可证 |
| 弃用密度 | 25% | 使用了多少已废弃的 API |
| 体积合理性 | 20% | 传递依赖的总大小 |
| 维护活跃度 | 10% | 最近是否有更新 |

最终输出一个 0-100 的健康分数，一目了然。

### 3. 多格式报告

支持终端、HTML、JSON、SARIF、Markdown 五种输出格式：

```bash
depsight report --html -o report.html    # 可视化 HTML 报告
depsight audit --json                     # JSON 结构化数据
depsight audit --sarif                    # GitHub Code Scanning 格式
depsight audit --markdown                 # GitHub README 兼容格式
```

### 4. CI/CD 集成

内置 CI 友好的退出码机制：

```bash
depsight audit --fail-on-score 80    # 健康分低于 80 时返回 exit code 1
depsight audit --fail-on-critical    # 发现 critical 问题时失败
```

支持 GitHub Actions 无缝集成。

### 5. 快速诊断

```bash
depsight outdated        # 检查过时依赖
depsight why <package>   # 追溯谁依赖了某个包
depsight check           # 一行健康检查（PASS/WARN/FAIL）
```

---

## 技术架构

项目采用模块化设计，结构清晰：

```
parse/       # moon.mod.json 解析器
fetch/       # 注册表抽象 & GitHub 内容获取
graph/       # 依赖图、拓扑排序、环检测
analyze/     # 核心分析引擎（semver、许可证、弃用检测、健康评分）
report/      # 诊断数据结构（Critical/Warning/Info）
cli/         # CLI 参数解析 & 命令分发
```

核心能力包括：

- **SemVer 语义版本分析**：支持 `^`、`~`、`~>`、`>=` 等约束匹配
- **许可证合规检测**：识别 12+ 种 SPDX 许可证，自动标记高风险 copyleft
- **弃用 API 扫描**：提取 `@deprecated` 注解，跨包反向追踪传播路径
- **环形依赖检测**：DFS 算法，结构化诊断输出 `CYCLE-001`
- **拓扑排序**：Kahn 算法，确保依赖顺序正确

---

## MoonBit 0.10.0 适配

最近项目完成了 **MoonBit 0.10.0 版本适配**，主要包含两项迁移：

### 模板写入语法迁移

MoonBit 0.10.0 引入了 `<+` 模板写入运算符，支持直接向 `StringBuilder` 写入模板内容：

```moonbit
// 旧写法
buf.write_string("Node: ")
buf.write_string(node_id)

// 新写法（MoonBit 0.10.0）
buf <+ "Node: \{node_id}"
```

项目 5 个报告渲染器（terminal、HTML、JSON、SARIF、Markdown）全部迁移至 `<+` 语法，累计删除 13 个手工拼接的 join 函数，代码更简洁、可读性更强。

### moon.mod 格式迁移

MoonBit 工具链推荐使用新的 `moon.mod` TOML 风格格式，替代旧的 `moon.mod.json`：

```toml
# 旧格式 moon.mod.json
{
  "name": "Tino-hue/depsight",
  "preferred-target": "js"
}

# 新格式 moon.mod
name = "Tino-hue/depsight"
preferred_target = "js"
```

依赖声明也从 JSON 对象改为 `import` 块：

```toml
import {
  "moonbitlang/core@0.4.8"
}
```

---

## 测试覆盖

项目目前拥有 **267 个测试用例**，全部通过：

```
Total tests: 267, passed: 267, failed: 0.
```

覆盖范围包括：

- 语义版本解析与约束匹配（52 个用例）
- 许可证合规检测（22 个用例）
- 弃用 API 扫描与传播追踪（25 个用例）
- 健康评分模型（34 个用例）
- 依赖图构建与拓扑排序（28 个用例）
- 五种报告渲染器输出验证（65 个用例）
- CLI 参数解析与边界场景（41 个用例）

---

## 性能表现

| 规模 | 节点数 | 图构建 | 分析 | 报告渲染 | 端到端 |
|------|--------|--------|------|----------|--------|
| 小型 | 5 | < 50ms | < 20ms | < 100ms | < 200ms |
| 中型 | 50 | < 200ms | < 100ms | < 500ms | < 1s |
| 大型 | 200 | < 1s | < 500ms | < 2s | < 5s |

*测试环境：Windows 11，Node.js v22.x，MoonBit JS debug 模式*

---

## 快速开始

### 从源码构建

```bash
git clone https://github.com/Tino-hue/moonmark.git
cd moonmark
moon build --target js
```

### 运行

```bash
node _build/js/debug/build/depsight.js audit
node _build/js/debug/build/depsight.js report --html -o report.html
```

---

## 开源地址

- **GitHub**: https://github.com/Tino-hue/moonmark
- **GitLink**: https://gitlink.org.cn/LittleFish/moonbit-depsight

---

## 写在最后

MoonBit 作为一门新兴的编程语言，其生态正在快速发展。Depsight 的目标是为这个生态提供可靠的依赖健康保障，让每一位 MoonBit 开发者都能安心地管理自己的项目依赖。

欢迎 Star、Issue、PR。
