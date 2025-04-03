---@diagnostic disable: undefined-global
-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- optionally enable 24-bit colour
vim.opt.termguicolors = true

-- Clipboard
vim.opt.clipboard = "unnamedplus"

vim.opt.backspace = "indent,eol,start"
vim.opt.wildmenu = true
vim.opt.cmdheight = 1
vim.opt.laststatus = 2
vim.opt.showcmd = true
vim.opt.hlsearch = true
vim.opt.hidden = true
vim.opt.backup = true
vim.opt.backupdir = os.getenv("HOME") .. '/.vim/backup'
vim.opt.swapfile = false
vim.opt.winblend = 20
vim.opt.pumblend = 20
vim.opt.termguicolors = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.number = true
vim.opt.wrap = false
vim.opt.nrformats = "bin,hex"
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.modeline = true
vim.opt.cursorline = true
vim.opt.mouse = ''
vim.opt.scrolloff = 5

vim.opt.background = "dark"


vim.api.nvim_create_autocmd('ColorScheme', {
    callback = function()
        vim.api.nvim_set_hl(0, 'CopilotSuggestion', {
            fg = '#555555',
            underdotted = true,
            ctermfg = 8,
            force = true
        })
    end
})
