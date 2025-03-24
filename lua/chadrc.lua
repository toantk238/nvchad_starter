-- This file needs to have same structure as nvconfig.lua 
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :( 

---@type ChadrcConfig
local M = {}

M.base46 = {
	theme = "monekai",

	-- hl_override = {
	-- 	Comment = { italic = true },
	-- 	["@comment"] = { italic = true },
	-- },
}

M.mason = {
  pkgs = {
    "lua-language-server",
    "stylua",

    -- web dev
    "css-lsp",
    "html-lsp",
    "typescript-language-server",
    -- "tsserver",
    "deno",
    "prettier",
    -- "emmet-ls",
    "json-lsp",
    -- "tailwindcss-language-server",
    "unocss-language-server",
    -- "emmet-language-server",

    -- shell
    "shfmt",
    "shellcheck",
    "bash-language-server",

    -- "clangd",
    -- "clang-format",
    -- xml
    "lemminx",
    "xmlformatter",

    -- ruby
    -- "rubocop",
    -- "solargraph",

    -- python
    "pyright",
    "autopep8",
    "debugpy",
    -- markdown
    "marksman",
    -- yaml
    "yaml-language-server",
    "yamlfmt",
    "yamllint",
    -- kotlin
    -- "kotlin-language-server"
    "ktlint",
    "terraform-ls",
    -- java
    "google-java-format",
    -- rust
    "rust-analyzer",
    -- cmake
    "cmake-language-server",
    -- make file
    -- "autotools-language-server",
    "texlab",
    "latexindent",
    "gopls",
  },
}
-- M.nvdash = { load_on_startup = true }
-- M.ui = {
--       tabufline = {
--          lazyload = false
--      }
--}

return M
