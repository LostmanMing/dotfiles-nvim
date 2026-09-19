-- 撤销树侧栏：Neovim 0.12 内置包 nvim.undotree 的包装（默认 30vnew，'splitright' 下落右侧）。
-- 交互（内置只有"光标移动即静默应用"）：
--   光标浏览   → 实时应用（所见即所得）
--   ⏎          → 采纳当前保存点并关闭
--   q / Esc    → 放弃浏览，恢复打开前的保存点，并关闭
--   再按 <leader>ut → 直接关闭（保留浏览到的状态）
-- 历史决策（勿再改）：2026-09 试过居中浮窗——浮窗遮住代码窗，浏览保存点时看不到
-- 改动详情，折回侧栏（树与代码窗并排才看得到 diff）。
local M = {}

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

    undotree.open()                                  -- 默认 30vnew；插件自己聚焦新窗
    local win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_get_current_buf()
    vim.wo[win].winbar = " ⏎ 确认 · q 取消 "        -- 侧栏没有浮窗标题，操作提示放 winbar

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
