# litigate.vim

Vim and Neovim support for litigate: `.lit` rule modules and `.case`
matters. litigate is a typed language for encoding procedural-law rules and
matters; its compiler also ships a language server, `litigate lsp --stdio`.

This repo is a **Vim plugin**. It ships an ordinary Vimscript layer
(`ftdetect`/`syntax`/`indent`) that gives both editors real highlighting and
indentation with **no build step and no dependencies**, and -- sitting *on
top* of that, Neovim-only -- real tree-sitter parsing whose parser is built
at install time from the grammar repo
[tree-sitter-litigate](https://github.com/davidawad/tree-sitter-litigate).

The grammar lives in its own repo because it has three consumers and none of
them is a Vim plugin: Helix fetches a grammar repo from `languages.toml`,
nvim-treesitter fetches one from a parser registry entry, and this plugin
builds a parser from it. This repo therefore commits **no** copy of the
grammar or its queries -- a committed copy is a copy that drifts.

Editor support for litigate: this plugin (Vim, Neovim),
[tree-sitter-litigate](https://github.com/davidawad/tree-sitter-litigate)
(the grammar; nvim-treesitter, anything else tree-sitter),
[helix-litigate](https://github.com/davidawad/helix-litigate) (Helix), and
[litigate-mode.el](https://github.com/davidawad/litigate-mode.el) (Emacs).

## What you get, and what each layer needs

1. **Classic Vim layer** (`ftdetect/litigate.vim`, `syntax/litigate.vim`,
   `indent/litigate.vim`) -- ordinary regex-based `:syntax match`/`:syntax
   region` highlighting plus a simple brace-aware `indentexpr`. Works in
   **plain Vim and Neovim alike**, zero dependencies, nothing to build.
2. **Tree-sitter layer** (`ftplugin/litigate.lua` + the parser built by
   `scripts/build-parser.sh`) -- accurate structural highlighting, expression
   folding from `folds.scm`, and (with nvim-treesitter) `indents.scm`
   indentation. **Neovim only** (tree-sitter is a Neovim built-in). Additive
   on top of the classic layer, not a replacement: if the parser is missing,
   this silently falls back to layer 1.
3. **Language server** (`lsp/litigate.lua`, Neovim 0.11+; or the
   nvim-lspconfig snippet below) -- diagnostics, hover and the rest of what
   `litigate lsp --stdio` provides. Needs `litigate` on `$PATH`.

Both `*.lit` and `*.case` get the `litigate` filetype. The ftplugin sets
`commentstring` to `// %s`, two-space indentation (the canonical format,
`litigate fmt`), and adds `-` to `iskeyword` (identifiers are kebab-case:
`answer-period`).

## Install

### vim-plug

```vim
" Plain Vim, or Neovim without a built parser -- classic layer only.
Plug 'davidawad/litigate.vim', { 'branch': 'main' }

" Neovim, with the tree-sitter parser built at install time.
Plug 'davidawad/litigate.vim', { 'branch': 'main', 'do': 'bash scripts/build-parser.sh' }
```

Then `:PlugInstall`. Two things in that line are load-bearing, and both fail
**silently** if you get them wrong:

- `{ 'branch': 'main' }` -- vim-plug checks out `master` by default and this
  repo's default branch is `main`, so a bare `Plug` line fails with
  `fatal: invalid reference: master`. The plugin directory is still created,
  which makes the breakage easy to miss: the `do` hook never runs, so there
  is no parser, so Neovim quietly drops to the classic layer.
- The `do` hook -- without it there is no `parser/litigate.so`, and Neovim
  searches the runtimepath for exactly `parser/<language>.so`. A `.so` at the
  repo root is never found.

`scripts/build-parser.sh` clones
[tree-sitter-litigate](https://github.com/davidawad/tree-sitter-litigate) at a
**pinned revision**, builds `parser/litigate.so`, and copies its
`queries/litigate/*.scm` into place. It needs the `tree-sitter` CLI and a C
compiler on `PATH` (`cargo install tree-sitter-cli` or
`npm i -g tree-sitter-cli`); if the CLI is missing it says so and exits
non-zero rather than half-installing. The committed grammar parser is
tree-sitter ABI 15; if the `nvim` on `PATH` loads only an older ABI (Neovim
0.10/0.11 builds against older libtree-sitter), the script regenerates the
parser at that ABI, which needs node. Both outputs are gitignored build
artifacts. Re-run it any time with `bash scripts/build-parser.sh`; bump the
grammar by editing `GRAMMAR_REV` there.

### lazy.nvim

```lua
{
  'davidawad/litigate.vim',
  branch = 'main',
  build = 'bash scripts/build-parser.sh',
  lazy = false,
}
```

### Native packages (no plugin manager)

```sh
git clone https://github.com/davidawad/litigate.vim ~/.vim/pack/plugins/start/litigate.vim
```

That is enough for the classic layer in both editors. For Neovim's
tree-sitter layer, additionally:

```sh
cd ~/.vim/pack/plugins/start/litigate.vim && bash scripts/build-parser.sh
```

### nvim-treesitter instead of the `do` hook

If you already use nvim-treesitter, let *it* own the parser rather than both
managing `parser/litigate.so`, and install this plugin without the `do` hook.
On the `master` branch:

```lua
require('nvim-treesitter.parsers').get_parser_configs().litigate = {
  install_info = {
    url = 'https://github.com/davidawad/tree-sitter-litigate',
    files = { 'src/parser.c', 'src/scanner.c' },
    branch = 'main',
  },
  filetype = 'litigate',
}
```

On the `main` branch, assign `require('nvim-treesitter.parsers').litigate = {
install_info = { url = ..., queries = 'queries' }, tier = 3 }` inside a
`User TSUpdate` autocommand. Then `:TSInstall litigate`. Do not do both
-- two managers writing the same `parser/litigate.so` is a race, not
redundancy. `src/scanner.c` must be listed (citations are lexed there).

## Language server

On Neovim 0.11+, `lsp/litigate.lua` is discovered from the runtimepath:

```lua
vim.lsp.enable('litigate')
```

On Neovim 0.10 with nvim-lspconfig:

```lua
local configs = require('lspconfig.configs')
if not configs.litigate then
  configs.litigate = {
    default_config = {
      cmd = { 'litigate', 'lsp', '--stdio' },
      filetypes = { 'litigate' },
      root_dir = require('lspconfig.util').root_pattern('Lit.toml', 'Lit.lock', '.git'),
    },
  }
end
require('lspconfig').litigate.setup({})
```

The server is `litigate lsp --stdio`; the project root is the directory with
`Lit.toml` (manifest) or `Lit.lock`.

## Internal parser/language name

The Neovim `filetype` for `*.lit` and `*.case` is `litigate`, and the
tree-sitter **language** is also `litigate`, so unlike bend.vim no
`vim.treesitter.language.register` bridge is needed.

## Testing / verification

```sh
# classic layer: filetype, syntax and indent all load
vim -N --clean --cmd 'set runtimepath+=.' -c 'filetype plugin indent on' \
    -c 'syntax on' -c 'edit path/to/file.lit' -c 'echo &filetype' -c 'qall!'

# tree-sitter layer + LSP config: parser and queries must BOTH resolve by
# name; every given file must parse clean with the highlighter attached.
nvim --clean --headless --cmd 'set runtimepath^=.' \
  -l scripts/verify.lua path/to/*.lit path/to/*.case
```

`scripts/verify.lua` exits non-zero on any failure, and prints one line per
check. Neither the grammar failing to parse nor a missing `src/scanner.c` is
what breaks here -- the grammar is verified in
[tree-sitter-litigate](https://github.com/davidawad/tree-sitter-litigate)
(`tree-sitter test`, zero `(ERROR)` nodes on every `.lit`/`.case` file in the
litgraph repo). What breaks in *this* repo is discovery, which no grammar test
covers.

One trap worth knowing: a **headless** Neovim cannot prove highlighting
*renders*. It reports an active highlighter and applies zero highlight
extmarks, because highlighting is applied on window redraw. To actually
confirm drawing, open a `.lit` file in a real terminal with `:syntax off`
-- anything still colored is tree-sitter, since the classic layer is off.

## Known Limitations

Grammar-level limitations are documented in
[tree-sitter-litigate's README](https://github.com/davidawad/tree-sitter-litigate),
because they are the grammar's, not this plugin's. The classic layer
additionally highlights contextual keywords by spelling (the grammar only
treats a word as a keyword where one is expected), so a name like `source`
used as an identifier is colored as a keyword there; the tree-sitter layer
does not have that problem.

## Provenance

Seeded on 2026-10-23 from `editors/nvim` in litgraph, restructured to the
layout of [bend.vim](https://github.com/davidawad/bend.vim): the grammar and
queries come from the pinned grammar repo instead of in-repo symlinks, the
classic Vimscript layer is new, and the nvim-treesitter registration moved to
this README. litgraph keeps its in-repo copy.

## License

GPL-3.0-or-later, the license of litgraph, where this was seeded from -- see
[LICENSE](LICENSE).
