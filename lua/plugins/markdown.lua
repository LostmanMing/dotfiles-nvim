-- Markdown 编辑器内渲染：标题、表格、复选框、引用直接显示成样式
return {
    {
        "MeanderingProgrammer/render-markdown.nvim",
        ft = { "markdown" },
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        keys = {
            { "<leader>mt", "<cmd>RenderMarkdown toggle<CR>", desc = "切换 markdown 渲染" },
        },
        -- conceallevel 由插件自己按窗口管理（渲染时设 3、离开时还原），
        -- 所以不在 options.lua 里全局设，避免污染其它文件类型。
        -- 默认 render_modes = { n, c, t }：插入模式自动显示原始文本，方便编辑。
        opts = {},
    },
}
