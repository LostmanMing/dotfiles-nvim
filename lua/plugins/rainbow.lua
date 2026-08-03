-- 彩虹括号：按嵌套深度给 ()[]{} 上色，深层嵌套时一眼看出配对关系
-- 复用 snacks.lua 里 indent scope 那套 onedark 调色板色序，保持缩进线与括号颜色语言一致
return {
    {
        "HiPhish/rainbow-delimiters.nvim",
        event = { "BufReadPost", "BufNewFile" },
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        config = function()
            -- 高亮组用 Snacks.util.set_hl 托管：换 colorscheme 会 hi clear，需要自动重挂
            Snacks.util.set_hl({
                RainbowDelimiterRed    = { fg = "#e06c75" },
                RainbowDelimiterOrange = { fg = "#d19a66" },
                RainbowDelimiterYellow = { fg = "#e5c07b" },
                RainbowDelimiterGreen  = { fg = "#98c379" },
                RainbowDelimiterCyan   = { fg = "#56b6c2" },
                RainbowDelimiterBlue   = { fg = "#61afef" },
                RainbowDelimiterViolet = { fg = "#c678dd" },
            })

            -- rainbow-delimiters 通过 vim.g 配置（没有 setup 函数）
            vim.g.rainbow_delimiters = {
                strategy = {
                    -- global：整个 buffer 一次性上色。大文件用 local（只处理光标所在作用域）省算力
                    [""] = "rainbow-delimiters.strategy.global",
                },
                highlight = {
                    "RainbowDelimiterRed",
                    "RainbowDelimiterOrange",
                    "RainbowDelimiterYellow",
                    "RainbowDelimiterGreen",
                    "RainbowDelimiterCyan",
                    "RainbowDelimiterBlue",
                    "RainbowDelimiterViolet",
                },
            }
        end,
    },
}
