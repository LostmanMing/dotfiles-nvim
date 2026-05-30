return {
    {
        "stevearc/oil.nvim",
        keys = {
            { "-", "<cmd>Oil<CR>", desc = "打开文件管理器" },
        },
        config = function()
            require("oil").setup({
                default_file_explorer = true,
                delete_to_trash = true,
                skip_confirm_for_simple_edits = true,
                view_options = { show_hidden = true },
            })
        end,
    },
}
