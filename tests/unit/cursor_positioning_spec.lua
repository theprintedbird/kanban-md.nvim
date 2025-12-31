-- Test that cursor positioning trigger marks cards correctly
local Board = require('kanban-md.board')
local Card = require('kanban-md.card')
local config = require('kanban-md.config')

describe("Cursor positioning feature #neovim-only", function()
  before_each(function()
    -- Reset to default config
    config.reset()
  end)

  describe("when enable_cursor_positioning is true", function()
    it("should mark card with _cursor_target when added to column", function()
      -- Enable cursor positioning
      config.setup({ enable_cursor_positioning = true })

      -- Create a board and columns
      local board = Board:new()
      local todo_col = board:add_column("todo", "Todo")

      -- Trigger auto-registration (normally called after parsing)
      board:auto_register_triggers()

      -- Create a new card
      local card = Card:new("card-1", "Test task")

      -- Add card to Todo column
      todo_col:add_card(card)

      -- Card should have _cursor_target flag set
      assert.is_true(card.properties._cursor_target, "Card should have _cursor_target flag after being added")
    end)

    it("should mark card when moved between columns", function()
      config.setup({ enable_cursor_positioning = true })

      local board = Board:new()
      local todo_col = board:add_column("todo", "Todo")
      local in_progress_col = board:add_column("in_progress", "In Progress")

      board:auto_register_triggers()

      local card = Card:new("card-2", "Test task")
      todo_col:add_card(card)

      -- Clear the flag (simulating it being cleaned up)
      card.properties._cursor_target = nil

      -- Move to In Progress
      board:move_card(card, todo_col, in_progress_col)

      -- Should have flag set again after moving
      assert.is_true(card.properties._cursor_target, "Card should have _cursor_target flag after being moved")
    end)

    it("should work for all columns", function()
      config.setup({ enable_cursor_positioning = true })

      local board = Board:new()
      local col1 = board:add_column("backlog", "Backlog")
      local col2 = board:add_column("ready", "Ready")
      local col3 = board:add_column("done", "Done")

      board:auto_register_triggers()

      local card1 = Card:new("card-3", "Test task 1")
      local card2 = Card:new("card-4", "Test task 2")
      local card3 = Card:new("card-5", "Test task 3")

      -- Test each column
      col1:add_card(card1)
      assert.is_true(card1.properties._cursor_target, "Card in Backlog should have _cursor_target flag")

      col2:add_card(card2)
      assert.is_true(card2.properties._cursor_target, "Card in Ready should have _cursor_target flag")

      col3:add_card(card3)
      assert.is_true(card3.properties._cursor_target, "Card in Done should have _cursor_target flag")
    end)
  end)

  describe("when enable_cursor_positioning is false", function()
    it("should NOT mark card with _cursor_target when disabled at plugin level", function()
      -- Disable cursor positioning
      config.setup({ enable_cursor_positioning = false })

      local board = Board:new()
      local todo_col = board:add_column("todo", "Todo")
      board:auto_register_triggers()

      local card = Card:new("card-6", "Test task")
      todo_col:add_card(card)

      -- Card should NOT have _cursor_target flag
      assert.is_nil(card.properties._cursor_target, "Card should NOT have _cursor_target flag when disabled")
    end)

    it("should NOT mark card when disabled at board level", function()
      -- Enable at plugin level but disable at board level
      config.setup({ enable_cursor_positioning = true })

      local board = Board:new()
      board.config.enable_cursor_positioning = false  -- Override at board level

      local todo_col = board:add_column("todo", "Todo")
      board:auto_register_triggers()

      local card = Card:new("card-7", "Test task")
      todo_col:add_card(card)

      -- Card should NOT have _cursor_target flag
      assert.is_nil(card.properties._cursor_target, "Card should NOT have _cursor_target flag when board config disables it")
    end)
  end)

  describe("board-level config overrides plugin-level config", function()
    it("should respect board.config.enable_cursor_positioning = true even if plugin default is false", function()
      config.setup({ enable_cursor_positioning = false })

      local board = Board:new()
      board.config.enable_cursor_positioning = true  -- Override at board level

      local todo_col = board:add_column("todo", "Todo")
      board:auto_register_triggers()

      local card = Card:new("card-8", "Test task")
      todo_col:add_card(card)

      -- Card SHOULD have flag because board config overrides plugin config
      assert.is_true(card.properties._cursor_target, "Card should have _cursor_target when board config enables it")
    end)

    it("should respect board.config.enable_cursor_positioning = false even if plugin default is true", function()
      config.setup({ enable_cursor_positioning = true })

      local board = Board:new()
      board.config.enable_cursor_positioning = false  -- Override at board level

      local todo_col = board:add_column("todo", "Todo")
      board:auto_register_triggers()

      local card = Card:new("card-9", "Test task")
      todo_col:add_card(card)

      -- Card should NOT have flag because board config overrides plugin config
      assert.is_nil(card.properties._cursor_target, "Card should NOT have _cursor_target when board config disables it")
    end)
  end)

  describe("_cursor_target should not be written to markdown", function()
    it("should filter out underscore-prefixed properties in writer", function()
      config.setup({ enable_cursor_positioning = true })

      local board = Board:new()
      board.title = "Test Board"
      local todo_col = board:add_column("todo", "Todo")
      board:auto_register_triggers()

      local card = Card:new("card-10", "Test task")
      todo_col:add_card(card)

      -- Verify flag is set
      assert.is_true(card.properties._cursor_target)

      -- Write board to markdown
      local lines = board:write()
      local markdown = table.concat(lines, "\n")

      -- Markdown should NOT contain _cursor_target
      assert.is_nil(markdown:find("_cursor_target"), "Markdown should not contain _cursor_target property")

      -- But should contain the card text
      assert.is_not_nil(markdown:find("Test task"), "Markdown should contain the card text")
    end)
  end)

  describe("cursor positioning should work after write-parse cycle", function()
    it("should find card by text and column name after re-parsing", function()
      config.setup({ enable_cursor_positioning = true })

      local board = Board:new()
      board.title = "Test Board"
      local todo_col = board:add_column("todo", "Todo")
      board:auto_register_triggers()

      local card = Card:new("card-11", "Unique Test Card")
      todo_col:add_card(card)

      -- Verify flag is set before writing
      assert.is_true(card.properties._cursor_target)

      -- Write to markdown
      local lines = board:write()

      -- Re-parse (simulating what happens in the command)
      local new_board = Board:new()
      new_board:parse(lines)

      -- The flag should NOT exist in the re-parsed board
      local found_flag = false
      for _, col in ipairs(new_board.columns) do
        for _, c in ipairs(col.cards) do
          if c.properties._cursor_target then
            found_flag = true
          end
        end
      end
      assert.is_false(found_flag, "Re-parsed board should not have _cursor_target flag")

      -- But we should be able to find the card by text and column
      local found_card = false
      for _, col in ipairs(new_board.columns) do
        if col.name == "Todo" then
          for _, c in ipairs(col.cards) do
            if c.text == "Unique Test Card" then
              found_card = true
              assert.is_not_nil(c.line_number, "Card should have line number after parsing")
            end
          end
        end
      end
      assert.is_true(found_card, "Should find card by text and column name")
    end)
  end)
end)
