" ftdetect/litigate.vim -- classic-Vim-compatible filetype detection for litigate.
" Works in plain Vim and in Neovim; Neovim additionally reads
" ftdetect/litigate.lua (if present) -- there isn't one here on purpose, this
" single autocommand is the only filetype-detection source this plugin
" ships, so both editors agree on the same `litigate` filetype name.
" `.lit` is a rule module, `.case` is a matter; both are the same language.
au BufRead,BufNewFile *.lit,*.case setfiletype litigate
