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
    -- Color scheme
    { "catppuccin/nvim",              as = "catppuccin" },
    { "nvim-tree/nvim-web-devicons" },

    -- Style
    { 'cameron-wags/rainbow_csv.nvim' },
    { 'rcarriga/nvim-notify' },
    { 'folke/noice.nvim' },
    { 'nvim-lualine/lualine.nvim' },
    { 'shellRaining/hlchunk.nvim' },
    { 'lewis6991/gitsigns.nvim' },
    { 'luukvbaal/statuscol.nvim' },

    -- Neo-tree
    {
        "nvim-neo-tree/neo-tree.nvim",
        -- branch = "v3.x",
        tag = "3.33",
        requires = {
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
            -- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
        },
        lazy = false, -- neo-tree will lazily load itself
    },

    { "dstein64/nvim-scrollview" },
    { "karb94/neoscroll.nvim" },
    { "terrortylor/nvim-comment" },
    { 'ray-x/guihua.lua' }, -- recommended if need floating window support
    { 'nvim-treesitter/nvim-treesitter', { 'do', ':TSUpdate' } },

    -- copilot
    { 'github/copilot.vim' },

    -- Claude Code
    {
        'greggh/claude-code.nvim',
        requires = {
            'nvim-lua/plenary.nvim', -- Required for git operations
        }
    },

    -- lsp
    { 'neovim/nvim-lspconfig' },
    { "mason-org/mason.nvim" },
    { "mason-org/mason-lspconfig.nvim" },
    { 'rachartier/tiny-inline-diagnostic.nvim' },
    { 'nvimdev/lspsaga.nvim' },

    -- formatter
    { "stevearc/conform.nvim" },

    -- completion
    { 'hrsh7th/nvim-cmp' },
    { 'hrsh7th/cmp-nvim-lsp' },
    { 'onsails/lspkind.nvim' },
    { 'hrsh7th/cmp-buffer' },
    { 'hrsh7th/cmp-path' },
    { 'hrsh7th/cmp-cmdline' },

    -- utils
    { 'folke/which-key.nvim' },
    {
        "goolord/alpha-nvim",
        dependencies = { 'nvim-tree/nvim-web-devicons' },
    },
    {
        'akinsho/toggleterm.nvim',
        tag = '*'
    },
    { "nvim-telescope/telescope.nvim" },
    { "kelly-lin/telescope-ag" },
    {
        'ruifm/gitlinker.nvim',
        requires = 'nvim-lua/plenary.nvim'
    },
    { "folke/trouble.nvim" },
    { 'simeji/winresizer' },

    -- お遊び
}
