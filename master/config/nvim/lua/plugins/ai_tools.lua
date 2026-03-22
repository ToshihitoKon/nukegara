---@diagnostic disable: undefined-global

require('gitsigns').setup()
require('gitlinker').setup()

-- LLM Support tools
require("copilot").setup({
    panel = {
        enabled = false,
    },
    suggestion = {
        enabled = false,
    }
})

require("copilot_cmp").setup()

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
