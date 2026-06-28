return {
    {
        "nvim-telescope/telescope.nvim",
        commit = "5255aa27c422de944791318024167ad5d40aad20",
        cmd = "Telescope",
        dependencies = {
            "nvim-lua/plenary.nvim",
            {
                "nvim-telescope/telescope-fzf-native.nvim",
                build = "make",
            },
        },
        keys = {
            { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "找文件" },
            { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "搜文本" },
            { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "搜 buffer" },
            { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "帮助" },
            { "<leader>fr", "<cmd>Telescope oldfiles<CR>", desc = "最近文件" },
            { "<leader>fs", "<cmd>Telescope git_status<CR>", desc = "Git 状态" },
            { "<leader>fd", "<cmd>Telescope diagnostics<CR>", desc = "诊断" },
            { "<leader>fo", "<cmd>Telescope resume<CR>", desc = "恢复上次搜索" },
        },
        opts = {
            defaults = {
                path_display = { "truncate" },
                initial_mode = "normal",
            },
            pickers = {
                find_files = {
                    hidden = true,
                },
            },
        },
        config = function(_, opts)
            require("telescope").setup(opts)
            pcall(function()
                require("telescope").load_extension("fzf")
            end)
        end,
    },
}
