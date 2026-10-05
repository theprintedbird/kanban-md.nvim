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

# Check if plenary is available
if ! nvim --headless --cmd "set rtp+=$KANBAN_PLENARY_PATH" -c "lua require('plenary')" -c "quit" 2>/dev/null; then
	echo "ERROR: plenary.nvim is not working properly"
	echo "Path: $KANBAN_PLENARY_PATH"
	exit 1
fi

# run_tests.lua ends with `cquit`, so nvim's exit status is the test result.
# The trailing `cquit 1` is only reached if the runner itself raised an error
# before getting that far; without it headless nvim would sit waiting.
nvim --headless --cmd "set rtp+=$KANBAN_PLENARY_PATH" \
	-c "luafile $PROJECT_ROOT/tests/run_tests.lua" \
	-c "cquit 1"
