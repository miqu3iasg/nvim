# Markdown in Neovim

A Neovim configuration for writing Markdown, with Obsidian integration and
Pandoc export.

## File layout

```
after/ftplugin/markdown.lua
lua/plugins/completions.lua
lua/plugins/obsidian.lua
lua/shared/pandoc.lua
pandoc/defaults.yaml
pandoc/metadata.yaml
pandoc/profiles/abnt.yaml
pandoc/filters/wikilinks.lua
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

Each export loads, in order (later wins):

1. **`pandoc/defaults.yaml`**: the pipeline itself (Markdown input with
   wikilinks, XeLaTeX backend). Always loaded.
2. **A `defaults.yaml` in the note's folder, or any parent up to `$HOME`**
   (optional, for project-level configuration). Relative paths inside it
   resolve from the note's folder.
3. **`pandoc/metadata.yaml`**: the default look and language (pt-BR, article
   class, 2.5 cm margins, paragraph indent, colored links).
4. **A profile**, if requested: `:Pandoc pdf abnt`.
5. **The note's own YAML frontmatter**, which overrides everything above.

Edit `metadata.yaml` to change the default for every document. Edit a single
note's frontmatter to change just that one.

### Details

- **Wikilinks**: `[[Note]]` and `[[Note|alias]]` become plain text.
  `![[img.png]]`, `![[img.png|300]]` (width) and `![[img.png|caption]]` become
  images, resolved from any `attachments/` folder at or above the note.
  Embedding another note inlines its text.
- **No citations**: the `citations` extension is off, so `@maria` is always
  plain text.
- The buffer is piped via stdin, so there is no need to save before exporting.
- Output goes to `.build/` next to the note. Obsidian doesn't index dotfiles.
- Only Pandoc errors and warnings surface. Success is silent.

## Commands and keybindings

In Markdown buffers (`<localleader>` is yours):

| Binding                                    | Action                                                                                                                                     |
| ------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `:Pandoc [fmt] [profile]`                  | Export and open (pdf, epub, docx, html)                                                                                                    |
| `:PandocPreview [fmt] [profile]`           | Toggle rebuild-on-save                                                                                                                     |
| `<localleader>pb`                          | Build PDF without opening                                                                                                                  |
| `<localleader>po`                          | Open last export (or build and open)                                                                                                       |
| `<localleader>pp`                          | Preview with rebuild-on-save                                                                                                               |
| `<localleader>pf`                          | Pick format and profile                                                                                                                    |
| `<leader>lt`                               | Toggle checkbox: `[ ]` ↔ `[x]`; a plain item gets `[ ]`; a normal line becomes `- [ ]`. Accepts count (`3<leader>lt`) and visual selection |
| `<leader>if`                               | Inline footnote `^[]`                                                                                                                      |
| `<leader>il` / `<leader>iw`                | Link `[]()` / wikilink `[[]]` (normal or visual mode)                                                                                      |
| `<leader>ib` / `<leader>ie` / `<leader>ic` | Bold / italic / inline code selection                                                                                                      |
| `<leader>ik`, `yc`                         | Code block / yank code block contents                                                                                                      |
| `<localleader>ss` / `<localleader>sl`      | Toggle spell / cycle pt_br+en_us → pt_br → en_us                                                                                           |
| `<C-l>` (insert)                           | Fix the last spell error                                                                                                                   |

In Markdown the completion menu stays closed, except for wikilinks (`[[`
opens it on its own). `<C-y>` opens it on demand.
