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
