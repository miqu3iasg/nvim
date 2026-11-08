# Snippets

LuaSnip snippets for this config, one file per filetype, loaded lazily. Each
file returns a table of snippets; `common.lua` holds language-agnostic snippets
that multiple filetypes inherit. They complement native LSP completion: the LSP
is the only source in the completion menu, so LuaSnip's own snippets do not
appear there — they are expanded manually instead.

## File layout

```
lua/snippets/common.lua
lua/snippets/c.lua
lua/snippets/java.lua
lua/snippets/latex.lua
lua/snippets/lisp.lua
lua/snippets/markdown.lua
lua/snippets/python.lua
lua/snippets/sql.lua
lua/snippets/typst.lua
```

## What this directory is

Snippets are expanded by trigger, autosnippet, or through the snippet keymaps
below. They are not part of the completion menu, which uses native LSP
completion as its only source. A snippet file is required only the first time a
buffer of its filetype appears, and loading failures are reported with
`vim.notify` instead of being raised, so a broken snippet file never blocks
completion.

## Conventions

Every file lives at `lua/snippets/<ft>.lua` and returns a LuaSnip snippet
table. Registration happens in `lua/plugins/completions.lua`:

- `snippet_modules` maps each filetype to its module under `lua/snippets/`.
- `common_filetypes` lists the filetypes that inherit `common`.
- `aliases` maps filetypes to a base (`scheme → lisp`, `mysql/plsql → sql`).
- `TRIGGER_FILETYPES` lists filetypes where the completion menu opens
  automatically; elsewhere completion is manual.

## How snippets are loaded

Loading is handled by `lua/plugins/completions.lua`:

1. `luasnip.setup` is called once with `enable_autosnippets = true` and
   `store_selection_keys = "<leader>s"`.
2. For every filetype in `common_filetypes`, `common` snippets are extended onto
   it via `luasnip.filetype_extend`. Aliases are extended the same way.
3. A `FileType` autocmd (group `LazySnippets`) calls `load_snippets(ft)`,
   which resolves aliases and loads `common` when applicable.
4. A startup loop over existing buffers covers buffers opened before the plugin
   ran, such as restored sessions.

Each module is required only once. `common` is shared across many filetypes,
so editing it affects all of them.

## Requirements

LuaSnip must be declared in `lua/config/pack.lua` and installed through the
plugin manager. It builds `jsregexp` with `make` at install time, so a C
toolchain must be on `PATH`.

## Keymaps

Snippet keymaps in insert mode:

| Binding   | Action                                                    |
| --------- | --------------------------------------------------------- |
| `<Tab>`   | Expand snippet, next completion item, or next placeholder |
| `<S-Tab>` | Previous completion item or previous placeholder          |
| `<C-n>`   | Next completion item / cycle snippet choice               |
| `<C-p>`   | Previous completion item / cycle snippet choice           |
| `<C-q>`   | Unlink active snippet                                     |
| `<CR>`    | Accept completion or newline                              |
| `<C-y>`   | Trigger LSP completion on demand                          |

## Adding snippets

Create `lua/snippets/<ft>.lua` returning a table of snippets, then register the
filetype and its inheritances in `lua/plugins/completions.lua`
(`snippet_modules`, `common_filetypes`, `aliases`).

## Useful links

See: `lua/plugins/completions.lua`
See: `lua/config/pack.lua`
See: `lua/utils/lazy.lua`
See: `https://github.com/L3MON4D3/LuaSnip`
See: `:help LuaSnip`
