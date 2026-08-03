return {
    {
        "olimorris/onedarkpro.nvim",
        lazy = false,
        priority = 1001,        -- 比 snacks（1000）高一档：等优先级时 lazy 加载顺序不确定，
                                -- 让配色确定地先于 snacks 加载
        config = function()
            require("onedarkpro").setup({
                options = {
                    cursorline = true,
                },
            })
            vim.cmd.colorscheme("onedark")
        end,
    },
}
