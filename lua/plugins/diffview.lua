return {
    {
        "sindrets/diffview.nvim",
        cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFileHistory" },
        keys = {
            { "<leader>gv", "<cmd>DiffviewOpen<CR>",          desc = "Diffview 打开" },
            { "<leader>gV", "<cmd>DiffviewClose<CR>",         desc = "Diffview 关闭" },
            { "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", desc = "当前文件历史" },
            { "<leader>gH", "<cmd>DiffviewFileHistory<CR>",   desc = "仓库历史" },
        },
        config = function()
            local actions = require("diffview.actions")
            require("diffview").setup({
                enhanced_diff_hl = true,
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
                        { "n", "<Tab>",   actions.select_next_entry, { desc = "下一个文件" } },
                        { "n", "<S-Tab>", actions.select_prev_entry, { desc = "上一个文件" } },
                        { "n", "]c",      actions.next_conflict,     { desc = "下一个冲突" } },
                        { "n", "[c",      actions.prev_conflict,     { desc = "上一个冲突" } },
                        { "n", "zR",      "zR",                       { desc = "展开全部折叠" } },
                        { "n", "zM",      "zM",                       { desc = "折叠全部" } },
                        { "n", "za",      "za",                       { desc = "切换折叠" } },
                        { "n", "<leader>e", actions.toggle_files,    { desc = "切换文件面板" } },
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
