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
            keymaps = {
                disable_defaults = false,
                view = {
                    { "n", "<Tab>",   function() require("diffview.actions").select_next_entry() end, { desc = "下一个文件" } },
                    { "n", "<S-Tab>", function() require("diffview.actions").select_prev_entry() end, { desc = "上一个文件" } },
                },
                file_panel = {
                    { "n", "s", function() require("diffview.actions").toggle_stage_entry() end, { desc = "stage/unstage" } },
                    { "n", "S", function() require("diffview.actions").stage_all() end, { desc = "stage 全部" } },
                    { "n", "U", function() require("diffview.actions").unstage_all() end, { desc = "unstage 全部" } },
                },
            },
        },
    },
}
