local M = require "nvchad.configs.lspconfig"

local vimLsp = vim.lsp

local servers = {
  "clangd",
  -- "tsserver",
  "unocss",
  -- "emmet_language_server",
  -- "lua_ls",
  -- "bashls",
  "lemminx",
  -- "gradle_ls",
  "marksman",
  -- "yamlls",
  -- "cucumber_language_server"
  -- golang
  "gopls",
  -- java
  -- "jdtls"
  "rust_analyzer",
  "cmake",
  -- make file
  "texlab",
}

local nvlsp = require "nvchad.configs.lspconfig"

-- lsps with default config
for _, lsp in ipairs(servers) do
  vimLsp.config(lsp, {
    on_attach = nvlsp.on_attach,
    on_init = nvlsp.on_init,
    capabilities = nvlsp.capabilities,
  })
  vimLsp.enable(lsp)
end

-- configuring single server, example: typescript
-- lspconfig.ts_ls.setup {
--   on_attach = nvlsp.on_attach,
--   on_init = nvlsp.on_init,
--   capabilities = nvlsp.capabilities,
-- }
vimLsp.config("jsonls", {
  on_attach = nvlsp.on_attach,
  capabilities = nvlsp.capabilities,
  on_init = nvlsp.on_init,
  settings = {
    json = {
      -- Schemas https://www.schemastore.org
      schemas = {
        {
          fileMatch = { "package.json" },
          url = "https://json.schemastore.org/package.json",
        },
        {
          fileMatch = { "tsconfig*.json" },
          url = "https://json.schemastore.org/tsconfig.json",
        },
        {
          fileMatch = {
            ".prettierrc",
            ".prettierrc.json",
            "prettier.config.json",
          },
          url = "https://json.schemastore.org/prettierrc.json",
        },
        {
          fileMatch = { ".eslintrc", ".eslintrc.json" },
          url = "https://json.schemastore.org/eslintrc.json",
        },
        {
          fileMatch = { ".babelrc", ".babelrc.json", "babel.config.json" },
          url = "https://json.schemastore.org/babelrc.json",
        },
        {
          fileMatch = { "lerna.json" },
          url = "https://json.schemastore.org/lerna.json",
        },
        {
          fileMatch = { "now.json", "vercel.json" },
          url = "https://json.schemastore.org/now.json",
        },
        {
          fileMatch = {
            ".stylelintrc",
            ".stylelintrc.json",
            "stylelint.config.json",
          },
          url = "http://json.schemastore.org/stylelintrc.json",
        },
      },
    },
  },
})
vimLsp.enable "jsonls"
-- typescript
require("typescript-tools").setup {
  dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
  on_attach = nvlsp.on_attach,
  on_init = nvlsp.on_init,

  settings = {
    tsserver_path = vim.env.TSSERVER_JS,
  },
}

local function organize_imports()
  local params = {
    command = "pyright.organizeimports",
    arguments = { vim.uri_from_bufnr(0) },
  }
  local clients = vim.lsp.get_clients {
    bufnr = vim.api.nvim_get_current_buf(),
    name = "pyright",
  }
  for _, client in ipairs(clients) do
    client.request("workspace/executeCommand", params, nil, 0)
  end
end -- Register the command

vim.api.nvim_create_user_command("PyrightOrganizeImports", organize_imports, {
  desc = "Organize imports using Pyright",
})

vim.lsp.config("pyright", {
  on_attach = nvlsp.on_attach,
  capabilities = nvlsp.capabilities,
  on_init = nvlsp.on_init,
  settings = {
    pyright = {
      disableTaggedHints = true,
      disableOrganizeImports = false,
    },
    python = {
      analysis = {
        typeCheckingMode = "off",
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = "openFilesOnly",
      },
    },
  },
})
vim.lsp.enable "pyright"

-- lspconfig.pyright.setup {
--   settings = {
--       },
--     },
--   },
-- }

vimLsp.config("solargraph", {
  on_attach = nvlsp.on_attach,
  capabilities = nvlsp.capabilities,
  on_init = nvlsp.on_init,
  settings = {
    solargraph = {
      diagnostics = false,
    },
  },
  cmd = { "bundle", "exec", "solargraph", "stdio" },
})
vimLsp.enable "solargraph"

-- lspconfig.bashls.setup({
-- 	on_attach = on_attach,
-- 	capabilities = capabilities,
-- 	filetypes = { "sh" },
-- })
vimLsp.config("yamlls", {
  on_attach = nvlsp.on_attach,
  capabilities = nvlsp.capabilities,
  on_init = nvlsp.on_init,
  settings = {
    yaml = {
      schemas = {
        ["https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.31.3-standalone-strict/all.json"] = "/*.k8s.yaml",
        ["https://raw.githubusercontent.com/datreeio/CRDs-catalog/refs/heads/main/rabbitmq.com/rabbitmqcluster_v1beta1.json"] = "/*.k8s.rabbit.yaml",
      },
      validate = false,
    },
  },
})
vimLsp.enable "yamlls"

vimLsp.config("cucumber_language_server", {
  on_attach = nvlsp.on_attach,
  capabilities = nvlsp.capabilities,
  on_init = nvlsp.on_init,
  filetypes = { "cucumber", "feature" },
  root_dir = vimLsp.util.find_git_ancestor,
  settings = {
    cucumber = {
      features = { "./src/**/*.feature" },
      glue = { "./src/**/*.ts", "./src/**/*.tsx", "./src/**/*.js", "./src/**/*.jsx" },
      parameterTypes = {},
      snippetTemplates = {},
    },
  },
  cmd = { "cucumber-language-server", "--stdio" },
})
vimLsp.enable "cucumber_language_server"

local possible_lsp = {
  ["kotlin-language-server"] = function()
    vimLsp.config("kotlin_language_server", {
      on_init = nvlsp.on_init,
      on_attach = nvlsp.on_attach,
      capabilities = nvlsp.capabilities,
      root_dir = vimLsp.util.root_pattern("settings.gradle", "settings.gradle.kts"),
    })
    vimLsp.enable "kotlin_language_server"
  end,
  ["sourcekit-lsp"] = function()
    vimLsp.config("sourcekit", {
      on_init = nvlsp.on_init,
      on_attach = nvlsp.on_attach,
      capabilities = nvlsp.capabilities,
    })
    vimLsp.enable "sourcekit"
  end,
  ["autotools-language-server"] = function()
    vimLsp.config("autotools_ls", {
      on_init = nvlsp.on_init,
      on_attach = nvlsp.on_attach,
      capabilities = vim.tbl_deep_extend("keep", nvlsp.capabilities, {
        workspace = {
          didChangeWatchedFiles = {
            dynamicRegistration = true,
          },
        },
      }),
    })
    vimLsp.enable "autotools_ls"
  end,
}

for command, lsp_setup in pairs(possible_lsp) do
  if vim.fn.executable(command) == 1 then
    lsp_setup()
  end
end

--local java_17_home = os.getenv("JAVA_17_HOME")
--if java_17_home then
--	local jdtls_path = os.getenv("HOME") .. "/.local/share/nvim/mason/packages/jdtls"
--
--	lspconfig.jdtls.setup({
--		on_attach = on_attach,
--		capabilities = capabilities,
--		cmd = {
--			java_17_home .. "/bin/java",
--			"-Declipse.application=org.eclipse.jdt.ls.core.id1",
--			"-Dosgi.bundles.defaultStartLevel=4",
--			"-Declipse.product=org.eclipse.jdt.ls.core.product",
--			"-Dlog.protocol=true",
--			"-Dlog.level=ALL",
--			"-Xms1g",
--			"--add-modules=ALL-SYSTEM",
--			"--add-opens",
--			"java.base/java.util=ALL-UNNAMED",
--			"--add-opens",
--			"java.base/java.lang=ALL-UNNAMED",
--			"-jar",
--			jdtls_path .. "/plugins/org.eclipse.equinox.launcher_1.6.400.v20210924-0641.jar",
--			"-configuration",
--			jdtls_path .. "/config_linux",
--			"-data",
--			os.getenv("HOME") .. "/.cache/my_jdtls",
--		},
--	})
--end

vimLsp.config("lua_ls", {
  on_attach = M.on_attach,
  capabilities = M.capabilities,
  on_init = M.on_init,
  settings = {
    Lua = {
      diagnostics = {
        globals = { "vim" },
      },
      runtime = { version = "LuaJIT" },
      workspace = {
        library = {
          vim.fn.expand "$VIMRUNTIME/lua",
          vim.fn.expand "$VIMRUNTIME/lua/vim/lsp",
          vim.fn.stdpath "data" .. "/lazy/ui/nvchad_types",
          vim.fn.stdpath "data" .. "/lazy/lazy.nvim/lua/lazy",
          "${3rd}/luv/library",
          vim.fn.stdpath "config" .. "/lua",
          vim.fn.stdpath "config" .. "/nvchad/lua",
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
})
vimLsp.enable "lua_ls"

local lsp_path = vim.fn.stdpath "config" .. "/lsp"
local python_version_file = lsp_path .. "/.python-version"
-- Verify the python-version file exists before proceeding
if vim.fn.filereadable(python_version_file) == 0 then
  -- vim.notify("Python version file not found: " .. python_version_file, vim.log.levels.WARN)
  return
end

local python_version = vim.trim(io.open(python_version_file, "r"):read "*a")
local python_path = vim.fn.expand "$HOME/.pyenv/versions/" .. python_version .. "/bin/python"
local root_files = {
  "Fastfile",
  "Gemfile",
  ".git",
}

-- if not configs.fastlane_ls then
--   configs.fastlane_ls = {
--     default_config = {
--       cmd = { python_path, lsp_path .. "/fastlane_ls.py" },
--       filetypes = { "ruby" },
--       root_dir = function(fname)
--         return util.root_pattern(unpack(root_files))(fname)
--       end,
--     },
--   }
-- end

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "ruby" },
  callback = function()
    vimLsp.config("fastlane_ls", {
      name = "fastlane_ls",
      cmd = { python_path, lsp_path .. "/fastlane_ls.py" },
      root_dir = vim.fs.root(0, root_files),
      on_attach = nvlsp.on_attach,
      capabilities = nvlsp.capabilities,
      on_init = nvlsp.on_init,
    })
    vimLsp.enable "fastlane_ls"
  end,
})

-- read :h vim.lsp.config for changing options of lsp servers
