local opt = vim.opt
opt.title = true

if vim.g.neovide then
  vim.o.guifont = "JetbrainsMono Nerd Font:h14"

  vim.g.neovide_refresh_rate = 75

  vim.g.neovide_cursor_vfx_mode = "railgun"

  vim.keymap.set("i", "<c-s-v>", "<c-r>+")
  vim.keymap.set("i", "<c-r>", "<c-s-v>")
end

local filename_table = {
  ["ruby"] = { "Appfile", "Podfile", "Pluginfile", "Matchfile" },
  ["bash"] = { "env.sample" },
}

local pattern_table = {
  ["ruby"] = { ".*Fastfile" },
  ["groovy"] = { "Jenkinsfile.*" },
  ["direnv"] = { ".*%.envrc%.*" },
  ["dockerfile"] = { "Dockerfile.*" },
  ["yaml"] = { ".*%.yml%..*" },
}

local function table_map_by_value(data)
  local result = {}
  for key, values in pairs(data) do
    for _, single_value in ipairs(values) do
      result[single_value] = key
    end
  end
  return result
end

vim.filetype.add {
  filename = table_map_by_value(filename_table),
  pattern = table_map_by_value(pattern_table),
  extension = {
    strings = "strings",
    conf = "config",
    hurl = "hurl",
    appiumsession = "json",
    storyboard = "xml",
  },
}

vim.g.loaded_ruby_provider = nil
-- vim.g.ruby_host_prog = os.getenv("GEM_HOME") .. "/bin/neovim-ruby-host"

vim.g.loaded_python3_provider = nil
vim.g.python3_host_prog = "/usr/bin/python3"
vim.g.python_host_prog = "~/.pyenv/versions/2.7.18/bin/python"
vim.g.coc_global_extensions = { "coc-flutter" }
vim.opt.shell = "zsh"

vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,localoptions"
vim.g.db_ui_auto_execute_table_helpers = 1
vim.g.db_ui_table_helpers = {
  mysql = {
    List = 'select * from `{table}` order by created_at desc limit 10',
  },
}

local all_dbs = os.getenv "DBS_URL"
if all_dbs and all_dbs ~= "" then
  vim.g.dbs = vim.json.decode(all_dbs)
end

-- vim.g.db_ui_save_location = "~/Public/Workspace/StreetChat/backend_java/queries"
local db_ui_save_location = os.getenv "SQL_SAVE_LOCATION"
if db_ui_save_location and db_ui_save_location ~= "" then
  vim.g.db_ui_save_location = db_ui_save_location
end

require("base46").load_all_highlights()
-- vim.lsp.set_log_level("debug")
