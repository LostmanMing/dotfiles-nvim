-- TODO/FIX/HACK 等注释关键词的高亮与检索
return {
    {
        "folke/todo-comments.nvim",
        -- 打开文件时才加载：高亮是按 buffer 生效的，启动阶段没有意义
        event = { "BufReadPost", "BufNewFile" },
        dependencies = { "nvim-lua/plenary.nvim" },
        keys = {
            -- 用函数而非命令：jump_next/jump_prev 可按关键词过滤，命令式没有这个能力
            { "]t", function() require("todo-comments").jump_next() end, desc = "下一个 TODO" },
            { "[t", function() require("todo-comments").jump_prev() end, desc = "上一个 TODO" },
            { "<leader>xt", "<cmd>Trouble todo toggle<CR>", desc = "TODO 列表" },
            { "<leader>ft", "<cmd>TodoTelescope<CR>", desc = "搜索 TODO" },
        },
        opts = {},      -- 默认关键词：FIX TODO HACK WARN PERF NOTE TEST
    },
}
