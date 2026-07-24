-- 跟踪 diffview 打开期间新引入的文件 buffer：
-- diffview 默认不清理 LOCAL（工作区）文件 buffer，导致浏览过的文件都残留在 buffer 列表。
-- 用 open_views 计数支持并发 view（如 DiffviewOpen + DiffviewFileHistory 同时开），
-- 只在首个 view 打开时快照、最后一个 view 关闭时清理，避免误清或泄漏。
local diff_pre = {}    -- 首个 view 打开前已存在的 buffer
local diff_seen = {}   -- diffview 期间新引入的 buffer
local open_views = 0   -- 当前打开的 diffview view 数量
local hint_off = {}    -- 被 diffview 临时关掉 inlay hint 的 buffer（关闭后恢复）

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

-- 关掉某 buffer 的 inlay hint（diffview 里参数名等 hint 会与 git 侧对不齐）
local function kill_inlay_hints(bufnr)
    if vim.api.nvim_buf_is_valid(bufnr)
        and vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }) then
        vim.lsp.inlay_hint.enable(false, { bufnr = bufnr })
        hint_off[bufnr] = true
    end
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
                -- 进入 diff buffer 窗口时关掉 inlay hint（参数名等会与 git 侧对不齐）
                -- 延迟再关一次，应对 LSP 异步 attach 后才启用 hint
                diff_buf_win_enter = function(bufnr, _, _)
                    kill_inlay_hints(bufnr)
                    vim.defer_fn(function() kill_inlay_hints(bufnr) end, 200)
                end,
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
                    local off = hint_off
                    hint_off = {}
                    vim.schedule(function()
                        for b, _ in pairs(seen) do
                            if vim.api.nvim_buf_is_valid(b)
                                and #vim.fn.win_findbuf(b) == 0 then
                                -- force=false：已修改未保存的 buffer 会报错，pcall 兜住并保留
                                pcall(vim.api.nvim_buf_delete, b, { force = false })
                            end
                        end
                        -- 恢复被临时关掉的 inlay hint（buffer 仍在的）
                        for b, _ in pairs(off) do
                            if vim.api.nvim_buf_is_valid(b) then
                                pcall(vim.lsp.inlay_hint.enable, true, { bufnr = b })
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
