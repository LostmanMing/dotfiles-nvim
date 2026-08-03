-- 粘性上下文：光标滚进长函数/长循环体时，把它的签名行钉在窗口顶部，
-- 不用再往上翻去看"我现在到底在哪个函数里"。对 C++ 长实现文件收益最大。
return {
    {
        "nvim-treesitter/nvim-treesitter-context",
        event = { "BufReadPost", "BufNewFile" },
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        keys = {
            { "<leader>cc", "<cmd>TSContext toggle<CR>", desc = "切换粘性上下文" },
            -- 跳到当前上下文的起始行（比如从函数体中间跳回函数签名）
            { "[C", function() require("treesitter-context").go_to_context() end, desc = "跳到上下文起始行" },
        },
        opts = {
            max_lines = 3,              -- 最多钉 3 行：再多会吃掉正文空间
            multiline_threshold = 1,    -- 多行签名压缩成 1 行显示，避免模板参数占满顶部
            trim_scope = "outer",       -- 超出 max_lines 时优先丢最外层（保留最贴近光标的作用域）
            -- 不设 separator：分隔线会横穿整个窗口宽度、把行号列切断，而线的上下两侧
            -- 都还有行号，看着像布局裂开。改用背景色区分钉住区（见下面的高亮设置），
            -- 也是插件默认做法。
            -- 注：钉住行前面那列数字是相对行号（因为开了 relativenumber），可直接拿来跳转，
            -- 比如显示 94 就是 94k 到那一行。插件的 line_numbers 选项在当前版本是死代码，
            -- 只在 config.lua 声明、渲染逻辑从不读取，设了没用。
        },
        config = function(_, opts)
            require("treesitter-context").setup(opts)
            -- 钉住区背景比正文底色(#282c34)略亮一档，形成一个"浮起"的色块；
            -- 行号列跟着用同一底色，整块才是连续的，不会像分隔线那样把 gutter 切断。
            -- 用 Snacks.util.set_hl 托管：换 colorscheme 会 hi clear，需要自动重挂。
            Snacks.util.set_hl({
                TreesitterContext = { bg = "#2f343f" },
                TreesitterContextLineNumber = { fg = "#5c6370", bg = "#2f343f" },
            })
        end,
    },
}
