return {
    -- 语法高亮（基于 AST）
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
        lazy = false,
        build = function()
            pcall(vim.cmd, "TSUpdate")
        end,
        config = function()
            require("nvim-treesitter").setup({
                ensure_installed = {
                    "c", "cpp", "python", "lua", "bash", "cmake", "markdown",
                    "markdown_inline",
                },
                auto_install = true,
                highlight = {
                    enable = true,
                },
            })
        end,
    },
}
