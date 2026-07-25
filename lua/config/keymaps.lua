-- ==========================================
-- 快捷键设置
-- ==========================================

-- Leader 键
vim.g.mapleader = " "              -- 前缀键设为空格
vim.g.maplocalleader = " "         -- 本地前缀键同样
vim.keymap.set({ "n", "x" }, " ", "<Nop>", { desc = "禁用空格原生行为" })

-- 窗口导航 Ctrl+hjkl：由 vim-tmux-navigator 接管（nvim 分屏 → tmux 面板无缝跳转）

-- 分屏：\ 垂直，- 水平
vim.keymap.set("n", "\\", "<C-w>v", { desc = "垂直分屏" })
vim.keymap.set("n", "-", "<C-w>s", { desc = "水平分屏" })

-- 窗口大小调整：Shift + 方向键
vim.keymap.set("n", "<S-Up>",    "<cmd>resize +2<CR>", { desc = "窗口增高" })
vim.keymap.set("n", "<S-Down>",  "<cmd>resize -2<CR>", { desc = "窗口变矮" })
vim.keymap.set("n", "<S-Left>",  "<cmd>vertical resize -2<CR>", { desc = "窗口变窄" })
vim.keymap.set("n", "<S-Right>", "<cmd>vertical resize +2<CR>", { desc = "窗口变宽" })

-- ==========================================
-- Buffer 切换
-- ==========================================
-- 按 bufferline 可视顺序切换（bnext/bprev 按编号排序，可能与标签栏顺序不一致）
vim.keymap.set("n", "H", "<cmd>BufferLineCyclePrev<CR>", { desc = "上一个 buffer" })
vim.keymap.set("n", "L", "<cmd>BufferLineCycleNext<CR>", { desc = "下一个 buffer" })

-- ==========================================
-- 智能关闭：q
-- 顺序：浮窗 → split 窗 → file buffer → 全退
-- nvim-tree 上按 q 视为"切到代码窗"，永不通过 q 关闭
-- 所有 file buffer 关完后自动 qa（避免 tree 独占）
-- ==========================================
local function is_tree_buf(buf)
    -- 插件没加载时 buffer 不可能是树；且避免 require 触发 lazy 提前加载 nvim-tree
    if not package.loaded["nvim-tree"] then return false end
    local ok, tree_api = pcall(require, "nvim-tree.api")
    if not ok then return false end
    return tree_api.tree.is_tree_buf(buf)
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

vim.keymap.set("n", "q", function()
    -- 光标在 nvim-tree 内 → focus 到右侧代码窗，不关 tree
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

    -- 收集 listed buffer
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
        for _, b in ipairs(listed) do
            if b ~= cur then
                target = b
                break
            end
        end
        if target then
            vim.api.nvim_win_set_buf(0, target)
            pcall(vim.api.nvim_buf_delete, cur, { force = false })
        else
            vim.cmd("bdelete")
        end
    else
        save_all_and_quit()         -- 最后一个 → 全退（先写盘所有已改 buffer，tree 跟着退）
    end
end, { desc = "智能关闭：tree focus 切回代码 / 浮窗 / split / buffer / 整体退出" })

-- 自动退出：当除了 nvim-tree（和浮窗）外没有任何窗口在显示内容时整体 qa
-- 注：不能用 listed buffer 计数判断——预览压缩包等 unlisted buffer 时 listed 会是 0，
-- 但归档窗口仍在，会被误判为“只剩 tree”而错误退出。改为按窗口判断。
vim.api.nvim_create_autocmd("BufEnter", {
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

-- jj 退出插入模式（等效 Esc）
vim.keymap.set("i", "jj", "<Esc>", { desc = "退出插入模式" })

-- 把宏录制移到 gq
vim.keymap.set("n", "gq", "q", { desc = "开始宏录制" })
vim.keymap.set("x", "q", "<Esc>", { desc = "退出 visual 模式" })

-- ==========================================
-- 清除搜索高亮：Esc
-- ==========================================
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "清除搜索高亮" })

-- ==========================================
-- F1 禁用（避免误触打开 help）
-- ==========================================
vim.keymap.set({ "n", "i" }, "<F1>", "<Nop>", { desc = "禁用 F1" })

-- ==========================================
-- gh：悬浮显示文档 + 诊断
-- ==========================================
vim.keymap.set("n", "gh", function()
    local diags = vim.diagnostic.get(0, { lnum = vim.api.nvim_win_get_cursor(0)[1] - 1 })
    if #diags > 0 then
        vim.diagnostic.open_float()
    else
        vim.lsp.buf.hover()
    end
end, { desc = "显示文档/诊断信息" })
