---@diagnostic disable: undefined-global

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
        },
        filtered_items = {
            hide_gitignored = false,
            hide_ignored = false,
        },
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

require('toggleterm').setup({
    open_mapping = [[<C-f>]],
    direction = 'float',
    float_opts = {
        border = 'double',
        title_pos = 'left',
        winblend = 20,
    },
})

require('neoscroll').setup({
    mappings = {
        '<C-u>', '<C-d>',
    }
})

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

-- Trouble: LSP Diagnostics viewer
require('trouble').setup {}

require("telescope").setup {}
require('telescope').load_extension('noice')
require('telescope-ag').setup()

require 'nvim-treesitter.configs'.setup {
    auto_install = true,
    highlight = {
        enable = true,
    },
}
