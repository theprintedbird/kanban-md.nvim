-- Lazy.nvim plugin specification for kanban-md
-- A Neovim plugin for managing Kanban boards in Markdown files

return {
  "theprintedbird/kanban-md.nvim",
  lazy = true,
  ft = { "markdown", "markdown.kanban" },
  submodules = true, -- lazy.nvim will fetch lib/kanban-md-engine for you
  config = function()
    require('kanban-md').setup()
  end,
  cmd = {
    "KanbanNewBoard", "KanbanNewCard", "KanbanNewColumn",
    "KanbanMoveCard", "KanbanCompleteCard", "KanbanForceCompleteCard",
    "KanbanSetComplexity", "KanbanArchive", "KanbanStats",
    "KanbanAddDependency", "KanbanPersistIds", "KanbanVersion",
  },
}
