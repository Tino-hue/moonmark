-- ============================================================
-- MoonHighlight — Neovim (nvim-treesitter) Configuration
-- Place this in your Neovim config (e.g. ~/.config/nvim/lua/plugins/moonbit.lua)
-- ============================================================

local parser_config = require("nvim-treesitter.parsers").get_parser_configs()

-- Option 1: Install from local clone (for development)
-- Change the path to your local moonmark directory
parser_config.moonbit = {
  install_info = {
    url = "D:/MoonHighlight",  -- Adjust to your local path
    files = { "src/parser.c", "src/scanner.c" },
    generate_requires_npm = true,
  },
  filetype = "moonbit",
}

-- Option 2: Install from GitHub (for end users)
--[[
parser_config.moonbit = {
  install_info = {
    url = "https://github.com/Tino-hue/moonmark.git",
    files = { "src/parser.c", "src/scanner.c" },
    branch = "main",
  },
  filetype = "moonbit",
}
--]]

-- Register .mbt filetype
vim.filetype.add({
  extension = {
    mbt = "moonbit",
  },
  filename = {
    ["moon.mod.json"] = "json",
  },
})

-- Configure nvim-treesitter
require("nvim-treesitter.configs").setup({
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
  indent = {
    enable = true,
  },
  -- Note: moonbit must be installed manually via :TSInstall moonbit
  -- since it is not in nvim-treesitter's official parser list yet
})

-- Optional: set query path for local development queries
-- If you are developing queries locally, you can point to your repo
vim.opt.runtimepath:prepend("D:/MoonHighlight")  -- Adjust to your path
