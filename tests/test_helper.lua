-- tests/test_helper.lua
-- Helper to set up package path for engine submodule
-- All test files should require this at the top

-- Determine project root
local current_file = debug.getinfo(1, "S").source:sub(2)
local test_dir = vim.fn.fnamemodify(current_file, ":p:h")
local project_root = vim.fn.fnamemodify(test_dir, ":h")
local lib_path = project_root .. "/lib/kanban-md-engine/lua"

-- Add submodule to package path
package.path = lib_path .. "/?.lua;" .. lib_path .. "/?/init.lua;" .. package.path

-- Return empty table
return {}
