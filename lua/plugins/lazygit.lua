return {
    {
        "kdheepak/lazygit.nvim",
        cmd = {
            "LazyGit",
            "LazyGitConfig",
            "LazyGitCurrentFile",
            "LazyGitFilter",
            "LazyGitFilterCurrentFile",
        },
        dependencies = { "nvim-lua/plenary.nvim" },
        keys = {
            { "<leader>gg", "<cmd>LazyGit<CR>", desc = "LazyGit" },
            { "<leader>gf", "<cmd>LazyGitCurrentFile<CR>", desc = "当前文件历史" },
        },
    },
}
