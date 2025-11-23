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

--- Toggle autoformat-on-save
--- ref: https://github.com/stevearc/conform.nvim/blob/master/doc/recipes.md#command-to-toggle-format-on-save
vim.api.nvim_create_user_command("FormatDisable", function(args)
    if args.bang then
        -- FormatDisable! will disable formatting just for this buffer
        vim.b.disable_autoformat = true
    else
        vim.g.disable_autoformat = true
    end
end, {
    desc = "Disable autoformat-on-save",
    bang = true,
})
vim.api.nvim_create_user_command("FormatEnable", function()
    vim.b.disable_autoformat = false
    vim.g.disable_autoformat = false
end, {
    desc = "Re-enable autoformat-on-save",
})

--- default: disable autoformat
vim.b.disable_autoformat = true
vim.g.disable_autoformat = true
