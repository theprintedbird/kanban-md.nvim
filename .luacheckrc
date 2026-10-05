-- Luacheck configuration for kanban-md.nvim.
-- https://luacheck.readthedocs.io/
--
-- Modelled on the engine's .luacheckrc: the checks that catch real defects
-- (undefined globals, shadowing, unreachable code) are on everywhere, and
-- each muted family is listed with its reason.

std = "luajit"       -- the Lua Neovim embeds

-- `vim` itself is read-only, but the variable and option tables are meant to
-- be assigned into (vim.g.x = ..., vim.b[buf].x = ..., vim.bo[buf].ft = ...).
local writable = { other_fields = true, read_only = false }
read_globals = {
  vim = {
    other_fields = true,
    fields = {
      g = writable, b = writable, w = writable, t = writable,
      o = writable, bo = writable, wo = writable, opt = writable,
      env = writable,
    },
  },
}

max_line_length = false

-- Adapter methods, triggers and command callbacks implement fixed
-- signatures, so unused arguments are the norm rather than a smell.
unused_args = false

ignore = {
  "611",             -- line contains only whitespace
  "612",             -- line contains trailing whitespace
  "614",             -- trailing whitespace in a comment
}

exclude_files = {
  "lib/",            -- the engine submodule lints itself
}

files["tests/"] = {
  std = "luajit+busted",
  ignore = {
    "211",           -- unused variable: specs require modules for readability
    "212",
    "213",           -- unused loop variable
    "231",           -- variable is never accessed
    "311",           -- value assigned to a variable is never used
    "431",           -- nested describe blocks routinely reuse outer names
    "122",           -- specs stub vim.ui.input and friends to script prompts
  },
}
