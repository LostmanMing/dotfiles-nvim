return {
    {
        "akinsho/toggleterm.nvim",
        version = "*",
        keys = {
            { "<leader>tt", function() require("config.terminal").open_dir("tab", 4) end, desc = "全屏终端" },
            { "<leader>tf", function() require("config.terminal").open_dir("float", 1) end, desc = "浮动终端" },
            { "<leader>th", function() require("config.terminal").open_dir("horizontal", 2) end, desc = "水平终端" },
            { "<leader>tv", function() require("config.terminal").open_dir("vertical", 3) end, desc = "垂直终端" },
        },
        config = function(_, opts)
            require("toggleterm").setup(opts)
            -- 状态机（最近聚焦记忆 / 环切 / gf / on_exit）在 config/terminal.lua
            require("config.terminal").setup()
        end,
        opts = {
            size = 20,
            open_mapping = [[<c-\>]],
            hide_numbers = true,
            persist_mode = true,
            persist_size = true,
            direction = "float",
            close_on_exit = true,
            shell = vim.o.shell,
            -- 退出终端时：若同方向还有其它终端，聚焦到剩余的最后一个；
            -- 只有同方向终端全没了，才自然返回普通 buffer（实现见 config/terminal.lua）
            on_exit = function(term) require("config.terminal").on_exit(term) end,
            float_opts = {
                border = "curved",
                winblend = 0,
            },
        },
    },
}
