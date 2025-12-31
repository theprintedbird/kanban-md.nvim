-- Lazy.nvim plugin specification for kanban-md
-- A Neovim plugin for managing Kanban boards in Markdown files

return {
  "theprintedbird/kanban-md.nvim",
	lazy = true,
  ft = "markdown",
  config = function()
    require('kanban-md').setup()
  end,
  cmd = {
    "KanbanNewBoard",
    "KanbanNewCard",
    "KanbanMoveCard",
    "KanbanCompleteCard",
    "KanbanArchive",
    "KanbanStats",
    "KanbanSetComplexity",
  },
}
