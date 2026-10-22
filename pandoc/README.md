# Markdown and Academic Writing in Vim

A Neovim configuration for writing Markdown.

Everything lives under `~/.config/nvim/` and follows the directory structure
below. No new plugins are required, the existing `pack.lua`, `init.lua`,
`formatting.lua` and friends stay as they are.

## File layout

```
after/ftplugin/markdown.lua
after/ftplugin/tex.lua
lua/plugins/completions.lua
lua/plugins/obsidian.lua
lua/shared/pandoc.lua
lua/shared/bib.lua
lua/shared/citekeys.lua
pandoc/defaults.yaml
pandoc/metadata.yaml
pandoc/profiles/abnt.yaml
pandoc/filters/wikilinks.lua
pandoc/filters/cites_to_text.lua
```

## Requirements (Arch Linux)

```bash
sudo pacman -S pandoc-cli zathura zathura-pdf-mupdf
sudo pacman -S texlive-xetex texlive-latex texlive-latexextra texlive-latexrecommended \
                texlive-fontsrecommended texlive-langportuguese
```

`texlive-langportuguese` provides pt-BR hyphenation and localized labels. If a
package name doesn't match your mirror, search with `pacman -Ss texlive`.

## How export works

The same command handles a shopping list and a peer-reviewed article. Nothing
forces a bibliography to exist.

Each export loads, in order (later wins):

1. **`pandoc/defaults.yaml`** — the pipeline itself: Markdown input with wikilinks,
   XeLaTeX backend. Always loaded.
2. **A `defaults.yaml` in the note's folder, or any parent up to `$HOME`**
   (optional, for project-level configuration). Relative paths inside it resolve
   from the note's folder, so prefer `${HOME}/...` for absolute safety.
3. **`pandoc/metadata.yaml`** — the academic look and language: pt-BR, article
   class, 2.5 cm margins, paragraph indent, colored links.
4. **A profile**, if requested: `:Pandoc pdf abnt`.
5. **The note's own YAML frontmatter**, which overrides everything above.

Edit `metadata.yaml` to change the default for every document. Edit a single
note's frontmatter to change just that one.

### Citations

Citations only kick in when a bibliography is available:

- The note has `bibliography:` in its YAML → that file is used.
- The note uses `@key`, and a `refs.bib`, `references.bib`, `bibliography.bib`
  or `library.bib` exists in the note's folder or any parent (your
  `~/personal/documents/refs.bib` is picked up naturally here) → that file is
  used. To change the default search path, edit `M.global` in
  `lua/shared/bib.lua`.
- Neither of the above → `@maria` stays plain text. No `(maria?)`, no error.

If a `.bib` is active and you need a literal `@`, write `\@maria`.

### Citation style

Without a `.csl` file, Pandoc falls back to Chicago author-date. For ABNT:

```bash
mkdir -p ~/.config/nvim/pandoc/csl
curl -L -o ~/.config/nvim/pandoc/csl/abnt.csl \
  https://raw.githubusercontent.com/citation-style-language/styles/master/associacao-brasileira-de-normas-tecnicas.csl
```

`csl/abnt.csl` is used with `:Pandoc pdf abnt`. To fix a style for every
document, save it as `csl/default.csl`. A `csl:` entry in the note's YAML
overrides both.

### Other details

- **Wikilinks**: `[[Note]]` and `[[Note|alias]]` become plain text. `![[img.png]]`,
  `![[img.png|300]]` (width) and `![[img.png|caption]]` become images, resolved
  from any `attachments/` folder at or above the note. Embedding another note
  inlines its text.
- The buffer is piped via stdin — no need to save before exporting.
- Output goes to `.build/` next to the note. Obsidian doesn't index dotfiles.
- Only Pandoc errors and warnings surface (e.g. a missing citekey). Success is
  silent.

## Example academic note

```yaml
---
title: Paper title
author: Your Name
date: \today
bibliography: refs.bib # optional if a refs.bib already exists above
toc: true
numbersections: true
# lang: en-US            # switch language
# reference-section-title: References
---
```

Cite with `[@silva2020]`, `[@silva2020, p. 12]`, `@silva2020` or `[-@silva2020]`.
The "References" section is generated automatically at the end.

Example project-level `defaults.yaml` (e.g. in a thesis folder):

```yaml
bibliography:
  - ${HOME}/personal/documents/refs.bib
csl: ${HOME}/.config/nvim/pandoc/csl/abnt.csl
```

## Commands and keybindings

In Markdown buffers (`<localleader>` is yours):

| Binding                                    | Action                                                                                                                                                                         |
| ------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `:Pandoc [fmt] [profile]`                  | Export and open (pdf, epub, docx, html)                                                                                                                                        |
| `:PandocPreview [fmt] [profile]`           | Toggle rebuild-on-save                                                                                                                                                         |
| `<localleader>pb`                          | Build PDF without opening                                                                                                                                                      |
| `<localleader>po`                          | Open last export (or build and open)                                                                                                                                           |
| `<localleader>pp`                          | Preview with rebuild-on-save                                                                                                                                                   |
| `<localleader>pf`                          | Pick format and profile                                                                                                                                                        |
| `<leader>lt`                               | Toggle checkbox: `[ ]` ↔ `[x]`; a plain item gets `[ ]`; a normal line becomes `- [ ]`. Accepts count (`3<leader>lt`) and visual selection. Works inside and outside the vault |
| `<leader>ir`                               | Insert `[@]` and open the `.bib` keys menu                                                                                                                                     |
| `<leader>if`                               | Inline footnote `^[]`                                                                                                                                                          |
| `<leader>il` / `<leader>iw`                | Link `[]()` / wikilink `[[]]` (normal or visual mode)                                                                                                                          |
| `<leader>ib` / `<leader>ie` / `<leader>ic` | Bold / italic / inline code selection                                                                                                                                          |
| `<leader>ik`, `yc`                         | Code block / yank code block contents                                                                                                                                          |
| `<localleader>ss` / `<localleader>sl`      | Toggle spell / cycle pt_br+en_us → pt_br → en_us                                                                                                                               |
| `<C-l>` (insert)                           | Fix the last spell error                                                                                                                                                       |

Autocomplete for `@key` opens automatically on `@` (or inside `[@`) and shows
author, year and title. Wikilinks starting with `[[` open the menu on their own
too. Everywhere else in Markdown the menu stays closed and `<C-y>` opens it on
demand. The Pandoc preview and the completion menu share the same `.bib`
resolution logic (`lua/shared/bib.lua`).
