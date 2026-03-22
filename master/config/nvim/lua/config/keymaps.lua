---@diagnostic disable: undefined-global
vim.keymap.set('n', '<C-t>', ':Neotree toggle<CR>', { silent = true })
vim.keymap.set('n', '<C-h>', '<C-w>h')
vim.keymap.set('n', '<C-j>', '<C-w>j')
vim.keymap.set('n', '<C-k>', '<C-w>k')
vim.keymap.set('n', '<C-l>', '<C-w>l')
vim.keymap.set('n', ';', '/')
vim.keymap.set('n', '<C-c><C-c>', ':noh<CR>', { silent = true })
vim.keymap.set('i', '<C-c>', '<Esc>', { silent = true })

local function keymap_w_repeat(mode, sign, cmd)
    vim.keymap.set(mode, sign,
        function()
            vim.cmd(cmd)
            vim.cmd(string.format('silent! call repeat#set(\'%s\')', sign))
        end,
        { silent = true, desc = cmd}
    )
end

-- Useful tool shortcuts. use 't' prefix
-- Gitsigns
vim.keymap.set('n', 'th', ':Gitsigns preview_hunk_inline<CR>', { silent = true })
keymap_w_repeat('n', 'tj', 'Gitsigns nav_hunk next')

-- Telescope
vim.keymap.set('n', 'td', ':Telescope diagnostic<CR>', { silent = true })
vim.keymap.set('n', 'tf', ':Telescope find_files<CR>', { silent = true })
vim.keymap.set('n', 'ty', ':Telescope live_grep<CR>', { silent = true })

-- LSP
vim.keymap.set('n', '<Space>', ':lua vim.lsp.buf.hover()<CR>', { silent = true })

-- Terminal
vim.keymap.set('t', '<C-p>', '<C-Bslash><C-N><C-c>', { silent = true })
