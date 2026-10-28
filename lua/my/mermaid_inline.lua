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
  -- cap on stretching a diagram (and its text) to fill the window, relative to its 1x size;
  -- up to `scale` the PNG has the pixels for it, past that it gets blurry
  max_zoom = 3,
  -- also lay diagrams out the other way (TD <-> LR) and show whichever suits the window: the one
  -- drawn clearly larger, else the one shaped like the window (wide window -> left to right).
  -- Only the rendered image changes, not the buffer.
  auto_direction = true,
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
        doneTaskBkgColor = "#585b70", -- gantt; the derived one is light grey under white text
        doneTaskBorderColor = "#a6adc8",
      },
    },
    light = { theme = "default" },
  },
}

-- mermaid config sections that take useMaxWidth
local diagram_kinds = {
  "flowchart",
  "sequence",
  "class",
  "state",
  "er",
  "gantt",
  "journey",
  "timeline",
  "mindmap",
  "pie",
  "requirement",
  "gitGraph",
  "quadrantChart",
  "xyChart",
  "sankey",
  "block",
  "architecture",
  "packet",
  "c4",
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

local function is_dark(r, g, b) return (0.299 * r + 0.587 * g + 0.114 * b) < 128 end

-- "dark" | "light" from the Normal highlight's background; vim.o.background isn't always kept in sync by colorschemes
local function background()
  local bg = vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg
  if not bg then return vim.o.background end
  return is_dark(bit.rshift(bg, 16), bit.band(bit.rshift(bg, 8), 0xff), bit.band(bg, 0xff)) and "dark" or "light"
end

-- r, g, b of a "#rgb" / "#rrggbb" / "rgb(r, g, b)" color; nil for anything else (named colors, ...)
local function parse_color(s)
  local hex = s:match "^#(%x+)$"
  if hex and #hex == 3 then hex = hex:gsub(".", "%0%0") end
  if hex and #hex == 6 then
    return tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
  end
  local r, g, b = s:match "^rgba?%(%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)"
  if r then return tonumber(r), tonumber(g), tonumber(b) end
end

-- Colors set in the diagram itself ignore the theme's text color, so e.g. a light `style ... fill:`
-- would get white text in dark mode. Give such fills a readable text color, and fade sequence
-- `rect`/`box` backgrounds that clash with the theme (their text is the theme's).
local function adapt_colors(src, mode)
  local lines = vim.split(src, "\n")
  for i, line in ipairs(lines) do
    local kw = line:match "^%s*(%a+)%s"
    if (kw == "style" or kw == "classDef") and not line:match "[%s,;]color%s*:" then
      local fill = line:match "fill%s*:%s*(rgba?%b())" or line:match "fill%s*:%s*(#%x+)"
      local r, g, b = parse_color(fill or "")
      if r then lines[i] = line:gsub("[%s;]*$", "") .. (",color:%s"):format(is_dark(r, g, b) and "#fff" or "#000") end
    elseif kw == "rect" or kw == "box" then
      local pre, r, g, b, post = line:match "^(%s*%a+%s+)rgba?%(%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)[^)]*%)(.*)$"
      if r and is_dark(tonumber(r), tonumber(g), tonumber(b)) ~= (mode == "dark") then
        lines[i] = ("%srgba(%s, %s, %s, 0.2)%s"):format(pre, r, g, b, post)
      end
    end
  end
  return table.concat(lines, "\n")
end

local flips = { TD = "LR", TB = "LR", BT = "RL", LR = "TD", RL = "BT" }

-- src laid out in the other direction, or nil for diagram types without one (sequence, gantt, ...)
local function flip_direction(src)
  local lines = vim.split(src, "\n")
  local h, in_frontmatter = nil, false
  for i, line in ipairs(lines) do
    if line:match "^%s*%-%-%-%s*$" then
      in_frontmatter = not in_frontmatter
    elseif not in_frontmatter and not line:match "^%s*$" and not line:match "^%s*%%%%" then
      h = i
      break
    end
  end
  if not h then return end
  local header = lines[h]
  local kw, rest = header:match "^%s*(%a+)(.*)$"
  if kw == "flowchart" or kw == "graph" then
    local pre, dir, post = rest:match "^(%s+)(%u%u)(.*)$"
    if dir and flips[dir] then
      lines[h] = header:sub(1, #header - #rest) .. pre .. flips[dir] .. post
    elseif rest:match "^%s*;?%s*$" then
      lines[h] = header:gsub("%s*;?%s*$", "") .. " LR" -- no direction means TD
    else
      return
    end
  elseif (kw == "stateDiagram" or kw == "classDiagram" or kw == "erDiagram") and rest:match "^%-?v?2?%s*$" then
    -- these take a `direction` statement; only a top-level one right after the header is swapped
    local j = h + 1
    while lines[j] and (lines[j]:match "^%s*$" or lines[j]:match "^%s*%%%%") do
      j = j + 1
    end
    local pre, dir, post = (lines[j] or ""):match "^(%s*direction%s+)(%u%u)(.*)$"
    if dir and flips[dir] then
      lines[j] = pre .. flips[dir] .. post
    elseif dir then
      return
    else
      table.insert(lines, h + 1, "  direction LR") -- no direction means TB
    end
  else
    return
  end
  return table.concat(lines, "\n")
end

-- width, height in px of a PNG file, from its IHDR chunk
local function png_size(path)
  local f = io.open(path, "rb")
  if not f then return end
  local head = f:read(24)
  f:close()
  if not head or #head < 24 or head:sub(13, 16) ~= "IHDR" then return end
  local function u32(i)
    local a, b, c, d = head:byte(i, i + 3)
    return ((a * 256 + b) * 256 + c) * 256 + d
  end
  return u32(17), u32(21)
end

-- Space in win a diagram can take: the text width, and the window height minus the anchor line,
-- which is the most that shows at once (scrolled to the top). Past the end of the buffer the
-- virtual lines can't be scrolled through at all, and elsewhere a taller image could never be
-- seen in one piece. Also returns the terminal's cell size in px, or nil if unknown.
local function space(win)
  local cols = vim.api.nvim_win_get_width(win) - vim.fn.getwininfo(win)[1].textoff
  local rows = vim.api.nvim_win_get_height(win) - 1
  return cols, rows, require("image/utils").term.get_size()
end

-- Columns to draw a w x h px diagram at in win, and the zoom that is relative to its natural (1x) size:
-- as large as fits the space, up to max_zoom. image.nvim derives the height from the aspect ratio
-- (rounding the rows up, which the floor below leaves room for).
local function fit(win, w, h)
  local cols, rows, term = space(win)
  if not term then return cols, 1 end
  local natural = w / M.opts.scale / term.cell_width
  local width = math.min(
    cols,
    math.ceil(natural * M.opts.max_zoom),
    math.floor(rows * term.cell_height * (w / h) / term.cell_width)
  )
  return width, width / natural
end

-- The better of two layouts (PNG paths) of a diagram for win: the one drawn clearly larger, so a
-- near tie doesn't swap layouts on every small resize, else the one shaped like the window.
local function pick(win, a, b)
  local aw, ah = png_size(a)
  local bw, bh = png_size(b)
  if not (aw and bw) then return aw and a or b end
  local _, za = fit(win, aw, ah)
  local _, zb = fit(win, bw, bh)
  if za > zb * 1.2 then return a end
  if zb > za * 1.2 then return b end
  local cols, rows, term = space(win)
  local wide = term and cols * term.cell_width >= rows * term.cell_height or cols >= rows * 2
  return (aw >= ah) == wide and a or b
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
  -- At the end of the buffer it hangs off the opening fence instead (render-markdown shows the language there).
  local anchor = block.end_row + 1 < line_count and block.end_row + 1 or block.start_row
  local hidden_end = block.end_row
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
  img.ignore_global_max_size = true
  img.geometry.width = fit(win, img.image_width, img.image_height)
  img:render { x = 0, y = anchor }
end

-- Render src to a PNG with mmdc (cached by content), then on_done(png) or on_done(nil, err).
local function to_png(src, config_json, config_file, on_done)
  local hash = vim.fn.sha256(config_json .. M.opts.scale .. src):sub(1, 16)
  local png = ("%s/%s.png"):format(cache_dir, hash)
  if vim.uv.fs_stat(png) then return on_done(png) end
  local input = ("%s/%s.mmd"):format(cache_dir, hash)
  vim.fn.writefile(vim.split(src, "\n"), input)
  vim.system(
    { "mmdc", "-i", input, "-o", png, "-c", config_file, "-b", "transparent", "-s", tostring(M.opts.scale) },
    { text = true },
    vim.schedule_wrap(function(res)
      os.remove(input)
      if res.code ~= 0 then return on_done(nil, (res.stderr or ""):match "Error[^\n]*" or res.stderr) end
      on_done(png)
    end)
  )
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

  local mode = background()
  local config = vim.deepcopy(M.opts.config[mode] or {})
  config.themeVariables = config.themeVariables or {}
  config.themeVariables.fontSize = M.opts.font_size .. "px"
  -- With useMaxWidth (the default) mermaid scales each diagram to mmdc's 800px page width, so a
  -- wide diagram is squeezed (tiny text) and a narrow one stretched. Off, the PNG is the diagram's
  -- real 1x size, which fit() and pick() size against.
  for _, kind in ipairs(diagram_kinds) do
    config[kind] = vim.tbl_extend("keep", config[kind] or {}, { useMaxWidth = false })
  end
  -- gantt has its own (11px) font size instead of the theme's
  config.gantt = vim.tbl_extend("keep", config.gantt, { fontSize = M.opts.font_size, sectionFontSize = M.opts.font_size })
  local config_json = encode_sorted(config)
  local config_file = ("%s/%s.json"):format(cache_dir, vim.fn.sha256(config_json):sub(1, 16))
  if not vim.uv.fs_stat(config_file) then vim.fn.writefile({ config_json }, config_file) end

  for _, block in ipairs(find_blocks(buf)) do
    local src = adapt_colors(block.src, mode)
    local function done(png)
      if enabled[buf] and vim.api.nvim_buf_is_valid(buf) then show(buf, png, block) end
    end
    to_png(src, config_json, config_file, function(png, err)
      if not png then
        return vim.notify("mermaid_inline: line " .. (block.start_row + 1) .. ": " .. err, vim.log.levels.ERROR)
      end
      local flipped = M.opts.auto_direction and flip_direction(src)
      if not flipped then return done(png) end
      to_png(flipped, config_json, config_file, function(alt)
        local win = vim.fn.bufwinid(buf)
        done(alt and win ~= -1 and pick(win, png, alt) or png)
      end)
    end)
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
