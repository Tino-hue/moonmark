# MoonHighlight — Neovim (nvim-treesitter) configuration
# Add to your init.lua or treesitter config:

-- Option 1: Manual registration
local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
parser_config.moonbit = {
  install_info = {
    url = "https://github.com/Tino-hue/moonmark.git",
    files = { "src/parser.c", "src/scanner.c" },
    branch = "main",
  },
  filetype = "moonbit",
}

vim.filetype.add({
  extension = {
    mbt = "moonbit",
  }
})

-- Highlight setup
require'nvim-treesitter.configs'.setup {
  highlight = {
    enable = true,
    disable = {},
    additional_vim_regex_highlighting = false,
  },
  ensure_installed = { "moonbit" },
}