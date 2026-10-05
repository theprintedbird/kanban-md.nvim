# Kanban-md.nvim


###### Backlog

- Automatically create folds for each column <!-- backlog: 1791178495 -->
- Set up Github workflows/actions for testing <!-- backlog: 1791178518 -->


###### Ready






###### In Progress






###### Done

- Register lib/kanban-md-engine as a real git submodule (currently untracked dir; .gitmodules entry exists but not in index) <!-- backlog: 1791170671, complexity: 1, done: 1791172977, in_progress: 1791172967, ready: 1791172876 -->
- Fix stale lib/kanban-md path in tests/run_tests.lua (lines 7, 23, 24) to lib/kanban-md-engine <!-- backlog: 1791170671, complexity: 1, done: 1791173996 -->
- Sync lazy.lua with README: full command list and submodules = true <!-- backlog: 1791170671, complexity: 1, done: 1791175297, in_progress: 1791174119, ready: 1791174033 -->
- Resolve duplicated kanban-md.* modules between plugin and engine (extras/*_triggers.lua, adapters/cli.lua, adapters/interface.lua, virtual_text.lua); id_triggers.lua has diverged <!-- backlog: 1791170671, complexity: 3, done: 1791176027, in_progress: 1791175837, ready: 1791175765 -->
- Set up a custom filetype, use `.markdown.kanban` so that Markdown parsers load first <!-- backlog: 1791178471, complexity: 2, done: 1791180148, in_progress: 1791179950, ready: 1791178600 -->
- KanbanNewBoard should write a marker for filetype detection purposes <!-- backlog: 1791180260, complexity: 2, done: 1791181657, in_progress: 1791181539, ready: 1791180344 -->
