return {
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "main",   -- v1.0 API，需要系统装 tree-sitter CLI
        lazy = false,
        build = ":TSUpdate",
        config = function()
            local parsers = {
                "c", "cpp", "python", "lua", "bash", "cmake",
                "markdown", "markdown_inline",
            }

            -- main 分支 API：显式安装 parser（已装的会跳过）
            require("nvim-treesitter").install(parsers)

            -- 进入对应 filetype 时启动 treesitter 高亮
            vim.api.nvim_create_autocmd("FileType", {
                pattern = { "c", "cpp", "python", "lua", "bash", "sh",
                            "cmake", "markdown" },
                callback = function()
                    pcall(vim.treesitter.start)
                end,
            })
        end,
    },
}
