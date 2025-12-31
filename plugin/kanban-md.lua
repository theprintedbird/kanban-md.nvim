-- plugin/kanban-md.lua
-- Auto-register Neovim commands when plugin loads
-- This makes commands like :KanbanNewBoard available immediately

-- Only register commands if not already done
if vim.g.kanban_md_commands_loaded then
  return
end

-- Register the commands
require('kanban-md.commands').setup()

-- Mark as loaded to prevent duplicate registration
vim.g.kanban_md_commands_loaded = true