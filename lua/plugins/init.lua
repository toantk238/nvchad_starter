local optionalPlugins = require "plugins.myplugins"

local coding_file_types = require "configs.codingfts"

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
        "pmizio/typescript-tools.nvim",
        branch = "master",
      },
    },
    config = function()
      require "configs.lspconfig"
      require "configs.mylspconfig"
    end,
    ft = coding_file_types,
  },
  {
    "nvimtools/none-ls.nvim",
    config = function()
      local null_ls = require "null-ls"
      null_ls.setup {
        sources = {
          null_ls.builtins.formatting.stylua,
          null_ls.builtins.diagnostics.ktlint,
          null_ls.builtins.formatting.ktlint.with {
            extra_args = { "--editorconfig=" .. vim.fn.stdpath "config" .. "/config/kotlin/.editorconfig" },
            timeout = 10000,
          },
          null_ls.builtins.formatting.just,
        },
      }
    end,
    dependencies = {
      {
        "nvim-lua/plenary.nvim",
      },
    },
    ft = coding_file_types,
  },
}

vim.list_extend(M, optionalPlugins)
return M
