-- lua/kanban-md/fold.lua
-- One fold per column: each H6 heading opens a level-1 fold that runs until
-- the next heading of any level, so the H2-H5 notes between columns stay unfolded.

local M = {}

local FOLD_OPTIONS = { "foldmethod", "foldexpr", "foldtext", "foldlevel" }

-- 'foldexpr' for a board buffer
-- @param lnum number|nil Line number; defaults to v:lnum
-- @return string
function M.foldexpr(lnum)
  local line = vim.fn.getline(lnum or vim.v.lnum)
  if line:match("^######%s") then
    return ">1"
  end
  local hashes = line:match("^(#+)%s")
  if hashes and #hashes < 6 then
    return "0"
  end
  return "="
end

-- 'foldtext' for a board buffer: the column heading and its card count
-- @return string
function M.foldtext()
  local lines = vim.api.nvim_buf_get_lines(0, vim.v.foldstart - 1, vim.v.foldend, false)
  local cards = 0
  for i = 2, #lines do
    if lines[i]:match("^%- ") then
      cards = cards + 1
    end
  end
  return string.format("%s (%d card%s)", lines[1], cards, cards == 1 and "" or "s")
end

-- Is column folding enabled? Defaults to on.
local function enabled()
  local ok, config = pcall(require, "kanban-md.config")
  return not ok or config.get_value("fold_columns") ~= false
end

-- Set the fold options in every window showing the buffer, and arrange for
-- them to be reset when the filetype changes
-- @param bufnr number
function M.attach(bufnr)
  if not enabled() then
    return
  end

  for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
    -- Like :setlocal, so the board's folding doesn't leak into new windows
    vim.api.nvim_win_call(win, function()
      local function setlocal(name, value)
        vim.api.nvim_set_option_value(name, value, { scope = "local" })
      end
      setlocal("foldmethod", "expr")
      setlocal("foldexpr", "v:lua.require'kanban-md.fold'.foldexpr()")
      setlocal("foldtext", "v:lua.require'kanban-md.fold'.foldtext()")
      -- Start with the columns open, unless the user chose otherwise
      if vim.o.foldlevelstart < 0 then
        setlocal("foldlevel", 99)
      end
    end)
  end

  local undo = "setlocal " .. table.concat(FOLD_OPTIONS, "< ") .. "<"
  local existing = vim.b[bufnr].undo_ftplugin
  if existing == nil or existing == "" then
    vim.b[bufnr].undo_ftplugin = undo
  elseif not existing:find(undo, 1, true) then
    vim.b[bufnr].undo_ftplugin = existing .. " | " .. undo
  end
end

return M
