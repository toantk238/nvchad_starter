local optionalPlugins = require "plugins.myplugins"

local M = {
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    -- opts = require "configs.conform",
    config = function()
      require "configs.conform"
    end,
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      {
        "Yuki-bun/typescript-tools.nvim",
        branch = "refac-use_native_lsp_api",
      },
    },
    config = function()
      require "configs.lspconfig"
      require "configs.mylspconfig"
    end,
    ft = {
      "lua",
      "python",
      "javascript",
      "typescript",
      "rust",
      "go",
      "swift",
      "yaml",
      "yml",
      "objc",
      "objcpp",
      "c",
      "cpp",
      "ruby",
    },
  },
}

vim.list_extend(M, optionalPlugins)
return M
