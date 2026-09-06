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
                -- 但下面 Neo-tree 每行的 │ 背景是主底 #282c34，两者颜色不同 →
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

            local function update_tabline()
                local has_file = false
                for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                    if vim.bo[buf].buflisted and vim.api.nvim_buf_is_loaded(buf)
                        and require("config.util").is_file_buf(buf) then
                        has_file = true
                        break
                    end
                end
                vim.o.showtabline = has_file and 2 or 0
            end
            local visibility_group = vim.api.nvim_create_augroup("BufferLineVisibility", { clear = true })
            vim.api.nvim_create_autocmd(
                { "BufAdd", "BufDelete", "BufWipeout", "BufEnter", "TabEnter", "TabLeave" },
                {
                    group = visibility_group,
                    callback = function() vim.schedule(update_tabline) end,
                }
            )
            vim.api.nvim_create_autocmd("User", {
                group = visibility_group,
                pattern = "NeoTreePreviewBufferChanged",
                callback = update_tabline,
            })
            vim.schedule(update_tabline)
        end,
        opts = {
            highlights = {
                buffer = { italic = false },
                buffer_visible = { italic = false },
                buffer_selected = { italic = false },
            },
            options = {
                auto_toggle_bufferline = false,
                diagnostics = false,         -- 诊断留给 lualine / Trouble，标签只显示文件名
                -- 斜切分隔：与 lualine 的尖箭头 section_separators 同一套视觉语言
                separator_style = "slope",
                -- 当前标签用下划线标记，比默认的左侧竖条(▎)更干净，也不占标签内宽度
                indicator = { style = "underline" },
                -- 只给 Neo-tree 临时预览用；无分组分隔，下一次预览会替换它。
                groups = {
                    items = {
                        {
                            name = "Preview",
                            matcher = function(buf) return vim.b[buf.id].neo_tree_preview == true end,
                            highlight = { italic = true },
                            separator = { style = function() return { sep_start = {}, sep_end = {} } end },
                        },
                    },
                },
                offsets = {                  -- 给 Neo-tree 侧栏留出区域
                    {
                        filetype = "neo-tree",
                        text = "Explorer",
                        separator = true,
                        highlight = "BufferLineExplorer",
                    },
                },
            },
        },
    },
}
