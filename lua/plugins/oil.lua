return {
    {
        "stevearc/oil.nvim",
        keys = {
            { "-", function()
                local ok, api = pcall(require, "nvim-tree.api")
                if ok and api.tree.is_visible() then api.tree.close() end
                vim.cmd("Oil")
            end, desc = "打开文件管理器" },
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
