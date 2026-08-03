return {
    {
        "akinsho/bufferline.nvim",
        version = "*",
        lazy = false,
        dependencies = { "nvim-tree/nvim-web-devicons" },
        init = function()
            -- bufferline 的 offset.highlight 只接受已存在的高亮组名字符串（源码 offset.lua:164
            -- 用 highlights.hl(hl_name)），传 table 会被静默忽略。注册组、后面按名字引用。
            -- 用 autocmd 覆盖 ColorScheme：换配色会 hi clear，需要重挂
            local function set_hl()
                vim.api.nvim_set_hl(0, "BufferLineExplorer", {
                    fg = "#9888d1",    -- 初号机紫（前景）
                    bold = true,
                })
                -- offset 右侧的分隔符 │ 默认背景是 BufferLineFill (#16181c 近黑)，
                -- 但下面 nvim-tree 每行的 │ 背景是主底 #282c34，两者颜色不同 →
                -- Explorer 行看起来被一块黑侵入、上下 │ 也断开。改成主底即可对齐。
                vim.api.nvim_set_hl(0, "BufferLineOffsetSeparator", {
                    fg = "#5c6370",
                    bg = "#282c34",
                })
            end
            set_hl()
            vim.api.nvim_create_autocmd("ColorScheme", {
                group = vim.api.nvim_create_augroup("BufferLineExplorerHl", { clear = true }),
                callback = set_hl,
            })
        end,
        opts = {
            options = {
                diagnostics = "nvim_lsp",   -- 标签上显示 LSP 诊断标记
                offsets = {                  -- 给 nvim-tree 侧栏留出区域
                    {
                        filetype = "NvimTree",
                        text = "Explorer",
                        separator = true,
                        highlight = "BufferLineExplorer",
                    },
                },
            },
        },
    },
}
