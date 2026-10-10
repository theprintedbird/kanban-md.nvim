-- Check the help file: run :helptags over doc/ (which fails on a duplicate
-- tag) and make sure every |link| resolves to a tag, in doc/ or in Neovim's
-- own help. Exits non-zero on any problem.
--
--   nvim --clean --headless -l scripts/check_doc.lua
--
-- :helptags runs on a copy of doc/ in a temp dir, so no doc/tags file is
-- left in the checkout.

local script_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
local doc_dir = vim.fn.fnamemodify(script_dir, ":h") .. "/doc"

local failures = 0
local function fail(msg)
  io.stderr:write(msg .. "\n")
  failures = failures + 1
end

local files = vim.fn.globpath(doc_dir, "*.txt", false, true)
if #files == 0 then
  io.stderr:write("No help files found in " .. doc_dir .. "\n")
  os.exit(1)
end

local tmp_dir = vim.fn.tempname()
vim.fn.mkdir(tmp_dir, "p")
for _, file in ipairs(files) do
  vim.fn.writefile(vim.fn.readfile(file), tmp_dir .. "/" .. vim.fn.fnamemodify(file, ":t"))
end

local ok, err = pcall(vim.cmd, "helptags " .. vim.fn.fnameescape(tmp_dir))
if not ok then
  fail("helptags: " .. tostring(err))
end

vim.o.tags = tmp_dir .. "/tags," .. vim.env.VIMRUNTIME .. "/doc/tags"

local function has_tag(name)
  return #vim.fn.taglist("\\V\\^" .. vim.fn.escape(name, "\\") .. "\\$") > 0
end

-- Links inside code blocks (from a line ending in ">" or ">lang" until a
-- line starting with "<" or with no indent) are not links.
for _, file in ipairs(files) do
  local in_code = false
  for lnum, line in ipairs(vim.fn.readfile(file)) do
    if in_code and (line:match("^<") or line:match("^%S")) then
      in_code = false
    end
    if not in_code then
      for name in line:gmatch("|([^%s|]+)|") do
        if not has_tag(name) then
          fail(string.format("%s:%d: no tag for |%s|", vim.fn.fnamemodify(file, ":t"), lnum, name))
        end
      end
      if line:match("%s>%w*$") or line:match("^>%w*$") then
        in_code = true
      end
    end
  end
end

vim.fn.delete(tmp_dir, "rf")

if failures > 0 then
  os.exit(1)
end
print(string.format("%d help file(s) OK", #files))
