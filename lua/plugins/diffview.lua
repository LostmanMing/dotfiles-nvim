-- 跟踪 diffview 打开期间新引入的文件 buffer：
-- diffview 默认不清理 LOCAL（工作区）文件 buffer，导致浏览过的文件都残留在 buffer 列表。
local diff_pre = {}   -- 打开 diffview 前已存在的 buffer
local diff_seen = {}  -- diffview 本次新引入的 buffer

-- 预览：打开选中项的 diff 但焦点留在文件面板（模仿文件浏览器 l 预览、enter 打开）
local function diff_preview()
    local panel_win = vim.api.nvim_get_current_win()
    require("diffview.actions").select_entry()
    -- diff_buf_win_enter hook 会把焦点移到可编辑侧，这里 schedule 在其之后夺回焦点
    vim.schedule(function()
        if vim.api.nvim_win_is_valid(panel_win) then
            pcall(vim.api.nvim_set_current_win, panel_win)
        end
    end)
end

return {
    {
        "sindrets/diffview.nvim",
        cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFileHistory" },
        keys = {
            { "<leader>gv", "<cmd>DiffviewOpen<CR>",            desc = "Diffview 打开" },
            { "<leader>gV", "<cmd>DiffviewClose<CR>",           desc = "Diffview 关闭" },
            { "<leader>gh", "<cmd>DiffviewFileHistory %<CR>",   desc = "当前文件历史" },
            { "<leader>gH", "<cmd>DiffviewFileHistory<CR>",     desc = "仓库历史" },
        },
        opts = {
            enhanced_diff_hl = true,
            view = {
                merge_tool = { layout = "diff3_mixed", disable_diagnostics = true },
            },
            hooks = {
                -- 打开文件 diff 时把光标放到可编辑的工作区文件那侧
                -- （git 版本侧 buffer 只读，工作区文件 buffer 可修改）
                diff_buf_win_enter = function(bufnr, winid, _)
                    if vim.bo[bufnr].modifiable and not vim.bo[bufnr].readonly then
                        vim.schedule(function()
                            if vim.api.nvim_win_is_valid(winid) then
                                pcall(vim.api.nvim_set_current_win, winid)
                            end
                        end)
                    end
                end,
                -- 记录打开前已有的 buffer，避免误删用户原本就打开的文件
                view_opened = function()
                    diff_pre = {}
                    for _, b in ipairs(vim.api.nvim_list_bufs()) do
                        diff_pre[b] = true
                    end
                    diff_seen = {}
                end,
                -- diffview 读入 diff buffer 时，若是本次新引入的则记录
                diff_buf_read = function(bufnr)
                    if not diff_pre[bufnr] then
                        diff_seen[bufnr] = true
                    end
                end,
                -- 关闭 diffview 后，清理本次新引入、当前未显示的 buffer
                view_closed = function()
                    vim.schedule(function()
                        for b, _ in pairs(diff_seen) do
                            if vim.api.nvim_buf_is_valid(b)
                                and #vim.fn.win_findbuf(b) == 0 then
                                -- force=false：已修改未保存的 buffer 会报错，pcall 兜住并保留
                                pcall(vim.api.nvim_buf_delete, b, { force = false })
                            end
                        end
                        diff_seen = {}
                    end)
                end,
            },
            keymaps = {
                disable_defaults = false,
                view = {
                    { "n", "<Tab>",   function() require("diffview.actions").select_next_entry() end, { desc = "下一个文件" } },
                    { "n", "<S-Tab>", function() require("diffview.actions").select_prev_entry() end, { desc = "上一个文件" } },
                },
                file_panel = {
                    { "n", "l", diff_preview, { desc = "预览 diff（焦点留在面板）" } },
                    { "n", "s", function() require("diffview.actions").toggle_stage_entry() end, { desc = "stage/unstage" } },
                    { "n", "S", function() require("diffview.actions").stage_all() end, { desc = "stage 全部" } },
                    { "n", "U", function() require("diffview.actions").unstage_all() end, { desc = "unstage 全部" } },
                },
                file_history_panel = {
                    { "n", "l", diff_preview, { desc = "预览 diff（焦点留在面板）" } },
                },
            },
        },
    },
}
