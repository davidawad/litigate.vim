# AGENTS.md -- litigate.vim

Standalone, publishable **Vim/Neovim plugin** for litigate (`.lit` rule
modules, `.case` matters). Three layers live in this repo:

- a classic regex Vimscript layer (`ftdetect/`, `syntax/litigate.vim`,
  `indent/litigate.vim`) that works in plain Vim and Neovim with no
  dependencies and no build step,
- a Neovim-only tree-sitter layer (`ftplugin/litigate.lua`) whose parser is
  built at install time by `scripts/build-parser.sh`, and
- a language-server config (`lsp/litigate.lua`) for `litigate lsp --stdio`.

There is **no grammar in this repo**. It lives in
[tree-sitter-litigate](https://github.com/davidawad/tree-sitter-litigate) and
is fetched at a pinned revision; `parser/` and `queries/litigate/` are
generated, gitignored build artifacts, deliberately not committed, so there
is exactly one source of truth for the grammar and its queries.

## For agents

- Read `README.md` first; it is the complete install, verification, and
  limitations reference.
- The two things that break this plugin are **discovery**, not logic, and
  both fail silently: the built parser must be at `parser/litigate.so`
  (Neovim searches the runtimepath for `parser/<language>.so`; a `.so` at the
  repo root is never found), and the queries must be at
  `queries/litigate/*.scm` (Neovim resolves queries by language name, so a
  query at `queries/highlights.scm` is invisible). Verify with
  `scripts/verify.lua` (README's "Testing / verification"), never by eye.
- A **headless** Neovim cannot prove highlighting renders. It reports the
  highlighter active and applies zero highlight extmarks, because
  highlighting is applied on window redraw. Use a real terminal with
  `:syntax off` to confirm drawing.
- To bump the grammar, edit `GRAMMAR_REV` in `scripts/build-parser.sh`. It
  is pinned on purpose: an unpinned grammar means `:PlugUpdate` can silently
  change how files highlight, with nothing to review. Test the script by
  deleting `parser/` and `queries/litigate/` and running it from scratch --
  that is the only way to know it does not depend on leftovers. The pin must
  be a commit that exists on the grammar repo's `main`.
- The grammar's committed parser is ABI 15. `build-parser.sh` regenerates an
  older ABI when the `nvim` on `PATH` needs one; keep that branch working.
- Do not add a second parser manager. If a user has nvim-treesitter, the
  README tells them to let nvim-treesitter own `parser/litigate.so` and to
  install this plugin *without* the `do` hook. Two managers writing the same
  `.so` is a race, not redundancy.
- Grammar-level limitations belong in the grammar repo's README, not here.
- Zero references to the owner's dotfiles are allowed here -- the repo must
  remain publishable as-is.
- Authorized: david, swe.

## Provenance

Seeded 2026-10-23 from `editors/nvim` in litgraph (commit `6dbf033`),
restructured to the bend.vim layout.
