local lspconfig = require "lspconfig"
local M = require "nvchad.configs.lspconfig"

lspconfig.lua_ls.setup {
  on_attach = M.on_attach,
  capabilities = M.capabilities,
  on_init = M.on_init,
  settings = {
    Lua = {
      diagnostics = {
        globals = { "vim" },
      },
      workspace = {
        library = {
          [vim.fn.expand "$VIMRUNTIME/lua"] = true,
          [vim.fn.stdpath "config" .. "/lua"] = true,
          [vim.fn.expand "$VIMRUNTIME/lua/vim/lsp"] = true,
          [vim.fn.stdpath "data" .. "/lazy/ui/nvchad_types"] = true,
          [vim.fn.stdpath "data" .. "/lazy/lazy.nvim/lua/lazy"] = true,
          ["${3rd}/luv/library"] = true,
        },
      },
      telemetry = {
        enable = false,
      },
      completion = {
        callSnippet = "Replace",
      },
      maxPreload = 100000,
      preloadFileSize = 10000,
    },
  },
}
