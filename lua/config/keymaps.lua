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
-- 按 bufferline 可视顺序切换，并跳过目录和工具 buffer
local function cycle_file_buffer(direction)
    local buffers = {}
    for _, element in ipairs(require("bufferline").get_elements().elements) do
        if type(element.id) == "number" and require("config.util").is_file_buf(element.id) then
            table.insert(buffers, element.id)
        end
    end

    local current = vim.api.nvim_get_current_buf()
    local index
    for i, buf in ipairs(buffers) do
        if buf == current then
            index = i
            break
        end
    end
    if not index or #buffers < 2 then return end

    vim.api.nvim_set_current_buf(buffers[(index - 1 + direction) % #buffers + 1])
end

vim.keymap.set("n", "H", function() cycle_file_buffer(-1) end, { desc = "上一个文件 buffer" })
vim.keymap.set("n", "L", function() cycle_file_buffer(1) end, { desc = "下一个文件 buffer" })

-- ==========================================
-- 智能关闭：q
-- 状态机（含写盘兜底与 BufEnter 自动退出）在 config/quit.lua
-- ==========================================
local quit = require("config.quit")
vim.keymap.set("n", "q", quit.smart_close,
    { desc = "智能关闭：tree focus 切回代码 / 浮窗 / split / tab / buffer / 整体退出" })

-- jj 退出插入模式（等效 Esc）
vim.keymap.set("i", "jj", "<Esc>", { desc = "退出插入模式" })

-- ==========================================
-- Tab（标签页）：想开新文件又不想拆掉当前分屏布局时用
-- 挂在 <leader><Tab> 而不是 <leader>t——后者已经是 terminal 组。
-- 切换可用原生 gt / gT，也可用 <leader><Tab>h/l；开文件到新 tab 用 <leader>ff
-- 再按 <C-t>（telescope 自带 select_tab）。关 tab 用 <leader><Tab>d——不走 q，
-- 因为 q 是关 buffer 的键，让它同时管 tab 会互相打架（见 config/quit.lua 里
-- tabclose 那段注释）。
-- ==========================================
vim.keymap.set("n", "<leader><Tab>n", "<cmd>tabnew<CR>", { desc = "新建 tab" })
vim.keymap.set("n", "<leader><Tab>h", "<cmd>tabprevious<CR>", { desc = "上一个 tab" })
vim.keymap.set("n", "<leader><Tab>l", "<cmd>tabnext<CR>", { desc = "下一个 tab" })
vim.keymap.set("n", "<leader><Tab>d", function()
    if vim.fn.tabpagenr("$") == 1 then
        vim.notify("只剩一个 tab，不能关", vim.log.levels.WARN, { title = "Tab" })
        return
    end
    quit.save_tab_and_close()
end, { desc = "关闭当前 tab（先写盘本 tab 的改动）" })

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

-- ==========================================
-- 诊断开关：<leader>cd
-- ==========================================
vim.keymap.set("n", "<leader>cd", function()
    local enabled = vim.diagnostic.is_enabled()
    vim.diagnostic.enable(not enabled)
    vim.notify(enabled and "诊断已关闭" or "诊断已开启", vim.log.levels.INFO, { title = "Diagnostic" })
end, { desc = "切换诊断显示" })

-- ==========================================
-- 撤销树：<leader>ut（0.12 内置包 nvim.undotree 的浮窗包装，见 config/undotree.lua）
-- 树窗内：光标移动即实时应用，⏎ 采纳关闭，q/Esc 放弃并恢复原状态
-- ==========================================
vim.keymap.set("n", "<leader>ut", function() require("config.undotree").toggle() end,
    { desc = "UndoTree" })
