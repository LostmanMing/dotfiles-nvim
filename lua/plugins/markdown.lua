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
        opts = {
            -- 默认会把标题图标也插到 sign 列，而那一列（statuscolumn 的 left 区）只有一格，
            -- 已经归 todo-comments 的 TODO/FIX 图标和 m{a-z} 书签，会互相顶掉。
            -- 标题图标本来就在行内 overlay 显示，sign 列纯属重复。
            sign = { enabled = false },
            -- 标题上下加横线：配合默认 width=full 的整行背景，观感接近排版好的文档
            heading = {
                border = true,
                -- 不要图标：默认的 󰲡󰲣󰲥 圆圈数字字形太重、不好看。
                -- 空串配 position="overlay"（默认）会把 '#' 覆盖成等宽空格，于是每级
                -- 标题天然左缩进一格，层级靠「缩进阶梯 + 整行背景色带」表达，没有字形噪音。
                -- 注意不能写成 icons = {}：那样 cycle 返回 nil，'#' 不会被遮、会露出原文。
                -- 代价：foregrounds（H1~H6 各自的色）只作用于图标，去掉图标后就不生效了，
                -- 而 H2~H4 的背景色都是很接近的深灰，实际主要靠缩进区分层级。
                icons = { "", "", "", "", "", "" },
            },
            -- 表格边框用圆角字符，与 winborder=rounded 的浮窗风格统一
            pipe_table = { preset = "round" },
            -- HTML 注释默认被整块隐藏（html.comment.conceal 缺省 true），渲染后
            -- 那几行只剩空白。但 <!-- --> 里常放的是 SPDX 版权头、翻译说明、
            -- 术语约定这类真要读的内容，隐藏了反而找不到，所以关掉。
            html = { comment = { conceal = false } },
        },
    },
}
