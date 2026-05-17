# Usage Guide

## Installation

### Prerequisites

```bash
npm install -g tree-sitter-cli
```

### Clone and Build

```bash
git clone https://github.com/Tino-hue/moonmark.git
cd moonmark
npm install
tree-sitter generate
```

## Editor Integration

### VSCode

1. Install [Tree-sitter Extension](https://marketplace.visualstudio.com/items?itemName=pydow.tree-sitter)
2. Copy `editors/vscode/` to your VSCode extensions directory
3. Select MoonBit Dark or Light theme

### Neovim

Add to your `init.lua`:

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

### Helix

Add to `~/.config/helix/languages.toml`:

```toml
[[language]]
name = "moonbit"
scope = "source.moonbit"
file-types = ["mbt"]
comment-token = "//"

[language.grammar]
source = { git = "https://github.com/Tino-hue/moonmark.git", subpath = "src", rev = "main" }
```

## Testing

```bash
# Generate parser from grammar.js
tree-sitter generate

# Parse a file
tree-sitter parse examples/demo.mbt

# Highlight a file
tree-sitter highlight examples/demo.mbt

# Build WASM for web playground
tree-sitter build-wasm
```
