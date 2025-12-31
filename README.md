# Kanban

Kanban in Markdown files. For use with Obsidian and Neovim.

## Goals

- create a markdown file extended syntax for creating kanban boards
- create Lua functions that I can then link to hotkeys for creating boards (e.g. markdown files with the necessary parts) and manipulating the file, e.g. adding tasks, moving tasks, having properties automatically updated upon a trigger (e.g. when a card is moved to a new list), deleting tasks, marking them done, archiving done tasks…
- Statistics are calculated dynamically and displayed via the `:KanbanStats` command, which shows metrics in a floating window

Some things I like:

- The board has a title.
- It can have definitions (e.g. WIP limits)
- Tasks are list items.
- Each task can have properties.
- When tasks enter a column they receive a timestamp.
- There's an archive for past tasks.
- List names are arbitrary, except for the archive (which has a special name: ## __ARCHIVE__).
- Lists can have definitions, or not.

Considerations:

- Obsidian compatibility: The syntax should render reasonably in Obsidian's preview mode
- Standard Markdown compliance: Should degrade gracefully in any Markdown viewer
- Parser-friendly: Easy to parse with Lua patterns

## Example syntax

kanban-md uses H6 headers (`######`) for column definitions, allowing you to include arbitrary markdown documentation in your boards.

### Basic Structure

```md
<!-- kanban-board -->
# Board Title
<!-- kanban:config
wip_limit: 7
cycle_time_unit: days
-->

###### Backlog
- Task name
- Complex task <!-- complexity: 3 -->

###### Ready
<!-- column:config wip_limit: 3 -->

###### In Progress
<!-- column:config wip_limit: 4 -->
- Current task <!-- in_progress: 1735948800 -->

###### Done
- Completed task <!-- in_progress: 1735948800, done: 1736035200 -->

###### __ARCHIVE__
<!-- archived tasks older than 30 days -->
```

A board with non-kanban markdown sections:

```md
<!-- kanban-board -->
# Sprint Planning Board

This board tracks our current sprint. Updated daily.

## How to Use

1. Add new cards to Backlog
2. Move cards through the workflow
3. Archive completed items weekly

###### Backlog
- Research API design
- Write user stories

###### In Progress
- Implement authentication

###### Done
- Set up CI/CD

###### __ARCHIVE__
- Old completed tasks
```


### Rationale

- HTML comments are invisible in Obsidian's preview and won't break rendering
- Timestamps in epoch format are unambiguous and easy to calculate with
- Special sections use double underscores: __ARCHIVE__
- Statistics are displayed via `:KanbanStats` command, not a markdown section
- The `<!-- kanban-board -->` marker (enabled by default) prevents accidental parsing of documentation files

#### Board Detection Strategies

kanban-md offers flexible strategies for detecting which markdown files should be parsed as kanban boards:

**`detection_strategy` options:**

- **`"marker"`** (default) - Requires explicit `<!-- kanban-board -->` marker in first 10 lines
  - The marker is invisible in rendered markdown

- **`"extension"`** - Only parse files with `.kanban.md` extension
  - Clean separation: `project.kanban.md` vs `README.md`
  - Works well with file organisation systems

- **`"both"`** - Accept either marker OR `.kanban.md` extension
  - Flexible: supports both naming conventions
  - Recommended for teams with mixed preferences

- **`"auto"`** - Auto-detect based on H6 headers (`######`)
  - Legacy behaviour, may parse unintended files
  - Use only if you're certain all markdown files are boards

**Configuration examples:**

```lua
-- Use file extension detection (recommended for new projects)
require('kanban-md').setup({
  detection_strategy = "extension",
})

-- Use both marker and extension (maximum flexibility)
require('kanban-md').setup({
  detection_strategy = "both",
})

-- Legacy auto-detection (not recommended)
require('kanban-md').setup({
  detection_strategy = "auto",
})
```

#### Why H6?

- **H1** (`#`) is reserved for the board title
- **H2-H5** (`##` to `#####`) can be used for documentation sections
- **H6** (`######`) marks kanban columns and is rarely used elsewhere
- If you accidentally use H6 for non-column headers, it will be obvious (tasks will appear underneath)

## Architecture Philosophy

This plugin uses a **buffer-as-source-of-truth** architecture:

- The markdown buffer is always the authoritative source of board state
- Every operation begins by parsing the current buffer content
- Operations modify an in-memory board object
- On success: changes are written back to the buffer
- On error: the board object is discarded, buffer remains unchanged
- Neovim's native undo (`u`) handles all undo functionality

### Error Handling

When operations fail (e.g., trigger errors, WIP limit violations):
- The error propagates up immediately
- No changes are written to the buffer
- The user can retry or fix the issue
- Buffer state is never corrupted

It's the simplest way I can think of to stop data corruption and keep consistency.

## Installation

### Using Plugin Managers (Recommended)

The plugin works with all major Neovim plugin managers. Commands like `:KanbanNewBoard` are available immediately after installation.

#### lazy.nvim
```lua
{
  dir = "/path/to/kanban-md", -- or git URL when published
  config = function()
    require('kanban-md').setup({
      -- Optional configuration
      default_columns = {"Backlog", "Ready", "In Progress", "Done"},
      auto_timestamp = true,
      archive_after_days = 30,
    })
  end
}
```

#### packer.nvim
```lua
use {
  "/path/to/kanban-md",
  config = function()
    require('kanban-md').setup()
  end
}
```

#### vim-plug
```vim
Plug '/path/to/kanban-md'

" In your init.vim or after plugin loads:
lua require('kanban-md').setup()
```

### Manual Installation

For drop-in installation without a plugin manager:

1. Copy the entire `lua/kanban-md/` directory to your Neovim config's `lua/` directory
2. Copy `plugin/kanban-md.lua` to your `plugin/` directory
3. Commands will be available on next Neovim restart

### Available Commands

After installation, these commands are immediately available:
- `:KanbanNewBoard` - Create a new kanban board
- `:KanbanNewCard` - Add a new card
- `:KanbanNewColumn` - Add a new_column
- `:KanbanMoveCard` - Move card at cursor to different column
- `:KanbanCompleteCard` - Mark card as complete and move to Done (respects all validations)
- `:KanbanForceCompleteCard` - Force complete card (bypasses dependency/subtask checks only)
- `:KanbanSetComplexity` - Set task complexity
- `:KanbanArchive` - Archive old completed cards
- `:KanbanStats` - Show board statistics
- `:KanbanAddDependency` - Specify the dependency between 2 (or more) tasks.
- `:KanbanPersistIds` - Set the config so that card IDs are persisted (a requirement for things like dependency tracking)

## Layout

		kanban-md
			├── board.lua
			├── card.lua
			├── column.lua
			├── column_type_resolver.lua
			├── commands.lua
			├── config.lua
			├── content_block.lua
			├── extras
			│   ├── capacity_triggers.lua
			│   ├── cursor_triggers.lua
			│   ├── id_triggers.lua
			│   ├── subtasks_triggers.lua
			│   └── workflow_triggers.lua
			├── helper
			│   ├── id_triggers.lua
			│   └── ulid.lua
			├── helpers
			│   ├── column.lua
			│   └── ulid.lua
			├── init.lua
			├── parser.lua
			├── stats.lua
			├── templates.lua
			├── triggerable.lua
			├── triggers.lua
			├── type_converter.lua
			├── validation_result.lua
			├── virtual_text.lua
			├── workflow_engine.lua
			└── writer_mixin.lua

## Triggers and Actions

The plugin uses a trigger-based architecture where operations execute user-defined functions in response to events. Triggers are registered on boards, columns, or cards and execute during lifecycle events.

### Trigger Events

- **on_create**: Fires when a board/column/card is created
- **on_entry**: Fires when a card enters a column
- **on_exit**: Fires when a card leaves a column
- **on_stay**: Fires while a card remains in a column (not commonly used)
- **on_checking**: Fires to validate before a transition occurs

### Built-in Triggers

The following triggers are automatically registered based on configuration:

**Timestamp Triggers** (when `auto_timestamp = true`, default):
- Automatically adds timestamp properties when cards enter columns
- Example: moving to "In Progress" sets `properties.in_progress = os.time()`
- Archive column gets special `archived` property name

**WIP Limit Triggers** (when column or board has `wip_limit` config):
- Validates column capacity before allowing card entry
- Prevents moves that would exceed configured limits

**Complexity Triggers** (when `use_complexity = true`):
- Adds default complexity value to cards without one
- Configurable via `default_complexity` setting

**Dependency Validation** (when `dependency_validation` is enabled):
- Prevents cards from completing until all dependencies are complete
- See "Optional Features" section for details

**Subtask Validation** (when `subtask_validation` is enabled):
- Prevents parent cards from completing until all subtasks are complete
- See "Optional Features" section for details

### Available Commands

These commands provide the user-facing actions:

- **KanbanNewBoard** - Create a new board with default columns
- **KanbanNewCard** - Add a card to a column
- **KanbanNewColumn** - Add a new column to the board
- **KanbanMoveCard** - Move card to different column (respects all validations)
- **KanbanCompleteCard** - Move card to completion column (respects all validations)
- **KanbanForceCompleteCard** - Force complete (bypasses dependency/subtask checks only)
- **KanbanSetComplexity** - Set or update card complexity
- **KanbanArchive** - Move completed cards to archive
- **KanbanStats** - Display board statistics
- **KanbanAddDependency** - Create dependency relationships between cards
- **KanbanPersistIds** - Enable persistent card IDs (required for dependencies)

## Writing Your Own Triggers

Triggers are functions that execute in response to events (entry, exit, stay, checking, create).

### Function Signature

```lua
function(self, context)
  -- self: the triggerable object (column, board, or card)
  -- context: table with board, column, card, timestamp, etc.
  -- Returns: true on success, or error() on failure
end
```

### Example: Timestamp Trigger

This already exists, it's just an example.

```lua
local function create_timestamp_trigger()
  return function(self, context)
    local normalize_column_name = function(column_name)
      if column_name == "__ARCHIVE__" then
        return "archived"
      end
      return column_name:lower():gsub("[^%w_]", "_")
    end

    local timestamp_key = normalize_column_name(self.name or self.id)
    context.card.properties[timestamp_key] = os.time()

    return true
  end
end
```

### Example: WIP Limit Trigger

This also already exists, it's just an example.

```lua
local function create_wip_limit_trigger(wip_limit)
  return function(self, context)
    if #self.cards >= wip_limit then
      error(string.format("WIP limit exceeded: %d/%d", #self.cards, wip_limit))
    end
    return true
  end
end
```

### Registering Triggers

You need to attach the timestampe to the right class of object e.g. board, column or card; that is what registration is for.

```lua
-- Register trigger on a column
local trigger_fn = create_timestamp_trigger()
column:register_on_entry("timestamp", trigger_fn)

-- Register trigger on a board
local trigger_fn = create_wip_limit_trigger(5)
board:register_on_checking("wip_limit", trigger_fn)
```

For more advanced examples, see `lua/kanban-md/triggers.lua` and `lua/kanban-md/extras/` directory.

## Optional Features

The plugin follows a modular architecture where advanced features are optional and disabled by default. These features are implemented entirely via triggers.

### Subtasks and Dependencies

**Status**: Optional (disabled by default)

These features validate task relationships during column transitions:
- **Subtasks**: Prevents parent tasks from moving to completion columns until all subtasks are complete
- **Dependencies**: Prevents tasks from moving to completion columns until all dependencies are complete

**Configuration**:
- Set `dependency_validation` to `true`, `"strict"`, or `"warn"` in your config
- Set `subtask_validation` to `true`, `"strict"`, or `"warn"` in your config
- Or configure per-board via `<!-- kanban:config dependency_validation: strict -->`

**Example Usage**:
```markdown
- Major feature <!-- id: parent-123, subtasks: [sub-1, sub-2] -->
- Implement API <!-- id: task-123, depends_on: [task-456] -->
```

See the Configuration Options section below for detailed documentation.

### Override Command: Force Complete

When dependency or subtask validation is enabled, the `:KanbanForceCompleteCard` command allows bypassing these checks while preserving all other validations (WIP limits, workflow rules, etc.). See the "Force Complete Command" section in Configuration Options for details.

## Properties System

Card properties are **completely arbitrary** - you can use any property names you want. Properties are stored in HTML comments and parsed as `key: value` pairs. The `type_converter.lua` module optionally converts specific property names to numbers, booleans, or arrays for convenience.

### How Properties Work

**Any property name works:**

```markdown
<!-- project: backend-api, story_points: 5, reviewer: bob, custom_field: whatever -->
```

The parser extracts any `key: value` pairs without restrictions. Properties are stored as strings unless you register them for type conversion (see below).

### Commonly Used Properties

These properties are used by built-in triggers and commands, but you're not required to use them:

| Property | Type | Used By | Description |
|----------|------|---------|-------------|
| `id` | string | All triggers | Unique card identifier (auto-generated by default) |
| `complexity` | number | Stats, triggers | Story points or estimation (see `:KanbanSetComplexity`) |
| `parent` | string | Subtasks | Parent task ID (when using subtask feature) |
| `position` | number | N/A | Position in column (for custom ordering) |
| `tags` | array | N/A | Categories/labels (comma-separated) |

**Timestamp Properties (epoch format):**
- Column entry timestamps are auto-added when `auto_timestamp = true` (default)
- Timestamp property names match column names (normalized to lowercase with underscores)
- Example: Moving to "In Progress" sets `in_progress: 1735948800`
- Special case: Archive column uses `archived` instead of `__archive__`

**Optional Properties (require extra modules):**
- `depends_on` (array): Task IDs this card depends on - requires `dependency_validation` enabled.
- `subtasks` (array): Task IDs of subtasks - requires `subtask_validation` enabled.
- `assignee` (string): Capacity triggers, who's working on the task - requires the `extras/capacity_triggers` module enabled.
- `sla`, `sla_config`, `started`, `priority`, `estimated_value`, `approved_by` - used in the `extras/workflow_triggers`

### Type Conversion Rules

Properties are automatically converted based on their name:

**Numbers:** `complexity`, `wip_limit`, `max_points`, timestamps, `actual_time`, `blocked_time`, `position`
**Booleans:** `blocked`, `urgent`, `reviewed`, `auto`, `revalidated`, `changes_requested`
**Arrays:** `tags`, `authorized_approvers`, `depends_on` (when enabled), `subtasks` (when enabled)

### Adding Custom Properties

You can add any custom properties in HTML comments. They will be preserved as strings unless you register them:

```lua
-- In your config or custom module:
local TypeConverter = require('kanban-md.type_converter')
TypeConverter.register_numeric_property('story_points')
TypeConverter.register_array_property('reviewers')
TypeConverter.register_boolean_property('needs_documentation')
```

### Example Card with Properties

```markdown
- Implement authentication system <!--
  id: auth-task-001,
  complexity: 5,
  assignee: alice,
  tags: backend, security,
  started: 1735948800,
  depends_on: [api-task-003, db-task-012]
-->
```

## Implementation Plan

### Phase 1: Core Parser (Week 1)

- Create parser.lua to convert markdown to Lua table √
- Create writer.lua to convert Lua table back to markdown √
- Handle property parsing from HTML comments √
- Add comprehensive tests √

### Phase 2: Basic Actions (Week 2)

- Implement create_card action √
- Implement move_card with WIP limit checking √
- Add keymappings configuration

### Phase 3: Statistics (Week 3)

- Calculate cycle time √
- Calculate throughput
- Create virtual text display for live stats
- Add stats persistence

### Phase 4: Advanced Features (Week 4)

- Archive automation
- Card filtering/search
- Board templates
- Integration with telescope.nvim for fuzzy finding

## Keybindings

```lua
-- In whichkey configuration
{ "<leader>k", group = "Kanban" },
{ "<leader>kn", ":KanbanNewCard<CR>", desc = "New card" },
{ "<leader>km", ":KanbanMoveCard<CR>", desc = "Move card" },
{ "<leader>kc", ":KanbanCompleteCard<CR>", desc = "Complete card" },
{ "<leader>kC", ":KanbanForceCompleteCard<CR>", desc = "Force complete card" },
{ "<leader>ka", ":KanbanArchive<CR>", desc = "Archive done cards" },
{ "<leader>ks", ":KanbanStats<CR>", desc = "Show statistics" },
{ "<leader>kb", ":KanbanNewBoard<CR>", desc = "Create new board" },
```

### Virtual Text Display Example

```lua
-- Display WIP limit warnings
if current_wip > wip_limit then
  vim.api.nvim_buf_set_extmark(bufnr, ns_id, line_num, 0, {
    virt_text = {{string.format(" ⚠ WIP limit exceeded (%d/%d)", current_wip, wip_limit), "WarningMsg"}},
    virt_text_pos = "eol"
  })
end

-- Display cycle time for completed cards
local cycle_time = calculate_cycle_time(card)
vim.api.nvim_buf_set_extmark(bufnr, ns_id, line_num, 0, {
  virt_text = {{string.format(" ⏱ %d days", cycle_time), "Comment"}},
  virt_text_pos = "eol"
})
```

## Configuration Options

```lua
require("kanban-md").setup({
  -- Board defaults
  default_columns = {"Backlog", "Ready", "In Progress", "Done"},
  archive_after_days = 30,

  -- WIP limits
  default_wip_limit = nil,
  warn_on_wip_exceeded = true,
  block_on_wip_exceeded = false,

  -- Display
  show_stats_virtual_text = true,
  show_cycle_time = true,
  date_format = "epoch", -- or "iso", "relative"

  -- Automation
  auto_archive = true,
  auto_timestamp = true,
  auto_id = true,
  persist_card_ids = false, -- Write card IDs to markdown (false = ephemeral, true = persistent)

  -- Validation (optional features)
  -- Dependency validation: prevents moving cards to completion columns when dependencies are incomplete
  --   false/"off": Disabled (default)
  --   true/"on"/"strict": Block moves to completion if dependencies incomplete
  --   "warn": Show warning but allow moves
  dependency_validation = false,

  -- Subtask validation: prevents moving parent cards to completion columns when subtasks are incomplete
  --   false/"off": Disabled (default)
  --   true/"on"/"strict": Block moves to completion if subtasks incomplete
  --   "warn": Show warning but allow moves
  subtask_validation = false,

  -- User interaction
  confirm_destructive = true, -- Show confirmation dialog for force complete and other destructive actions
})
```

### Dependency and Subtask Validation

These are optional features that validate task relationships during column transitions:

#### `dependency_validation`
Controls enforcement of dependency checks when moving cards. When enabled, cards with incomplete dependencies (tracked via the `depends_on` property) cannot be moved to completion columns.

**Values:**
- `false` or `"off"` - Disabled (default)
- `true`, `"on"`, or `"strict"` - Strict enforcement (blocks moves)
- `"warn"` - Warning mode (allows moves but shows warnings)

**Example usage:**
```markdown
- Implement feature <!-- id: task-123, depends_on: [task-456] -->
```

#### `subtask_validation`
Controls enforcement of subtask completion checks when moving parent cards. When enabled, parent cards with incomplete subtasks (tracked via the `subtasks` property) cannot be moved to completion columns.

**Values:**
- `false` or `"off"` - Disabled (default)
- `true`, `"on"`, or `"strict"` - Strict enforcement (blocks moves)
- `"warn"` - Warning mode (allows moves but shows warnings)

**Example usage:**
```markdown
- Major feature <!-- id: parent-123, subtasks: [sub-1, sub-2] -->
  - Sub-task 1 <!-- id: sub-1, parent: parent-123 -->
  - Sub-task 2 <!-- id: sub-2, parent: parent-123 -->
```

### Force Complete Command

When dependency or subtask validation is enabled, you may occasionally need to bypass these checks (e.g., when dependencies were completed outside the system). The `:KanbanForceCompleteCard` command allows this:

**What it bypasses:**
- ✓ Dependency validation (`depends_on` checks)
- ✓ Subtask validation (parent card with incomplete subtasks)

**What it preserves:**
- ✓ WIP limit validation (board and column level)
- ✓ Workflow transition rules
- ✓ Custom validation triggers

**Usage:**
1. Position cursor on the card you want to force complete
2. Run `:KanbanForceCompleteCard`
3. Confirm the action if `confirm_destructive` is enabled

**Suggested keybinding:**
```lua
{ "<leader>kC", ":KanbanForceCompleteCard<CR>", desc = "Force complete card" }
```

## About the parser.lua

### Key Features

#### Complete Markdown Parsing:

- Board title from # Title.
- Column headers from ###### Column Name.
- Task items being with `- `, they are just list items.
- HTML comment blocks for configuration and properties.


#### Property System:

- Automatically detects property types (numbers, booleans, arrays, strings)
- Supports both inline comments <!-- property: value --> and multi-line blocks
- Generates unique IDs for tasks if not specified


#### Special Sections:

- `__ARCHIVE__` section handling.
- Board and column configuration through comments.


#### Statistics Calculation:

- WIP counts per column
- Cycle time calculation
- Task completion metrics
- Complexity totals


#### Validation:

- WIP limit checking (both board and column level)
- Duplicate ID detection
- Structure validation

## Implementation Plan

### Phase 1: Core Parser (Week 1)

- Create parser.lua to convert markdown to Lua table
- Create writer.lua to convert Lua table back to markdown
- Handle property parsing from HTML comments
- Add comprehensive tests

### Phase 2: Basic Actions (Week 2)

- Implement create_card action
- Implement move_card with WIP limit checking
- Implement complete_card action
- Add keymappings configuration

### Phase 3: Statistics (Week 3)

- Calculate cycle time
- Calculate throughput
- Create virtual text display for live stats
- Add stats persistence

### Phase 4: Advanced Features (Week 4)

- Archive automation
- Card filtering/search
- Board templates
- Integration with telescope.nvim for fuzzy finding

## Testing

This project uses [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) for testing.

### Prerequisites

Install plenary.nvim in your Neovim setup:

```lua
-- Using packer.nvim
use 'nvim-lua/plenary.nvim'

-- Using lazy.nvim
{ 'nvim-lua/plenary.nvim' }
```

### Running Tests

**Run all tests:**
```bash
make test
# or
./tests/run_tests.sh
```

**Run specific test suites:**
```bash
make test-parser      # Parser module tests only
make test-writer      # Writer module tests only
make test-integration # Integration tests only
```

**Run tests directly with Neovim:**
```bash
nvim --headless -c "PlenaryTestFile tests/parser_spec.lua" -c "quit"
```

### Test Structure

	tests
	├── e2e
	│   ├── realistic_scenarios_spec.lua
	│   └── triggers_spec.lua
	├── fixtures
	│   ├── boards
	│   │   ├── board_auto_move.md
	│   │   ├── board_complex.md
	│   │   ├── board_custom.md
	│   │   ├── board_edge.md
	│   │   ├── board_simple.md
	│   │   └── test_basic_config.md
	│   └── boards.lua
	├── helpers
	│   └── mocks.lua
	├── integration
	│   ├── auto_complexity_spec.lua
	│   ├── auto_complexity_spec.lua.bak
	│   ├── auto_timestamp_spec.lua
	│   ├── board_spec.lua
	│   ├── card_spec.lua
	│   ├── cli_usage_spec.lua
	│   ├── column_spec.lua
	│   ├── column_type_spec.lua
	│   ├── column_type_spec.lua.bak
	│   ├── content_preservation_spec.lua
	│   ├── cursor_positioning_spec.lua
	│   ├── dependency_validation_spec.lua
	│   ├── force_complete_command_spec.lua
	│   ├── selective_bypass_spec.lua
	│   ├── state_transitions_spec.lua
	│   ├── subtask_validation_spec.lua
	│   ├── timestamp_on_initial_placement_spec.lua
	│   └── writer_adapters_spec.lua
	├── manual-tests
	│   ├── COMPLEXITY_IMPLEMENTATION_SUMMARY.md
	│   ├── complexity_demo.md
	│   ├── diagnose_cursor.lua
	│   ├── test_board.md
	│   ├── test_board_level_complexity.lua
	│   ├── test_commands.lua
	│   ├── test_complexity.lua
	│   ├── test_complexity_demo.lua
	│   ├── test_cursor_positioning.lua
	│   └── test_set_complexity_command.lua
	├── run_tests.lua
	└── unit
			├── adapters
			│   └── cli_adapter_spec.lua
			├── board_validate_dependencies_spec.lua
			├── card_spec.lua
			├── column_helpers_spec.lua
			├── column_type_resolver_spec.lua
			├── config_dependency_refactor_spec.lua
			├── config_triggers_spec.lua
			├── id_persistence_spec.lua
			├── parser_content_blocks_spec.lua
			├── stats_formatting_spec.lua
			├── stats_metrics_spec.lua
			├── triggerable_spec.lua
			├── type_converter_spec.lua
			├── utils_string_spec.lua
			├── utils_table_spec.lua
			├── virtual_text_spec.lua
			├── workflow_engine_spec.lua
			├── writer_content_blocks_spec.lua
			└── writer_mixin_spec.lua

- `tests/run_tests.lua` - Test runner script
- `tests/run_tests.sh` - Shell script to run all tests
- `Makefile` - Convenient test targets

### Test Coverage

The tests cover:
- **Parser functionality**: Board parsing, task extraction, property parsing, configuration handling
- **Writer functionality**: Markdown generation, task manipulation, archiving, formatting
- **Round-trip consistency**: Ensuring parse → write → parse maintains data integrity
- **Edge cases**: Special characters, empty sections, malformed data
- **Statistics**: WIP calculation, cycle times, complexity totals
- **Validation**: WIP limits, duplicate IDs, structural validation

Consider using plenary.nvim for testing

