return {
    {
        "folke/flash.nvim",
        event = "VeryLazy",
        opts = {},
        keys = {
            { "<leader>s", mode = { "n", "x", "o" }, function() require("flash").jump() end,      desc = "Flash 字符跳转" },
            { "<leader>S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash 选中语法节点" },
        },
    },
}
