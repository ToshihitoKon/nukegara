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

if require('config.profile').is_review then
    vim.diagnostic.enable(false)
end

-- LSP Sever management
require('mason').setup()
require('mason-lspconfig').setup({})

vim.api.nvim_create_user_command("LspDeleteLog", function()
    local log_path = vim.lsp.get_log_path()
    os.remove(log_path)
end, {
    desc = "Delete LSP log file",
})
