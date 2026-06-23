return {
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "master",   -- master 分支：预编译 parser，无需本地 tree-sitter CLI
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
                indent = { enable = true },
            })
        end,
    },
}
