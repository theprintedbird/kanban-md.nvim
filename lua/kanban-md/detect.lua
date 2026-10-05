-- lua/kanban-md/detect.lua
-- Decides which markdown buffers are kanban boards, and so get the
-- compound filetype "markdown.kanban" (markdown ftplugin/syntax/treesitter
-- load first, then anything registered for "kanban").

local M = {}

M.FILETYPE = "markdown.kanban"

local MARKER_PATTERN = "<!%-%-%s*kanban%-board%s*%-%->"

-- Resolve detection_strategy, honouring the legacy require_kanban_marker option.
-- Detection can run before the engine is on package.path, so fall back to "marker".
local function get_strategy()
  local ok, config = pcall(require, "kanban-md.config")
  if not ok then
    return "marker"
  end

  local strategy = config.get_value("detection_strategy")
  if strategy and strategy ~= "" then
    return strategy
  end

  local require_marker = config.get_value("require_kanban_marker")
  if require_marker == false then
    return "auto"
  end
  return "marker"
end

local function has_marker(bufnr)
  for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, 10, false)) do
    if line:match(MARKER_PATTERN) then
      return true
    end
  end
  return false
end

local function has_column_header(bufnr)
  for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
    if line:match("^######%s+") then
      return true
    end
  end
  return false
end

-- Is this buffer a kanban board?
-- @param bufnr number
-- @param path string|nil Buffer path; defaults to the buffer's name
-- @return boolean
function M.is_board(bufnr, path)
  path = path or vim.api.nvim_buf_get_name(bufnr)

  -- *.kanban.md is always a board, whatever the strategy
  if path:match("%.kanban%.md$") then
    return true
  end

  local strategy = get_strategy()
  if strategy == "marker" or strategy == "both" then
    return has_marker(bufnr)
  elseif strategy == "auto" then
    return has_column_header(bufnr)
  end
  return false
end

-- vim.filetype.add callback. Returning nil falls through to the built-in
-- markdown detection.
function M.match(path, bufnr)
  if M.is_board(bufnr, path) then
    return M.FILETYPE
  end
end

return M
