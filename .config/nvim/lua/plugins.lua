---@diagnostic disable: undefined-global
-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
    -- use { '' }
    -- Packer can manage itself
    use 'wbthomason/packer.nvim'

    -- Color schema
    use { "catppuccin/nvim", as = "catppuccin" }
    -- use { "bluz71/vim-moonfly-colors", as = "moonfly" }

    -- status line
    use { 'nvim-tree/nvim-web-devicons' }
    use { 'nvim-lualine/lualine.nvim', }

    use {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        requires = {
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
            -- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
        }
    }
    -- use { "petertriho/nvim-scrollbar" }
    use { "dstein64/nvim-scrollview" }
    use { 'karb94/neoscroll.nvim' }
    use { "terrortylor/nvim-comment" }
    use { 'ray-x/guihua.lua' } -- recommended if need floating window support
    use { 'nvim-treesitter/nvim-treesitter' }

    -- copliot
    use { 'github/copilot.vim' }
    use { 'CopilotC-Nvim/CopilotChat.nvim' }

    -- lsp
    use { 'neovim/nvim-lspconfig' }
    use { "williamboman/mason.nvim" }
    use { "williamboman/mason-lspconfig.nvim" }
    use { "lukas-reineke/lsp-format.nvim" }
    use { 'dgagn/diagflow.nvim' }

    -- formatter
    use { "stevearc/conform.nvim" }

    -- completion
    use { 'hrsh7th/nvim-cmp' }
    use { 'hrsh7th/cmp-nvim-lsp' }
    -- use { 'onsails/lspkind.nvim' }

    -- golang
    use { 'ray-x/go.nvim' }

    -- utils
    use { 'shellRaining/hlchunk.nvim' }
    use({
        "kelly-lin/telescope-ag",
        requires = { "nvim-telescope/telescope.nvim" },
    })
    use { 'cameron-wags/rainbow_csv.nvim' }
    use { 'lewis6991/gitsigns.nvim' }
end)
