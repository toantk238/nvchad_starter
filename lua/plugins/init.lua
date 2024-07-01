local map = vim.keymap.set
-- local hasLuaRocks = vim.fn.isdirectory(vim.fn.expand "$HOME/.luarocks")

return {
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    config = function()
      require "configs.conform"
    end,
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "pmizio/typescript-tools.nvim",
    },
    config = function()
      require("nvchad.configs.lspconfig").defaults()
      require "configs.lspconfig"
    end,
    ft = { "lua", "python", "javascript", "typescript", "rust", "go" },
  },

  -- {
  -- 	"williamboman/mason.nvim",
  -- 	opts = {
  -- 		ensure_installed = {
  -- 			"lua-language-server", "stylua",
  -- 			"html-lsp", "css-lsp" , "prettier"
  -- 		},
  -- 	},
  -- },
  --
  -- {
  -- 	"nvim-treesitter/nvim-treesitter",
  -- 	opts = {
  -- 		ensure_installed = {
  -- 			"vim", "lua", "vimdoc",
  --      "html", "css"
  -- 		},
  -- 	},
  -- },
  {
    "Asheq/close-buffers.vim",
    cmd = "Bdelete",
  },
  {
    "folke/neodev.nvim",
    ft = { "lua" },
    lazy = true,
    config = function()
      require("neodev").setup {}
      require "configs.lspconfig-lua"
    end,
  },
  {
    "karb94/neoscroll.nvim",
    keys = { "<C-d>", "<C-u>" },
    config = function()
      require("neoscroll").setup()
    end,
  },
  {
    "direnv/direnv.vim",
    lazy = false,
  },

  {
    "johmsalas/text-case.nvim", -- after = "ui",
    config = function()
      require "configs.textcase"
    end,
    lazy = false,
  },
  {
    "rmagatti/auto-session",
    -- after = "ui",
    config = function()
      require("auto-session").setup {
        log_level = "error",
        auto_session_suppress_dirs = { "~/", "~/Downloads", "/" },
        post_restore_cmds = { "NvimTreeToggle" },
      }
      require("base46").load_all_highlights()
    end,
    lazy = false,
    -- cmd = "SessionRestore"
  },
  {
    "tpope/vim-fugitive",
    lazy = false,
  },

  {
    "chaoren/vim-wordmotion",
    lazy = true,
    keys = "ci<leader>w",
  },

  {
    "smoka7/hop.nvim",
    version = "*",
    -- cmd = "HopWord",
    lazy = true,
    config = function()
      -- you can configure Hop the way you like here; see :h hop-config
      require("hop").setup { keys = "etovxqpdygfblzhckisuran" }
      map("n", "<leader>fj", ":HopPattern <CR>", { desc = "HopPattern" })
    end,
    keys = "<leader>fj",
  },
  {
    "kdheepak/lazygit.nvim",
    cmd = "LazyGit",
    branch = "main",
    -- after = "ui",
  },
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim", -- required
      "nvim-telescope/telescope.nvim", -- optional
      "sindrets/diffview.nvim", -- optional
    },
    config = true,
    lazy = false,
  },
  {
    "junegunn/fzf.vim",
    dependencies = {
      "junegunn/fzf",
    },
    lazy = false,
  },
  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = {
      { "tpope/vim-dadbod", lazy = true },
      { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
    },
    cmd = {
      "DBUI",
      "DBUIToggle",
      "DBUIAddConnection",
      "DBUIFindBuffer",
    },
    init = function()
      -- Your DBUI configuration
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_expand_query_results = 1
    end,
  },
  {
    "toantk238/aerial.nvim",
    opts = {},
    branch = "feature/more_languages",
    -- Optional dependencies
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("aerial").setup {
        -- optionally use on_attach to set keymaps when aerial has attached to a buffer
        on_attach = function(bufnr)
          -- Jump forwards/backwards with '{' and '}'
          map("n", "{", "<cmd>AerialPrev<CR>", { buffer = bufnr })
          map("n", "}", "<cmd>AerialNext<CR>", { buffer = bufnr })
        end,
        backends = { "treesitter", "lsp", "markdown", "man" },
        -- filter_kind = false,
        filter_kind = {
          "Class",
          "Constructor",
          "Enum",
          "Function",
          "Interface",
          "Module",
          "Method",
          "Struct",
          "Property",
        },
      }
      -- vim.keymap.set("n", "<leader>a", "<cmd>AerialNavToggle<CR>")
      require("telescope").load_extension "aerial"
      map("n", "<leader>fc", "<cmd>:Telescope aerial<CR>", { desc = "Toggle Aerial" })
    end,
    lazy = true,
    keys = "<leader>fc",
  },
  {
    "alexghergh/nvim-tmux-navigation",
    lazy = false,
    config = function()
      require("nvim-tmux-navigation").setup {
        disable_when_zoomed = true, -- defaults to false
        keybindings = {
          left = "<C-h>",
          down = "<C-j>",
          up = "<C-k>",
          right = "<C-l>",
          last_active = "<C-\\>",
          next = "<C-Space>",
        },
      }
    end,
  },
  -- {
  --   "3rd/image.nvim",
  --   lazy = not hasLuaRocks,
  --   config = function()
  --     package.path = package.path .. ";" .. vim.fn.expand "$HOME" .. "/.luarocks/share/lua/5.1/?/init.lua;"
  --     package.path = package.path .. ";" .. vim.fn.expand "$HOME" .. "/.luarocks/share/lua/5.1/?.lua;"
  --     require("image").setup {
  --       backend = "kitty",
  --       integrations = {
  --         markdown = {
  --           enabled = true,
  --           clear_in_insert_mode = false,
  --           download_remote_images = true,
  --           only_render_image_at_cursor = false,
  --           filetypes = { "markdown", "vimwiki" }, -- markdown extensions (ie. quarto) can go here
  --         },
  --         neorg = {
  --           enabled = true,
  --           clear_in_insert_mode = false,
  --           download_remote_images = true,
  --           only_render_image_at_cursor = false,
  --           filetypes = { "norg" },
  --         },
  --       },
  --       max_width = nil,
  --       max_height = nil,
  --       max_width_window_percentage = nil,
  --       max_height_window_percentage = 50,
  --       window_overlap_clear_enabled = false, -- toggles images when windows are overlapped
  --       window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
  --       editor_only_render_when_focused = false, -- auto show/hide images when the editor gains/looses focus
  --       tmux_show_only_in_active_window = false, -- auto show/hide images in the correct Tmux window (needs visual-activity off)
  --       hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp" }, -- render image files as images when opened
  --     }
  --   end,
  -- },
  -- {
  --   "nvim-treesitter/nvim-treesitter-context",
  --   lazy = true,
  --   opts = {
  --     throttle = true,
  --     max_lines = 0,
  --     patterns = {
  --       default = {
  --         "class",
  --         "function",
  --         "method",
  --       },
  --     },
  --   },
  --   event = "LspAttach",
  --   config = function (_, opts)
  --     require("treesitter-context").setup(opts)
  --
  --     vim.cmd [[
  --       :hi TreesitterContextLineNumberBottom gui=underline guisp=Grey
  --       :hi TreesitterContextBottom gui=underline guisp=Grey
  --     ]]
  --   end
  -- },
  -- {
  --   "nvimdev/lspsaga.nvim",
  --   event = "LspAttach",
  --   config = function()
  --     require("lspsaga").setup {}
  --     -- map("n", "K", "<cmd>Lspsaga hover_doc<CR>")
  --     -- map("n", "gd", "<cmd>Lspsaga goto_definition<CR>")
  --   end,
  --   dependencies = {
  --     "nvim-treesitter/nvim-treesitter", -- optional
  --     "nvim-tree/nvim-web-devicons", -- optional
  --   },
  -- },
  {
    "rainbowhxch/beacon.nvim",
    lazy = false,
  },
  {
    "HiPhish/rainbow-delimiters.nvim",
    lazy = false,
  },
  {
    "windwp/nvim-spectre",
    config = function()
      require("spectre").setup()
    end,
  },
  {
    "stevearc/oil.nvim",
    lazy = false,
    config = function()
      require("oil").setup {
        -- Oil will take over directory buffers (e.g. `vim .` or `:e src/`)
        -- Set to false if you still want to use netrw.
        default_file_explorer = true,
      }
      map("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
    end,
  },
  {
    "Exafunction/codeium.nvim",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "hrsh7th/nvim-cmp",
    },
    config = function()
      require("codeium").setup {}
    end,
  },
  {
    "neoclide/coc.nvim",
    branch = "release",
    ft = { "dart", "terraform", "tf" },
    lazy = true,
    dependencies = {
      {
        "dart-lang/dart-vim-plugin",
      },
      {
        "natebosch/vim-lsc",
      },
      {
        "natebosch/vim-lsc-dart",
      },
    },
    config = function()
      require "configs.coc"
    end,
  },
  -- {
  --   "code-biscuits/nvim-biscuits",
  --   event = "LspAttach",
  --   dependencies = {
  --     "nvim-treesitter/nvim-treesitter",
  --   },
  --   config = function()
  --     require("nvim-biscuits").setup {
  --       on_events = { "InsertLeave", "CursorHoldI" },
  --       show_on_start = true, -- defaults to false
  --     }
  --     map("n", "<leader>cb", function()
  --       require("nvim-biscuits").toggle_biscuits()
  --     end)
  --     vim.cmd [[
  --       :hi BiscuitColor ctermfg=blue
  --       :hi BiscuitColorPython ctermfg=red
  --     ]]
  --   end,
  -- },
  {
    "mikesmithgh/kitty-scrollback.nvim",
    enabled = true,
    lazy = true,
    cmd = { "KittyScrollbackGenerateKittens", "KittyScrollbackCheckHealth" },
    event = { "User KittyScrollbackLaunch" },
    -- version = '*', -- latest stable version, may have breaking changes if major version changed
    -- version = '^4.0.0', -- pin major version, include fixes and features that do not have breaking changes
    config = function()
      require("kitty-scrollback").setup()
    end,
  },
}
