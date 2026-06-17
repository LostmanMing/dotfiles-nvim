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
-- ==========================================
vim.keymap.set("n", "q", function()
    -- 判断是否有浮窗
    local function is_floating(winnr)
        local config = vim.api.nvim_win_get_config(winnr)
        return config.relative ~= "" or config.zindex ~= nil
    end

    -- 统计非浮窗的窗口数
    local win_count = 0
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.api.nvim_win_get_height(win) ~= -1
            and vim.api.nvim_win_get_width(win) ~= -1
            and not is_floating(win) then
            win_count = win_count + 1
        end
    end

    -- 统计有名字的 buffer 数
    local listed_bufs = 0
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[b].buflisted and vim.api.nvim_buf_is_loaded(b) then
            listed_bufs = listed_bufs + 1
        end
    end

    if win_count > 1 or is_floating(0) then
        -- 多窗口 → 关闭当前窗口
        vim.cmd("hide")
    elseif listed_bufs > 1 then
        -- 多 buffer → 关闭当前 buffer
        vim.cmd("bdelete")
    else
        -- 最后一个 → 可写的且有文件名的先保存，然后退出
        if vim.bo.modifiable and vim.bo.buftype == "" and vim.api.nvim_buf_get_name(0) ~= "" then
            vim.cmd("write")
        end
        vim.cmd("quit!")
    end
end, { desc = "智能关闭：窗→buffer→退出" })

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
