-- plugin/kanban-md.lua
-- Auto-register Neovim commands when plugin loads
-- This makes commands like :KanbanNewBoard available immediately

-- Only register commands if not already done
if vim.g.kanban_md_commands_loaded then
  return
end

-- Add submodule to package path BEFORE requiring any engine modules
-- Determine plugin root by finding the directory containing this file
local current_file = debug.getinfo(1, "S").source:sub(2)
local plugin_root = vim.fn.fnamemodify(current_file, ":p:h:h")
local lib_path = plugin_root .. '/lib/kanban-md-engine/lua'
package.path = lib_path .. '/?.lua;' .. lib_path .. '/?/init.lua;' .. package.path

-- Register the commands
require('kanban-md.commands').setup()

-- Mark as loaded to prevent duplicate registration
vim.g.kanban_md_commands_loaded = true