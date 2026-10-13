-- Centred floating text input for kanban prompts
--
-- vim.ui.input is replaced by whatever UI plugin the user has installed, so
-- its size and position are unpredictable. This opens a wide float in the
-- middle of the editor instead. The text wraps and the window grows, up to
-- max_height lines, so a long card stays fully visible.
--
-- Set `input = { native = true }` in setup() to use vim.ui.input instead.

local M = {}

M.defaults = {
  native = false,   -- use vim.ui.input instead of the float
  width = 0.6,      -- fraction of the editor width (<= 1), or columns (> 1)
  min_width = 40,
  max_width = 100,
  max_height = 5,   -- lines; the window grows to this as the text wraps
  border = "rounded",
}

-- Plugin defaults merged with the `input` table from setup()
-- @return table
function M.options()
  local ok, config = pcall(require, "kanban-md.config")
  local user = ok and config.get_value("input") or nil
  if type(user) ~= "table" then
    user = {}
  end
  return vim.tbl_extend("force", M.defaults, user)
end

local function clamp(n, lo, hi)
  return math.max(lo, math.min(hi, n))
end

-- Width of the text area, in columns
local function text_width(opts)
  local columns = vim.o.columns
  local width = opts.width <= 1 and math.floor(columns * opts.width) or opts.width
  width = clamp(width, opts.min_width, opts.max_width)
  -- Leave room for the border and a margin on a narrow screen
  return math.max(1, math.min(width, columns - 4))
end

-- Number of screen lines the text needs when wrapped at `width`
local function wrapped_height(win, width)
  if vim.api.nvim_win_text_height then
    return vim.api.nvim_win_text_height(win, {}).all
  end
  local lines = vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(win), 0, -1, false)
  local height = 0
  for _, line in ipairs(lines) do
    -- +1 so the cursor has room at the end of a full line
    height = height + math.max(1, math.ceil((vim.fn.strdisplaywidth(line) + 1) / width))
  end
  return height
end

-- Float config that centres a `width` x `height` text area in the editor
local function layout(opts, width, height)
  local border = opts.border ~= "none" and 2 or 0
  local editor_height = vim.o.lines - vim.o.cmdheight
  height = clamp(height, 1, math.max(1, math.min(opts.max_height, editor_height - border - 2)))
  return {
    relative = "editor",
    width = width,
    height = height,
    row = math.max(0, math.floor((editor_height - height - border) / 2)),
    col = math.max(0, math.floor((vim.o.columns - width - border) / 2)),
  }
end

-- The prompt, without the trailing colon and spaces commands add for the
-- command line, as the window title
local function title_for(prompt)
  local title = (prompt or ""):gsub("[%s:]+$", "")
  if title == "" then
    return nil
  end
  return " " .. title .. " "
end

-- Open the input window
-- @param prompt string|nil Shown as the window title
-- @param default string|nil Initial text
-- @param on_confirm fun(input: string|nil) Called with the text, or nil when cancelled
-- @return number|nil The window id (nil when vim.ui.input is used)
function M.open(prompt, default, on_confirm)
  local opts = M.options()
  if opts.native then
    vim.ui.input({ prompt = prompt, default = default }, on_confirm)
    return nil
  end

  local origin = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "kanban-md-input"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { default or "" })

  local width = text_width(opts)
  local win_config = layout(opts, width, 1)
  win_config.style = "minimal"
  win_config.border = opts.border
  if opts.border ~= "none" then
    win_config.title = title_for(prompt)
    win_config.title_pos = win_config.title and "center" or nil
  end
  local win = vim.api.nvim_open_win(buf, true, win_config)
  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true
  vim.wo[win].breakindent = false
  vim.wo[win].sidescrolloff = 0

  local function resize()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_set_config(win, layout(opts, width, wrapped_height(win, width)))
    end
  end
  resize()

  local done = false
  local group = vim.api.nvim_create_augroup("KanbanMdInput" .. buf, { clear = true })

  local function finish(result)
    if done then
      return
    end
    done = true
    pcall(vim.api.nvim_del_augroup_by_id, group)
    -- Go back to the board, unless the user already moved to another window
    if vim.api.nvim_get_current_win() == win then
      vim.cmd("stopinsert")
      if vim.api.nvim_win_is_valid(origin) then
        vim.api.nvim_set_current_win(origin)
      end
    end
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    -- Run after the window has gone, so the command sees the board buffer
    vim.schedule(function()
      on_confirm(result)
    end)
  end

  local function confirm()
    -- A card is one line: join anything pasted over several lines
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    finish(table.concat(lines, " "))
  end

  local function cancel()
    finish(nil)
  end

  local map = function(modes, lhs, rhs)
    vim.keymap.set(modes, lhs, rhs, { buffer = buf, nowait = true, silent = true })
  end
  map({ "i", "n" }, "<CR>", confirm)
  map({ "i", "n" }, "<C-c>", cancel)
  map("n", "<Esc>", cancel)
  map("n", "q", cancel)

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = group,
    buffer = buf,
    callback = resize,
  })
  vim.api.nvim_create_autocmd("VimResized", {
    group = group,
    callback = function()
      width = text_width(opts)
      resize()
    end,
  })
  -- Leaving the window (a mouse click, <C-w>w) cancels, so the float is never
  -- left behind. Scheduled, as a window cannot be closed inside WinLeave.
  vim.api.nvim_create_autocmd("WinLeave", {
    group = group,
    buffer = buf,
    callback = function()
      vim.schedule(cancel)
    end,
  })

  vim.cmd("startinsert!")
  return win
end

return M
