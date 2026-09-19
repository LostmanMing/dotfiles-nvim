-- 撤销树浮窗：把 Neovim 0.12 内置包 nvim.undotree 画在居中浮窗里（与仓库统一观感）。
-- 内置的 :Undotree 用 30vnew 竖窗；undotree.open() 支持传 winid/bufnr，这里自建浮窗 +
-- scratch buffer 再交给它绘制。
-- 关键细节：浮窗必须 enter=false 创建——open() 会把树窗记录在"当前 buffer"上
-- （vim.b[buf].nvim_undotree），抢占焦点会让记录挂到树 buffer 自己身上，导致
-- 从代码窗再按 <leader>ut 关不掉。绘制完成后我们再手动聚焦树窗。
-- 关闭：再按 <leader>ut 从任何一侧关（这里直接复刻插件的关闭动作），
-- 树窗里按 q 也会被智能关闭的浮窗分支关掉（config/quit.lua）。
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
        title = " UndoTree ",
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

function M.toggle()
    vim.cmd.packadd("nvim.undotree")
    local undotree = require("undotree")

    local w = existing_tree_win(vim.api.nvim_get_current_buf())
    if w then
        vim.api.nvim_win_close(w, true)   -- 复刻插件关闭动作（含树 buffer wipe）
        return
    end

    local win, buf = open_float()
    undotree.open({ winid = win, bufnr = buf })
    vim.api.nvim_set_current_win(win)     -- 绘制完成后聚焦树窗，光标移动即切换保存点
end

return M
