-- Cursor positioning trigger for newly created cards
-- Marks cards with _cursor_target flag when they enter a column
-- The flag is used by commands to position the cursor after writing to buffer
--
-- The engine does not know about this feature: the plugin registers the
-- trigger itself, through the public trigger API, with register(board).

-- Create cursor target marking trigger
-- When a card enters a column, mark it with _cursor_target = true
-- This flag will be detected by commands after writing to position the cursor
local function create_cursor_target_trigger()
  return function(self, context)
    -- Mark the card for cursor positioning
    local card = context.card or self
    if card and card.properties then
      card.properties._cursor_target = true
    end

    return true
  end
end

-- Register the trigger on every regular column of a board, if
-- enable_cursor_positioning is on (board file config wins over plugin config).
-- Call it after board:parse() or board:auto_register_triggers(). Triggers are
-- keyed by name, so calling it again is harmless.
-- @param board Board
-- @return boolean - whether the trigger was registered
local function register(board)
  if not board:get_config_value('enable_cursor_positioning') then
    return false
  end

  local cursor_fn = create_cursor_target_trigger()
  for _, column in ipairs(board.columns) do
    column:register_on_entry("mark_for_cursor", cursor_fn)
  end

  return true
end

return {
  create_cursor_target_trigger = create_cursor_target_trigger,
  register = register,
}
