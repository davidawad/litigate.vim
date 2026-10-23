" indent/litigate.vim -- classic indentexpr for litigate (works in plain Vim too).
"
" litigate is brace-structured, two spaces per level (`litigate fmt`). This is
" deliberately the simplest-correct v1: copy the previous non-blank line's
" indent, add one `shiftwidth()` after a line whose (comment-stripped) text
" ends in an opening `{`, `(` or `[`, and take one back on a line that starts
" with a closing delimiter. In Neovim with nvim-treesitter, the ftplugin
" replaces this with the grammar's indents.scm.

if exists("b:did_indent")
  finish
endif
let b:did_indent = 1

setlocal indentexpr=LitigateIndent()
setlocal indentkeys=0{,0},0),0],!^F,o,O
setlocal nosmartindent
setlocal noautoindent

if exists("*LitigateIndent")
  finish
endif

function! LitigateIndent() abort
  let l:prevlnum = prevnonblank(v:lnum - 1)
  if l:prevlnum == 0
    return 0
  endif

  " Strip a trailing `// ...` comment before looking at the last character.
  let l:stripped = substitute(getline(l:prevlnum), '//.*$', '', '')
  let l:indent = indent(l:prevlnum)

  if l:stripped =~ '[{(\[]\s*$'
    let l:indent += shiftwidth()
  endif
  if getline(v:lnum) =~ '^\s*[})\]]'
    let l:indent -= shiftwidth()
  endif
  return max([l:indent, 0])
endfunction
