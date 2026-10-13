-- Set up package path for engine submodule
require('tests.test_helper')

local config = require('kanban-md.config')
local input = require('kanban-md.input')

local function feed(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "x", false)
end

describe("floating input #neovim-only", function()
  local origin, result, called

  -- Open the float and record what the callback receives
  local function open(prompt, default)
    return input.open(prompt, default, function(value)
      called = true
      result = value
    end)
  end

  local function wait_for_callback()
    vim.wait(1000, function() return called end)
  end

  before_each(function()
    config.reset()
    vim.o.columns = 80
    vim.o.lines = 24
    origin = vim.api.nvim_get_current_win()
    result, called = nil, false
  end)

  after_each(function()
    vim.cmd("stopinsert")
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if win ~= origin then
        pcall(vim.api.nvim_win_close, win, true)
      end
    end
    -- Closing a float schedules its cancel callback; let it run now, not in the next test
    vim.wait(50)
    config.reset()
  end)

  it("opens a wide float centred in the editor", function()
    local win = open("Card title: ", "")
    local cfg = vim.api.nvim_win_get_config(win)

    assert.equals("editor", cfg.relative)
    assert.equals(48, cfg.width) -- 60% of 80 columns
    assert.equals(1, cfg.height)
    -- Centred, counting the two border cells
    assert.equals(math.floor((80 - 48 - 2) / 2), cfg.col)
    assert.equals(math.floor((24 - vim.o.cmdheight - 1 - 2) / 2), cfg.row)
    assert.equals(win, vim.api.nvim_get_current_win())
  end)

  it("keeps the minimum width on a narrow editor", function()
    vim.o.columns = 50
    local cfg = vim.api.nvim_win_get_config(open("Card title: ", ""))
    assert.equals(40, cfg.width)
  end)

  it("uses the prompt, without its trailing colon, as the title", function()
    local cfg = vim.api.nvim_win_get_config(open("Card title: ", ""))
    local title = cfg.title
    if type(title) == "table" then
      title = title[1][1]
    end
    assert.equals(" Card title ", title)
  end)

  it("fills the buffer with the default text", function()
    local win = open("Rename: ", "Old name")
    local buf = vim.api.nvim_win_get_buf(win)
    assert.same({ "Old name" }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
  end)

  it("grows to fit wrapped text, up to max_height", function()
    local win = open("Card title: ", "")
    local buf = vim.api.nvim_win_get_buf(win)

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { string.rep("word ", 20) }) -- 100 chars
    vim.api.nvim_exec_autocmds("TextChanged", { buffer = buf })
    assert.equals(3, vim.api.nvim_win_get_config(win).height)

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { string.rep("word ", 200) })
    vim.api.nvim_exec_autocmds("TextChanged", { buffer = buf })
    assert.equals(input.defaults.max_height, vim.api.nvim_win_get_config(win).height)
  end)

  it("honours width and max_height from setup()", function()
    config.setup({ input = { width = 70, max_height = 2 } })
    local win = open("Card title: ", string.rep("word ", 100))
    local cfg = vim.api.nvim_win_get_config(win)
    assert.equals(70, cfg.width)
    assert.equals(2, cfg.height)
  end)

  it("returns the text on <CR> and goes back to the original window", function()
    local win = open("Card title: ", "New card")
    feed("<CR>")
    wait_for_callback()

    assert.equals("New card", result)
    assert.is_false(vim.api.nvim_win_is_valid(win))
    assert.equals(origin, vim.api.nvim_get_current_win())
  end)

  it("joins text pasted over several lines into one line", function()
    local win = open("Card title: ", "")
    vim.api.nvim_buf_set_lines(vim.api.nvim_win_get_buf(win), 0, -1, false, { "one", "two" })
    feed("<CR>")
    wait_for_callback()
    assert.equals("one two", result)
  end)

  it("cancels with <Esc> in normal mode", function()
    local win = open("Card title: ", "Draft")
    feed("<Esc><Esc>")
    wait_for_callback()

    assert.is_true(called)
    assert.is_nil(result)
    assert.is_false(vim.api.nvim_win_is_valid(win))
    assert.equals(origin, vim.api.nvim_get_current_win())
  end)

  it("cancels when focus leaves the window", function()
    local win = open("Card title: ", "Draft")
    vim.cmd("stopinsert")
    vim.api.nvim_set_current_win(origin)
    wait_for_callback()

    assert.is_true(called)
    assert.is_nil(result)
    assert.is_false(vim.api.nvim_win_is_valid(win))
  end)

  it("uses vim.ui.input when native is set", function()
    config.setup({ input = { native = true } })
    local original = vim.ui.input
    local seen
    vim.ui.input = function(opts, callback)
      seen = opts
      callback("from vim.ui.input")
    end

    local win = open("Card title: ", "x")
    vim.ui.input = original

    assert.is_nil(win)
    assert.same({ prompt = "Card title: ", default = "x" }, seen)
    assert.equals("from vim.ui.input", result)
  end)
end)
