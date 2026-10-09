-- Render ```mermaid blocks in markdown buffers inline via mmdc -> PNG -> image.nvim.
-- While shown, the block's source and fences are concealed (and folded) and the image sits below the block.
local M = {}

local ns = "mermaid_inline"
local extmark_ns = vim.api.nvim_create_namespace(ns)
local cache_dir = vim.fn.stdpath "cache" .. "/mermaid_inline"
local enabled = {} -- bufnr -> true (on) | false (turned off by the user)

M.opts = {
  auto = true, -- turn on automatically for markdown buffers that contain a mermaid block
  scale = 3, -- mmdc --scale, keeps text sharp when the image is stretched to the window
  font_size = 20, -- px at 1x (mermaid's default is 16)
  max_zoom = 1.5, -- cap on stretching a diagram to the window width, relative to its 1x size
  -- mermaid config for a dark/light Normal background; the dark one is high contrast (mermaid's own dark theme is grey on grey)
  config = {
    dark = {
      theme = "base",
      themeVariables = {
        darkMode = true,
        background = "#1e1e2e",
        primaryColor = "#313244",
        primaryTextColor = "#ffffff",
        primaryBorderColor = "#89b4fa",
        secondaryColor = "#45475a",
        tertiaryColor = "#1e1e2e",
        lineColor = "#cdd6f4",
        textColor = "#ffffff",
        nodeTextColor = "#ffffff",
        titleColor = "#f9e2af",
        clusterBkg = "#181825",
        clusterBorder = "#6c7086",
        edgeLabelBackground = "#11111b",
      },
    },
    light = { theme = "default" },
  },
}

-- vim.json.encode with sorted keys, so the output (and the cache hash built from it) is stable across sessions
local function encode_sorted(v)
  if type(v) ~= "table" then return vim.json.encode(v) end
  local keys = vim.tbl_keys(v)
  table.sort(keys)
  local parts = {}
  for _, k in ipairs(keys) do
    table.insert(parts, vim.json.encode(tostring(k)) .. ":" .. encode_sorted(v[k]))
  end
  return "{" .. table.concat(parts, ",") .. "}"
end

-- "dark" | "light" from the Normal highlight's background; vim.o.background isn't always kept in sync by colorschemes
local function background()
  local bg = vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg
  if not bg then return vim.o.background end
  local r, g, b = bit.rshift(bg, 16), bit.band(bit.rshift(bg, 8), 0xff), bit.band(bg, 0xff)
  return (0.299 * r + 0.587 * g + 0.114 * b) < 128 and "dark" or "light"
end

local function find_blocks(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local blocks, start = {}, nil
  for i, line in ipairs(lines) do
    if not start and line:match "^%s*```+%s*mermaid%s*$" then
      start = i
    elseif start and line:match "^%s*```+%s*$" then
      -- rows are 0-indexed: start_row is the ```mermaid fence, end_row the closing fence
      table.insert(blocks, { src = table.concat(lines, "\n", start + 1, i - 1), start_row = start - 1, end_row = i - 1 })
      start = nil
    end
  end
  return blocks
end

local function clear(buf)
  vim.api.nvim_buf_clear_namespace(buf, extmark_ns, 0, -1)
  local win = vim.fn.bufwinid(buf)
  for _, row in ipairs(vim.b[buf].mermaid_inline_folds or {}) do
    if win ~= -1 then pcall(vim.api.nvim_win_call, win, function() vim.cmd(("silent! %dnormal! zd"):format(row)) end) end
  end
  vim.b[buf].mermaid_inline_folds = nil
  local ok, image = pcall(require, "image")
  if not ok then return end
  for _, img in ipairs(image.get_images { buffer = buf, namespace = ns }) do
    img:clear()
  end
end

local function show(buf, png, block)
  local win = vim.fn.bufwinid(buf)
  if win == -1 then return end
  if vim.wo[win].conceallevel == 0 then vim.wo[win].conceallevel = 2 end
  local line_count = vim.api.nvim_buf_line_count(buf)
  -- The image hangs off the line after the block. It must not be a concealed line
  -- (render-markdown conceals the closing fence), or its virtual lines can't be scrolled through.
  local anchor = block.end_row + 1 < line_count and block.end_row + 1 or block.end_row
  local hidden_end = anchor - 1
  if hidden_end > block.start_row then
    local last = vim.api.nvim_buf_get_lines(buf, hidden_end, hidden_end + 1, false)[1]
    vim.api.nvim_buf_set_extmark(buf, extmark_ns, block.start_row + 1, 0, {
      end_row = hidden_end,
      end_col = #last,
      conceal_lines = "",
    })
    -- a closed fold makes <C-e>/j skip the hidden lines in one step instead of one per line
    if vim.wo[win].foldmethod == "manual" then
      vim.api.nvim_win_call(win, function()
        vim.cmd(("silent! %d,%dfold"):format(block.start_row + 2, hidden_end + 1))
      end)
      local folds = vim.b[buf].mermaid_inline_folds or {}
      table.insert(folds, block.start_row + 2)
      vim.b[buf].mermaid_inline_folds = folds
    end
  end
  local img = require("image").from_file(png, {
    id = ("%s:%d:%d"):format(ns, buf, anchor),
    window = win,
    buffer = buf,
    with_virtual_padding = true,
    namespace = ns,
  })
  if not img then return end
  -- stretch to the window's text width, but at most max_zoom x the natural (1x) size, so a wide
  -- (landscape) window doesn't blow the diagram up to several screens tall. image.nvim derives
  -- the height from the aspect ratio; tall diagrams run past the window and scroll like text.
  img.ignore_global_max_size = true
  local width = vim.api.nvim_win_get_width(win) - vim.fn.getwininfo(win)[1].textoff
  local term = require("image/utils").term.get_size()
  if term then
    local natural = img.image_width / M.opts.scale / term.cell_width
    width = math.min(width, math.ceil(natural * M.opts.max_zoom))
  end
  img.geometry.width = width
  img:render { x = 0, y = anchor }
end

function M.render(buf)
  buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
  if not pcall(require, "image") then
    return vim.notify("mermaid_inline: image.nvim not loaded", vim.log.levels.ERROR)
  end
  if vim.fn.executable "mmdc" == 0 then
    return vim.notify("mermaid_inline: mmdc not found", vim.log.levels.ERROR)
  end
  vim.fn.mkdir(cache_dir, "p")
  clear(buf)

  local config = vim.deepcopy(M.opts.config[background()] or {})
  config.themeVariables = config.themeVariables or {}
  config.themeVariables.fontSize = M.opts.font_size .. "px"
  local config_json = encode_sorted(config)
  local config_file = ("%s/%s.json"):format(cache_dir, vim.fn.sha256(config_json):sub(1, 16))
  if not vim.uv.fs_stat(config_file) then vim.fn.writefile({ config_json }, config_file) end

  for _, block in ipairs(find_blocks(buf)) do
    local hash = vim.fn.sha256(config_json .. M.opts.scale .. block.src):sub(1, 16)
    local png = ("%s/%s.png"):format(cache_dir, hash)
    if vim.uv.fs_stat(png) then
      show(buf, png, block)
    else
      local input = ("%s/%s.mmd"):format(cache_dir, hash)
      vim.fn.writefile(vim.split(block.src, "\n"), input)
      vim.system(
        { "mmdc", "-i", input, "-o", png, "-c", config_file, "-b", "transparent", "-s", tostring(M.opts.scale) },
        { text = true },
        vim.schedule_wrap(function(res)
          os.remove(input)
          if res.code ~= 0 then
            local err = (res.stderr or ""):match "Error[^\n]*" or res.stderr
            return vim.notify("mermaid_inline: line " .. (block.start_row + 1) .. ": " .. err, vim.log.levels.ERROR)
          end
          if enabled[buf] and vim.api.nvim_buf_is_valid(buf) then show(buf, png, block) end
        end)
      )
    end
  end
end

function M.toggle()
  local buf = vim.api.nvim_get_current_buf()
  if enabled[buf] then
    enabled[buf] = false
    clear(buf)
  else
    enabled[buf] = true
    M.render(buf)
  end
end

-- follow render-markdown's global on/off state (on when render-markdown isn't installed)
local function markdown_rendering()
  local ok, rm = pcall(require, "render-markdown")
  return not ok or rm.get()
end

-- Re-sync every buffer with render-markdown's state; call after toggling render-markdown.
-- Turning on drops per-buffer :MermaidInline overrides, so hidden buffers re-render on BufWinEnter.
function M.sync()
  local on = markdown_rendering()
  for buf, state in pairs(enabled) do
    if state and vim.api.nvim_buf_is_valid(buf) then clear(buf) end
  end
  enabled = {}
  if not (on and M.opts.auto) then return end
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if enabled[buf] == nil and vim.bo[buf].filetype == "markdown" and #find_blocks(buf) > 0 then
      enabled[buf] = true
      M.render(buf)
    end
  end
end

function M.setup(opts)
  M.opts = vim.tbl_extend("force", M.opts, opts or {})
  vim.api.nvim_create_user_command("MermaidInline", M.toggle, { desc = "Toggle inline mermaid rendering" })
  local group = vim.api.nvim_create_augroup("MermaidInline", { clear = true })
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    pattern = { "*.md", "*.markdown" },
    callback = function(ev)
      if enabled[ev.buf] then M.render(ev.buf) end
    end,
  })
  vim.api.nvim_create_autocmd({ "WinResized", "ColorScheme" }, {
    group = group,
    callback = function(ev)
      -- images are sized to the window and themed after the colorscheme; PNGs are cached per theme
      local wins = ev.event == "WinResized" and vim.v.event.windows or vim.api.nvim_list_wins()
      local seen = {}
      for _, win in ipairs(wins) do
        local buf = vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win)
        if buf and enabled[buf] and not seen[buf] then
          seen[buf] = true
          M.render(buf)
        end
      end
    end,
  })
  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = group,
    pattern = { "*.md", "*.markdown" },
    callback = function(ev)
      -- scheduled so the window is settled (and image.nvim can load) before rendering
      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(ev.buf) or vim.fn.bufwinid(ev.buf) == -1 then return end
        if enabled[ev.buf] == nil and M.opts.auto and markdown_rendering() and #find_blocks(ev.buf) > 0 then
          enabled[ev.buf] = true
        end
        -- also re-render when the buffer is shown again, since images are tied to a window
        if enabled[ev.buf] then M.render(ev.buf) end
      end)
    end,
  })
end

return M
