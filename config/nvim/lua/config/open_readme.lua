---@diagnostic disable: undefined-global

local function is_cwd(path)
    return vim.uv.fs_realpath(path) == vim.uv.fs_realpath(vim.fn.getcwd())
end

-- VimEnter で README を開いても、neo-tree がディレクトリの乗っ取りで後から窓のバッファを
-- 差し替えるため、ディレクトリのバッファが読み込まれる前に引数ごと捨てる
if vim.fn.argc() == 1 and is_cwd(vim.fn.argv(0)) then
    local dir_buf = vim.api.nvim_get_current_buf()
    vim.cmd('%argdelete')
    vim.cmd.enew()
    vim.api.nvim_buf_delete(dir_buf, { force = true })
end

local function find_readme()
    local readmes = vim.tbl_filter(function(path)
        -- 空ファイルだと、直後に動く alpha が空バッファと判定してダッシュボードで上書きする
        return vim.fn.getfsize(path) > 0
    end, vim.fn.glob('README.*', false, true))
    if vim.tbl_contains(readmes, 'README.md') then
        return 'README.md'
    end
    return readmes[1]
end

vim.api.nvim_create_autocmd('VimEnter', {
    -- nested がないと README の FileType などが発火せず、ハイライトや LSP が付かない
    nested = true,
    callback = function()
        if vim.fn.argc() > 0 then return end
        for _, arg in ipairs(vim.v.argv) do
            if arg == '-c' or vim.startswith(arg, '+') then return end
        end
        local is_blank_buffer = vim.api.nvim_buf_get_name(0) == ''
            and vim.api.nvim_buf_line_count(0) == 1
            and vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == ''
        if not is_blank_buffer then return end

        local readme = find_readme()
        if readme then
            vim.cmd.edit(vim.fn.fnameescape(readme))
        end
    end,
})
