---@diagnostic disable: undefined-global
vim.keymap.set('n', '<C-t>', ':Neotree toggle<CR>', { silent = true })
vim.keymap.set('n', '<C-h>', '<C-w>h')
vim.keymap.set('n', '<C-j>', '<C-w>j')
vim.keymap.set('n', '<C-k>', '<C-w>k')
vim.keymap.set('n', '<C-l>', '<C-w>l')
vim.keymap.set('n', ';', '/')
vim.keymap.set('n', '<C-c><C-c>', ':noh<CR>', { silent = true })
vim.keymap.set('i', '<C-c>', '<Esc>', { silent = true })

-- Claude Code
-- vim.keymap.set('n', '<C-Bslash>', ':ClaudeCode<CR>', { silent = true })

-- LSP
vim.keymap.set('n', '<Space>', ':lua vim.lsp.buf.hover()<CR>', { silent = true })

-- Buffers
vim.keymap.set('n', '<C-b><C-b>', ':Telescope buffers<CR>', { silent = true })
vim.keymap.set('n', '<C-b><C-q>', ':bdelete<CR>', { silent = true })
vim.keymap.set('n', '<C-b><C-a>', ':%bd<CR>', { silent = true })
vim.keymap.set('n', '<', ':b#<CR>', { silent = true })

-- Terminal
vim.keymap.set('t', '<C-p>', '<C-Bslash><C-N><C-c>', { silent = true })
