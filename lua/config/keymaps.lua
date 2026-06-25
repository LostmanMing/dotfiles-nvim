-- ==========================================
-- 快捷键设置
-- ==========================================

-- Leader 键
vim.g.mapleader = " "              -- 前缀键设为空格
vim.g.maplocalleader = " "         -- 本地前缀键同样
vim.keymap.set({ "n", "v" }, " ", "<Nop>", { desc = "禁用空格原生行为" })

-- ==========================================
-- 窗口导航：Ctrl + hjkl 在分割窗口间移动
-- ==========================================
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "跳到左边窗口" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "跳到下面窗口" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "跳到上面窗口" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "跳到右边窗口" })

-- 窗口大小调整：Shift + 方向键
vim.keymap.set("n", "<S-Up>",    ":resize +2<CR>", { desc = "窗口增高" })
vim.keymap.set("n", "<S-Down>",  ":resize -2<CR>", { desc = "窗口变矮" })
vim.keymap.set("n", "<S-Left>",  ":vertical resize -2<CR>", { desc = "窗口变窄" })
vim.keymap.set("n", "<S-Right>", ":vertical resize +2<CR>", { desc = "窗口变宽" })

-- ==========================================
-- Buffer 切换：<leader>hl
-- ==========================================
vim.keymap.set("n", "<leader>h", "<cmd>bprevious<CR>", { desc = "上一个 buffer" })
vim.keymap.set("n", "<leader>l", "<cmd>bnext<CR>",     { desc = "下一个 buffer" })
vim.keymap.set("n", "gb",         "<cmd>buffer #<CR>",  { desc = "切回上一个 buffer" })
vim.keymap.set("n", "<leader>q", "<cmd>bdelete<CR>", { desc = "关闭当前 buffer" })

-- ==========================================
-- 智能关闭：q
-- 顺序：浮窗 → split 窗 → file buffer → 全退
-- nvim-tree 上按 q 视为"切到代码窗"，永不通过 q 关闭
-- 所有 file buffer 关完后自动 qa（避免 tree 独占）
-- ==========================================
local function is_tree_buf(buf)
    local ok, tree_api = pcall(require, "nvim-tree.api")
    if not ok then return false end
    return tree_api.tree.is_tree_buf(buf)
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
    if vim.bo.modifiable and vim.bo.buftype == "" and vim.api.nvim_buf_get_name(0) ~= "" then
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
        vim.cmd("qa!")              -- 最后一个 → 全退（tree 跟着退）
    end
end, { desc = "智能关闭：tree focus 切回代码 / 浮窗 / split / buffer / 整体退出" })

-- 自动退出：当所有 listed file buffer 都关闭，仅剩 nvim-tree 时整体 qa
vim.api.nvim_create_autocmd("BufEnter", {
    callback = function()
        if not is_tree_buf(0) then return end
        -- 当前在 tree（说明 bdelete 后切到了 tree）
        local listed = 0
        for _, b in ipairs(vim.api.nvim_list_bufs()) do
            if vim.bo[b].buflisted and vim.api.nvim_buf_is_loaded(b) then
                listed = listed + 1
            end
        end
        if listed == 0 then
            vim.cmd("qa!")
        end
    end,
})

-- jj 退出插入模式（等效 Esc）
vim.keymap.set("i", "jj", "<Esc>", { desc = "退出插入模式" })

-- 把宏录制移到 gq
vim.keymap.set("n", "gq", "q", { desc = "开始宏录制" })
vim.keymap.set("v", "q", "<Esc>", { desc = "退出 visual 模式" })

-- ==========================================
-- 清除搜索高亮：Esc
-- ==========================================
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "清除搜索高亮" })

-- ==========================================
-- 诊断跳转：[d ]d
-- ==========================================
vim.keymap.set("n", "[d", function()
    vim.diagnostic.jump({ count = -vim.v.count1 })
end, { desc = "上一个诊断" })
vim.keymap.set("n", "]d", function()
    vim.diagnostic.jump({ count = vim.v.count1 })
end, { desc = "下一个诊断" })

-- ==========================================
-- F1 禁用（避免误触打开 help）
-- ==========================================
vim.keymap.set("n", "<F1>", "", { desc = "禁用 F1" })

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
