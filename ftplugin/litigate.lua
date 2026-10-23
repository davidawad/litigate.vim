-- ftplugin/litigate.lua -- buffer settings, plus Neovim-only tree-sitter
-- activation for litigate (.lit rule modules, .case matters).
--
-- Classic Vim never autoloads a `.lua` ftplugin, so this file is invisible
-- to it; plain-Vim users get only syntax/litigate.vim + indent/litigate.vim
-- (see README.md's "Plain Vim" install section). Neovim users additionally
-- get this, which starts native tree-sitter highlighting and folding IF the
-- `litigate` parser has been installed (see README.md's "Neovim" install
-- section) -- it is a silent no-op otherwise, so simply having this plugin
-- on the runtimepath without having built the parser yet does not error.
--
-- The tree-sitter language name equals the filetype (`litigate`), so no
-- `vim.treesitter.language.register` bridge is needed.

-- Two-space indentation is the canonical format (`litigate fmt`).
vim.bo.commentstring = '// %s'
vim.bo.comments = 's1:/*,mb:*,ex:*/,:///,://'
vim.bo.expandtab = true
vim.bo.shiftwidth = 2
vim.bo.softtabstop = 2
vim.bo.tabstop = 2
vim.opt_local.iskeyword:append('-')

-- Tree-sitter highlighting and folding when the parser is installed.
if pcall(vim.treesitter.start, 0, 'litigate') then
  vim.wo[0][0].foldmethod = 'expr'
  vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
  vim.wo[0][0].foldlevel = 99
  -- Indentation from queries/indents.scm needs nvim-treesitter's indentexpr.
  if pcall(require, 'nvim-treesitter') then
    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end
end

vim.b.undo_ftplugin = (vim.b.undo_ftplugin and (vim.b.undo_ftplugin .. ' | ') or '')
  .. 'setlocal commentstring< comments< expandtab< shiftwidth< softtabstop< tabstop< iskeyword< indentexpr<'
