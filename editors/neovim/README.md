# MoonBit Highlight for Neovim

Tree-sitter powered syntax highlighting for MoonBit in Neovim.

## Prerequisites

- Neovim 0.9+ (0.10+ recommended)
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) plugin installed
- C compiler (gcc/clang/msvc) for building the parser

## Installation

### Method 1: Local Development (Recommended)

1. Clone this repository to your local machine
2. Copy `neovim.lua` to your Neovim config:

```bash
# For lazy.nvim / packer users
cp editors/neovim.lua ~/.config/nvim/lua/plugins/moonbit.lua
```

3. Edit the path in `moonbit.lua` to point to your local clone:

```lua
parser_config.moonbit = {
  install_info = {
    url = "D:/MoonHighlight",  -- Change this to your path
    files = { "src/parser.c", "src/scanner.c" },
    generate_requires_npm = true,
  },
  filetype = "moonbit",
}
```

4. Restart Neovim and run:

```vim
:TSInstall moonbit
```

### Method 2: From GitHub

Use the commented-out GitHub config in `neovim.lua` instead:

```lua
parser_config.moonbit = {
  install_info = {
    url = "https://github.com/Tino-hue/moonmark.git",
    files = { "src/parser.c", "src/scanner.c" },
    branch = "main",
  },
  filetype = "moonbit",
}
```

## Features

- **Syntax Highlighting**: Full AST-based highlighting via tree-sitter
- **Indentation**: Smart indentation based on tree-sitter `indents.scm`
- **Variable Scope**: Locals tracking via `locals.scm` for rename/refactor support
- **File Detection**: Auto-detect `.mbt` files as MoonBit

## Troubleshooting

### Parser not found

Ensure you ran `:TSInstall moonbit` after adding the config.

### Queries not loading

Check that nvim-treesitter copied queries correctly:

```vim
:echo nvim_get_runtime_file("queries/moonbit/highlights.scm", v:true)
```

If empty, manually copy:

```bash
cp queries/* ~/.local/share/nvim/lazy/nvim-treesitter/queries/moonbit/
```

### Build fails on Windows

Ensure you have Visual Studio Build Tools with C++ workload installed.
Run `tree-sitter generate` first to ensure `src/parser.c` exists.

## Development

Test queries locally:

```bash
tree-sitter query queries/highlights.scm examples/demo.mbt
tree-sitter query queries/indents.scm examples/demo.mbt
tree-sitter query queries/locals.scm examples/demo.mbt
```
