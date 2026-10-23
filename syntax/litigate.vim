" syntax/litigate.vim -- classic regex-based syntax highlighting for litigate
" (.lit rule modules, .case matters). Works in plain Vim (no tree-sitter, no
" Lua) and in Neovim when the tree-sitter parser isn't installed/active. See
" README.md for how this relates to the tree-sitter highlights.scm layer.

if exists("b:current_syntax")
  finish
endif

" Identifiers may contain `-` (`answer-period`, `12b-motion-filed`).
syntax iskeyword @,48-57,_,-,192-255

" ---------------------------------------------------------------------
" Comments: `// ...`, doc comments `/// ...`, block `/* ... */`.
" ---------------------------------------------------------------------

syntax match litigateComment "//.*$" contains=@Spell
syntax match litigateDocComment "///.*$" contains=@Spell
syntax region litigateBlockComment start="/\*" end="\*/" contains=@Spell

" ---------------------------------------------------------------------
" Strings
" ---------------------------------------------------------------------

syntax match litigateEscape "\\[\"\\nrt]" contained
syntax region litigateString start=+"+ skip=+\\\\\|\\"+ end=+"+ contains=litigateEscape,@Spell

" ---------------------------------------------------------------------
" Keywords. Every litigate keyword is contextual (`default`, `note`, `p`
" stay usable as names); the regex layer cannot tell, so it highlights the
" declaration keywords and a few unambiguous clause keywords only.
" ---------------------------------------------------------------------

syntax keyword litigateKeyword module import package start group type enum event
syntax keyword litigateKeyword state decision chance terminal link instance rule
syntax keyword litigateKeyword deadline counting calendar transition authority
syntax keyword litigateKeyword exception test case uses as_of known_at summary
syntax keyword litigateKeyword notes source perspective parties events facts
syntax keyword litigateKeyword stakes beliefs observe analysis given expect on
syntax keyword litigateClause forum by outcome effort cost within duration mode
syntax keyword litigateClause sets clears requires forbids replaces tags attrs
syntax keyword litigateClause valence payoff pack remove_edges probabilities roles
syntax keyword litigateClause from after before counted_by holidays anchor
syntax keyword litigateClause effective observed amends subject_to notwithstanding
syntax keyword litigateClause supersedes revives override rebuts undercuts priority url
syntax keyword litigateConditional when unless otherwise match
syntax keyword litigateCite cite
syntax keyword litigateBoolean true false

" ---------------------------------------------------------------------
" Literals: dates, money (`2_000.usd`), durations (`30.days`), numbers.
" ---------------------------------------------------------------------

syntax match litigateDate "\<\d\{4}-\d\{2}-\d\{2}\>"
syntax match litigateNumber "\<\d[0-9_]*\%(\.\d[0-9_]*\)\?\%(\.\%(usd\|days\|court_days\|business_days\|hours\)\)\?\>"
syntax match litigateHole "?\%(\s*(\)\@="

" ---------------------------------------------------------------------
" Declared names: `event Served`, `rule NAME`, `deadline NAME`, ...
" ---------------------------------------------------------------------

syntax match litigateName "\%(\<\%(event\|type\|enum\|rule\|deadline\|counting\|calendar\|transition\|default\|exception\)\>\s\+\)\zs[A-Za-z_][A-Za-z0-9_-]*"

" ---------------------------------------------------------------------
" Operators
" ---------------------------------------------------------------------

syntax match litigateOperator "->\|=>\|==\|!=\|<=\|>=\|&&\|||"

" ---------------------------------------------------------------------
" Links
" ---------------------------------------------------------------------

highlight default link litigateComment Comment
highlight default link litigateDocComment SpecialComment
highlight default link litigateBlockComment Comment
highlight default link litigateString String
highlight default link litigateEscape SpecialChar
highlight default link litigateKeyword Keyword
highlight default link litigateClause Keyword
highlight default link litigateConditional Conditional
highlight default link litigateCite PreProc
highlight default link litigateBoolean Boolean
highlight default link litigateDate Number
highlight default link litigateNumber Number
highlight default link litigateHole Todo
highlight default link litigateName Function
highlight default link litigateOperator Operator

let b:current_syntax = "litigate"
