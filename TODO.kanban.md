# Kanban-md.nvim


###### Backlog

- Resolve duplicated kanban-md.* modules between plugin and engine (extras/*_triggers.lua, adapters/cli.lua, adapters/interface.lua, virtual_text.lua); id_triggers.lua has diverged <!-- backlog: 1791170671, complexity: 3 -->
- Sync lazy.lua with README: full command list and submodules = true <!-- backlog: 1791170671, complexity: 1 -->

###### Ready


###### In Progress


###### Done

- Register lib/kanban-md-engine as a real git submodule (currently untracked dir; .gitmodules entry exists but not in index) <!-- backlog: 1791170671, complexity: 1, done: 1791172977, in_progress: 1791172967, ready: 1791172876 -->
- Fix stale lib/kanban-md path in tests/run_tests.lua (lines 7, 23, 24) to lib/kanban-md-engine <!-- backlog: 1791170671, complexity: 1, done: 1791173996 -->
