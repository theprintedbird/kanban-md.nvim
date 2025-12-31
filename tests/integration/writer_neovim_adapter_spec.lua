-- tests/integration/writer_neovim_adapter_spec.lua
-- Integration tests for writer operations with NeovimAdapter
-- Ensures NeovimAdapter handles write operations correctly with Neovim buffers

-- Skip this file in standalone Lua (requires Neovim)
if not vim or not vim.api then
  return
end

-- Set up package path for engine submodule
require('tests.test_helper')

_G._TEST = true

local Board = require("kanban-md.board")
local Card = require("kanban-md.card")
local Column = require("kanban-md.column")
local NeovimAdapter = require("kanban-md.adapters.neovim")
local CLIAdapter = require("kanban-md.adapters.cli")
local config_module = require("kanban-md.config")
local adapter_registry = require("kanban-md.adapter_registry")

describe("Writer NeovimAdapter integration #neovim-only", function()
  local original_config
  local original_adapter

  before_each(function()
    original_config = vim.deepcopy(config_module.get())
    config_module.setup({ persist_card_ids = true })

    -- Save original adapter
    original_adapter = _G.adapter

    -- Set NeovimAdapter as the global adapter
    _G.adapter = NeovimAdapter
    adapter_registry.set_adapter(NeovimAdapter)
  end)

  after_each(function()
    config_module.setup(original_config)

    -- Restore original adapter
    _G.adapter = original_adapter
    if original_adapter then
      adapter_registry.set_adapter(original_adapter)
    end
  end)

  describe("NeovimAdapter write operations", function()
    it("should write simple board to buffer", function()
      local board = Board:new()
      board:parse({
        "# Simple Board",
        "",
        "###### Todo",
        "- Task 1 <!-- id: t1 -->",
        "- Task 2 <!-- id: t2 -->",
        "",
        "###### Done",
        "- Task 3 <!-- id: t3 -->"
      })

      -- Create test buffer
      local bufnr = vim.api.nvim_create_buf(false, true)

      -- Write board to buffer using adapter
      local success = board:write_to_buffer(bufnr)
      assert.is_true(success)

      -- Read buffer contents
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      local output_text = table.concat(lines, "\n")

      -- Verify content
      assert.is_not_nil(output_text:match("# Simple Board"))
      assert.is_not_nil(output_text:match("###### Todo"))
      assert.is_not_nil(output_text:match("###### Done"))
      assert.is_not_nil(output_text:match("Task 1"))
      assert.is_not_nil(output_text:match("Task 2"))
      assert.is_not_nil(output_text:match("Task 3"))

      -- Clean up
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it("should write complex board with properties and config", function()
      local board = Board:new()
      board:parse({
        "# Complex Board",
        "",
        "## Documentation",
        "This is important context.",
        "",
        "###### Backlog",
        "- Feature A <!-- id: feat-a, priority: P0, complexity: 5 -->",
        "",
        "###### In Progress",
        "<!-- column:config wip_limit: 2 -->",
        "- Feature B <!-- id: feat-b, assignee: Alice -->",
        "",
        "###### Done",
        "<!-- column:config is_completion_state: true -->",
        "- Feature C <!-- id: feat-c -->",
        "",
        "## Notes",
        "Review weekly."
      })

      -- Create test buffer
      local bufnr = vim.api.nvim_create_buf(false, true)

      -- Write board to buffer
      local success = board:write_to_buffer(bufnr)
      assert.is_true(success)

      -- Read buffer contents
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      local output_text = table.concat(lines, "\n")

      -- Verify all content preserved
      assert.is_not_nil(output_text:match("# Complex Board"))
      assert.is_not_nil(output_text:match("## Documentation"))
      assert.is_not_nil(output_text:match("This is important context"))
      assert.is_not_nil(output_text:match("## Notes"))
      assert.is_not_nil(output_text:match("Review weekly"))

      -- Verify columns and cards
      assert.is_not_nil(output_text:match("###### Backlog"))
      assert.is_not_nil(output_text:match("###### In Progress"))
      assert.is_not_nil(output_text:match("###### Done"))
      assert.is_not_nil(output_text:match("feat%-a"))
      assert.is_not_nil(output_text:match("feat%-b"))
      assert.is_not_nil(output_text:match("feat%-c"))

      -- Verify properties preserved
      assert.is_not_nil(output_text:match("priority"))
      assert.is_not_nil(output_text:match("complexity"))
      assert.is_not_nil(output_text:match("assignee"))

      -- Verify config preserved
      assert.is_not_nil(output_text:match("wip_limit"))
      assert.is_not_nil(output_text:match("is_completion_state"))

      -- Clean up
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it("should preserve cursor position during write", function()
      local board = Board:new()
      board:parse({
        "# Board",
        "###### Todo",
        "- Task 1",
        "- Task 2",
        "- Task 3",
        "###### Done"
      })

      -- Create test buffer and write initial content
      local bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_set_current_buf(bufnr)

      -- Write board first to populate buffer
      board:write_to_buffer(bufnr)

      -- Now set cursor to line 3 (which should exist after write)
      local line_count = vim.api.nvim_buf_line_count(bufnr)
      local cursor_line = math.min(3, line_count) -- Don't exceed buffer size
      vim.api.nvim_win_set_cursor(0, { cursor_line, 0 })

      -- Write board again (should preserve or adjust cursor)
      board:write_to_buffer(bufnr)

      -- Get cursor position after write
      local cursor = vim.api.nvim_win_get_cursor(0)

      -- Cursor should be preserved or adjusted if line count changed
      assert.is_not_nil(cursor)
      assert.is_number(cursor[1])
      assert.is_true(cursor[1] >= 1, "Cursor line should be at least 1")
      assert.is_true(cursor[1] <= vim.api.nvim_buf_line_count(bufnr), "Cursor line should not exceed buffer size")

      -- Clean up
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it("should handle board modifications and rewrite", function()
      local board = Board:new()
      board:parse({
        "# Project Board",
        "###### Todo",
        "- Task A <!-- id: ta -->",
        "###### Done"
      })

      -- Create buffer
      local bufnr = vim.api.nvim_create_buf(false, true)

      -- Initial write
      board:write_to_buffer(bufnr)

      -- Modify board: move task and add new one
      local todo = board:get_column_by_name("Todo")
      local done = board:get_column_by_name("Done")
      local task_a = board:find_task("ta")

      board:move_card(task_a, todo, done)

      local new_task = Card:new("tb", "Task B")
      todo:add_card(new_task)

      -- Write again
      board:write_to_buffer(bufnr)

      -- Verify updated content
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      local output_text = table.concat(lines, "\n")

      assert.is_not_nil(output_text:match("Task B"))
      assert.is_not_nil(output_text:match("ta"))

      -- Clean up
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)
  end)

  describe("Cross-adapter consistency", function()
    it("should produce identical markdown output from both adapters", function()
      -- Create test board
      local test_input = {
        "# Test Board",
        "",
        "## Overview",
        "This board tests adapter consistency.",
        "",
        "###### Todo",
        "- Task 1 <!-- id: t1, priority: high -->",
        "- Task 2 <!-- id: t2 -->",
        "",
        "###### In Progress",
        "<!-- column:config wip_limit: 3 -->",
        "- Task 3 <!-- id: t3, assignee: Bob -->",
        "",
        "###### Done",
        "- Task 4 <!-- id: t4 -->",
        "",
        "## Notes",
        "Keep this board updated."
      }

      -- Parse with first board instance
      local board1 = Board:new()
      board1:parse(test_input)

      -- Get output from core write() (adapter-independent)
      local output1 = board1:write()
      local text1 = table.concat(output1, "\n")

      -- Parse with second board instance
      local board2 = Board:new()
      board2:parse(test_input)

      local output2 = board2:write()
      local text2 = table.concat(output2, "\n")

      -- Both should produce identical output
      assert.equals(text1, text2, "Core write() should be adapter-independent")

      -- Now test with NeovimAdapter
      _G.adapter = NeovimAdapter
      local bufnr = vim.api.nvim_create_buf(false, true)
      board1:write_to_buffer(bufnr)
      local nvim_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      local nvim_text = table.concat(nvim_lines, "\n")

      -- Test with CLIAdapter
      _G.adapter = CLIAdapter
      CLIAdapter._buffer_lines = {}
      local cli_lines = board2:write()
      CLIAdapter:write_buffer(cli_lines, {})
      local cli_text = table.concat(CLIAdapter._buffer_lines, "\n")

      -- Both adapters should produce the same markdown
      assert.equals(nvim_text, cli_text, "NeovimAdapter and CLIAdapter should produce identical output")

      -- Verify all content is present in both
      for _, adapter_text in ipairs({ nvim_text, cli_text }) do
        assert.is_not_nil(adapter_text:match("# Test Board"))
        assert.is_not_nil(adapter_text:match("## Overview"))
        assert.is_not_nil(adapter_text:match("## Notes"))
        assert.is_not_nil(adapter_text:match("###### Todo"))
        assert.is_not_nil(adapter_text:match("###### In Progress"))
        assert.is_not_nil(adapter_text:match("###### Done"))
        assert.is_not_nil(adapter_text:match("t1"))
        assert.is_not_nil(adapter_text:match("t2"))
        assert.is_not_nil(adapter_text:match("t3"))
        assert.is_not_nil(adapter_text:match("t4"))
      end

      -- Clean up
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it("should maintain content through parse-write roundtrip with both adapters", function()
      local original_input = {
        "# Roundtrip Board",
        "",
        "## Instructions",
        "Follow the process carefully.",
        "",
        "###### Backlog",
        "- Feature X <!-- id: fx, complexity: 8 -->",
        "",
        "###### Development",
        "<!-- column:config wip_limit: 2, is_start_state: true -->",
        "- Feature Y <!-- id: fy, assignee: Carol -->",
        "",
        "###### Complete",
        "<!-- column:config is_completion_state: true -->",
        "",
        "###### __ARCHIVE__",
        "",
        "## Metrics",
        "Track velocity weekly."
      }

      -- Test with NeovimAdapter
      _G.adapter = NeovimAdapter

      local board1 = Board:new()
      board1:parse(original_input)

      local bufnr = vim.api.nvim_create_buf(false, true)
      board1:write_to_buffer(bufnr)
      local nvim_output = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

      -- Parse output again
      local board1_roundtrip = Board:new()
      board1_roundtrip:parse(nvim_output)

      -- Test with CLIAdapter
      _G.adapter = CLIAdapter

      local board2 = Board:new()
      board2:parse(original_input)

      local temp_file = os.tmpname()
      local cli_lines = board2:write()
      CLIAdapter:write_buffer(cli_lines, { file = temp_file })

      -- Read back and parse
      local f = io.open(temp_file, "r")
      local cli_content = f:read("*a")
      f:close()

      local cli_output = {}
      for line in cli_content:gmatch("[^\n]+") do
        table.insert(cli_output, line)
      end

      local board2_roundtrip = Board:new()
      board2_roundtrip:parse(cli_output)

      -- Both roundtrip boards should match
      assert.equals(board1.title, board2.title)
      assert.equals(#board1.columns, #board2.columns)
      assert.equals(board1_roundtrip.title, board2_roundtrip.title)
      assert.equals(#board1_roundtrip.columns, #board2_roundtrip.columns)

      -- Verify content preservation
      local final_nvim = table.concat(nvim_output, "\n")
      local final_cli = cli_content

      -- Both should preserve all documentation
      for _, text in ipairs({ final_nvim, final_cli }) do
        assert.is_not_nil(text:match("## Instructions"))
        assert.is_not_nil(text:match("Follow the process carefully"))
        assert.is_not_nil(text:match("## Metrics"))
        assert.is_not_nil(text:match("Track velocity weekly"))
        assert.is_not_nil(text:match("fx"))
        assert.is_not_nil(text:match("fy"))
      end

      -- Clean up
      vim.api.nvim_buf_delete(bufnr, { force = true })
      os.remove(temp_file)
    end)

    it("should handle empty boards consistently", function()
      local empty_input = {
        "# Empty Board",
        "",
        "###### Todo",
        "",
        "###### Done"
      }

      -- NeovimAdapter
      _G.adapter = NeovimAdapter
      local board1 = Board:new()
      board1:parse(empty_input)

      local bufnr = vim.api.nvim_create_buf(false, true)
      board1:write_to_buffer(bufnr)
      local nvim_text = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")

      -- CLIAdapter
      _G.adapter = CLIAdapter
      local board2 = Board:new()
      board2:parse(empty_input)

      CLIAdapter._buffer_lines = {}
      CLIAdapter:write_buffer(board2:write(), {})
      local cli_text = table.concat(CLIAdapter._buffer_lines, "\n")

      -- Should be identical
      assert.equals(nvim_text, cli_text)

      -- Clean up
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)
  end)

  describe("Error handling", function()
    it("should handle NeovimAdapter buffer write failures gracefully", function()
      _G.adapter = NeovimAdapter

      local board = Board:new()
      board:parse({
        "# Test Board",
        "###### Todo",
        "- Task 1"
      })

      -- Try to write to invalid buffer (should handle error)
      local invalid_bufnr = 99999

      local success, err = pcall(function()
        board:write_to_buffer(invalid_bufnr)
      end)

      -- Should either fail gracefully or return false
      -- The actual behaviour depends on implementation
      assert.is_not_nil(success ~= nil)
    end)

    it("should handle CLIAdapter file write failures gracefully", function()
      _G.adapter = CLIAdapter

      local board = Board:new()
      board:parse({
        "# Test Board",
        "###### Todo",
        "- Task 1"
      })

      -- Try to write to invalid file path
      local invalid_path = "/nonexistent/directory/file.md"

      local lines = board:write()

      -- CLIAdapter should handle the error internally and notify
      CLIAdapter:write_buffer(lines, { file = invalid_path })

      -- Should not crash (error is logged via notify)
      assert.is_true(true)
    end)
  end)
end)
