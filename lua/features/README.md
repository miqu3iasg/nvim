# Features

Self-contained components written for this config. Each one exposes a `setup()`
function, owns its own state, and is reached only through its own API — never
written from another file. Keeping every feature small and explicit makes it
easy to remove one by deleting its file.

## File layout

```
lua/features/close_view.lua
lua/features/compile.lua
lua/features/markdown_lists.lua
lua/features/sessions.lua
lua/features/statusline.lua
lua/features/stdsrc.lua
lua/features/todos.lua
lua/features/window_zoom.lua
```

## What this layer is

`features/` sits between the plugin adapters in `plugins/` and the shared
domain logic in `shared/`. While `plugins/` wraps third-party software,
`features/` holds hand-rolled components for this config: the statusline,
per-directory sessions, Fugitive view closing, window zoom, the `:StdSrc`
source search, native Markdown list editing, an Emacs-like `:Compile`, and TODO
comment navigation.

Every module begins with a comment containing its own path
(`-- lua/features/<name>.lua`) and exports a table `M` with a `setup()` that
must be called exactly once.

## Conventions

The load order is:

```
init.lua → config → plugins → features → shared → utils
```

A feature may only `require` layers below it. Nothing in `shared/` or `utils/`
requires upwards, so removing a feature means deleting its file here and any
calls to its `setup()` in the layers above.

Feature state belongs to its module and is reached only through its API.
Shared or cross-cutting state (exports, pandoc glue, autoformat state) lives
in `shared/`, not here. Keymaps that only make sense for one feature live in
that feature's file; all others live in `config/keymaps/`.

## How features relate to other layers

A feature is a self-contained component: it declares its own commands,
autocmds and keymaps inside `setup()`, and keeps state in module-level
variables. It does not own plugin installation — that happens in
`config/pack.lua` for eager plugins and in the adapter file itself for lazy
ones via `utils.lazy`. If a feature depends on a plugin, that dependency is
declared in the plugin's layer, not here.

## Commands and keybindings

| Binding / command         | Action                                                          |
| ------------------------- | --------------------------------------------------------------- |
| `:StdSrc`                 | Search declarations in the source of the current language       |
| `:Compile` / `:Recompile` | Run / rerun a build command asynchronously                      |
| `:CompileInterrupt`       | Interrupt the running command                                   |
| `:Todos`                  | Scan project for task comments and jump to the first one        |
| `]t` / `[t`               | Next / previous task comment                                    |
| `<leader>cc` / `<leader>cr` / `<leader>ck` | Compile prompt / recompile / interrupt              |
| `<leader>lt`              | Toggle Markdown checkbox `[ ]` ↔ `[x]`                          |
| `<C-y>` (insert)          | Trigger LSP completion on demand                                |

## Adding a feature

Create `lua/features/<name>.lua` with a `-- lua/features/<name>.lua` header,
export a table `M` with `setup()`, and call `M.setup()` from the appropriate
layer above (usually `plugins/init.lua` or `config/`). State stays inside the
module; do not write it from another file.

## Useful links

See: `lua/features/close_view.lua`
See: `lua/features/compile.lua`
See: `lua/features/markdown_lists.lua`
See: `lua/features/sessions.lua`
See: `lua/features/statusline.lua`
See: `lua/features/stdsrc.lua`
See: `lua/features/todos.lua`
See: `lua/features/window_zoom.lua`
See: `lua/config/pack.lua`
See: `lua/plugins/init.lua`
See: `lua/shared/autoformat.lua`
See: `lua/utils/lazy.lua`
See: `https://github.com/tpope/vim-fugitive`
See: `https://github.com/ibhagwan/fzf-lua`
See: `:help 'statusline'`
See: `:help quickfix`
See: `:help :mksession`
See: `:help :source`
