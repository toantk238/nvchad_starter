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
  ["yaml"] = { "Podfile.lock" },
}

local pattern_table = {
  ["ruby"] = { ".*Fastfile" },
  ["groovy"] = { "Jenkinsfile.*" },
  ["direnv"] = { ".*%.envrc%.*" },
  ["dockerfile"] = { "Dockerfile.*" },
  ["yaml"] = { ".*%.yml%..*" },
  ["python"] = { "gittool" },
  ["swift"] = { ".*%.swiftinterface" },
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

local patterns_config = table_map_by_value(pattern_table)
patterns_config = vim.tbl_deep_extend("keep", patterns_config, {
  [".*"] = {
    function(path, bufnr)
      local content = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] or ""
      -- vim.print("content = " .. content)
      if vim.regex([[^#!.*\\<mine\\>]]):match_str(content) ~= nil then
        return "mine"
      elseif vim.regex([[\\<drawing\\>]]):match_str(content) ~= nil then
        return "drawing"
      end
    end,
    { priority = -math.huge },
  },
})

vim.filetype.add {
  filename = table_map_by_value(filename_table),
  pattern = patterns_config,
  extension = {
    strings = "strings",
    conf = "config",
    hurl = "hurl",
    appiumsession = "json",
    storyboard = "xml",
    podspec = "ruby",
  },
}

vim.g.loaded_ruby_provider = nil
-- vim.g.ruby_host_prog = os.getenv("GEM_HOME") .. "/bin/neovim-ruby-host"

vim.g.loaded_python3_provider = nil
vim.g.python3_host_prog = "~/.pyenv/shims/python"
vim.g.python_host_prog = "~/.pyenv/versions/2.7.18/bin/python"
vim.g.coc_global_extensions = { "coc-flutter" }
vim.opt.shell = "zsh"

vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,localoptions"
vim.g.db_ui_auto_execute_table_helpers = 1
vim.g.db_ui_table_helpers = {
  mysql = {
    List = "select * from `{table}` order by created_at desc limit 10",
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
