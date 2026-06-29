return {
    {
        "folke/flash.nvim",
        event = "VeryLazy",
        opts = {},
        keys = {
            { "<leader>s", mode = { "n", "x", "o" }, function()
                if vim.bo.buftype ~= "" then return end  -- Telescope 等特殊 buffer 里不激活
                require("flash").jump()
            end, desc = "Flash 字符跳转" },
            { "<leader>S", mode = { "n", "x", "o" }, function()
                if vim.bo.buftype ~= "" then return end
                require("flash").treesitter()
            end, desc = "Flash 选中语法节点" },
        },
    },
}
