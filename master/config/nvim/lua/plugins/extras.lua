---@diagnostic disable: undefined-global

-- Color scheme (must be set up before lualine)
require("catppuccin").setup({
    flavour = "mocha",
    transparent_background = true,
    integrations = {
        -- https://github.com/catppuccin/nvim?tab=readme-ov-file#integrations
        cmp = true,
        gitsigns = true,
        mason = true,
        neotree = true,
        -- copilot_vim = true,
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

-- alpha
local startify = require("alpha.themes.startify")
startify.file_icons.provider = "devicons"
require("alpha").setup(
    startify.config
)

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

local builtin = require('statuscol.builtin')
require('statuscol').setup({
    relculright = true,
    bt_ignore = { 'terminal', 'nofile' },
    segments = {
        {
            sign = {
                namespace = { 'gitsigns' },
            },
        },
        {
            sign = {
                namespace = { 'diagnostic' },
            },
        },
        {
            text = { builtin.lnumfunc },
        },
        { text = { ' ' } },
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
