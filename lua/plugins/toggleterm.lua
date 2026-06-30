return {
    {
        "akinsho/toggleterm.nvim",
        version = "*",
        keys = {
            { "<leader>tt", "<cmd>4ToggleTerm direction=tab<CR>", desc = "全屏终端" },
            { "<leader>tf", "<cmd>1ToggleTerm direction=float<CR>", desc = "浮动终端" },
            { "<leader>th", "<cmd>2ToggleTerm direction=horizontal<CR>", desc = "水平终端" },
            { "<leader>tv", "<cmd>3ToggleTerm direction=vertical<CR>", desc = "垂直终端" },
        },
        config = function(_, opts)
            require("toggleterm").setup(opts)
            vim.keymap.set("t", "<C-]>", function()
                local terms = require("toggleterm.terminal").get_all()
                if #terms < 2 then return end
                local cur = require("toggleterm.terminal").get(tonumber(vim.b.toggle_number))
                local idx
                for i, t in ipairs(terms) do
                    if t.id == cur.id then idx = i break end
                end
                local next_term = terms[idx % #terms + 1]
                cur:close()
                next_term:open()
            end, { desc = "下一个终端" })
            vim.keymap.set("t", "<C-[>", function()
                local terms = require("toggleterm.terminal").get_all()
                if #terms < 2 then return end
                local cur = require("toggleterm.terminal").get(tonumber(vim.b.toggle_number))
                local idx
                for i, t in ipairs(terms) do
                    if t.id == cur.id then idx = i break end
                end
                local prev_term = terms[(idx - 2) % #terms + 1]
                cur:close()
                prev_term:open()
            end, { desc = "上一个终端" })
            vim.keymap.set("t", "<C-n>", function()
                local terminal = require("toggleterm.terminal")
                local cur = terminal.get(tonumber(vim.b.toggle_number))
                local dir = (cur and cur.direction) or "float"
                local new_id = #terminal.get_all() + 1
                vim.cmd(new_id .. "ToggleTerm direction=" .. dir)
                vim.schedule(function() vim.cmd("startinsert") end)
            end, { desc = "新建终端（继承当前方向）" })
            vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { desc = "退出到 normal 模式" })
        end,
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
