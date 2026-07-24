return {
    {
        -- 按当前文件实际缩进风格自动设置 shiftwidth/expandtab/tabstop
        -- 检测不出时回落到 options.lua 里的默认（4 格）；有 .editorconfig 时 nvim 内置支持优先
        "tpope/vim-sleuth",
        event = { "BufReadPre", "BufNewFile" },
    },
}
