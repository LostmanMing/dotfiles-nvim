-- 跟踪 diffview 打开期间新引入的文件 buffer：
-- diffview 默认不清理 LOCAL（工作区）文件 buffer，导致浏览过的文件都残留在 buffer 列表。
-- 用 open_views 计数支持并发 view（如 DiffviewOpen + DiffviewFileHistory 同时开），
-- 只在首个 view 打开时快照、最后一个 view 关闭时清理，避免误清或泄漏。
local diff_pre = {}    -- 首个 view 打开前已存在的 buffer
local diff_seen = {}   -- diffview 期间新引入的 buffer
local open_views = 0   -- 当前打开的 diffview view 数量

-- 消除 keymaps 里重复的 require("diffview.actions")：返回调用对应 action 的闭包
local function da(name)
    return function() require("diffview.actions")[name]() end
end

-- l 预览（焦点留面板），<cr>/o 打开并进入右侧可编辑窗口；两个面板共用
local nav = {
    { "n", "l",    da("select_entry"), { desc = "预览 diff（焦点留在面板）" } },
    { "n", "<cr>", da("focus_entry"),  { desc = "打开 diff（进入可编辑窗口）" } },
    { "n", "o",    da("focus_entry"),  { desc = "打开 diff（进入可编辑窗口）" } },
}

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
                -- 首个 view 打开时快照已有 buffer，避免误删用户原本就打开的文件
                view_opened = function()
                    if open_views == 0 then
                        diff_pre = {}
                        for _, b in ipairs(vim.api.nvim_list_bufs()) do
                            diff_pre[b] = true
                        end
                        diff_seen = {}
                    end
                    open_views = open_views + 1
                end,
                -- diffview 读入 diff buffer 时，若是本次新引入的则记录
                diff_buf_read = function(bufnr)
                    if not diff_pre[bufnr] then
                        diff_seen[bufnr] = true
                    end
                end,
                -- 最后一个 view 关闭后，清理本次新引入、当前未显示的 buffer
                view_closed = function()
                    open_views = math.max(0, open_views - 1)
                    if open_views > 0 then return end
                    -- 先同步快照再调度，避免延迟期间被新 view 重置/污染（竞态）
                    local seen = diff_seen
                    diff_seen = {}
                    vim.schedule(function()
                        for b, _ in pairs(seen) do
                            if vim.api.nvim_buf_is_valid(b)
                                and #vim.fn.win_findbuf(b) == 0 then
                                -- force=false：已修改未保存的 buffer 会报错，pcall 兜住并保留
                                pcall(vim.api.nvim_buf_delete, b, { force = false })
                            end
                        end
                    end)
                end,
            },
            keymaps = {
                view = {
                    { "n", "<Tab>",   da("select_next_entry"), { desc = "下一个文件" } },
                    { "n", "<S-Tab>", da("select_prev_entry"), { desc = "上一个文件" } },
                },
                file_panel = vim.list_extend({
                    { "n", "s", da("toggle_stage_entry"), { desc = "stage/unstage" } },
                    { "n", "S", da("stage_all"),          { desc = "stage 全部" } },
                    { "n", "U", da("unstage_all"),        { desc = "unstage 全部" } },
                }, nav),
                file_history_panel = nav,
            },
        },
    },
}
