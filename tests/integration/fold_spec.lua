-- Set up package path for engine submodule
require('tests.test_helper')

local config = require('kanban-md.config')
local detect = require('kanban-md.detect')

-- Real Neovim adapter, commands and autocmds
require('kanban-md').setup()

-- Register the filetype detection (normally sourced from ftdetect/ at startup)
local project_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
dofile(project_root .. "/ftdetect/kanban-md.lua")

describe("column folds #neovim-only", function()
  local dir

  local board = {
    "# Board",                  -- 1
    "",                         -- 2
    "## Notes",                 -- 3
    "Some notes",               -- 4
    "",                         -- 5
    "###### Todo",              -- 6
    "",                         -- 7
    "- First",                  -- 8
    "- Second",                 -- 9
    "  continued",              -- 10
    "",                         -- 11
    "###### Done",              -- 12
    "- Third",                  -- 13
    "",                         -- 14
    "## Trailing notes",        -- 15
    "More notes",               -- 16
  }

  local function open(name, lines)
    local path = dir .. "/" .. name
    vim.fn.writefile(lines, path)
    vim.cmd("edit " .. vim.fn.fnameescape(path))
    return vim.api.nvim_get_current_buf()
  end

  before_each(function()
    dir = vim.fn.tempname()
    vim.fn.mkdir(dir, "p")
    config.reset()
  end)

  after_each(function()
    vim.cmd("silent! %bwipeout!")
    vim.fn.delete(dir, "rf")
    config.reset()
  end)

  it("folds each column from its heading to the next heading", function()
    open("todo.kanban.md", board)
    assert.equals("expr", vim.wo.foldmethod)

    assert.equals(0, vim.fn.foldlevel(4))
    assert.equals(-1, vim.fn.foldclosed(6)) -- columns start open
    vim.cmd("normal! zM")
    assert.equals(6, vim.fn.foldclosed(8))
    assert.equals(11, vim.fn.foldclosedend(6))
    assert.equals(12, vim.fn.foldclosed(13))
    assert.equals(14, vim.fn.foldclosedend(12))
    assert.equals(0, vim.fn.foldlevel(15))
    assert.equals(0, vim.fn.foldlevel(16))
  end)

  it("shows the column heading and card count in the fold text", function()
    open("todo.kanban.md", board)
    vim.cmd("normal! zM")

    assert.equals("###### Todo (2 cards)", vim.fn.foldtextresult(6))
    assert.equals("###### Done (1 card)", vim.fn.foldtextresult(12))
  end)

  it("leaves ordinary markdown unfolded", function()
    open("notes.md", board)
    assert.equals("markdown", vim.bo.filetype)
    assert.are_not.equals("v:lua.require'kanban-md.fold'.foldexpr()", vim.wo.foldexpr)
  end)

  it("removes the folds when the buffer stops being a board", function()
    local buf = open("board.md", vim.list_extend({ detect.MARKER }, board))
    assert.equals(detect.FILETYPE, vim.bo[buf].filetype)
    assert.equals("expr", vim.wo.foldmethod)

    vim.api.nvim_buf_set_lines(buf, 0, 1, false, {})
    vim.cmd("silent write")
    assert.equals("markdown", vim.bo[buf].filetype)
    assert.are_not.equals("v:lua.require'kanban-md.fold'.foldexpr()", vim.wo.foldexpr)
  end)

  it("does nothing when fold_columns is false", function()
    config.setup({ fold_columns = false })
    open("todo.kanban.md", board)
    assert.are_not.equals("v:lua.require'kanban-md.fold'.foldexpr()", vim.wo.foldexpr)
  end)
end)
