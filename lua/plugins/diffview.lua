return {
    {
        "sindrets/diffview.nvim",
        cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFileHistory" },
        keys = {
            { "<leader>gv", function()
                local lib = require("diffview.lib")
                local view = lib.get_current_view()
                if view then
                    -- 已打开：刷新文件列表（检测磁盘变化）
                    local actions = require("diffview.actions")
                    actions.refresh_files()
                else
                    vim.cmd("DiffviewOpen")
                end
            end, desc = "Diffview 打开/刷新" },
            { "<leader>gV", "<cmd>DiffviewClose<CR>",         desc = "Diffview 关闭" },
            { "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", desc = "当前文件历史" },
            { "<leader>gH", "<cmd>DiffviewFileHistory<CR>",   desc = "仓库历史" },
        },
        config = function()
            local actions = require("diffview.actions")
            require("diffview").setup({
                enhanced_diff_hl = true,
                file_panel = {
                    listing_style = "tree",
                },
                view = {
                    merge_tool = {
                        layout = "diff3_mixed",
                        disable_diagnostics = true,
                    },
                },
                keymaps = {
                    -- 不删插件默认键，只追加常用的
                    disable_defaults = false,

                    -- 右侧 diff 窗口
                    view = {
                        { "n", "<Tab>",     actions.select_next_entry, { desc = "下一个文件" } },
                        { "n", "<S-Tab>",   actions.select_prev_entry, { desc = "上一个文件" } },
                        { "n", "zR",        "zR",                       { desc = "展开全部折叠" } },
                        { "n", "zM",        "zM",                       { desc = "折叠全部" } },
                        { "n", "za",        "za",                       { desc = "切换折叠" } },
                        { "n", "<leader>e", actions.toggle_files,       { desc = "切换文件面板" } },
                        -- 注：[c/]c 走 vim 原生 diff 跳 hunk；冲突用 diffview 默认的 [x/]x
                    },

                    -- 左侧 file panel（git status 文件列表）
                    file_panel = {
                        { "n", "j",       actions.next_entry,         { desc = "下移" } },
                        { "n", "k",       actions.prev_entry,         { desc = "上移" } },
                        { "n", "<CR>",    actions.select_entry,       { desc = "选中查看" } },
                        { "n", "<Tab>",   actions.select_next_entry,  { desc = "下一个并打开" } },
                        { "n", "<S-Tab>", actions.select_prev_entry,  { desc = "上一个并打开" } },
                        { "n", "s",       actions.toggle_stage_entry, { desc = "stage / unstage 当前" } },
                        { "n", "S",       actions.stage_all,          { desc = "stage 全部" } },
                        { "n", "U",       actions.unstage_all,        { desc = "unstage 全部" } },
                        { "n", "X",       actions.restore_entry,      { desc = "丢弃当前文件改动（危险）" } },
                        { "n", "R",       actions.refresh_files,      { desc = "刷新" } },
                        { "n", "<leader>e", actions.toggle_files,     { desc = "切换文件面板" } },
                    },

                    -- 文件历史面板
                    file_history_panel = {
                        { "n", "j",       actions.next_entry,        { desc = "下移" } },
                        { "n", "k",       actions.prev_entry,        { desc = "上移" } },
                        { "n", "<CR>",    actions.select_entry,      { desc = "选中查看" } },
                        { "n", "<Tab>",   actions.select_next_entry, { desc = "下一个 commit" } },
                        { "n", "<S-Tab>", actions.select_prev_entry, { desc = "上一个 commit" } },
                        { "n", "y",       actions.copy_hash,         { desc = "复制 commit hash" } },
                    },
                },
            })
        end,
    },
}
