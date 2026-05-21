# MoonBit Language Server

> 基于 Tree-sitter 的 MoonBit 跨编辑器语义服务与智能 IDE 核心

[![License: MIT](https://img.shields.io/badge/License-MIT-green)](LICENSE)

---

## 项目定位

MoonBit Language Server（MBT-LS）是 MoonBit 生态中首个**开源、跨编辑器**的 Language Server Protocol（LSP）实现。它基于 Tree-sitter 增量解析引擎，向上层编辑器提供符号表、实时诊断、自动补全、定义跳转、悬停提示等标准语义服务，让 MoonBit 在 VSCode、Neovim、Helix、Zed 等任意 LSP 兼容编辑器中都能获得 IDE 级智能体验。

**与官方生态的关系**：官方 `tree-sitter-moonbit` 与本项目的 Tree-sitter Grammar 负责语法前端（词法/语法解析），MBT-LS 在其之上构建语言服务端，与官方形成**上下游互补**关系，而非替代。

---

## 核心功能

**1. 增量语法解析**

基于 Tree-sitter 实现 MoonBit 完整语法解析，覆盖关键字、标识符、类型、表达式、模式匹配、属性、异步、错误处理等全部语法单元。

**2. 语义分析引擎**

符号表构建、作用域分析、引用追踪，基于 AST 自动收集函数声明、变量绑定、类型定义，并生成实时诊断信息。

**3. LSP 协议服务**

`textDocument/diagnostic`（实时错误检测）、`textDocument/documentSymbol`（文档大纲）、`textDocument/completion`（自动补全）、`textDocument/definition`（跳转定义）、`textDocument/hover`（悬停提示）。

**4. 跨编辑器客户端**

VSCode Extension（LSP Client）支持增量文档同步与 LSP 消息收发。

**5. 配套语法高亮**

Tree-sitter queries（`highlights.scm`、`indents.scm`、`injections.scm`、`locals.scm`）提供 AST 级语法高亮、缩进规则与字符串插值注入。

---

## 项目结构

```
moonmark/
├── grammar.js                  # Tree-sitter 语法定义（解析器前端）
├── src/
│   ├── scanner.c               # 外部扫描器
│   └── parser.c                # 自动生成（Tree-sitter CLI）
├── server/
│   ├── src/
│   │   ├── server.ts           # LSP 入口（Connection / Documents / Handlers）
│   │   ├── parser.ts           # Tree-sitter 内存解析器（Node binding）
│   │   └── analyzer.ts         # 语义分析引擎（符号表 / 诊断 / 补全 / 跳转）
│   ├── package.json
│   └── tsconfig.json
├── client/
│   └── vscode/
│       ├── src/
│       │   └── extension.ts    # VSCode LSP Client 启动逻辑
│       ├── package.json
│       └── tsconfig.json
├── queries/
│   ├── highlights.scm          # 语法高亮查询（附加价值）
│   ├── injections.scm          # 语言注入
│   ├── indents.scm             # 缩进规则
│   └── locals.scm              # 作用域规则
├── editors/
│   ├── vscode/                 # 配套语法高亮 + 主题插件
│   ├── neovim/                 # Neovim 配置
│   └── helix/                  # Helix 配置
├── bindings/node/              # Tree-sitter Node.js binding
├── test/corpus/                # Tree-sitter 语料测试
└── examples/
    └── demo.mbt                # 语法展示示例
```

---

## 快速开始

### 前置依赖

```bash
# Node.js >= 18
node --version

# Tree-sitter CLI (用于生成/测试 parser)
npm install -g tree-sitter-cli
```

### 构建解析器

```bash
# 生成 C 解析器与 Node binding
tree-sitter generate

# 构建 Node.js native binding（供 LSP server 内存内解析）
npm install
# 若 binding 未生成，执行：
# node-gyp rebuild 或 npm run install:node
```

### 启动 Language Server

```bash
cd server
npm install
npm run build       # tsc 编译到 out/
node out/server.js  # 以 stdio 方式启动 LSP server
```

### 启动 VSCode Client（开发调试）

```bash
cd client/vscode
npm install
npm run build       # tsc 编译到 out/
# 然后在 VSCode 中按 F5 运行 Extension Host
```

### 运行语料测试

```bash
tree-sitter test
```

---

## 编辑器支持

| 编辑器 | 支持方式 |
|--------|---------|
| **VSCode** | 本仓库 `client/vscode`（LSP Client） |
| **Neovim** | 任意 LSP Client 连接 MBT-LS |
| **Helix** | 内置 LSP 连接 MBT-LS |
| **Zed** | 内置 LSP 连接 MBT-LS |

> 语法高亮（Tree-sitter queries）已在 VSCode/Neovim/Helix 中可用，属于附加价值。

---

## 开发路线

1. **Phase 1 — 语法与解析**
   - 完整的 Tree-sitter Grammar 覆盖 MoonBit v0.9.2 全部语法
   - 语料测试用例确保解析正确性

2. **Phase 2 — 语义引擎**
   - 符号表与作用域分析
   - 实时诊断（语法错误、基础语义检查）
   - 自动补全、定义跳转、悬停提示

3. **Phase 3 — 生态集成**
   - VSCode Extension 打包发布
   - 多编辑器配置文档与自动化脚本
   - CI/CD 与性能基准测试

---

## 许可证

[MIT License](LICENSE)

---

> **MoonBit Language Server** — 让 MoonBit 在任何编辑器中都能拥有 IDE 级智能体验。
