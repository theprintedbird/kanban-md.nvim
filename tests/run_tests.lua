-- tests/run_tests.lua
-- Test runner for Kanban plugin tests
--
-- Run through tests/run_tests.sh, which sets KANBAN_PLENARY_PATH. Each spec
-- runs in its own headless Neovim process. The runner quits with `cquit 1`
-- if any spec fails or none are found, so the shell sees a non-zero status.

-- Add the project root and submodule to Lua path so modules can be required
local current_file = debug.getinfo(1, "S").source:sub(2)
local project_root = vim.fn.fnamemodify(current_file, ":p:h:h")
local lib_path = project_root .. "/lib/kanban-md-engine/lua"
package.path = lib_path .. "/?.lua;" .. lib_path .. "/?/init.lua;" .. package.path .. ";" .. project_root .. "/?.lua"

local function finish(ok)
  vim.cmd(ok and "qall!" or "cquit 1")
end

-- Require plenary test harness with error checking
local plenary_success, plenary = pcall(require, "plenary.test_harness")
if not plenary_success then
  print("ERROR: Could not load plenary.test_harness: " .. tostring(plenary))
  return finish(false)
end

local plenary_path = os.getenv("KANBAN_PLENARY_PATH")
if not plenary_path or plenary_path == "" then
  print("ERROR: KANBAN_PLENARY_PATH is not set; run the tests through tests/run_tests.sh")
  return finish(false)
end

-- Helper function to run a single test file in a separate Neovim process
local function run_test_file(test_file)
  local test_name = vim.fn.fnamemodify(test_file, ":t")
  local lib_root = project_root .. "/lib/kanban-md-engine"

  -- The child gets plenary, the plugin and the engine on its runtimepath and
  -- the engine on package.path. %q yields Lua string literals, so paths need
  -- no further escaping inside the Lua chunks.
  local setup = string.format(
    "lua vim.opt.rtp:append(%q); vim.opt.rtp:append(%q); vim.opt.rtp:append(%q);"
      .. " package.path = %q .. package.path",
    plenary_path,
    project_root,
    lib_root,
    lib_path .. "/?.lua;" .. lib_path .. "/?/init.lua;"
  )
  local run = string.format("lua require('plenary.test_harness').test_file(%q)", test_file)
  -- --clean keeps the developer's init.lua and plugins out of the spec;
  -- run_tests.sh has already pointed the XDG dirs at a temp directory.
  local cmd = table.concat({
    "nvim --headless --clean",
    "--cmd", vim.fn.shellescape(setup),
    "-c", vim.fn.shellescape(run),
    "-c quit",
  }, " ")

  -- Execute the command and let output stream directly to terminal
  print("Running: " .. test_name)
  local exit_code = os.execute(cmd)

  -- os.execute returns 0 for success on Unix systems
  local success = exit_code == 0

  return {
    name = test_name,
    exit_code = exit_code,
    success = success
  }
end

-- Find spec files tagged with #neovim-only, at any depth under dir_path.
-- All other tests run via busted in standalone Lua in the engine repo.
local function find_neovim_test_files(dir_path)
  local files = {}
  for _, file in ipairs(vim.fn.globpath(dir_path, "**/*_spec.lua", false, true)) do
    local f = io.open(file, "r")
    if f then
      local content = f:read("*a")
      f:close()
      if content:find("#neovim-only", 1, true) then
        table.insert(files, file)
      end
    end
  end
  table.sort(files)
  return files
end

local test_files = find_neovim_test_files(project_root .. "/tests")

-- A broken discovery step must not pass vacuously.
if #test_files == 0 then
  print("ERROR: no spec files tagged #neovim-only found under " .. project_root .. "/tests")
  return finish(false)
end

local results = {}
local total_tests = #test_files
local passed_tests = 0

for i, test_file in ipairs(test_files) do
  print("\n=== Running " .. vim.fn.fnamemodify(test_file, ":t") .. " (" .. i .. "/" .. total_tests .. ") ===\n")

  local result = run_test_file(test_file)
  table.insert(results, result)

  if result.success then
    print("✓ " .. result.name .. " passed")
    passed_tests = passed_tests + 1
  else
    print("✗ " .. result.name .. " failed (exit code: " .. tostring(result.exit_code) .. ")")
  end

  print("Finished processing test file " .. i .. "/" .. total_tests)
end

-- Print summary
print("\n" .. string.rep("=", 50))
print("TEST SUMMARY")
print(string.rep("=", 50))
print(string.format("Total tests: %d", total_tests))
print(string.format("Passed: %d", passed_tests))
print(string.format("Failed: %d", total_tests - passed_tests))

for _, result in ipairs(results) do
  local status = result.success and "✓" or "✗"
  print(string.format("%s %s", status, result.name))
end

if passed_tests == total_tests then
  print("\n🎉 All tests passed!")
else
  print(string.format("\n❌ %d test(s) failed", total_tests - passed_tests))
end

finish(passed_tests == total_tests)
