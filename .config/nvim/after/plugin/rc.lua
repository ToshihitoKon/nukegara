-- vim.g.moonflyTransparent = true
-- vim.cmd.colorscheme "moonfly"
require("catppuccin").setup({
    flavour = "mocha",
    transparent_background = true,
    integrated = {
        -- https://github.com/catppuccin/nvim?tab=readme-ov-file#integrations
        cmp = true,
        gitsigns = true,
        mason = true,
        neotree = true,
        native_lsp = {
            enabled = true,
            virtual_text = {
                errors = { "italic" },
                hints = { "italic" },
                warnings = { "italic" },
                information = { "italic" },
                ok = { "italic" },
            },
            underlines = {
                errors = { "underline" },
                hints = { "underline" },
                warnings = { "underline" },
                information = { "underline" },
                ok = { "underline" },
            },
            inlay_hints = {
                background = true,
            },
        },
    }
})
vim.cmd.colorscheme "catppuccin"

require('neo-tree').setup()
require('lualine').setup({
    options = {
        theme = "catppuccin"
    }
})
require('scrollview').setup({
    excluded_filetypes = {},
    current_only = true,
    base = 'right',
    -- column = 80,
    signs_overflow = 'left',
    signs_on_startup = { 'all' },
    diagnostics_severities = { vim.diagnostic.severity.ERROR }
})
require('neoscroll').setup()
require("go").setup()
require('nvim_comment').setup()
require('diagflow').setup({
    -- https://github.com/dgagn/diagflow.nvim
    enable = true,
    scope = 'line', -- 'cursor', 'line' this changes the scope, so instead of showing errors under the cursor, it shows errors on the entire line
    -- padding_top = 2,
    padding_right = 4,
    -- show_borders = true,
    format = function(diagnostic)
        return string.format("%s (%s: %s)", diagnostic.message, diagnostic.source, diagnostic.code)
    end,
})

require 'nvim-treesitter.configs'.setup {
    auto_install = true,
    highlight = {
        enable = true,
    },
}

require("hlchunk").setup({
    chunk = {
        enable = true,
        duration = 0,
        delay = 0,
    },
    indent = {
        enable = true,
        delay = 0,
        style = {
            "#444444"
        },
        chars = {
            "│",
        },
    }
})
require 'rainbow_csv'.setup()
local cmp = require('cmp')

-- local capabilities = require('cmp_nvim_lsp').default_capabilities()
-- local lspkind = require('lspkind')

require('telescope-ag').setup()

-- 1. LSP Sever management
require('mason').setup()
require('mason-lspconfig').setup()
require("lsp-format").setup()

require('mason-lspconfig').setup_handlers({
    function(server_name)
        vim.o.signcolumn = "yes:1"
        require('lspconfig')[server_name].setup({
            on_attach = require("lsp-format").on_attach,
            -- capabilities = capabilities,
        })
    end,
})

-- 2. Formatter
require("conform").setup({
    formatters_by_ft = {
        yaml = { "yamlfmt" }
    },
    format_on_save = {
        timeout_ms = 500,
        lsp_format = "fallback",
    },
})

-- 3. Completion
cmp.setup({
    snippet = {
        expand = function(args)
            vim.snippet.expand(args.body) -- For native neovim snippets (Neovim v0.10+)
        end,
    },
    window = {
        -- completion = cmp.config.window.bordered(),
        -- documentation = cmp.config.window.bordered(),
    },
    mapping = cmp.mapping.preset.insert({
        -- ['<C-b>'] = cmp.mapping.scroll_docs(-4),
        -- ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-p>'] = cmp.mapping.select_next_item(),
        ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
    }),
    sources = cmp.config.sources({
        { name = 'nvim_lsp' },
    }),
    -- formatting = {
    --     format = lspkind.cmp_format()
    -- }
})

-- diagnostic Format
vim.diagnostic.config({
    virtual_text = {
        format = function(diagnostic)
            return string.format("%s", diagnostic.code)
        end,
    },
})
