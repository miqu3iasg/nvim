# My Nvim Config

For those who are insane.

Hand-rolled Neovim 0.12+ configuration built on the native plugin manager
(`vim.pack`), the native LSP stack (`vim.lsp.config` / `vim.lsp.enable`) and a
minimal set of deliberately chosen plugins. No distribution, no lazy-loading
framework: startup stays around 250 ms because every module is small and every
require is explicit.

## Layout

The config is split into layers with a one-directional dependency rule:

```
init.lua      entry point: fixed load order, nothing else
colors/       custom colorschemes (loaded on demand by :colorscheme)
ftplugin/     java: buffer-local setup for Java, including the jdtls setup
after/        ftplugin overrides for specific filetypes
lua/
  config/     editor behavior, loaded unconditionally at startup
    options.lua     the :set surface (vim.opt only)
    autocmds.lua    cross-cutting autocmds (big files, sessions, whitespace)
    commands.lua    user commands (:Setwd, :Format*, :Pack*)
    pack.lua        plugin declarations for vim.pack + build hooks
    keymaps/        keymaps split by theme (windows, files, editing, ...)
  plugins/    adapters for third-party plugins, one file per plugin suite
  features/   self-contained components written in this config, each with a
              .setup() and owner of its own state
    statusline.lua     statusline on the native 'statusline' option
    sessions.lua       per-cwd session save/restore (tmux only)
    close_view.lua     closing Fugitive views without quitting Neovim
    window_zoom.lua    window zoom with tab split and a [Z] indicator
    stdsrc.lua         :StdSrc, source-repository declaration search
  shared/     domain logic reused by two or more features/plugins
    exports.lua        where documents are exported and built
    pandoc.lua         pandoc commands and shared markdown/exports glue
    autoformat.lua     single source of truth for the autoformat state
  utils/      pure, stateless helpers (never register autocmds/keymaps)
    bigfile.lua        detection of big/minified buffers
    system.lua         OS detection
    buffers.lua        buffer helpers
    substitute.lua     substitution operators
  snippets/   LuaSnip snippets, one file per filetype, loaded lazily
```

Dependency rule, from top to bottom — a layer may only require the layers
below it:

```
init.lua -> config -> plugins -> features -> shared -> utils
```

`utils/` and `shared/` never require upwards. This is what keeps each layer
replaceable: a plugin can be removed by deleting its file in `plugins/` and its
entry in `lua/config/pack.lua` + `lua/plugins/init.lua`.

## Conventions

- The first line of every module is a comment with its own path
  (`-- lua/<path>.lua`), so documentation always matches the file location.
- Plugins own their keymaps: keymaps that only make sense for one plugin live
  in that plugin's file in `lua/plugins/`. Everything else lives in
  `lua/config/keymaps/`.
- Feature state is owned by the feature module and reached through its API,
  never written directly from another file (see `features/window_zoom.lua`,
  `shared/autoformat.lua`).

## Adding things

- Plugin: add the entry to `lua/config/pack.lua` (with a one-paragraph doc),
  create `lua/plugins/<name>.lua`, and add the module name to the list in
  `lua/plugins/init.lua`.
- Snippet: create `lua/snippets/<ft>.lua` returning a table of snippets, then
  register the filetype in the module map and inheritances in
  `lua/plugins/completions.lua`.
- Filetype: add an `after/ftplugin/<ft>.lua` for buffer-local overrides;
  anything shared by two or more filetypes goes to `lua/shared/`.
- Keymap: pick the theme file in `lua/config/keymaps/`, and use the existing
  `:<leader>`-group conventions there.

## External requirements

Arch Linux installs below; see the file headers in `lua/` for the per-plugin
details (each dependency is documented next to its consumer).

```
sudo pacman -S git tmux fzf ripgrep fd nodejs npm jdk21-openjdk \
  clang go typst typstyle texlive-basic texlive-latex texlive-latexextra \
  texlive-binextra pandoc-cli zathura zathura-pdf-mupdf
```

Observations:

- `fzf-lua` needs `fzf`, `grep`, `ripgrep` and `fd`; `substitute.lua` and
  `features/stdsrc.lua` additionally drive `rg` directly.
- `LuaSnip` compiles `jsregexp` through `make` at install time (see
  `config/pack.lua`), so a C toolchain must be on PATH.
- `jdtls` (Java LSP) is installed through Mason and needs Python 3 on PATH;
  the details are in `after/ftplugin/java.lua`.
- Pandoc export/preview needs `pandoc-cli` and `zathura`; profiles and filters
  live in the `pandoc/` directory.
- `prettierd`, `sql-formatter`, `elm-format` and friends are best installed
  globally (`npm i -g`) or through Mason; the full list is in
  `lua/plugins/formatting.lua`.
