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
            enabled = true,
            leave_dirs_open = true,
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

-- local builtin = require('telescope.builtin')
local actions = require ('telescope.actions')
require("telescope").setup {
    defaults = {
        mappings = {
            i = {
                ["<C-j>"] = actions.move_selection_next,
                ["<C-k>"] = actions.move_selection_previous,
                ["<C-u>"] = actions.results_scrolling_up,
                ["<C-d>"] = actions.results_scrolling_down,
            }
        },
        preview = {
            filesize_limit = 0.1, -- MB
        },
        layout_strategy = "center",
        layout_config = {
          center = {
            height = 0.4,
            width = 0.8,
            preview_cutoff = 0,
            prompt_position = "top",
          },
        },
    },
    pickers = {
    },
    extensions = {}
}

require('telescope').load_extension('noice')
require('telescope-ag').setup()

-- nvim-treesitter (main ブランチ / Neovim 0.12 新 API)
-- 旧 require('nvim-treesitter.configs').setup{} は廃止。
-- パーサーは install で明示管理し、ハイライトは FileType で vim.treesitter.start() する。
require('nvim-treesitter').install({
    'bash', 'css', 'csv', 'dockerfile', 'embedded_template', 'git_config',
    'git_rebase', 'gitcommit', 'gitignore', 'go', 'gomod', 'gosum', 'groovy',
    'hcl', 'html', 'ini', 'java', 'javascript', 'json', 'jsonc', 'jsonnet',
    'lua', 'make', 'markdown', 'nginx', 'properties', 'python', 'rego', 'ruby',
    'scss', 'sql', 'ssh_config', 'svelte', 'tera', 'terraform', 'tmux', 'toml',
    'tsx', 'typescript', 'vim', 'vimdoc', 'xml', 'yaml',
})

vim.api.nvim_create_autocmd('FileType', {
    callback = function(args)
        -- パーサーが存在する filetype だけハイライトを開始する。
        -- 未対応 filetype で start() を呼ぶと no parser エラーになるため pcall で保護。
        pcall(vim.treesitter.start, args.buf)
    end,
})
