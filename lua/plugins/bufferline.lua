return {
    {
        "akinsho/bufferline.nvim",
        version = "*",
        lazy = false,
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {
            options = {
                diagnostics = "nvim_lsp",   -- 标签上显示 LSP 诊断标记
                offsets = {                  -- 给 nvim-tree 侧栏留出区域
                    { filetype = "NvimTree", text = "Explorer", separator = true },
                },
            },
        },
    },
}
