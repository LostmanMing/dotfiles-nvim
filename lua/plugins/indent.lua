return {
    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",                         -- 模块名是 ibl，需显式指定
        event = { "BufReadPre", "BufNewFile" },
        opts = {
            indent = { char = "│" },          -- 各缩进层级的竖线
            scope = {                          -- 当前作用域高亮（依赖 treesitter）
                enabled = true,
                show_start = false,            -- 不在作用域首尾加下划线
                show_end = false,
            },
        },
    },
}
