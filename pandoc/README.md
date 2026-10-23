# Markdown in Neovim

A Neovim configuration for writing Markdown, with Obsidian integration and
Pandoc export. Exported PDFs from Markdown, LaTeX and Typst all land in the
same place, described in "Where exports go" below.

## File layout

```
after/ftplugin/markdown.lua
lua/plugins/completions.lua
lua/plugins/obsidian.lua
lua/shared/exports.lua
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

## Where exports go

Every note format shares one convention, defined in `lua/shared/exports.lua`.
Final documents go to `exports/` at the root of the project, whether they came
from Pandoc, VimTeX or Tinymist, so a repo that mixes Markdown, LaTeX and Typst
notes ends up with a single folder of PDFs. Compilation byproducts, such as
the auxiliary files, logs and SyncTeX data that latexmk produces, stay in a
hidden `.build/` folder at the same root, organized by the note's subfolder
and name. Pandoc writes no intermediate files, so it only uses `exports/`.

The project root is found by looking for markers in order of priority. A
`.exports-root` file, which you can create on purpose in any folder, wins over
everything. Next comes version control (`.git`, `.jj`, `.hg` or `.svn`), which
gives the real repo root even when a subfolder has its own README. Only when
no repository is found do weaker hints apply, such as `.obsidian`, a README, a
LICENSE or a Makefile. If nothing matches, the note's own folder is used. To
force a single global folder for everything, set `vim.g.exports_root`, for
example `vim.g.exports_root = "~/exports"`.

Because `exports/` is flat, two notes with the same name and different
formats, like `algebra.md` and `algebra.tex`, produce the same
`algebra.pdf`, and the last one compiled wins. Add `.build/` to your
`.gitignore`, and `exports/` too if you don't want to version the PDFs. If the
repo is also an Obsidian vault, add `exports` to the excluded files in
Settings, Files & links, so the PDFs are not indexed.

## How Pandoc export works

Each export loads its configuration in a fixed order, where later files win.
It starts with `pandoc/defaults.yaml`, the pipeline itself (Markdown input
with wikilinks, XeLaTeX backend), which is always loaded. Next comes an
optional `defaults.yaml` in the note's folder or any parent up to `$HOME`,
meant for project-level configuration; relative paths inside it resolve from
the note's folder. Then `pandoc/metadata.yaml` sets the default look and
language (pt-BR, article class, 2.5 cm margins, paragraph indent, colored
links), and a profile such as `:Pandoc pdf abnt` can be layered on top. Last,
the note's own YAML frontmatter overrides everything above. To change the
default for every document, edit `metadata.yaml`; to change a single note,
edit its frontmatter.

Wikilinks like `[[Note]]` and `[[Note|alias]]` become plain text, since a link
inside a PDF would be broken. Image embeds such as `![[img.png]]`,
`![[img.png|300]]` (width) and `![[img.png|caption]]` become real images,
resolved from any `attachments/` folder at or above the note, while embedding
another note simply inlines its text. The `citations` extension is off, so
`@maria` is always plain text.

The buffer is piped through stdin, so there is no need to save before
exporting. Success is silent; only Pandoc errors and warnings are shown.

## Commands and keybindings

These work in Markdown buffers, where `<localleader>` is whatever you have set.

| Binding                                    | Action                                                                                                                                       |
| ------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------- |
| `:Pandoc [fmt] [profile]`                  | Export and open (pdf, epub, docx, html)                                                                                                      |
| `:PandocPreview [fmt] [profile]`           | Toggle rebuild-on-save                                                                                                                       |
| `<localleader>pb`                          | Build PDF without opening                                                                                                                    |
| `<localleader>po`                          | Open last export (or build and open)                                                                                                         |
| `<localleader>pp`                          | Preview with rebuild-on-save                                                                                                                 |
| `<localleader>pf`                          | Pick format and profile                                                                                                                      |
| `<leader>lt`                               | Toggle checkbox: `[ ]` ↔ `[x]`; a plain item gets `[ ]`; a normal line becomes `- [ ]`. Accepts a count (`3<leader>lt`) and visual selection |
| `<leader>if`                               | Inline footnote `^[]`                                                                                                                        |
| `<leader>il` / `<leader>iw`                | Link `[]()` / wikilink `[[]]` (normal or visual mode)                                                                                        |
| `<leader>ib` / `<leader>ie` / `<leader>ic` | Bold / italic / inline code selection                                                                                                        |
| `<leader>ik`, `yc`                         | Code block / yank code block contents                                                                                                        |
| `<localleader>ss` / `<localleader>sl`      | Toggle spell / cycle pt_br+en_us → pt_br → en_us                                                                                             |
| `<C-l>` (insert)                           | Fix the last spell error                                                                                                                     |

In Markdown the completion menu stays closed, except for wikilinks (`[[` opens
it on its own). `<C-y>` opens it on demand.
