---@diagnostic disable: undefined-global

vim.api.nvim_create_autocmd('ColorScheme', {
    callback = function()
        vim.api.nvim_set_hl(0, 'CopilotSuggestion', {
            fg = '#555555',
            underdotted = true,
            ctermfg = 8,
            force = true
        })
    end
})
