---@diagnostic disable: undefined-global

local function find_diff_pair()
    local wins = vim.tbl_filter(function(win)
        return vim.wo[win].diff
    end, vim.api.nvim_tabpage_list_wins(0))
    if #wins ~= 2 then
        return nil, nil
    end
    table.sort(wins, function(a, b)
        return vim.api.nvim_win_get_position(a)[2] < vim.api.nvim_win_get_position(b)[2]
    end)
    return wins[1], wins[2]
end

local function restore_wrap(win)
    if vim.w[win].diff_saved_wrap == nil then
        return
    end
    vim.wo[win].wrap = vim.w[win].diff_saved_wrap
    vim.w[win].diff_saved_wrap = nil
end

-- 閉じると diffopt の closeoff で diff 自体が解除されるため、閉じずに幅 1 まで縮める
local function show_only(shown, hidden)
    restore_wrap(shown)
    -- カーソルのあるウィンドウは 'winwidth' 未満に縮められないため、先に表示する側へ移る
    vim.api.nvim_set_current_win(shown)

    -- 幅 1 で wrap が有効だと 1 行が縦に長く折り返されるため、縮める側だけ切る
    if vim.w[hidden].diff_saved_wrap == nil then
        vim.w[hidden].diff_saved_wrap = vim.wo[hidden].wrap
    end
    vim.wo[hidden].wrap = false
    vim.api.nvim_win_set_width(hidden, 1)
end

local function show_both(left, right)
    restore_wrap(left)
    restore_wrap(right)
    local total_width = vim.api.nvim_win_get_width(left) + vim.api.nvim_win_get_width(right)
    vim.api.nvim_win_set_width(left, math.floor(total_width / 2))
end

local function with_diff_pair(fn)
    return function()
        local left, right = find_diff_pair()
        if not left then
            vim.notify('左右 2 つの diff ウィンドウが見つかりません', vim.log.levels.WARN)
            return
        end
        fn(left, right)
    end
end

vim.keymap.set('n', 'g[', with_diff_pair(function(left, right) show_only(left, right) end),
    { desc = 'diff: 左だけ表示' })
vim.keymap.set('n', 'g]', with_diff_pair(function(left, right) show_only(right, left) end),
    { desc = 'diff: 右だけ表示' })
vim.keymap.set('n', 'g.', with_diff_pair(show_both), { desc = 'diff: 左右を同じ幅に戻す' })

require('diffview').setup()
vim.keymap.set('n', 'tgd', ':DiffviewOpen<CR>', { silent = true })
vim.keymap.set('n', 'tgh', ':DiffviewFileHistory %<CR>', { silent = true })
vim.keymap.set('n', 'tgq', ':DiffviewClose<CR>', { silent = true })
