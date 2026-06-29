return {
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "master",
        lazy = false,
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter.configs").setup({
                ensure_installed = {
                    "c", "cpp", "python", "lua", "bash", "cmake",
                    "markdown", "markdown_inline",
                },
                auto_install = true,
                highlight = {
                    enable = true,
                    additional_vim_regex_highlighting = false,
                },

                incremental_selection = {
                    enable = true,
                    keymaps = {
                        init_selection = "<CR>",
                        node_incremental = "<CR>",
                        scope_incremental = "<S-CR>",
                        node_decremental = "<BS>",
                    },
                },
            })
        end,
    },

    -- Text objects (select + swap + move)
    {
        "nvim-treesitter/nvim-treesitter-textobjects",
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        lazy = false,
        config = function()
            -- swap 走 configs 集成
            require("nvim-treesitter.configs").setup({
                textobjects = {
                    swap = {
                        enable = true,
                        swap_next = { ["<leader>na"] = "@parameter.inner" },
                        swap_previous = { ["<leader>pa"] = "@parameter.inner" },
                    },
                },
            })

            local select = require("nvim-treesitter-textobjects.select")
            local move = require("nvim-treesitter-textobjects.move")
            local map = vim.keymap.set

            -- select text objects（直接绑）
            local text_objects = {
                ["af"] = "@function.outer",  ["if"] = "@function.inner",
                ["ac"] = "@class.outer",     ["ic"] = "@class.inner",
                ["al"] = "@loop.outer",      ["il"] = "@loop.inner",
                ["ap"] = "@parameter.outer", ["ip"] = "@parameter.inner",
            }
            for key, query in pairs(text_objects) do
                map({ "o", "x" }, key, function() select.select_textobject(query) end, { desc = query })
            end

            -- move（直接绑）
            map({ "n", "x", "o" }, "]f", function() move.goto_next_start("@function.outer") end, { desc = "下一个函数" })
            map({ "n", "x", "o" }, "[f", function() move.goto_previous_start("@function.outer") end, { desc = "上一个函数" })
            map({ "n", "x", "o" }, "]p", function() move.goto_next_start("@parameter.inner") end, { desc = "下一个参数" })
            map({ "n", "x", "o" }, "[p", function() move.goto_previous_start("@parameter.inner") end, { desc = "上一个参数" })
        end,
    },
}
