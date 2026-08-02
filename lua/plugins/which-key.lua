return {
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        opts = {
            spec = {
                -- 前缀分组标签（弹窗里显示组名而非一串未命名项）
                { "<leader>f", group = "find" },
                { "<leader>g", group = "git" },
                { "<leader>t", group = "terminal" },
                { "<leader>x", group = "diagnostics" },
                { "<leader>c", group = "code" },
                { "<leader>m", group = "markdown" },
            },
        },
    },
}
