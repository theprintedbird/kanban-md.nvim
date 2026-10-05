# kanban-md.nvim

[![Tests](https://github.com/theprintedbird/kanban-md.nvim/actions/workflows/test.yml/badge.svg)](https://github.com/theprintedbird/kanban-md.nvim/actions/workflows/test.yml)

Kanban boards in Markdown files, for Neovim.

kanban-md.nvim is the **Neovim plugin layer** of the kanban-md project. It provides the commands, keymaps, buffer I/O, and virtual text display that let you manage a kanban board directly from a Neovim buffer. It does not itself parse or manipulate the markdown — that logic lives in a separate engine that this plugin depends on.

## The kanban-md project

kanban-md used to be a single repository. It has since been split into three:

- **[kanban-md](https://github.com/theprintedbird/kanban-md)** – defines the markdown syntax/spec for kanban boards (columns, cards, properties, archive, configuration comments).
- **[kanban-md-engine](https://github.com/theprintedbird/kanban-md-engine)** – the platform-agnostic Lua engine: parsing, writing, board/column/card model, triggers, stats, validation, dependency/subtask handling. Included here as a git submodule (`lib/kanban-md-engine`).
- **[kanban-md.nvim](https://github.com/theprintedbird/kanban-md.nvim)** (this repo) – the Neovim integration: user commands, keymaps, buffer/cursor handling, virtual text (WIP warnings, cycle time), and the adapter that lets the engine talk to Neovim.

If you're looking for details on the markdown syntax itself, or how the parser/board/trigger model works, see the `kanban-md` and `kanban-md-engine` repositories. This README only covers what lives in kanban-md.nvim.

## Architecture

This plugin uses an **adapter pattern** to keep the engine platform-agnostic:

```
┌─────────────────────────────────────────┐
│   kanban-md.nvim (this repo)             │  Commands, keymaps, virtual text
│   lua/kanban-md/commands.lua              │
│   lua/kanban-md/adapters/neovim.lua       │
├─────────────────────────────────────────┤
│   Adapter Interface (Strategy Pattern)    │  engine: kanban-md.adapters.interface
│   - notify() / read_buffer() / write_buffer()
│   - prompt_input() / prompt_select()
│   - cursor & extmark operations
├─────────────────────────────────────────┤
│   kanban-md-engine (git submodule)        │  lib/kanban-md-engine
│   Board / Column / Card, parser, writer,  │
│   triggers, stats, config, validation     │
└─────────────────────────────────────────┘
```

The engine is buffer-agnostic: every command re-parses the current buffer into a `Board` object, mutates it, and writes it back on success. On error, nothing is written and Neovim's native undo (`u`) handles the rest — see the engine repo for details on that model.

This repo ships one adapter, **`lua/kanban-md/adapters/neovim.lua`**, backed by `vim.*` APIs. The adapter contract (`adapters/interface.lua`), a plain stdin/stdout adapter (`adapters/cli.lua`), the virtual-text renderer (`virtual_text.lua`) and the stock triggers (`extras/*_triggers.lua`) all live in the engine. Only `extras/cursor_triggers.lua` is plugin-specific.

See `lib/kanban-md-engine/lua/kanban-md/adapters/README.md` for the full adapter interface and how to implement your own.

## Installation

kanban-md.nvim depends on `kanban-md-engine`, included as a git submodule at `lib/kanban-md-engine`. Make sure submodules are fetched, however you install the plugin.

### lazy.nvim
```lua
{
  "theprintedbird/kanban-md.nvim",
  lazy = true,
  ft = { "markdown", "markdown.kanban" },
  submodules = true, -- lazy.nvim will fetch lib/kanban-md-engine for you
  config = function()
    require('kanban-md').setup({
      -- Optional configuration
      default_columns = {"Backlog", "Ready", "In Progress", "Done"},
      auto_timestamp = true,
      archive_after_days = 30,
    })
  end,
  cmd = {
    "KanbanNewBoard", "KanbanNewCard", "KanbanNewColumn",
    "KanbanMoveCard", "KanbanCompleteCard", "KanbanForceCompleteCard",
    "KanbanSetComplexity", "KanbanArchive", "KanbanStats",
    "KanbanAddDependency", "KanbanPersistIds", "KanbanVersion",
  },
}
```

### packer.nvim
```lua
use {
  "theprintedbird/kanban-md.nvim",
  requires_submodules = true,
  config = function()
    require('kanban-md').setup()
  end
}
```

### Manual installation

```sh
git clone --recurse-submodules https://github.com/theprintedbird/kanban-md.nvim ~/.config/nvim/pack/plugins/start/kanban-md.nvim
# or wherever your config is (XDG_CONFIG_HOME etc)
```

If you already cloned without `--recurse-submodules`, run `git submodule update --init` inside the plugin directory.

## Available Commands

- `:KanbanNewBoard` - Create a new kanban board
- `:KanbanNewCard` - Add a new card
- `:KanbanNewColumn` - Add a new column
- `:KanbanMoveCard` - Move card at cursor to a different column
- `:KanbanCompleteCard` - Mark card as complete and move to the completion column (respects all validations)
- `:KanbanForceCompleteCard` - Force complete a card (bypasses dependency/subtask checks only; WIP limits and workflow rules still apply)
- `:KanbanSetComplexity` - Set task complexity on the card at cursor
- `:KanbanArchive` - Archive completed cards older than `archive_after_days`
- `:KanbanStats` - Show board statistics in a floating/split window
- `:KanbanAddDependency` - Create a dependency between two cards (two-step: mark the dependant card, then the dependency)
- `:KanbanPersistIds` - Enable persistent card IDs in the markdown (required for dependency tracking)
- `:KanbanVersion` - Show the installed plugin version

## Layout

    kanban-md.nvim
    ├── lazy.lua                       -- lazy.nvim plugin spec
    ├── ftdetect/
    │   └── kanban-md.lua               -- sets the markdown.kanban filetype
    ├── plugin/
    │   └── kanban-md.lua               -- registers commands on load
    ├── lua/kanban-md/
    │   ├── init.lua                    -- Neovim entry point (setup())
    │   ├── commands.lua                 -- user commands (:Kanban*)
    │   ├── detect.lua                   -- board detection (detection_strategy)
    │   ├── extras/
    │   │   └── cursor_triggers.lua      -- cursor positioning after moves
    │   └── adapters/
    │       └── neovim.lua               -- Neovim adapter
    ├── lib/kanban-md-engine/                  -- kanban-md-engine (git submodule)
    └── tests/                          -- plenary.nvim specs for this plugin

## Board Detection

Markdown buffers that are kanban boards get the compound filetype **`markdown.kanban`**. Neovim loads everything for `markdown` first (ftplugin, syntax, treesitter), then anything for `kanban`. Virtual text is shown in `markdown.kanban` buffers. You can add your own board settings in `ftplugin/markdown.kanban.lua` or with a `FileType markdown.kanban` autocmd.

These buffers get the filetype:

- Files with a `.kanban.md` extension, always.
- Buffers where `:KanbanNewBoard` is run. It also writes the `<!-- kanban-board -->` marker as the first line, so the file is still recognised when you reopen it under the `"marker"` and `"both"` strategies.
- Other markdown files that the `detection_strategy` config option accepts:
  - **`"marker"`** (default) - Requires an explicit `<!-- kanban-board -->` comment in the first 10 lines. Invisible in rendered markdown, and prevents accidental parsing of ordinary docs.
  - **`"extension"`** - Only files with a `.kanban.md` extension.
  - **`"both"`** - Either the marker or the `.kanban.md` extension.
  - **`"auto"`** - Legacy: any file containing H6 headers (`######`). May match unintended files, and scans the whole of every markdown file that isn't a board.

Detection runs when a file is opened, and again each time it is written, so adding or removing the marker changes the filetype on the next `:w`.

If you lazy-load the plugin by filetype, include both: `ft = { "markdown", "markdown.kanban" }`.

```lua
require('kanban-md').setup({
  detection_strategy = "extension", -- or "marker" | "both" | "auto"
})
```

## Configuration

Configuration is defined and validated by the engine (`kanban-md-engine`), but is typically set through this plugin's `setup()`:

```lua
require("kanban-md").setup({
  -- Board defaults
  default_columns = {"Backlog", "Ready", "In Progress", "Done"},
  archive_after_days = 30,

  -- Detection
  detection_strategy = "marker", -- "marker" | "extension" | "both" | "auto"

  -- Display
  show_stats_virtual_text = true,
  show_cycle_time = true,

  -- Automation
  auto_timestamp = true,
  persist_card_ids = false, -- write card IDs to markdown (false = ephemeral, true = persistent)

  -- Validation (optional features, disabled by default)
  dependency_validation = false, -- false/"off" | true/"on"/"strict" | "warn"
  subtask_validation = false,    -- false/"off" | true/"on"/"strict" | "warn"

  -- User interaction
  confirm_destructive = true, -- confirm before force-complete and other destructive actions
})
```

For the full list of config options, property types, triggers, and how to write your own, see the `kanban-md-engine` repository.

## Testing

This plugin's own tests (buffer handling, virtual text, cursor positioning) use [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) and live under `tests/`. They require the `lib/kanban-md-engine` submodule to be initialised, since commands are exercised against the real engine.

```sh
git submodule update --init
./tests/run_tests.sh
```

The script runs under any POSIX `sh` and exits non-zero if a spec fails. It clones plenary.nvim into `${XDG_CACHE_HOME:-$HOME/.cache}/kanban-md/` on first run. Set `PLENARY_REF` to pin plenary to a tag or commit.

Or run a single spec directly:

```sh
nvim --headless -c "PlenaryTestFile tests/integration/virtual_text_spec.lua" -c "quit"
```

Engine-level tests (parser, writer, board/column/card behaviour, triggers, stats) live in the `kanban-md-engine` repository, not here.

Lint with [luacheck](https://github.com/lunarmodules/luacheck), configured in `.luacheckrc`:

```sh
luacheck lua plugin ftdetect tests lazy.lua
```

## CI

`.github/workflows/test.yml` runs on pushes to `master`, on pull requests and on manual dispatch. It has two jobs:

- **Luacheck**, the lint command above.
- **Tests**, `./tests/run_tests.sh` against Neovim stable on `ubuntu-latest` and `macos-latest`.

The engine submodule is a private repository with an SSH URL, so the test job fetches it with a **deploy key**. To set one up:

1. Generate a key pair: `ssh-keygen -t ed25519 -N "" -f kanban-md-engine-deploy -C "kanban-md.nvim CI"`.
2. On kanban-md-engine, go to Settings → Deploy keys → Add deploy key. Paste the contents of `kanban-md-engine-deploy.pub` and leave "Allow write access" unticked.
3. On kanban-md.nvim, go to Settings → Secrets and variables → Actions → New repository secret. Name it `ENGINE_DEPLOY_KEY` and paste the contents of `kanban-md-engine-deploy` (the private half).
4. Delete both local files.

A deploy key can read only that one repository, and it doesn't expire. `.gitmodules` keeps its SSH URL for local development.

To run the workflow locally with [act](https://github.com/nektos/act), which reads its defaults from `.actrc` and runs the Linux leg only:

```sh
act -s ENGINE_DEPLOY_KEY="$(cat path/to/kanban-md-engine-deploy)"
```
