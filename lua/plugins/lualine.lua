return {
    {
        "nvim-lualine/lualine.nvim",
        event = "VeryLazy",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {
            options = {
                theme = "onedark",
                globalstatus = true,   -- 全局状态栏，与 laststatus=3 一致
            },
        },
    },
}
