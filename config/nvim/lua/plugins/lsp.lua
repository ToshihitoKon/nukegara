---@diagnostic disable: undefined-global

-- diagnostic Format
vim.diagnostic.config({
    virtual_text = false,
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = '●',
            [vim.diagnostic.severity.WARN] = '●',
        },
    },
})

require('tiny-inline-diagnostic').setup({
    preset = "modern",
    options = {
        format = function(diagnostic)
            return string.format("[%s/%s]\n%s", diagnostic.source, tostring(diagnostic.code), diagnostic.message)
        end,
        show_source = {
            enabled = true,
            if_many = false,
        },
        use_icons_from_diagnostic = true,
        set_arrow_to_diag_color = true,
        show_all_diags_on_cursorline = true,
    },
})

-- LSP Sever management
require('mason').setup()
require('mason-lspconfig').setup({})
require('lspsaga').setup({
    lightbulb = {
        enable = false,
    },
})

-- Completion
local cmp = require('cmp')
local lspkind = require('lspkind')
lspkind.init({
    symbol_map = {
        Copilot = "",
    },
})

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
        { name = "copilot", group_index = 2 },
        { name = 'nvim_lsp' },
        { name = 'path' }
    }),
    formatting = {
        format = lspkind.cmp_format({
            mode = 'symbol',          -- show only symbol annotations
            maxwidth = {
                menu = 50,            -- leading text (labelDetails)
                abbr = 50,            -- actual suggestion item
            },
            ellipsis_char = '...',    -- when popup menu exceed maxwidth, the truncated part would show ellipsis_char instead (must define maxwidth first)
            show_labelDetails = true, -- show labelDetails in menu. Disabled by default
            before = function(entry, vim_item)
                return vim_item
            end
        })
    }
})

cmp.setup.cmdline(':', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
        { name = 'path' },
        { name = 'cmdline' }
    }),
    matching = { disallow_symbol_nonprefix_matching = false }
})

vim.api.nvim_create_user_command("LspDeleteLog", function()
    local log_path = vim.lsp.get_log_path()
    os.remove(log_path)
end, {
    desc = "Delete LSP log file",
})
