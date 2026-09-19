-- 智能关闭（q）状态机 + BufEnter 自动退出。
-- 从 keymaps.lua 拆出：q 键与 BufEnter 自动退出共享同一套逻辑（is_tree_buf、
-- 写盘兜底、scope 查询）。行为契约（勿改）：
--   顺序：浮窗 → split 窗 → diff → tab → buffer → 全退
--   Neo-tree 上按 q 视为"切到代码窗"，永不通过 q 关闭
--   所有 file buffer 关完后自动 qa（避免 tree 独占）
local M = {}

local function is_tree_buf(buf)
    buf = buf == 0 and vim.api.nvim_get_current_buf() or buf
    return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "neo-tree"
end

-- 全退前把所有可写且已修改的 buffer 写盘，避免 qa! 静默丢掉隐藏 buffer 的改动
local function save_all_and_quit()
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(b) and vim.bo[b].modified
            and require("config.util").is_writable_file_buf(b) then
            vim.api.nvim_buf_call(b, function() pcall(vim.cmd, "silent write") end)
        end
    end
    vim.cmd("qa!")
end

-- 关 tab 前先把这个 tab 里改过的 buffer 写盘，然后关。
-- 背景：tabclose 之后，只属于这个 tab 的 buffer 会变成「活着但哪儿都不列出」的
-- 僵尸——实测关掉 tab 后那个文件既不 buflisted、也不在 scope 的 cache 里，
-- 连 <leader>fB 都搜不到（文件本身在磁盘上，重新 <leader>ff 打开即可，不算丢）。
-- options.lua 的 AutoSave 事件实际已经覆盖了绝大多数情况，这里再写一遍纯粹是给
-- "关掉就够不着了"这条不可逆路径兜底，
-- 和 save_all_and_quit 在 qa! 前兜一遍是同一个理由。
-- 在 scope.nvim 下 buflisted 就等于「属于当前 tab」，所以直接扫 buflisted 即可。
function M.save_tab_and_close()
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[b].buflisted and vim.api.nvim_buf_is_loaded(b) and vim.bo[b].modified
            and require("config.util").is_writable_file_buf(b) then
            vim.api.nvim_buf_call(b, function() pcall(vim.cmd, "silent write") end)
        end
    end
    vim.cmd("tabclose")
end

-- 这个 buffer 在别的 tab 里是否也开着。
-- 用途：buffer 已经按 tab 隔离（scope.nvim），而 nvim_buf_delete 是**全局**的，
-- 对着一个两个 tab 都开着的文件按 q，会让它从另一个 tab 里一起消失（实测过：
-- 在 tab2 关 f1，回 tab1 后 f1 没了）。这种情况只在本 tab 取消列出就够了。
-- scope.core.cache 是 tab handle -> buffer 列表，scope 自带的 telescope 扩展也读它。
local function open_in_other_tab(buf)
    local ok, core = pcall(require, "scope.core")
    if not ok then return false end
    local cur_tab = vim.api.nvim_get_current_tabpage()
    for tab, bufs in pairs(core.cache) do
        if tab ~= cur_tab and vim.api.nvim_tabpage_is_valid(tab) then
            for _, b in ipairs(bufs) do
                if b == buf then return true end
            end
        end
    end
    return false
end

-- q 主回调（键位注册在 keymaps.lua）
function M.smart_close()
    -- 光标在 Neo-tree 内 → focus 到右侧代码窗，不关 tree
    if is_tree_buf(0) then
        vim.cmd("wincmd l")
        return
    end

    local function is_floating(winnr)
        local config = vim.api.nvim_win_get_config(winnr)
        return config.relative ~= ""
    end

    -- Diffview：检测当前 tab 是否由 Diffview 占据；是则用其自带 close
    local function in_diffview_tab()
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            local buf = vim.api.nvim_win_get_buf(win)
            local name = vim.api.nvim_buf_get_name(buf)
            if name:match("^diffview://") or vim.bo[buf].filetype:match("^Diffview") then
                return true
            end
        end
        return false
    end
    if in_diffview_tab() then
        pcall(vim.cmd, "DiffviewClose")
        return
    end

    -- gitsigns / 原生 :diffsplit 的 diff 模式：把所有处于 diff 的窗口一起关掉
    if vim.wo.diff then
        local closed = 0
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            if vim.api.nvim_win_is_valid(win) and vim.wo[win].diff then
                pcall(vim.api.nvim_win_close, win, false)
                closed = closed + 1
            end
        end
        if closed > 0 then return end
    end

    -- 浮窗：关浮窗（pcall 防御 buffer modified 报错）
    if is_floating(0) then
        local ok = pcall(vim.cmd, "close")
        if not ok then pcall(vim.cmd, "close!") end
        return
    end

    -- 统计非浮窗 + 非 tree 的窗口数
    local non_tree_wins = 0
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local buf = vim.api.nvim_win_get_buf(win)
        if not is_floating(win) and not is_tree_buf(buf) then
            non_tree_wins = non_tree_wins + 1
        end
    end

    -- 收集 listed buffer。scope.nvim 让 buflisted 本身就是 tab 作用域的
    -- （切 tab 时把不属于该 tab 的 buffer 置为 unlisted），所以这里照常数全局
    -- buflisted 就等于"当前 tab 的 buffer"，不需要额外过滤。
    local listed = {}
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[b].buflisted and vim.api.nvim_buf_is_loaded(b) then
            table.insert(listed, b)
        end
    end

    -- 自动保存（可写的、有文件名的普通 buffer）
    if require("config.util").is_writable_file_buf() then
        pcall(vim.cmd, "silent write")
    end

    if non_tree_wins > 1 then
        vim.cmd("hide")             -- 关当前 split，留 buffer
    elseif #listed > 1 then
        -- 删 buffer 前先把当前窗口切到另一个 listed buffer，
        -- 否则 nvim 在删除当前 buffer 时可能让 tree 独占空间
        local cur = vim.api.nvim_get_current_buf()
        local target
        -- 优先回到「刚才来的那个文件」：gd/gf 等跳转会把原文件设成 alternate（#），
        -- q 关掉跳转目标后就该退回它，而不是编号最小的第一个 buffer。
        -- alternate 是全局的、可能指向别的 tab 的文件，但那种情况下它在当前 tab
        -- 是 unlisted（scope.nvim 干的），下面的 buflisted 判断已经把它挡掉了。
        local alt = vim.fn.bufnr("#")
        if alt > 0 and alt ~= cur
            and vim.api.nvim_buf_is_loaded(alt) and vim.bo[alt].buflisted then
            target = alt
        else
            for _, b in ipairs(listed) do
                if b ~= cur then
                    target = b
                    break
                end
            end
        end
        if target then
            vim.api.nvim_win_set_buf(0, target)
            if open_in_other_tab(cur) then
                vim.bo[cur].buflisted = false    -- 别的 tab 还在用，只在本 tab 隐藏
            else
                pcall(vim.api.nvim_buf_delete, cur, { force = false })
            end
        else
            vim.cmd("bdelete")
        end
    else
        -- 这个 tab 已经没内容可留了（只剩一个窗口、且没有别的 listed buffer）。
        -- tabclose 必须放在删 buffer 之后：放前面会让「有 2+ 个 tab」时 q 完全
        -- 关不掉 buffer（buffer 一直堆积），而且在分屏那个 tab 里收到最后一个
        -- 窗口再按 q 会把你正在用的 tab 关掉、人被丢到另一个 tab 去。
        -- 想主动关掉某个 tab 用 <leader><Tab>d，不走 q。
        if vim.fn.tabpagenr("$") > 1 then
            M.save_tab_and_close()
        else
            save_all_and_quit()     -- 最后一个 → 全退（先写盘所有已改 buffer，tree 跟着退）
        end
    end
end

-- 自动退出：当除了 Neo-tree（和浮窗）外没有任何窗口在显示内容时整体 qa
-- 注：不能用 listed buffer 计数判断——预览压缩包等 unlisted buffer 时 listed 会是 0，
-- 但归档窗口仍在，会被误判为“只剩 tree”而错误退出。改为按窗口判断。
vim.api.nvim_create_autocmd("BufEnter", {
    group = vim.api.nvim_create_augroup("SmartQuitAutoExit", { clear = true }),
    callback = function()
        if not is_tree_buf(0) then return end
        local other_wins = 0
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            local cfg = vim.api.nvim_win_get_config(win)
            local buf = vim.api.nvim_win_get_buf(win)
            if cfg.relative == "" and not is_tree_buf(buf) then
                other_wins = other_wins + 1
            end
        end
        if other_wins == 0 then
            save_all_and_quit()
        end
    end,
})

return M
