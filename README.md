# kanban-md.nvim

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
│   lua/kanban-md/virtual_text.lua          │
├─────────────────────────────────────────┤
│   Adapter Interface (Strategy Pattern)    │  lua/kanban-md/adapters/
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

Two adapters ship in this repo:

- **`lua/kanban-md/adapters/neovim.lua`** – used by the plugin, backed by `vim.*` APIs.
- **`lua/kanban-md/adapters/cli.lua`** – a plain stdin/stdout adapter, useful for exercising the engine outside of Neovim.

See `lua/kanban-md/adapters/README.md` for the full adapter interface and how to implement your own.

## Installation

kanban-md.nvim depends on `kanban-md-engine`, included as a git submodule at `lib/kanban-md-engine`. Make sure submodules are fetched, however you install the plugin.

### lazy.nvim
```lua
{
  "theprintedbird/kanban-md.nvim",
  lazy = true,
  ft = "markdown",
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
    ├── plugin/
    │   └── kanban-md.lua               -- registers commands on load
    ├── lua/kanban-md/
    │   ├── init.lua                    -- Neovim entry point (setup())
    │   ├── commands.lua                 -- user commands (:Kanban*)
    │   ├── virtual_text.lua             -- WIP/cycle-time virtual text
    │   └── adapters/
    │       ├── interface.lua            -- adapter contract + validation
    │       ├── neovim.lua               -- Neovim adapter
    │       ├── cli.lua                  -- CLI adapter
    │       └── README.md                -- adapter docs
    ├── lib/kanban-md-engine/                  -- kanban-md-engine (git submodule)
    └── tests/                          -- plenary.nvim specs for this plugin

## Board Detection

kanban-md.nvim scans markdown buffers to decide whether to parse them as boards and attach virtual text. This is controlled by the `detection_strategy` config option:

- **`"marker"`** (default) - Requires an explicit `<!-- kanban-board -->` comment in the first 10 lines. Invisible in rendered markdown, and prevents accidental parsing of ordinary docs.
- **`"extension"`** - Only parses files with a `.kanban.md` extension.
- **`"both"`** - Accepts either the marker or the `.kanban.md` extension.
- **`"auto"`** - Legacy: detects any file containing H6 headers (`######`). May parse unintended files.

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

Or run a single spec directly:

```sh
nvim --headless -c "PlenaryTestFile tests/integration/virtual_text_spec.lua" -c "quit"
```

Engine-level tests (parser, writer, board/column/card behaviour, triggers, stats) live in the `kanban-md-engine` repository, not here.
