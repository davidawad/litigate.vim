#!/usr/bin/env bash
# build-parser.sh -- fetch the pinned litigate grammar and build the Neovim parser.
#
# Run from the plugin root; vim-plug's `do` hook does exactly that. Produces
# two build artifacts, both gitignored, so the grammar has exactly one source
# of truth (davidawad/tree-sitter-litigate) and this repo commits no copy of it:
#
#   parser/litigate.so            -- what Neovim searches the runtimepath for,
#                                    by name. A litigate.so at the repo root is
#                                    never found, and the failure is silent.
#   queries/litigate/*.scm        -- the grammar's queries (highlights, indents,
#                                    folds, locals, injections). Neovim resolves
#                                    queries by language name, so they must be
#                                    under queries/<lang>/.
#
# Nothing here is Neovim-specific except that Neovim is the editor consuming
# the output; plain Vim ignores both and uses syntax/litigate.vim instead.
#
# The committed grammar parser is tree-sitter ABI 15. A Neovim whose bundled
# libtree-sitter is older loads at most ABI 14, so this script asks the nvim on
# PATH which it needs and regenerates the parser (needs node) when it is < 15.
set -euo pipefail

GRAMMAR_REPO="https://github.com/davidawad/tree-sitter-litigate"
# Pinned on purpose. An unpinned grammar means `:PlugUpdate` can silently
# change how your files highlight, with no review. Bump deliberately.
GRAMMAR_REV="ceb16e66552f524fde0c47ef6ffcf86dda2499af"

cd "$(dirname "${BASH_SOURCE[0]}")/.."

if ! command -v tree-sitter >/dev/null 2>&1; then
  echo "build-parser: the tree-sitter CLI is not on PATH." >&2
  echo "  install: cargo install tree-sitter-cli   (or: npm i -g tree-sitter-cli)" >&2
  echo "  then re-run: bash scripts/build-parser.sh" >&2
  exit 1
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

git clone --quiet --no-checkout "$GRAMMAR_REPO" "$tmp/grammar"
git -C "$tmp/grammar" checkout --quiet "$GRAMMAR_REV"

abi=15
if command -v nvim >/dev/null 2>&1; then
  abi="$(nvim --headless --clean \
    -c 'lua io.stdout:write(tostring(vim.treesitter.language_version))' \
    -c 'qa!' 2>/dev/null || true)"
  abi="${abi:-15}"
fi
if [ "$abi" -lt 15 ]; then
  echo "build-parser: this Neovim loads tree-sitter ABI $abi; regenerating the parser (needs node)" >&2
  (cd "$tmp/grammar" && tree-sitter generate --abi "$abi")
fi

mkdir -p parser queries/litigate
tree-sitter build -o parser/litigate.so "$tmp/grammar"
cp "$tmp/grammar/queries/litigate/"*.scm queries/litigate/

echo "build-parser: wrote parser/litigate.so (ABI $abi) and queries/litigate/*.scm"
echo "build-parser: from $GRAMMAR_REPO @ ${GRAMMAR_REV:0:12}"
