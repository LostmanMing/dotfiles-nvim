return {
    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",                         -- 模块名是 ibl，需显式指定
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            -- 当前作用域竖线的高亮：亮蓝加粗（主题里默认色太淡，看不出区别）
            -- 必须通过 ibl 的 HIGHLIGHT_SETUP 钩子注册，换 colorscheme 后也能自动重建
            local hooks = require("ibl.hooks")
            hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
                vim.api.nvim_set_hl(0, "IblScopeBold", { fg = "#61afef", bold = true })
            end)

            require("ibl").setup({
                indent = { char = "│" },          -- 各缩进层级：细灰竖线
                scope = {                          -- 光标所在代码块（treesitter 作用域）
                    enabled = true,
                    char = "┃",                    -- 粗字形，和普通层级区分
                    highlight = "IblScopeBold",    -- 亮蓝加粗
                    show_start = false,            -- 不在作用域首尾加下划线
                    show_end = false,
                },
            })
        end,
    },
}
