-- ftdetect/kanban-md.lua
-- Give kanban boards the compound filetype "markdown.kanban".
-- Positive priority runs these before the built-in md -> markdown mapping;
-- returning nil for ordinary files lets that mapping apply.

local function match(path, bufnr)
  return require("kanban-md.detect").match(path, bufnr)
end

vim.filetype.add({
  pattern = {
    [".*%.md"] = { match, { priority = 10 } },
    [".*%.markdown"] = { match, { priority = 10 } },
  },
})
