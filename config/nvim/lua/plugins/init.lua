---@diagnostic disable: undefined-global
-- This file can be loaded by calling `lua require('plugins')` from your init.vim

local function bootstrap_pckr()
    local pckr_path = vim.fn.stdpath("data") .. "/pckr/pckr.nvim"

    if not (vim.uv or vim.loop).fs_stat(pckr_path) then
        vim.fn.system({
            'git',
            'clone',
            "--filter=blob:none",
            'https://github.com/lewis6991/pckr.nvim',
            pckr_path
        })
    end

    vim.opt.rtp:prepend(pckr_path)
end

bootstrap_pckr()

require('pckr').add {
    -- core
    {
        "nvim-neo-tree/neo-tree.nvim",
        tag = "3.33",
        requires = {
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
            -- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
        },
        lazy = false, -- neo-tree will lazily load itself
    },
    { "karb94/neoscroll.nvim" },
    { "terrortylor/nvim-comment" },
    { 'ray-x/guihua.lua' },
    { 'rcarriga/nvim-notify' },
    { 'folke/noice.nvim' },
    { "folke/trouble.nvim" },
    { "nvim-telescope/telescope.nvim" },
    { "kelly-lin/telescope-ag" },
    { 'nvim-treesitter/nvim-treesitter', { 'do', ':TSUpdate' } },
    { 'akinsho/toggleterm.nvim', tag = '*' },
    { 'tpope/vim-repeat' },

    -- lsp
    { 'neovim/nvim-lspconfig' },
    { "mason-org/mason.nvim" },
    { "mason-org/mason-lspconfig.nvim" },
    { 'rachartier/tiny-inline-diagnostic.nvim' },
    { 'nvimdev/lspsaga.nvim' },
    { 'hrsh7th/nvim-cmp' },
    { 'hrsh7th/cmp-nvim-lsp' },
    { 'hrsh7th/cmp-buffer' },
    { 'hrsh7th/cmp-path' },
    { 'hrsh7th/cmp-cmdline' },
    { 'onsails/lspkind.nvim' },

    -- ai_tools
    { 'lewis6991/gitsigns.nvim' },
    {
        'ruifm/gitlinker.nvim',
        requires = 'nvim-lua/plenary.nvim'
    },
    -- { 'github/copilot.vim' },
    { 'zbirenbaum/copilot.lua' },
    { 'zbirenbaum/copilot-cmp' },
    {
        'greggh/claude-code.nvim',
        requires = {
            'nvim-lua/plenary.nvim', -- Required for git operations
        }
    },

    -- formatting
    { "stevearc/conform.nvim" },

    -- extras
    { "catppuccin/nvim", as = "catppuccin" },
    { "nvim-tree/nvim-web-devicons" },
    { 'cameron-wags/rainbow_csv.nvim' },
    { 'nvim-lualine/lualine.nvim' },
    { 'shellRaining/hlchunk.nvim' },
    { 'luukvbaal/statuscol.nvim' },
    { "dstein64/nvim-scrollview" },
    {
        "goolord/alpha-nvim",
        dependencies = { 'nvim-tree/nvim-web-devicons' },
    },
    { 'folke/which-key.nvim' },
    { 'mattn/emmet-vim' },
    { 'simeji/winresizer' },
}
