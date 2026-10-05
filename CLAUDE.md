# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

kanban-md.nvim is only the **Neovim layer** of the kanban-md project: user commands, keymaps, buffer/cursor I/O, virtual text, and the Neovim adapter. All parsing, writing, the Board/Column/Card model, triggers, stats, config and validation live in the **kanban-md-engine** git submodule at `lib/kanban-md-engine` (it has its own `CLAUDE.md`, `Makefile` and busted tests). The markdown syntax spec lives in the separate `kanban-md` repo. Engine bugs should be fixed in the engine repo, not patched here.

The repo is colocated with jj (`.jj/` exists alongside `.git/`).

## Task tracking

Work items live in `TODO.kanban.md`, a kanban-md board. Change it through the engine (the `kanban-md` skill or `kanban-board` agent), not by hand-editing. Each card gets a `complexity` property: `1` least complex (small, mechanical, one place), `2` moderate, `3` most complex (cross-cutting, needs design decisions or touches the engine).
When starting work on a card, open a new `jj` change for it, and move the card to In Progress. When done, move it to Done. When handing off to an agent, choose an appropriate model based on the complexity. For work that can be done in parallel, use jj workspaces in the `.workspaces/` directory. Deal with conflicts in the kanban board upon merge/rebase, do not use possible conflicts in the board as a reason not to work concurrently.

## Commands

```sh
git submodule update --init      # engine must be present for anything to load
./tests/run_tests.sh             # all plugin specs; exits non-zero if any fail
nvim --headless -c "PlenaryTestFile tests/integration/virtual_text_spec.lua" -c "quit"   # single spec
```

There is no build step. Lint with `luacheck lua plugin ftdetect tests lazy.lua` (config in `.luacheckrc`; CI runs the same command).

`tests/run_tests.sh` is POSIX `sh`, so it runs on macOS and Linux. On first run it clones plenary.nvim into `${XDG_CACHE_HOME:-$HOME/.cache}/kanban-md/plenary.nvim`. Set `PLENARY_REF` to pin plenary to a tag or commit. The script exports that path as `KANBAN_PLENARY_PATH` and `tests/run_tests.lua` reads it, so it's defined only once. `run_tests.lua` must be started through the shell script.

`tests/run_tests.lua` runs **only** spec files, at any depth under `tests/`, that contain the tag `#neovim-only` (each in its own headless nvim process). A new spec without that tag in its `describe(...)` string is silently skipped. If no tagged specs are found, the runner fails. Each spec starts with `require('tests.test_helper')` to put the engine on `package.path`.

## Architecture

### Shared `kanban-md.*` Lua namespace

The plugin (`lua/kanban-md/`) and the engine (`lib/kanban-md-engine/lua/kanban-md/`) use the **same module namespace**. `require('kanban-md.board')` resolves to the engine; `require('kanban-md.commands')` resolves to the plugin. The engine is made reachable by prepending `lib/kanban-md-engine/lua` to `package.path`, a step repeated in `plugin/kanban-md.lua`, `lua/kanban-md/init.lua`, `tests/test_helper.lua` and `tests/run_tests.lua`. If the submodule path changes, update all four.

No module may exist in both trees. Neovim's runtimepath loader runs before the `package.path` searcher, so a plugin copy would silently shadow the engine's. `virtual_text.lua`, `adapters/interface.lua`, `adapters/cli.lua` and the stock `extras/*_triggers.lua` live only in the engine. The plugin owns only `commands.lua`, `detect.lua`, `init.lua`, `adapters/neovim.lua` and `extras/cursor_triggers.lua`.

### Load / setup flow

1. `plugin/kanban-md.lua` runs on startup. It adds the engine to `package.path` and calls `commands.setup()` to register the `:Kanban*` user commands, guarded by `vim.g.kanban_md_commands_loaded`.
2. `require('kanban-md').setup(opts)` (`lua/kanban-md/init.lua`) passes the Neovim adapter to the engine's `core.setup`, which applies config and registers the adapter, then calls `commands.setup()` again.

### Adapter pattern

The engine never calls `vim.*` directly. It goes through an adapter fetched from the engine's `kanban-md.adapter_registry` (`get_adapter()` / `set_adapter()`). `lua/kanban-md/adapters/neovim.lua` returns an **already-instantiated** adapter, so don't call `.new()` on it. The contract (required: `notify`, `read_buffer`, `write_buffer`, `get_cursor`, `set_cursor`, `prompt_input`, `prompt_select`; optional: the virtual-text/extmark methods) is in the engine's `adapters/interface.lua` and `adapters/README.md`. Tests swap in a mock with `adapter_registry.set_adapter(...)` **before** requiring modules like `virtual_text`.

### Command model (`lua/kanban-md/commands.lua`)

Each command reads the whole buffer through the adapter, parses it into a fresh engine `Board`, mutates the board, and writes the whole buffer back only on success. On error nothing is written, and Neovim's undo is the rollback mechanism. Engine trigger and validation errors are raised as Lua errors and reduced to user-facing text by `extract_error_message()`. If you change the engine's error formats, keep its patterns in sync. `:KanbanAddDependency` keeps two-step state (`dependency_state`) between invocations.

### Board detection

Boards get the compound filetype `markdown.kanban`, set by `ftdetect/kanban-md.lua` through `lua/kanban-md/detect.lua`. Virtual text autocmds key off that filetype. `*.kanban.md` files always qualify, `:KanbanNewBoard` sets it (with the `vim.b.kanban_md_board` flag so a save doesn't drop it), and other markdown files go by `detection_strategy` (`"marker"` default: `<!-- kanban-board -->` in the first 10 lines; `"extension"`: `*.kanban.md` only; `"both"`; `"auto"`: legacy, any H6 header). Detection runs again on `BufWritePost`.
