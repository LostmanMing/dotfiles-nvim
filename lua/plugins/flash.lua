return {
    {
        "folke/flash.nvim",
        event = "VeryLazy",
        opts = {},
        keys = {
            { "<leader>s", mode = { "n", "x", "o" }, function()
                -- 允许普通文件和终端（终端普通模式）里用；其它特殊 buffer（Telescope 等）不激活
                if vim.bo.buftype ~= "" and vim.bo.buftype ~= "terminal" then return end
                require("flash").jump()
            end, desc = "Flash 字符跳转" },
            { "<leader>S", mode = { "n", "x", "o" }, function()
                if vim.bo.buftype ~= "" and vim.bo.buftype ~= "terminal" then return end
                require("flash").treesitter()
            end, desc = "Flash 选中语法节点" },
        },
    },
}
