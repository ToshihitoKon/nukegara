---@diagnostic disable: undefined-global

-- vim.g.moonflyTransparent = true
-- vim.cmd.colorscheme "moonfly"
require("catppuccin").setup({
    flavour = "mocha",
    transparent_background = true,
    integrations = {
        -- https://github.com/catppuccin/nvim?tab=readme-ov-file#integrations
        cmp = true,
        gitsigns = true,
        mason = true,
        neotree = true,
        copilot_vim = true,
        treesitter = true,
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

require('gitsigns').setup()
require('gitlinker').setup()

require('neo-tree').setup({
    close_if_last_window = false,
    sort_case_insensitive = false,

    default_component_configs = {
        git_status = {
            symbols = {
                -- NOTE: Status はいらん
                untracked = "",
                ignored   = "",
                unstaged  = "",
                staged    = "",
            }
        }
    },
    filesystem = {
        follow_current_file = {
            enable = true,
        }
    },
    source_selector = {
        winbar = true,
        statusline = true
    },
    window = {
        mappings = {
            ["<C-f>"] = false, -- use Toggleterm
        }
    },
})

local function buffer_name(buf)
    return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ':t')
end

local function alternate_buffer_name()
    local current = vim.fn.bufnr()
    local alt_buf = vim.fn.bufnr("#")
    if alt_buf == -1 or not vim.api.nvim_buf_is_valid(alt_buf) or (current == alt_buf) then
        return ""
    end
    return "alt: " .. buffer_name(alt_buf)
end

require('lualine').setup({
    options = {
        theme = "catppuccin",
        globalstatus = true,
    },

    extensions = { 'neo-tree', 'mason', 'toggleterm' },

    tabline = {
        lualine_a = { 'branch' },
        lualine_b = { 'tabs' },
        lualine_c = {
            'filename',
            'diagnostic',
        },
        lualine_x = {
            alternate_buffer_name
        },
        lualine_y = {},
        lualine_z = {}
    },


    -- for noice
    -- https://github.com/folke/noice.nvim?tab=readme-ov-file#-statusline-components
    sections = {
        lualine_x = {
            {
                require("noice").api.status.message.get_hl,
                cond = require("noice").api.status.message.has,
            },
            {
                require("noice").api.status.command.get,
                cond = require("noice").api.status.command.has,
                color = { fg = "#ff9e64" },
            },
            {
                require("noice").api.status.mode.get,
                cond = require("noice").api.status.mode.has,
                color = { fg = "#ff9e64" },
            },
            {
                require("noice").api.status.search.get,
                cond = require("noice").api.status.search.has,
                color = { fg = "#ff9e64" },
            },
        },
    },
})

require('toggleterm').setup({
    open_mapping = [[<C-f>]],
    direction = 'float',
    float_opts = {
        border = 'double',
        title_pos = 'left',
        winblend = 20,
    },
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

require('neoscroll').setup({
    mappings = {
        '<C-u>', '<C-d>',
    }
})

require("go").setup()
require("go.format").goimports()
require('nvim_comment').setup()
vim.notify = require("notify")
vim.notify.setup({
    background_colour = "#000000",
    render = "wrapped-compact",
    stages = "static",
    top_down = false

})

require("noice").setup({
    cmdline = {
        view = "cmdline_popup",
    },
    lsp = {
        -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
        override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
            ["vim.lsp.util.stylize_markdown"] = true,
            -- ["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
        },
    },
    -- you can enable a preset for easier configuration
    presets = {
        bottom_search = true,          -- use a classic bottom cmdline for search
        command_palette = true,        -- position the cmdline and popupmenu together
        long_message_to_split = false, -- long messages will be sent to a split
        inc_rename = false,            -- enables an input dialog for inc-rename.nvim
        lsp_doc_border = false,        -- add a border to hover docs and signature help
    },
})

require("telescope").setup {}
require('telescope').load_extension('noice')

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


require('claude-code').setup {
    keymaps = {
        toggle = {
            normal = "<C-Bslash>",   -- Normal mode keymap for toggling Claude Code, false to disable
            terminal = "<C-Bslash>", -- Terminal mode keymap for toggling Claude Code, false to disable
        },
        window_navigation = true,    -- Enable window navigation keymaps (<C-h/j/k/l>)
        scrolling = true,            -- Enable scrolling keymaps (<C-f/b>) for page up/down
    }
}

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
        ruby = { "rubocop" },
        yaml = { "prettier" },
        typescript = { "prettier" },
        json = { "prettier" },
        javascript = { "prettier" },
        terraform = { "terraform fmt" }
    },
    format_on_save = {
        timeout_ms = 2000,
        lsp_format = "fallback",
    },
})

-- 3. Completion
local cmp = require('cmp')
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

    cmp.setup.cmdline(':', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
            { name = 'path' }
        }, {
            { name = 'cmdline' }
        }),
        matching = { disallow_symbol_nonprefix_matching = false }
    })
})
