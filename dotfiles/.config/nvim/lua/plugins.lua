-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
    -- Packer can manage itself
    use 'wbthomason/packer.nvim'
    -- Color schema
    -- use {"catppuccin/nvim", as = "catppuccin"}
    use { "bluz71/vim-moonfly-colors", as = "moonfly" }

    -- status line
    use {
        'nvim-lualine/lualine.nvim',
        requires = { 'nvim-tree/nvim-web-devicons', opt = true }
    }
    use {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        requires = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
            "MunifTanjim/nui.nvim",
            -- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
        }
    }
    use { "petertriho/nvim-scrollbar" }
    use { 'karb94/neoscroll.nvim' }
    use { "terrortylor/nvim-comment" }
    use { 'ray-x/guihua.lua' } -- recommended if need floating window support
    use { 'nvim-treesitter/nvim-treesitter' }
    -- lsp
    use { 'neovim/nvim-lspconfig' }
    use { "williamboman/mason.nvim" }
    use { "williamboman/mason-lspconfig.nvim" }
    use { "lukas-reineke/lsp-format.nvim" }

    -- golang
    use { 'ray-x/go.nvim' }
end)
