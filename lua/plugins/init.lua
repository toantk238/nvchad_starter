local map = vim.keymap.set

local notInsideKittyScrollback = vim.env.KITTY_SCROLLBACK_NVIM ~= "true"

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
      "pmizio/typescript-tools.nvim",
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

  -- These are some examples, uncomment them if you want to see them work!
  -- test new blink
  -- { import = "nvchad.blink.lazyspec" },

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
    "folke/lazydev.nvim",
    ft = "lua", -- only load on lua files
    opts = {
      library = {
        -- See the configuration section for more details
        -- Load luvit types when the `vim.uv` word is found
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },
  { -- optional cmp completion source for require statements and module annotations
    "hrsh7th/nvim-cmp",
    opts = function(_, opts)
      opts.sources = opts.sources or {}
      table.insert(opts.sources, {
        name = "lazydev",
        group_index = 0, -- set group index to 0 to skip loading LuaLS completions
      })
    end,
  },
  { -- optional blink completion source for require statements and module annotations
    "saghen/blink.cmp",
    opts = {
      sources = {
        -- add lazydev to your completion providers
        default = { "lazydev", "lsp", "path", "snippets", "buffer" },
        providers = {
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            -- make lazydev completions top priority (see `:h blink.cmp`)
            score_offset = 100,
          },
        },
      },
    },
  },
  {
    "karb94/neoscroll.nvim",
    keys = { "<C-d>", "<C-u>", "zz" },
    opts = {
      mappings = { -- Keys to be mapped to their corresponding default scrolling animation
        "<C-u>",
        "<C-d>",
        "<C-b>",
        "<C-f>",
        -- "<C-y>",
        -- "<C-e>",
        "zt",
        "zz",
        "zb",
      },
    },
    config = function(_, opts)
      require("neoscroll").setup(opts)
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
        auto_session_enabled = notInsideKittyScrollback,
      }
      require("base46").load_all_highlights()
    end,
    lazy = false,
    cond = notInsideKittyScrollback,
    -- cmd = "SessionRestore"
  },
  {
    "tpope/vim-fugitive",
    lazy = false,
  },

  {
    "chaoren/vim-wordmotion",
    lazy = true,
    keys = { "ci<leader>w", "ca<leader>w", "di<leader>w", "da<leader>w", "<leader>w" },
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
    lazy = true,
    cmd = "Neogit",
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
    submodules = false,
    branch = "master",
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
  -- {
  --   "Exafunction/codeium.nvim",
  --   lazy = false,
  --   dependencies = {
  --     "nvim-lua/plenary.nvim",
  --     "hrsh7th/nvim-cmp",
  --   },
  --   config = function()
  --     require("codeium").setup {}
  --   end,
  -- },
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
    cmd = {
      "KittyScrollbackGenerateKittens",
      "KittyScrollbackCheckHealth",
      "KittyScrollbackGenerateCommandLineEditing",
    },
    event = { "User KittyScrollbackLaunch" },
    -- version = '*', -- latest stable version, may have breaking changes if major version changed
    -- version = '^4.0.0', -- pin major version, include fixes and features that do not have breaking changes
    config = function()
      require("kitty-scrollback").setup()
    end,
  },
  -- {
  --   "zbirenbaum/copilot.lua",
  --   cmd = "Copilot",
  --   event = "InsertEnter",
  --   lazy = false,
  --   config = function()
  --     require("copilot").setup {
  --       suggestion = { enabled = false },
  --       panel = { enabled = false },
  --       filetypes = {
  --         ["*"] = true,
  --       },
  --     }
  --   end,
  -- },
  -- {
  --   "zbirenbaum/copilot-cmp",
  --   lazy = false,
  --   config = function()
  --     local cmp = require "copilot_cmp"
  --     local has_words_before = function()
  --       if vim.api.nvim_buf_get_option(0, "buftype") == "prompt" then
  --         return false
  --       end
  --       local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  --       return col ~= 0 and vim.api.nvim_buf_get_text(0, line - 1, 0, line - 1, col, {})[1]:match "^%s*$" == nil
  --     end
  --     cmp.setup {
  --       mapping = {
  --         ["<Tab>"] = vim.schedule_wrap(function(fallback)
  --           if cmp.visible() and has_words_before() then
  --             cmp.select_next_item { behavior = cmp.SelectBehavior.Select }
  --           else
  --             fallback()
  --           end
  --         end),
  --       },
  --     }
  --   end,
  -- },
}

local optionalPlugins = {
  {
    "3rd/image.nvim",
    event = "VeryLazy",
    tag = "v1.4.0",
    otps = {
      backend = "kitty",
      kitty_method = "normal",
      processor = "magick_rock", -- or "magick_cli"
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = false,
          download_remote_images = true,
          only_render_image_at_cursor = false,
          only_render_image_at_cursor_mode = "popup",
          floating_windows = false, -- if true, images will be rendered in floating markdown windows
          filetypes = { "markdown", "vimwiki" }, -- markdown extensions (ie. quarto) can go here
        },
        neorg = {
          enabled = true,
          filetypes = { "norg" },
        },
        typst = {
          enabled = true,
          filetypes = { "typst" },
        },
        html = {
          enabled = false,
        },
        css = {
          enabled = false,
        },
      },
      selector = {
        exclude_auto_select = { "NvimTree" },
      },
      max_width = nil,
      max_height = nil,
      max_width_window_percentage = nil,
      max_height_window_percentage = 50,
      window_overlap_clear_enabled = false, -- toggles images when windows are overlapped
      window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "snacks_notif", "scrollview", "scrollview_sign" },
      editor_only_render_when_focused = false, -- auto show/hide images when the editor gains/looses focus
      tmux_show_only_in_active_window = false, -- auto show/hide images in the correct Tmux window (needs visual-activity off)
      hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" }, -- render image files as images when opened
    },
    config = function(_, opts)
      package.path = package.path .. ";" .. vim.fn.expand "$HOME" .. "/.luarocks/share/lua/5.1/?/init.lua"
      package.path = package.path .. ";" .. vim.fn.expand "$HOME" .. "/.luarocks/share/lua/5.1/?.lua"
      require("image").setup(opts)
    end,
    cond = function()
      local luarocks = vim.fn.expand("$HOME" .. "/.luarocks")
      return vim.fn.isdirectory(luarocks) == 1
    end,
  },
  {
    "Ramilito/kubectl.nvim",
    version = "2.*",
    dependencies = "saghen/blink.download",
    opts = {
      logs = {
        prefix = false,
        timestamps = false,
        since = "5m",
      },
    },
    cmd = { "Kubectl", "Kubectx", "Kubens" },
    keys = {
      { "<leader>k", '<cmd>lua require("kubectl").toggle()<cr>' },
      { "<C-k>", "<Plug>(kubectl.kill)", ft = "k8s_*" },
      { "7", "<Plug>(kubectl.view_nodes)", ft = "k8s_*" },
      { "8", "<Plug>(kubectl.view_overview)", ft = "k8s_*" },
      { "<C-t>", "<Plug>(kubectl.view_top)", ft = "k8s_*" },
    },
    lazy = true,
    cond = function()
      return vim.fn.executable "kubectl" == 1
    end,
  },
  {
    "ravitemer/mcphub.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    build = "bundled_build.lua", -- Bundles `mcp-hub` binary along with the neovim plugin
    opts = {
      use_bundled_binary = true,
    },
    config = function(_, opts)
      require("mcphub").setup(opts)
    end,
  },
  {
    "greggh/claude-code.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim", -- Required for git operations
    },
    lazy = false,
    opts = {
      -- Terminal window settings
      window = {
        split_ratio = 0.3, -- Percentage of screen for the terminal window (height for horizontal, width for vertical splits)
        position = "botright", -- Position of the window: "botright", "topleft", "vertical", "float", etc.
        enter_insert = true, -- Whether to enter insert mode when opening Claude Code
        hide_numbers = true, -- Hide line numbers in the terminal window
        hide_signcolumn = true, -- Hide the sign column in the terminal window

        -- Floating window configuration (only applies when position = "float")
        float = {
          width = "80%", -- Width: number of columns or percentage string
          height = "80%", -- Height: number of rows or percentage string
          row = "center", -- Row position: number, "center", or percentage string
          col = "center", -- Column position: number, "center", or percentage string
          relative = "editor", -- Relative to: "editor" or "cursor"
          border = "rounded", -- Border style: "none", "single", "double", "rounded", "solid", "shadow"
        },
      },
      -- File refresh settings
      refresh = {
        enable = true, -- Enable file change detection
        updatetime = 100, -- updatetime when Claude Code is active (milliseconds)
        timer_interval = 1000, -- How often to check for file changes (milliseconds)
        show_notifications = true, -- Show notification when files are reloaded
      },
      -- Git project settings
      git = {
        use_git_root = true, -- Set CWD to git root when opening Claude Code (if in git project)
      },
      -- Shell-specific settings
      shell = {
        separator = "&&", -- Command separator used in shell commands
        pushd_cmd = "pushd", -- Command to push directory onto stack (e.g., 'pushd' for bash/zsh, 'enter' for nushell)
        popd_cmd = "popd", -- Command to pop directory from stack (e.g., 'popd' for bash/zsh, 'exit' for nushell)
      },
      -- Command settings
      command = "claude", -- Command used to launch Claude Code
      -- Command variants
      command_variants = {
        -- Conversation management
        continue = "--continue", -- Resume the most recent conversation
        resume = "--resume", -- Display an interactive conversation picker

        -- Output options
        verbose = "--verbose", -- Enable verbose logging with full turn-by-turn output
      },
      -- Keymaps
      keymaps = {
        toggle = {
          normal = "<C-,>", -- Normal mode keymap for toggling Claude Code, false to disable
          terminal = "<C-,>", -- Terminal mode keymap for toggling Claude Code, false to disable
          variants = {
            continue = "<leader>cC", -- Normal mode keymap for Claude Code with continue flag
            verbose = "<leader>cV", -- Normal mode keymap for Claude Code with verbose flag
          },
        },
        window_navigation = true, -- Enable window navigation keymaps (<C-h/j/k/l>)
        scrolling = true, -- Enable scrolling keymaps (<C-f/b>) for page up/down
      },
    },
    config = function(_, opts)
      require("claude-code").setup(opts)
    end,
  },
  {
    "Exafunction/windsurf.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "hrsh7th/nvim-cmp",
    },
    lazy = false,
    config = function()
      require("codeium").setup {
        -- Optionally disable cmp source if using virtual text only
        enable_cmp_source = false,
        virtual_text = {
          enabled = true,

          -- These are the defaults

          -- Set to true if you never want completions to be shown automatically.
          manual = false,
          -- A mapping of filetype to true or false, to enable virtual text.
          filetypes = {
            python = true,
            yaml = true,
            markdown = true,
            json = true,
            html = true,
            css = true,
            scss = true,
            javascript = true,
            typescript = true,
            javascriptreact = true,
            typescriptreact = true,
            vue = true,
            bash = true,
            lua = true,
            rust = true,
            go = true,
            php = true,
            c = true,
            cpp = true,
          },
          -- Whether to enable virtual text of not for filetypes not specifically listed above.
          default_filetype_enabled = false,
          -- How long to wait (in ms) before requesting completions after typing stops.
          idle_delay = 75,
          -- Priority of the virtual text. This usually ensures that the completions appear on top of
          -- other plugins that also add virtual text, such as LSP inlay hints, but can be modified if
          -- desired.
          virtual_text_priority = 65535,
          -- Set to false to disable all key bindings for managing completions.
          map_keys = true,
          -- The key to press when hitting the accept keybinding but no completion is showing.
          -- Defaults to \t normally or <c-n> when a popup is showing.
          accept_fallback = nil,
          -- Key bindings for managing completions in virtual text mode.
          key_bindings = {
            -- Accept the current completion.
            accept = "<Tab>",
            accept_fallback = "<Tab>",
            -- Accept the next word.
            accept_word = false,
            -- Accept the next line.
            accept_line = false,
            -- Clear the virtual text.
            clear = false,
            -- Cycle to the next completion.
            next = "<M-]>",
            -- Cycle to the previous completion.
            prev = "<M-[>",
          },
        },
      }
    end,
  },
  {
    "folke/twilight.nvim",
    cmd = "Twilight",
    lazy = true,
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    },
  },
  {
    "emmanueltouzery/decisive.nvim",
    lazy = true,
    filetype = "csv",
  },
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    event = "VeryLazy",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function(_, _)
      require "configs.harpoon"
    end,
  },
  {
    "nanotee/zoxide.vim",
    lazy = true,
    keys = {
      { "<leader>zi", "<cmd>Zi<cr>", desc = "Zoxide" },
    },
    cmd = { "Zi", "Tzi", "Lzi" },
  },
}

-- local avante = {
--   event = "VeryLazy",
--   lazy = true,
--   version = false, -- set this if you want to always pull the latest change
--   keys = {
--     {
--       "<leader>a+",
--       function()
--         local tree_ext = require "avante.extensions.nvim_tree"
--         tree_ext.add_file()
--       end,
--       desc = "Select file in NvimTree",
--       ft = "NvimTree",
--     },
--     {
--       "<leader>a-",
--       function()
--         local tree_ext = require "avante.extensions.nvim_tree"
--         tree_ext.remove_file()
--       end,
--       desc = "Deselect file in NvimTree",
--       ft = "NvimTree",
--     },
--   },
--   opts = {
--     provider = "copilot",
--     providers = {
--       copilot = {
--         model = "claude-3.5-sonnet",
--       },
--     },
--     -- provider = "copilot", -- use copilot as the main provider
--     -- provider = "code
--     -- provider = "openai",
--     auto_suggestions_provider = "copilot",
--     behaviour = {
--       auto_suggestions = false, -- Experimental stage
--       auto_set_highlight_group = true,
--       auto_set_keymaps = true,
--       auto_apply_diff_after_generation = false,
--       support_paste_from_clipboard = true,
--     },
--     suggestion = {
--       debounce = 1200,
--       throttle = 600,
--     },
--     web_search_engine = {
--       provider = "tavily", -- tavily, serpapi, searchapi, google or kagi
--     },
--     -- add any opts here
--   },
--   build = "make",
--   -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
--   dependencies = {
--     "stevearc/dressing.nvim",
--     "nvim-lua/plenary.nvim",
--     "MunifTanjim/nui.nvim",
--     --- The below dependencies are optional,
--     "nvim-telescope/telescope.nvim", -- for file_selector provider telescope
--     "hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
--     -- "ibhagwan/fzf-lua", -- for file_selector provider fzf
--     "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
--     "zbirenbaum/copilot.lua", -- for providers='copilot'
--     {
--       -- support for image pasting
--       "HakonHarnes/img-clip.nvim",
--       event = "VeryLazy",
--       opts = {
--         -- recommended settings
--         default = {
--           embed_image_as_base64 = false,
--           prompt_for_file_name = false,
--           drag_and_drop = {
--             insert_mode = true,
--           },
--           -- required for Windows users
--           use_absolute_path = true,
--         },
--       },
--       keys = {
--         -- suggested keymap
--         { "<leader>p", "<cmd>PasteImage<cr>", desc = "Paste image from system clipboard" },
--       },
--     },
--     {
--       -- Make sure to set this up properly if you have lazy=true
--       "MeanderingProgrammer/render-markdown.nvim",
--       opts = {
--         file_types = { "markdown", "Avante" },
--       },
--       ft = { "markdown", "Avante" },
--     },
--   },
--   cond = function()
--     return os.getenv "ENABLE_AVANTE" == "true"
--   end,
-- }
--
-- local avante_dir = os.getenv "AVANTE_DIR"
-- if avante_dir then
--   avante.dir = avante_dir
-- else
--   avante[1] = "yetone/avante.nvim"
-- end
-- table.insert(M, avante)

for _, plugin in ipairs(optionalPlugins) do
  table.insert(M, plugin)
end

return M
