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

local common = {
    -- core
    {
        "nvim-neo-tree/neo-tree.nvim",
        -- tag = "3.33",
        requires = {
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
            -- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
        },
        lazy = false, -- neo-tree will lazily load itself
    },
    { "karb94/neoscroll.nvim" },
    { 'ray-x/guihua.lua' },
    { 'rcarriga/nvim-notify' },
    { 'folke/noice.nvim' },
    { "nvim-telescope/telescope.nvim" },
    { "kelly-lin/telescope-ag" },
    { 'nvim-treesitter/nvim-treesitter', branch = 'main' },
    { 'akinsho/toggleterm.nvim', tag = '*' },
    { 'tpope/vim-repeat' },

    -- lsp
    { 'neovim/nvim-lspconfig' },
    { "mason-org/mason.nvim" },
    { "mason-org/mason-lspconfig.nvim" },

    -- git
    { 'lewis6991/gitsigns.nvim' },
    {
        'ruifm/gitlinker.nvim',
        requires = 'nvim-lua/plenary.nvim'
    },
    { 'gh-tui-tools/gh-review.nvim' },

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
    { 'simeji/winresizer' },
    { 'OXY2DEV/markview.nvim' },
    { 'folke/zen-mode.nvim' },
}

local editing = {
    { "terrortylor/nvim-comment" },
    { "folke/trouble.nvim" },

    -- lsp
    { 'rachartier/tiny-inline-diagnostic.nvim' },
    { 'nvimdev/lspsaga.nvim' },
    { 'hrsh7th/nvim-cmp' },
    { 'hrsh7th/cmp-nvim-lsp' },
    { 'hrsh7th/cmp-buffer' },
    { 'hrsh7th/cmp-path' },
    { 'hrsh7th/cmp-cmdline' },
    { 'onsails/lspkind.nvim' },

    -- ai_tools
    -- { 'github/copilot.vim' },
    { 'zbirenbaum/copilot.lua' },
    { 'zbirenbaum/copilot-cmp' },

    -- formatting
    { "stevearc/conform.nvim" },

    { 'mattn/emmet-vim' },
}

local review = {
    { 'dlyongemallo/diffview-plus.nvim', tag = '*' },
}

-- 登録から外すと :Pckr sync の clean で削除されるため、登録は残してロードだけ止める
local function disable_loading(specs)
    for _, spec in ipairs(specs) do
        spec.cond = function() end
    end
end

if require('config.profile').is_review then
    disable_loading(editing)
else
    disable_loading(review)
end

require('pckr').add(vim.list_extend(vim.list_extend(common, editing), review))
