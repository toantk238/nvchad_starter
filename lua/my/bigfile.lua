-- Big file rules: skip the expensive per-buffer tooling (treesitter, LSP) when a
-- buffer is big by any measure -- too many lines, too many bytes, or long lines
-- (minified/bundled sources are few lines but enormous ones).

local M = {}

M.opts = {
  max_lines = 2000,
  max_bytes = 512 * 1024,
  -- average bytes per line, only applied once the buffer is at least min_bytes
  max_line_bytes = 1000,
  min_bytes = 64 * 1024,
}

---@param bufnr integer|nil buffer handle, nil or 0 for the current buffer
---@return boolean
function M.is_big(bufnr)
  local opts = M.opts
  local buf = (bufnr == nil or bufnr == 0) and vim.api.nvim_get_current_buf() or bufnr
  if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf) then
    return false
  end

  local lines = vim.api.nvim_buf_line_count(buf)
  if lines > opts.max_lines then
    return true
  end

  -- byte offset one past the last line == size of the buffer in bytes
  local bytes = vim.api.nvim_buf_get_offset(buf, lines)
  if bytes < 0 then
    return false
  end
  if bytes > opts.max_bytes then
    return true
  end

  return bytes > opts.min_bytes and bytes / lines > opts.max_line_bytes
end

-- wrap once, so reloading this module doesn't stack guards
if not vim.g.big_file_guards then
  vim.g.big_file_guards = true

  -- Skip treesitter (parse + highlight) for big files
  local ts_start = vim.treesitter.start
  vim.treesitter.start = function(bufnr, ...)
    if M.is_big(bufnr) then
      return
    end
    return ts_start(bufnr, ...)
  end

  -- Plugins (rainbow-delimiters, indent-blankline, ...) call get_parser directly,
  -- which builds the whole parse tree even when treesitter.start was skipped
  local ts_get_parser = vim.treesitter.get_parser
  vim.treesitter.get_parser = function(bufnr, lang, opts)
    if M.is_big(bufnr) then
      return nil
    end
    return ts_get_parser(bufnr, lang, opts)
  end

  -- Don't start LSP clients for big files
  local lsp_start = vim.lsp.start
  vim.lsp.start = function(config, opts)
    if M.is_big(opts and opts.bufnr) then
      return
    end
    return lsp_start(config, opts)
  end
end

return M
