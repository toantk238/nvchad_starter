require "nvchad.options"

-- add yours here!

-- local o = vim.o
-- o.cursorlineopt ='both' -- to enable cursorline!
-- Verify if lemonade is installed

if vim.fn.executable "lemonade" then
  vim.g.clipboard = {
    name = "lemonade",
    copy = {
      ["+"] = { "lemonade", "copy", "--host=127.0.0.1" },
      ["*"] = { "lemonade", "copy", "--host=127.0.0.1" },
    },
    paste = {
      ["+"] = { "lemonade", "paste", "--host=127.0.0.1" },
      ["*"] = { "lemonade", "paste", "--host=127.0.0.1" },
    },
    cache_enabled = false,
  }
end

vim.g.wordmotion_prefix = "<Leader>"
