-- verify.lua -- assert litigate.vim is wired up, by name, on this Neovim.
--
--   nvim --clean --headless --cmd 'set runtimepath^=.' -l scripts/verify.lua [FILE...]
--
-- Checks, in order: parser/litigate.so and every query resolve on the
-- runtimepath by name; each FILE gets the `litigate` filetype and the
-- ftplugin, parses with zero errors, and has an active highlighter; the
-- lsp/ config (Neovim 0.11+) is discovered. Exits non-zero on any failure.
-- A headless Neovim cannot prove highlighting RENDERS (no redraw, so zero
-- extmarks); `highlighter active` is as far as this goes -- see README.
local failed = 0
local function check(name, ok, detail)
  io.stdout:write((ok and 'ok   ' or 'FAIL ') .. name .. (detail and (': ' .. detail) or '') .. '\n')
  if not ok then
    failed = failed + 1
  end
end

local parser = vim.api.nvim_get_runtime_file('parser/litigate.so', true)
check('parser/litigate.so on runtimepath', #parser > 0)
check('language loads', (pcall(vim.treesitter.language.add, 'litigate')))
for _, q in ipairs({ 'highlights', 'indents', 'folds', 'locals', 'injections' }) do
  local ok, query = pcall(vim.treesitter.query.get, 'litigate', q)
  check('query ' .. q .. ' compiles', ok and query ~= nil)
end

local errors = 0
for _, file in ipairs(_G.arg) do
  vim.cmd.edit(vim.fn.fnameescape(file))
  local buf = vim.api.nvim_get_current_buf()
  local ft = vim.bo[buf].filetype
  local active = vim.treesitter.highlighter.active[buf] ~= nil
  local tree = vim.treesitter.get_parser(buf, 'litigate'):parse()[1]
  local bad = ft ~= 'litigate' or not active or tree:root():has_error() or vim.bo[buf].shiftwidth ~= 2
  if bad then
    errors = errors + 1
    io.stdout:write(('     %s: filetype=%s highlighter=%s has_error=%s\n'):format(file, ft, tostring(active), tostring(tree:root():has_error())))
  end
  vim.cmd('bwipeout!')
end
if #_G.arg > 0 then
  check(('%d files: filetype, ftplugin, clean parse, highlighter active'):format(#_G.arg), errors == 0, errors > 0 and (errors .. ' failed') or nil)
end

if vim.fn.has('nvim-0.11') == 1 then
  local cfg = vim.lsp.config.litigate
  check('lsp/litigate.lua discovered', cfg ~= nil and vim.deep_equal(cfg.cmd, { 'litigate', 'lsp', '--stdio' }))
end

io.stdout:write(failed == 0 and 'all checks passed\n' or (failed .. ' checks failed\n'))
vim.cmd(failed == 0 and 'qa!' or 'cquit 1')
