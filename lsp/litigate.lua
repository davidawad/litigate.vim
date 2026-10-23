-- Language server config for Neovim 0.11+ (`:h lsp-config`). With this
-- directory on 'runtimepath', enable it with `vim.lsp.enable('litigate')`.
-- The server is `litigate lsp --stdio` (the litigate-lsp crate); it must be
-- on $PATH. On Neovim 0.10 use the nvim-lspconfig snippet in README.md.
---@type vim.lsp.Config
return {
  cmd = { 'litigate', 'lsp', '--stdio' },
  filetypes = { 'litigate' },
  root_markers = { 'Lit.toml', 'Lit.lock', '.git' },
}
