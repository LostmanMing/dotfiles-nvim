return {
    {
        "aserowy/tmux.nvim",
        lazy = false,                   -- 必须立即加载，否则按键映射不生效
        config = function()
            require("tmux").setup({
                navigation = {
                    enable_default_keybindings = true,    -- 启用默认 Ctrl+hjkl
                },
                -- 不接管剪贴板，用我们的 pbcopy/pbpaste 配置
                clipboard = {
                    enable = false,
                },
            })
        end,
    },
}
