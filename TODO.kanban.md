# Kanban-md.nvim


###### Backlog

- Automatically create folds for each column <!-- backlog: 1791178495 -->


###### Ready

- tests/run_tests.sh passes the runner path to luafile unescaped, so a checkout path containing spaces breaks the test run <!-- backlog: 1791188866, complexity: 1, ready: 1791191020 -->








###### In Progress








###### Done

- Register lib/kanban-md-engine as a real git submodule (currently untracked dir; .gitmodules entry exists but not in index) <!-- backlog: 1791170671, complexity: 1, done: 1791172977, in_progress: 1791172967, ready: 1791172876 -->
- Fix stale lib/kanban-md path in tests/run_tests.lua (lines 7, 23, 24) to lib/kanban-md-engine <!-- backlog: 1791170671, complexity: 1, done: 1791173996 -->
- Sync lazy.lua with README: full command list and submodules = true <!-- backlog: 1791170671, complexity: 1, done: 1791175297, in_progress: 1791174119, ready: 1791174033 -->
- Resolve duplicated kanban-md.* modules between plugin and engine (extras/*_triggers.lua, adapters/cli.lua, adapters/interface.lua, virtual_text.lua); id_triggers.lua has diverged <!-- backlog: 1791170671, complexity: 3, done: 1791176027, in_progress: 1791175837, ready: 1791175765 -->
- Set up a custom filetype, use `.markdown.kanban` so that Markdown parsers load first <!-- backlog: 1791178471, complexity: 2, done: 1791180148, in_progress: 1791179950, ready: 1791178600 -->
- KanbanNewBoard should write a marker for filetype detection purposes <!-- backlog: 1791180260, complexity: 2, done: 1791181657, in_progress: 1791181539, ready: 1791180344 -->
- CI 1: make tests/run_tests.lua and run_tests.sh exit non-zero when specs fail (and when zero specs are found) <!-- complexity: 1, done: 1791188684, in_progress: 1791188547, ready: 1791188164 -->
- CI 2: make the test runner portable to Linux: POSIX sh instead of zsh, one cache default XDG_CACHE_HOME or HOME/.cache shared via KANBAN_PLENARY_PATH, globpath-based spec discovery, optional PLENARY_REF pin, update CLAUDE.md <!-- complexity: 1, done: 1791188685, in_progress: 1791188548, ready: 1791188169 -->
- Neovim adapter write_buffer called undefined global get_current_buffer() when opts.bufnr was omitted (found by luacheck; fixed with CI 5) <!-- backlog: 1791188865, complexity: 1, done: 1791188868 -->
- CI 5: add .luacheckrc (modelled on the engine's) and a luacheck lint job; fix or justify warnings <!-- complexity: 2, done: 1791188890, in_progress: 1791188807, ready: 1791188178 -->
- CI 6: copy the engine's .actrc for local act runs, add a CI badge and CI/deploy-key notes to README <!-- complexity: 1, done: 1791188922, in_progress: 1791188895, ready: 1791188181 -->
- CI 4 (manual): create a read-only deploy key on kanban-md-engine and store its private half as the ENGINE_DEPLOY_KEY Actions secret on kanban-md.nvim <!-- complexity: 1, done: 1791190952, ready: 1791188175 -->
- CI 3: add .github/workflows/test.yml (push master, PRs, dispatch; contents read; PR concurrency cancel; ubuntu+macos, nvim stable via rhysd/action-setup-vim; submodule via webfactory/ssh-agent plus ENGINE_DEPLOY_KEY); needs CI 1, 2, 4 <!-- complexity: 2, done: 1791190970, in_progress: 1791188790, ready: 1791188172 -->
- Set up Github workflows/actions for testing <!-- backlog: 1791178518, done: 1791190980, in_progress: 1791188155, ready: 1791187545 -->
- Register the cursor positioning trigger (extras/cursor_triggers.lua) from the plugin; engine commit da82ced stopped wiring it, so tests/unit/cursor_positioning_spec.lua fails 6/9 <!-- backlog: 1791183130, complexity: 2, done: 1791191195, in_progress: 1791191135, ready: 1791191002 -->
