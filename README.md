# MoonHighlight — Tree-sitter Grammar for MoonBit

> 为 MoonBit 编程语言提供精准语法高亮和语义分析的 Tree-sitter 语法库

[![CI](https://github.com/Tino-hue/moonmark/actions/workflows/ci.yml/badge.svg)](https://github.com/Tino-hue/moonmark/actions/workflows/ci.yml)
[![npm version](https://img.shields.io/npm/v/moonhighlight?label=moonhighlight)](https://www.npmjs.com/package/moonhighlight)
[![Tree-sitter](https://img.shields.io/badge/tree--sitter-v0.26-blue)](https://tree-sitter.github.io/tree-sitter/)
[![MoonBit](https://img.shields.io/badge/MoonBit-v0.9.2-orange)](https://www.moonbitlang.cn/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green)](LICENSE)

---

## 支持语法特性一览

| 类别 | 覆盖内容 | 状态 |
|------|---------|------|
| 🔤 词法 | 关键字（50+）、运算符、字面量、注释 | ✅ 100% |
| 📦 声明 | fn / let / const / type / struct / enum / trait / impl / suberror | ✅ 100% |
| 💬 表达式 | 字面量、调用、方法、闭包、管道符 `\|>` | ✅ 100% |
| 🔀 控制流 | if / match / guard / while / for / loop / break | ✅ 100% |
| 🎯 模式匹配 | 通配 / 字面 / 构造器 / 范围 / or 模式 | ✅ 100% |
| 🏷️ 类型系统 | 内置类型 / 泛型 / 元组 / 函数类型 / Result / Option | ✅ 100% |
| 🏷️ 属性 | `#[deprecated]` / `#[cfg]` / `#[inline]` 等 | ✅ 100% |
| ⚠️ 错误处理 | raise / try–catch / suberror / noraise | ✅ 100% |
| ⚡ 异步 | async fn / await / defer / task 组 | ✅ 100% |
| 📝 字符串 | 普通 / 原始 `#\|...\|\#` / 插值 `$"..."` / 字节 | ✅ 100% |

---

## 支持的编辑器

| 编辑器 | 状态 | 安装方式 |
|--------|------|---------|
| **VSCode** | ✅ 完整支持 | 见下方 [VSCode 安装](#vscode-安装) |
| **Neovim** | ✅ 配置就绪 | 见下方 [Neovim 安装](#neovim-安装) |
| **Helix** | ✅ 配置就绪 | 见下方 [Helix 安装](#helix-安装) |
| **Zed** | 🔜 规划中 | 等待 Tree-sitter 原生集成 |
| **GitHub** | ✅ 开箱即用 | 自动识别 `.mbt` 文件 |

---

## 快速安装

### 前置依赖

```bash
# 安装 tree-sitter CLI (v0.23+)
npm install -g tree-sitter-cli

# 确认安装成功
tree-sitter --version
```

### 生成解析器

```bash
git clone https://github.com/Tino-hue/moonmark.git
cd moonmark
tree-sitter generate   # 从 grammar.js 生成 src/parser.c
```

---

## 编辑器配置

### VSCode 安装

1. 安装官方 [Tree-sitter Extension](https://marketplace.visualstudio.com/items?itemName=pydow.tree-sitter)
2. 将 `editors/vscode/` 目录复制到你的 VSCode 扩展目录，或修改已有扩展的 `package.json`：

```json
{
  "contributes": {
    "languages": [{
      "id": "moonbit",
      "extensions": [".mbt"],
      "configuration": "./language-configuration.json"
    }],
    "grammars": [{
      "language": "moonbit",
      "scopeName": "source.moonbit",
      "path": "path/to/moonmark/queries/highlights.scm"
    }]
  }
}
```

3. 选择主题：**MoonBit Dark** 或 **MoonBit Light**（已随仓库提供）

### Neovim 安装

在 `init.lua` 中添加：

```lua
local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
parser_config.moonbit = {
  install_info = {
    url = "https://github.com/Tino-hue/moonmark.git",
    files = { "src/parser.c", "src/scanner.c" },
    branch = "main",
  },
  filetype = "moonbit",
}

vim.filetype.add({ extension = { mbt = "moonbit" } })

require'nvim-treesitter.configs'.setup {
  ensure_installed = { "moonbit" },
  highlight = { enable = true },
}
```

### Helix 安装

在 `~/.config/helix/languages.toml` 中添加：

```toml
[[language]]
name = "moonbit"
scope = "source.moonbit"
file-types = ["mbt"]
roots = []
comment-token = "//"

[language.grammar]
source = { git = "https://github.com/Tino-hue/moonmark.git", subpath = "src", rev = "main" }
```

---

## 配色方案预览

### Dark 主题（Dracula 风格）

![Dark Theme](https://via.placeholder.com/600x300/282A36/F8F8F2?text=MoonBit+Dark+Theme)

| 元素 | 颜色 | 效果 |
|------|------|------|
| 关键字 | `#FF79C6` 粉红 | 正常 |
| 类型 | `#8BE9FD` 青色 | 正常 |
| 函数 | `#50FA7B` 绿色 | 正常 |
| 字符串 | `#F1FA8C` 黄色 | 正常 |
| 数字 | `#BD93F9` 紫色 | 正常 |
| 注释 | `#6272A4` 灰色 | 斜体 |
| 属性 | `#E9F068` 青柠 | 正常 |
| 异常 | `#FF5555` 红色 | 斜体 |

### Light 主题（GitHub 风格）

![Light Theme](https://via.placeholder.com/600x300/FFFFFF/24292E?text=MoonBit+Light+Theme)

| 元素 | 颜色 | 效果 |
|------|------|------|
| 关键字 | `#D73A49` 红色 | 正常 |
| 类型 | `#005CC5` 蓝色 | 正常 |
| 函数 | `#22863A` 绿色 | 正常 |
| 字符串 | `#032F62` 深蓝 | 正常 |
| 数字 | `#005CC5` 蓝色 | 正常 |
| 注释 | `#6A737D` 灰色 | 斜体 |

---

## 开发命令

```bash
# 生成 C 解析器
tree-sitter generate

# 运行全部语料测试（25 个覆盖全部语法）
tree-sitter test

# 解析单个文件（可视化 AST）
tree-sitter parse examples/demo.mbt

# 渲染 AST 为 PNG 图片
tree-sitter render examples/demo.mbt -o ast.png

# 构建 WASM 模块（用于 Web Playground）
tree-sitter build-wasm

# 启动 Web Playground
npx tree-sitter playground examples/demo.mbt

# Node.js 原生绑定构建
npm install
npm run install:node   # 编译 bindings/node/moonhighlight.node
```

---

## 项目结构

```
moonmark/
├── grammar.js              # 核心语法定义（~24KB，~300 条规则）
├── src/
│   ├── scanner.c           # 外部扫描器（复杂字符串处理）
│   ├── parser.c            # 自动生成（勿手动修改）
│   └── tree_sitter/        # 自动生成（勿手动修改）
├── queries/
│   ├── highlights.scm      # 语法高亮查询（120+ 条规则）
│   ├── injections.scm      # 语言注入（字符串插值）
│   ├── indents.scm         # 缩进规则
│   └── locals.scm          # 变量作用域规则
├── corpus/
│   └── test_moonbit.txt    # 25 个测试用例（~15KB）
├── editors/
│   ├── vscode/             # VSCode 扩展配置 + 主题
│   ├── neovim.lua          # Neovim nvim-treesitter 配置
│   └── helix.toml          # Helix 编辑器配置
├── examples/
│   └── demo.mbt            # 完整语法展示示例
├── bindings/
│   └── node/               # Node.js 绑定
├── package.json            # npm 包配置
├── README.md               # 项目文档（本文件）
├── CONTRIBUTING.md         # 贡献指南
├── CLAUDE.md               # 项目技术文档
└── LICENSE                 # MIT 许可证
```

---

## 测试用例展示

运行 `tree-sitter test` 将验证以下全部语法特性：

```
✓ 1. Basic declarations (fn/let/return types)
✓ 2. Struct with derive clause
✓ 3. Enum variant payloads
✓ 4. Trait with super traits
✓ 5. Impl block methods
✓ 6. Pattern matching (constructor patterns)
✓ 7. Guard expressions
✓ 8. Error handling (try/catch/raise)
✓ 9. Async function syntax
✓ 10. String interpolation
✓ 11. For loop with range patterns
✓ 12. Closure expressions
✓ 13. Generic type parameters
✓ 14. Attributes (#[deprecated], #[inline])
✓ 15. Struct creation and update
✓ 16. Enum creation (Color::Rgb(...))
✓ 17. Pipeline operator (|> )
✓ 18. Type alias
✓ 19. Suberror declarations
✓ 20. Defer expressions
✓ 21. Loop with break
✓ 22. Comments (line + block)
✓ 23. Package clause and imports
✓ 24. Raw multi-line strings
✓ 25. Byte literals and byte strings
```

---

## 技术实现细节

### 为什么需要 `scanner.c`？

Tree-sitter 的 `grammar.js` 无法处理以下复杂词法结构，需要外部 C 扫描器：

1. **字符串插值** `$"Hello, \{name}!"` — 需要递归追踪 `{...}` 嵌套深度
2. **原始字符串** `#|...|#` — 需要扫描到终结符 `|#`
3. **字节字面量** `b'...'` 和 `b"..."` — 需要与常规字符串区分
4. **转义序列** — `"Hello\nWorld"` 中的 `\n` 需要正确识别

`scanner.c` 实现了完整的 Tree-sitter 外部扫描器 API：
- `tree_sitter_moonbit_external_scanner_create()` — 初始化状态
- `tree_sitter_moonbit_external_scanner_scan()` — 主扫描逻辑
- `serialize()` / `deserialize()` — 支持增量解析的状态序列化

### 高亮查询设计

`queries/highlights.scm` 使用 Tree-sitter 的 `@capture` 机制，将 AST 节点映射到 TextMate 作用域名称：

```scheme
(function_declaration (identifier) @function)   ; 函数名 → @function
(type_identifier) @type                        ; 类型名 → @type
(call_expr (identifier) @function.call)        ; 调用 → @function.call
```

支持 36 种不同作用域，包括：
- `@keyword`, `@type`, `@function`, `@variable`
- `@string`, `@number`, `@comment`, `@operator`
- `@attribute`, `@exception`, `@module`

---

## 参与贡献

详见 [CONTRIBUTING.md](CONTRIBUTING.md)

快速开始：

```bash
# Fork 本仓库后克隆
git clone https://github.com/<your-username>/moonmark.git
cd moonmark

# 创建功能分支
git checkout -b feat/your-feature

# 修改 grammar.js 后重新生成
tree-sitter generate

# 运行测试确保通过
tree-sitter test

# 提交 PR
git push origin feat/your-feature
```

---

## 相关链接

- [Tree-sitter 官方文档](https://tree-sitter.github.io/tree-sitter/)
- [MoonBit 官方文档（中文）](https://docs.moonbitlang.cn)
- [MoonBit 官网](https://www.moonbitlang.cn/)
- [TextMate 作用域命名规范](https://macromates.com/manual/en/language_grammars)
- [tree-sitter-rust](https://github.com/tree-sitter/tree-sitter-rust) — 语法参考
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)

---

## 许可证

[MIT License](LICENSE) — 可自由使用、修改和分发。

---

## 作者

**Tino-hue（肖若愚）**

- GitHub: [@Tino-hue](https://github.com/Tino-hue)
- 参赛项目：2026 MoonBit 国产基础软件开源大赛

---

> 🌙 **MoonHighlight** — 让 MoonBit 代码在任意编辑器中都能拥有精准、美观的语法高亮。