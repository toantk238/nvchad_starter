local map = vim.keymap.set

map("n", "<leader>mw", ":%bd|e#<CR>", { desc = "Close all (windows) but this buffer" })
map("n", "<leader>cu", "<cmd>:ccl<CR>", { desc = "Close quickfix list" })
map("n", "<leader>cf", '<cmd>:let @+=expand("%")<CR>', { desc = "Copy relative path" })
map("n", "<leader>cF", '<cmd>:let @+=expand("%:p")<CR>', { desc = "Copy full path" })
map("n", "<leader>ct", '<cmd>:let @+=expand("%:t")<CR>', { desc = "Copy filename" })
map("n", "<leader>ch", '<cmd>:let @+=expand("%:p:h")<CR>', { desc = "Copy dir" })

-- ["jk"] = { "<ESC>", "escape insert mode" },

map("n", "<Bslash>", function()
  require("shade").toggle()
end, { desc = "toggle shade.nvim" })

-- M.nvterm = {
--   n = {
--     ["<leader>gc"] = {
--
--       function()
--         local file = vim.fn.expand "%"
--
--         local fts = {
--           cpp = "clear && g++ -o out " .. file .. " && ./out",
--           python = "some command",
--         }
--
--         require("nvterm.terminal").send(fts[vim.bo.ft], "vertical")
--       end,
--
--       "run commands based on current filetype",
--     },
--   },
-- }

-- map("n", "<F7>", ":TagbarToggle <CR>", { desc = "toggle Tag Bar" })

map("n", "<F5>", "<cmd>lua require'dap'.continue()<cr>", { desc = "Start Debug" })
map("n", "<F8>", "<cmd>lua require'dap'.step_into()<cr>", { desc = "Step Into" })
map("n", "<F12>", "<cmd>lua require'dap'.step_out()<cr>", { desc = "Step Out" })
map("n", "<F9>", "<cmd>lua require'dap'.toggle_breakpoint()<cr>", { desc = "Toggle Breakpoint" })
map("n", "<F3>", "<cmd>lua require'dap'.terminate()<cr>", { desc = "Terminate" })
map("n", "<leader>du", "<cmd>lua require'dapui'.toggle()<cr>", { desc = "Toggle UI" })
map("n", "<leader>dh", "<cmd>lua require'dap.ui.widgets'.hover()<cr>", { desc = "Hover Variables" })
map("n", "<leader>ep", "<cmd>lua require'dapui'.eval(vim.fn.input '[Expression] > ')<cr>", { desc = "Evaluate Input" })
map("n", "<leader>de", "<cmd>lua require'dap'.repl.toggle()<cr>", { desc = "Toggle Repl" })

map("n", "<leader>s", "<esc>:lua require('spectre').open_visual()<CR>", { desc = "Open Search" })
map("n", "<leader>sw", "<cmd>lua require('spectre').open_visual({select_word=true})<CR>", { desc = "Search word" })

map("n", "<leader>ze", ":ZenMode <CR>", { desc = "Toggle ZenMode" })

map("n", "<leader>lg", ":LazyGit <CR>", { desc = "Open LazyGit" })
map("n", "<leader>lz", ":Neogit <CR>", { desc = "Open Neogit" })

map("n", "<leader>fs", ":Telescope resume <CR>", { desc = "Telescope resume" })

map("n", "<leader>gf", ":Telescope changed_files <cr>", { desc = "Open changed files" })

map("n", "<leader>me", ":Bdelete other<CR>", { desc = "Close all but this buffer" })

map("v", "<leader>gfr", ":Gen Review_Code<CR>", { desc = "Review code" })

-- Git signs

map("n", "]c", function()
  if vim.wo.diff then
    return "]c"
  end
  vim.schedule(function()
    require("gitsigns").next_hunk()
  end)
  return "<Ignore>"
end, {
  desc = "Jump to next hunk",
  remap = true,
  -- opts = { expr = true },
})

map("n", "[c", function()
  if vim.wo.diff then
    return "[c"
  end
  vim.schedule(function()
    require("gitsigns").prev_hunk()
  end)
  return "<Ignore>"
end, {
  desc = "Jump to prev hunk",
  remap = true,
  -- opts = { expr = true },
})

map("n", "<leader>gb", "<CMD>:G blame<CR>", { desc = "Blame Line" })
