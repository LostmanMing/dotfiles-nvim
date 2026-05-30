return {
    {
        "akinsho/toggleterm.nvim",
        version = "*",
        cmd = "ToggleTerm",
        keys = {
            { "<leader>tt", "<cmd>ToggleTerm<CR>", desc = "切换终端" },
            { "<leader>tf", "<cmd>ToggleTerm direction=float<CR>", desc = "浮动终端" },
            { "<leader>th", "<cmd>ToggleTerm direction=horizontal<CR>", desc = "水平终端" },
            { "<leader>tv", "<cmd>ToggleTerm direction=vertical<CR>", desc = "垂直终端" },
        },
        opts = {
            size = 20,
            open_mapping = [[<c-\>]],
            hide_numbers = true,
            start_in_insert = true,
            insert_mappings = true,
            persist_size = true,
            direction = "float",
            close_on_exit = true,
            shell = vim.o.shell,
            float_opts = {
                border = "curved",
                winblend = 0,
            },
        },
    },
}
