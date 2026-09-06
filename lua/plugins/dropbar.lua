-- 面包屑导航栏（winbar）：每个窗口顶部显示 路径 > 类 > 函数 的层级
-- 配的是 laststatus=3 的短板——全局状态栏只有一条，分屏时看不出哪个窗口是哪个文件，
-- winbar 是按窗口的，正好补上这个信息。
return {
    {
        "Bekaboo/dropbar.nvim",
        event = { "BufReadPost", "BufNewFile" },
        keys = {
            -- 进入面包屑交互模式：可以用 hjkl 在层级间移动、回车跳转到对应符号
            { "<leader>cb", function() require("dropbar.api").pick() end, desc = "面包屑交互选择" },
        },
        opts = {
            bar = {
                -- 特殊 buffer 不显示面包屑：这些窗口没有"路径 > 符号"的概念，
                -- 显示出来只会占掉一行高度
                enable = function(buf, win, _)
                    if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_win_is_valid(win) then
                        return false
                    end
                    -- 浮窗没有稳定的普通文件上下文，不挂面包屑。
                    if vim.api.nvim_win_get_config(win).relative ~= "" then return false end
                    if vim.bo[buf].buftype ~= "" then return false end
                    local ft = vim.bo[buf].filetype
                    local skip = {
                        ["neo-tree"] = true, ["neo-tree-preview"] = true,
                        toggleterm = true, trouble = true,
                        snacks_dashboard = true, lazy = true, mason = true,
                        DiffviewFiles = true, DiffviewFileHistory = true,
                    }
                    if skip[ft] then return false end
                    -- diff 模式下左右并排，面包屑会各占一行挤掉正文
                    if vim.wo[win].diff then return false end
                    return vim.api.nvim_buf_get_name(buf) ~= ""
                end,
            },
            icons = {
                ui = { bar = { separator = "  " } },   -- 层级分隔符换成右尖角，和 lualine 同一套字形
            },
        },
    },
}
