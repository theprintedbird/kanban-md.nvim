-- Set up package path for engine submodule
require('tests.test_helper')

local config = require('kanban-md.config')
local detect = require('kanban-md.detect')

-- Real Neovim adapter, commands and autocmds
require('kanban-md').setup()

-- Register the filetype detection (normally sourced from ftdetect/ at startup)
local project_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
dofile(project_root .. "/ftdetect/kanban-md.lua")

describe("filetype detection #neovim-only", function()
  local dir

  -- Write lines to a file in the temp dir and open it
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

  it("gives *.kanban.md files the kanban filetype without a marker", function()
    local buf = open("todo.kanban.md", { "# Board", "", "###### Todo" })
    assert.equals(detect.FILETYPE, vim.bo[buf].filetype)
  end)

  it("gives *.md files with the marker the kanban filetype", function()
    local buf = open("board.md", { "<!-- kanban-board -->", "# Board", "", "###### Todo" })
    assert.equals(detect.FILETYPE, vim.bo[buf].filetype)
  end)

  it("leaves *.md files without the marker as markdown", function()
    local buf = open("notes.md", { "# Notes", "", "###### Not a column" })
    assert.equals("markdown", vim.bo[buf].filetype)
  end)

  it("ignores the marker under the extension strategy", function()
    config.setup({ detection_strategy = "extension" })
    local buf = open("board.md", { "<!-- kanban-board -->", "# Board" })
    assert.equals("markdown", vim.bo[buf].filetype)
  end)

  it("detects H6 columns under the auto strategy", function()
    config.setup({ detection_strategy = "auto" })
    local buf = open("board.md", { "# Board", "", "###### Todo" })
    assert.equals(detect.FILETYPE, vim.bo[buf].filetype)
  end)

  it("updates the filetype on write when the marker is added or removed", function()
    local buf = open("board.md", { "# Board", "", "###### Todo" })
    assert.equals("markdown", vim.bo[buf].filetype)

    vim.api.nvim_buf_set_lines(buf, 0, 0, false, { "<!-- kanban-board -->" })
    vim.cmd("silent write")
    assert.equals(detect.FILETYPE, vim.bo[buf].filetype)

    vim.api.nvim_buf_set_lines(buf, 0, 1, false, {})
    vim.cmd("silent write")
    assert.equals("markdown", vim.bo[buf].filetype)
  end)

  it("sets the kanban filetype on :KanbanNewBoard and keeps it on write", function()
    local original_input = vim.ui.input
    vim.ui.input = function(_, callback) callback("Test Board") end
    config.setup({ input = { native = true } })

    local buf = open("new.md", { "" })
    assert.equals("markdown", vim.bo[buf].filetype)

    local ok, err = pcall(vim.cmd, "KanbanNewBoard")
    vim.ui.input = original_input
    assert(ok, err)

    assert.equals(detect.FILETYPE, vim.bo[buf].filetype)
    vim.cmd("silent write")
    assert.equals(detect.FILETYPE, vim.bo[buf].filetype)
  end)

  it("writes the marker on :KanbanNewBoard so the file is detected when reopened", function()
    local original_input = vim.ui.input
    vim.ui.input = function(_, callback) callback("Test Board") end
    config.setup({ input = { native = true } })

    local buf = open("marked.md", { "" })
    local path = vim.api.nvim_buf_get_name(buf)

    local ok, err = pcall(vim.cmd, "KanbanNewBoard")
    vim.ui.input = original_input
    assert(ok, err)

    assert.equals(detect.MARKER, vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1])
    vim.cmd("silent write")

    -- A fresh buffer has no kanban_md_board flag, so only the marker can match
    vim.cmd("bwipeout!")
    vim.cmd("edit " .. vim.fn.fnameescape(path))
    assert.equals(detect.FILETYPE, vim.bo.filetype)
    assert.is_nil(vim.b.kanban_md_board)
  end)
end)
