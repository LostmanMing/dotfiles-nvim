-- 撤销树浮窗：把 Neovim 0.12 内置包 nvim.undotree 画在居中浮窗里，并补一套选择器式交互。
-- 内置行为只有"光标移动即静默应用"（浏览 = 立即生效，没有确认/取消）；这里在浮动封装上补：
--   光标浏览   → 实时应用（保持插件机制，所见即所得；树里状态即缓冲区状态）
--   ⏎          → 采纳当前保存点并关闭
--   q / Esc    → 放弃浏览，恢复打开前的保存点，并关闭
--   再按 <leader>ut → 直接关闭（保留浏览到的状态）
-- 关键细节：浮窗必须 enter=false 创建——undotree.open() 把树窗记录在"当前 buffer"上
-- （vim.b[buf].nvim_undotree），抢焦点会让记录挂到树 buffer 自己身上，导致
-- 从代码窗再按 <leader>ut 关不掉。绘制完成后再手动聚焦树窗。
local M = {}

local function open_float()
    local buf = vim.api.nvim_create_buf(false, true)
    local width = math.max(44, math.floor(vim.o.columns * 0.45))
    local height = math.max(12, math.floor(vim.o.lines * 0.6))
    local win = vim.api.nvim_open_win(buf, false, {
        relative = "editor",
        width = width,
        height = height,
        row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
        col = math.floor((vim.o.columns - width) / 2),
        style = "minimal",
        -- 不显式给 border：继承全局 'winborder'（options.lua 里统一 rounded）
        title = " UndoTree · ⏎ 确认 · q 取消 ",
        title_pos = "center",
    })
    return win, buf
end

-- 当前 buffer 上是否已记录着打开的树窗（与 undotree.open 的关闭条件一致）
local function existing_tree_win(buf)
    for _, var in ipairs({ "nvim_undotree", "nvim_is_undotree" }) do
        local w = vim.b[buf][var]
        if w and vim.api.nvim_win_is_valid(w) then return w end
    end
end

local function close_win(w)
    if vim.api.nvim_win_is_valid(w) then vim.api.nvim_win_close(w, true) end
end

function M.toggle()
    vim.cmd.packadd("nvim.undotree")
    local undotree = require("undotree")

    local src = vim.api.nvim_get_current_buf()
    local w = existing_tree_win(src)
    if w then
        close_win(w)   -- 直接关：保留浏览到的状态
        return
    end

    local start_seq = vim.fn.undotree(src).seq_cur   -- 打开前的保存点，q/Esc 取消用

    local win, buf = open_float()
    undotree.open({ winid = win, bufnr = buf })
    vim.api.nvim_set_current_win(win)

    -- 选择器式交互：buffer-local，随树 buffer（bufhidden=wipe）关闭自动消失
    local function cancel()
        if start_seq then
            vim.api.nvim_buf_call(src, function()
                vim.cmd.undo { start_seq, mods = { silent = true } }
            end)
        end
        close_win(win)
    end
    vim.keymap.set("n", "<CR>", function() close_win(win) end,
        { buffer = buf, desc = "采纳此保存点并关闭" })
    vim.keymap.set("n", "q", cancel,
        { buffer = buf, desc = "放弃浏览，恢复打开前的保存点" })
    vim.keymap.set("n", "<Esc>", cancel,
        { buffer = buf, desc = "放弃浏览，恢复打开前的保存点" })
end

return M
