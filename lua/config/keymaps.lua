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
-- 顺序：浮窗 → split 窗 → file buffer → 全退
-- Neo-tree 上按 q 视为"切到代码窗"，永不通过 q 关闭
-- 所有 file buffer 关完后自动 qa（避免 tree 独占）
-- ==========================================
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
-- config.autosave 的全局保存事件实际已经覆盖了绝大多数情况，这里再写一遍纯粹是给
-- "关掉就够不着了"这条不可逆路径兜底，
-- 和 save_all_and_quit 在 qa! 前兜一遍是同一个理由。
-- 在 scope.nvim 下 buflisted 就等于「属于当前 tab」，所以直接扫 buflisted 即可。
local function save_tab_and_close()
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

vim.keymap.set("n", "q", function()
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
            save_tab_and_close()
        else
            save_all_and_quit()     -- 最后一个 → 全退（先写盘所有已改 buffer，tree 跟着退）
        end
    end
end, { desc = "智能关闭：tree focus 切回代码 / 浮窗 / split / tab / buffer / 整体退出" })

-- 自动退出：当除了 Neo-tree（和浮窗）外没有任何窗口在显示内容时整体 qa
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

-- ==========================================
-- Tab（标签页）：想开新文件又不想拆掉当前分屏布局时用
-- 挂在 <leader><Tab> 而不是 <leader>t——后者已经是 terminal 组。
-- 切换可用原生 gt / gT，也可用 <leader><Tab>h/l；开文件到新 tab 用 <leader>ff
-- 再按 <C-t>（telescope 自带 select_tab）。关 tab 用 <leader><Tab>d——不走 q，
-- 因为 q 是关 buffer 的键，让它同时管 tab 会互相打架（见上面 tabclose 那段注释）。
-- ==========================================
vim.keymap.set("n", "<leader><Tab>n", "<cmd>tabnew<CR>", { desc = "新建 tab" })
vim.keymap.set("n", "<leader><Tab>h", "<cmd>tabprevious<CR>", { desc = "上一个 tab" })
vim.keymap.set("n", "<leader><Tab>l", "<cmd>tabnext<CR>", { desc = "下一个 tab" })
vim.keymap.set("n", "<leader><Tab>d", function()
    if vim.fn.tabpagenr("$") == 1 then
        vim.notify("只剩一个 tab，不能关", vim.log.levels.WARN, { title = "Tab" })
        return
    end
    save_tab_and_close()
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
