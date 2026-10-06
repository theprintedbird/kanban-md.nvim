#!/bin/sh

# run_tests.sh - Run Kanban plugin tests using Neovim and Plenary
#
# Exits with the test runner's status, so a failing spec fails the caller.
#
# Environment:
#   XDG_CACHE_HOME  plenary.nvim is cloned under it (default: $HOME/.cache)
#   PLENARY_REF     optional tag/branch/commit of plenary.nvim to pin to

set -u

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# The one place the plenary location is decided; run_tests.lua reads it back.
KANBAN_PLENARY_PATH="${XDG_CACHE_HOME:-$HOME/.cache}/kanban-md/plenary.nvim"
export KANBAN_PLENARY_PATH

# Keep the developer's own config, plugins and state out of the run. Every nvim
# here (and each per-spec nvim run_tests.lua starts) uses --clean; these point
# whatever else nvim reads or writes at a throwaway directory. XDG_CACHE_HOME
# is left alone so the plenary clone is reused between runs.
KANBAN_TEST_HOME="$(mktemp -d "${TMPDIR:-/tmp}/kanban-md-tests.XXXXXX")" || exit 1
trap 'rm -rf "$KANBAN_TEST_HOME"' EXIT
trap 'exit 1' HUP INT TERM
XDG_CONFIG_HOME="$KANBAN_TEST_HOME/config"
XDG_DATA_HOME="$KANBAN_TEST_HOME/data"
XDG_STATE_HOME="$KANBAN_TEST_HOME/state"
export XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME
unset NVIM_APPNAME

echo "Running Kanban plugin tests..."
echo "Project directory: $PROJECT_ROOT"
echo "Plenary path: $KANBAN_PLENARY_PATH"

# Install plenary if not available
if [ ! -d "$KANBAN_PLENARY_PATH" ]; then
	echo "Installing plenary.nvim to $KANBAN_PLENARY_PATH..."
	mkdir -p "$(dirname "$KANBAN_PLENARY_PATH")"
	git clone https://github.com/nvim-lua/plenary.nvim "$KANBAN_PLENARY_PATH" || exit 1
fi

if [ -n "${PLENARY_REF:-}" ]; then
	echo "Pinning plenary.nvim to $PLENARY_REF"
	git -C "$KANBAN_PLENARY_PATH" fetch --quiet origin "$PLENARY_REF" || exit 1
	git -C "$KANBAN_PLENARY_PATH" checkout --quiet --detach FETCH_HEAD || exit 1
fi

# Paths reach nvim through the environment rather than being spliced into Ex
# commands, where a space would split them.
ADD_PLENARY="lua vim.opt.rtp:append(os.getenv('KANBAN_PLENARY_PATH'))"

# Check if plenary is available
if ! nvim --headless --clean --cmd "$ADD_PLENARY" -c "lua require('plenary')" -c "quit" 2>/dev/null; then
	echo "ERROR: plenary.nvim is not working properly"
	echo "Path: $KANBAN_PLENARY_PATH"
	exit 1
fi

# run_tests.lua ends with `cquit`, so nvim's exit status is the test result.
# The trailing `cquit 1` is only reached if the runner itself raised an error
# before getting that far; without it headless nvim would sit waiting.
KANBAN_TEST_RUNNER="$PROJECT_ROOT/tests/run_tests.lua" nvim --headless --clean --cmd "$ADD_PLENARY" \
	-c "lua dofile(os.getenv('KANBAN_TEST_RUNNER'))" \
	-c "cquit 1"
