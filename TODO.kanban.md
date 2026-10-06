# Kanban-md.nvim
<!-- kanban:config persist_card_ids: true -->


###### Backlog

- CI 11: handle fork PRs: they do not receive ENGINE_DEPLOY_KEY, so the test job fails at webfactory/ssh-agent; either skip the submodule and test steps with a clear notice when the secret is empty (job env HAS_KEY from secrets.ENGINE_DEPLOY_KEY != empty string, steps gated on it) or state in README/CONTRIBUTING that fork PRs are not accepted; do NOT switch to pull_request_target, which would expose the key to untrusted code <!-- backlog: 1791196924, complexity: 1, id: card_01M463W7NF3P338WCKC9VTDED1 -->
- CI 13 (optional): StyLua format check: add stylua.toml matching the engine (or agree a config if the engine has none), one-off format commit over lua plugin ftdetect tests lazy.lua, then a stylua --check step (JohnnyMorganz/stylua-action, SHA-pinned) in the lint job; mention the command in CLAUDE.md <!-- backlog: 1791196932, complexity: 1, id: card_01M463W8FEZTVFA56QX9AYPQ62 -->
- CI 14 (optional): vimdoc and help check: there is no doc/ directory, so :help kanban-md does not exist; write doc/kanban-md.txt (by hand or generated from README with panvimdoc), then add a CI step running nvim --headless -c "helptags doc" -c q that fails on duplicate or bad tags; if panvimdoc is used, also regenerate and fail when it differs from the committed file <!-- backlog: 1791196936, complexity: 2, id: card_01M463W8GGZDDD2GJAK4D5RET3 -->
- CI 16 (optional, low priority): typos/codespell check and a markdown link check on README.md and SPEC links; once versions are tagged, consider release automation (release-please, a luarocks rockspec and upload, CHANGELOG) <!-- backlog: 1791196944, complexity: 1, id: card_01M463W7TAVKYSJWT0Y8D3SV1V -->
- Make the "new card" text box centred in the screen, and larger. <!-- backlog: 1791250669, id: card_01M47DR8ARJX5MFFMGD1TK9XGP -->
- Moving several cards at once between columns <!-- backlog: 1791250713, id: card_01M47DSJT99H34N2A35KEVVXSF -->
- Remove the extra keypress needed when adding a dependency <!-- backlog: 1791250744, id: card_01M47DTGW3QV7D2V77A8HMHMYZ -->
- Update README, it's out of date, especially the section on the different projects. <!-- backlog: 1791303103, id: card_01M48ZRD12231KAR28XP9HPY8Y -->
- CI 17 (future): widen macOS coverage and containerise local testing: macos-latest already runs nvim stable, so add the v0.9.5 minimum and nightly legs on macOS too (drop the ubuntu-only include entries in .github/workflows/test.yml, nightly stays continue-on-error); for local runs add a container setup (Dockerfile or Containerfile plus a script such as tests/run_in_container.sh, working with docker or podman) that builds Linux images with a chosen nvim version (stable, 0.9.5, nightly), mounts the checkout including lib/kanban-md-engine read-only, caches plenary pinned via PLENARY_REF, and runs ./tests/run_tests.sh; document it in README and CLAUDE.md; containers only cover Linux, so macOS results still come from CI; this also gives the isolation the test-runner-loads-user-config card asks for; still, always use --clean <!-- backlog: 1791303894, complexity: 2, id: card_01M490GHBS4WFKAA7VBJY8V3PV -->



###### Ready






###### In Progress







###### Done

- Register lib/kanban-md-engine as a real git submodule (currently untracked dir; .gitmodules entry exists but not in index) <!-- backlog: 1791170671, complexity: 1, done: 1791172977, id: card_01M463W88HSZMFDCP04DBHVNNN, in_progress: 1791172967, ready: 1791172876 -->
- Fix stale lib/kanban-md path in tests/run_tests.lua (lines 7, 23, 24) to lib/kanban-md-engine <!-- backlog: 1791170671, complexity: 1, done: 1791173996, id: card_01M463W8DSCMAAZ4JYQWJWAHQW -->
- Sync lazy.lua with README: full command list and submodules = true <!-- backlog: 1791170671, complexity: 1, done: 1791175297, id: card_01M463W7RFK01ZVR5SX1Y6RFF7, in_progress: 1791174119, ready: 1791174033 -->
- Resolve duplicated kanban-md.* modules between plugin and engine (extras/*_triggers.lua, adapters/cli.lua, adapters/interface.lua, virtual_text.lua); id_triggers.lua has diverged <!-- backlog: 1791170671, complexity: 3, done: 1791176027, id: card_01M463W7V3FFMSTZ4W97WQF8HJ, in_progress: 1791175837, ready: 1791175765 -->
- Set up a custom filetype, use `.markdown.kanban` so that Markdown parsers load first <!-- backlog: 1791178471, complexity: 2, done: 1791180148, id: card_01M463W7KNVWK5HTBRKZZ689CF, in_progress: 1791179950, ready: 1791178600 -->
- KanbanNewBoard should write a marker for filetype detection purposes <!-- backlog: 1791180260, complexity: 2, done: 1791181657, id: card_01M463W85RXTXREDV2A5K4RH4Q, in_progress: 1791181539, ready: 1791180344 -->
- CI 1: make tests/run_tests.lua and run_tests.sh exit non-zero when specs fail (and when zero specs are found) <!-- complexity: 1, done: 1791188684, id: card_01M463W87QB0A7FN14C3EAA4WA, in_progress: 1791188547, ready: 1791188164 -->
- CI 2: make the test runner portable to Linux: POSIX sh instead of zsh, one cache default XDG_CACHE_HOME or HOME/.cache shared via KANBAN_PLENARY_PATH, globpath-based spec discovery, optional PLENARY_REF pin, update CLAUDE.md <!-- complexity: 1, done: 1791188685, id: card_01M463W858G732Z6Z4PJ36QQZF, in_progress: 1791188548, ready: 1791188169 -->
- Neovim adapter write_buffer called undefined global get_current_buffer() when opts.bufnr was omitted (found by luacheck; fixed with CI 5) <!-- backlog: 1791188865, complexity: 1, done: 1791188868, id: card_01M463W8333E4YA30Y51S9MCSD -->
- CI 5: add .luacheckrc (modelled on the engine's) and a luacheck lint job; fix or justify warnings <!-- complexity: 2, done: 1791188890, id: card_01M463W8FMFVM6GXBKJM8RBK9F, in_progress: 1791188807, ready: 1791188178 -->
- CI 6: copy the engine's .actrc for local act runs, add a CI badge and CI/deploy-key notes to README <!-- complexity: 1, done: 1791188922, id: card_01M463W83Q1HFNHQWFMQ90CAH9, in_progress: 1791188895, ready: 1791188181 -->
- CI 4 (manual): create a read-only deploy key on kanban-md-engine and store its private half as the ENGINE_DEPLOY_KEY Actions secret on kanban-md.nvim <!-- complexity: 1, done: 1791190952, id: card_01M463W7TKCHCBDFB00AVN2ZV7, ready: 1791188175 -->
- CI 3: add .github/workflows/test.yml (push master, PRs, dispatch; contents read; PR concurrency cancel; ubuntu+macos, nvim stable via rhysd/action-setup-vim; submodule via webfactory/ssh-agent plus ENGINE_DEPLOY_KEY); needs CI 1, 2, 4 <!-- complexity: 2, done: 1791190970, id: card_01M463W8FDNN0G47D7RFW721NW, in_progress: 1791188790, ready: 1791188172 -->
- Set up Github workflows/actions for testing <!-- backlog: 1791178518, done: 1791190980, id: card_01M463W8D82AHKYKCFVGHB2S4A, in_progress: 1791188155, ready: 1791187545 -->
- Register the cursor positioning trigger (extras/cursor_triggers.lua) from the plugin; engine commit da82ced stopped wiring it, so tests/unit/cursor_positioning_spec.lua fails 6/9 <!-- backlog: 1791183130, complexity: 2, done: 1791191195, id: card_01M463W7QD8FXCJ53K02218WAD, in_progress: 1791191135, ready: 1791191002 -->
- tests/run_tests.sh passes the runner path to luafile unescaped, so a checkout path containing spaces breaks the test run <!-- backlog: 1791188866, complexity: 1, done: 1791191312, id: card_01M463W82CHV9AF4ZXEN2VQ7AJ, in_progress: 1791191200, ready: 1791191020 -->
- Automatically create folds for each column <!-- backlog: 1791178495, complexity: 2, done: 1791191900, id: card_01M463W7Q8GKAA7Q78050Z4AW4, in_progress: 1791191764, ready: 1791191714 -->
- CI 7: harden test.yml checkouts and action refs: pin every uses: to a full commit SHA with a "# vX.Y.Z" comment (actions/checkout, leafo/gh-actions-lua, leafo/gh-actions-luarocks, rhysd/action-setup-vim, webfactory/ssh-agent - ssh-agent matters most because it receives ENGINE_DEPLOY_KEY); add persist-credentials: false to both checkouts so GITHUB_TOKEN is not left in .git/config (the submodule fetch uses the SSH agent, so it is unaffected); verify with act using .actrc <!-- backlog: 1791196907, complexity: 1, done: 1791207404, id: card_01M463W89GYGCNB2JDZNAH7MQW, in_progress: 1791207140, ready: 1791207022 -->
- CI 8: add workflow linting: a .github/workflows/lint-workflows.yml (or a job beside Luacheck) running zizmor (zizmorcore/zizmor-action or pipx run zizmor .github/workflows; optionally upload SARIF to code scanning with security-events: write scoped to that job only) and actionlint (expression/type errors, shellcheck on run: blocks); trigger on changes to .github/**; needs CI 7 first or zizmor reports unpinned-uses and artipacked immediately; document the local commands in README and CLAUDE.md <!-- backlog: 1791196912, complexity: 1, depends_on: [card_01M463W89GYGCNB2JDZNAH7MQW], done: 1791207577, id: card_01M463W7X4S7JJ8DTRSY6KSHKA, in_progress: 1791207410, ready: 1791207025 -->
- CI 9: add .github/dependabot.yml: github-actions ecosystem, weekly, grouped into one PR, so the SHA pins from CI 7 do not go stale; optionally the gitsubmodule ecosystem for lib/kanban-md-engine so engine bumps arrive as tested PRs (check Dependabot can reach the private SSH submodule - may need a Dependabot secret or an HTTPS URL); needs CI 7 <!-- backlog: 1791196916, complexity: 1, depends_on: [card_01M463W89GYGCNB2JDZNAH7MQW], done: 1791207632, id: card_01M463W7NHDNT2GCTF2TBHHC5A, in_progress: 1791207583, ready: 1791207028 -->
- CI 15 (engine repo - do the work there, not here): apply the same hardening to lib/kanban-md-engine/.github/workflows/ci.yml: top-level permissions: contents: read, timeout-minutes per job, a concurrency group cancelling superseded PR runs, plus the CI 7-9 changes (SHA pins, persist-credentials: false, zizmor + actionlint, dependabot.yml); note actions/upload-artifact@v4 lags the other actions; zizmor --persona pedantic currently reports 7 unpinned-uses, 2 artipacked, 3 excessive-permissions, concurrency-limits, and a template-injection from ${{ matrix.lua }} in the busted run: block (pass it through env: instead); verify with zizmor .github and actionlint, then bump the submodule here <!-- backlog: 1791196940, complexity: 3, done: 1791304755, id: card_01M463W7QTYJRCEKNJEM4QG892 -->
- CI 10: Neovim version matrix: add an nvim axis to the test job with stable, nightly (continue-on-error so upstream breakage shows without blocking) and a minimum supported version; first decide and document that minimum in README (vim.fs, vim.filetype.add and extmark APIs set the floor); keep ubuntu+macos, or run nightly on ubuntu only to save minutes; include the nvim version in the job name <!-- backlog: 1791196920, complexity: 2, done: 1791303583, id: card_01M463W7WXTXP4XHE4GJN5Y7XH, in_progress: 1791303530, ready: 1791250367 -->
- Test runner loads the developer's own Neovim config: tests/run_tests.sh and the per-spec nvim processes started by tests/run_tests.lua don't pass --clean or -u NONE, so a local init.lua (or NVIM_APPNAME) runs during tests and can fail specs that pass in CI (seen: 0.9.5 runs failing filetype_spec and fold_spec with E474 because of a user config); start every nvim with --clean (or -u NONE), point XDG_CONFIG_HOME, XDG_DATA_HOME and XDG_STATE_HOME at a temp dir and unset NVIM_APPNAME, then check plenary still loads and all specs pass <!-- backlog: 1791303687, complexity: 1, done: 1791304369, id: card_01M490A7SQ3ZMC3XR6562J1P75, in_progress: 1791304241, ready: 1791304197 -->
- CI 12: pin the luacheck version in the lint job (luarocks install luacheck <ver>) so a new upstream release cannot turn lint red with no code change; take the version from the engine rockspec test_dependencies so both repos agree <!-- backlog: 1791196928, complexity: 1, done: 1791444020, id: card_01M463W8D4K484ZGNCEES8DSKJ, in_progress: 1791444006, ready: 1791305177 -->
