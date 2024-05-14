require("catppuccin").setup({
    flavour = "mocha", -- latte, frappe, macchiato, mocha
    transparent_background = true, -- disables setting the background color.
})
vim.cmd.colorscheme "catppuccin"

require('lualine').setup()
require('scrollbar').setup()
require('neoscroll').setup()
require("go").setup()
require('nvim_comment').setup()
require("lsp-format").setup()

-- 1. LSP Sever management
require('mason').setup()
require('mason-lspconfig').setup()
require('mason-lspconfig').setup_handlers({
    function(server_name)
        vim.o.signcolumn = "yes:1"
        require('lspconfig')[server_name].setup({
            on_attach = require("lsp-format").on_attach
        })
    end,
})
