-- 底部状态栏
return {
    {
        "nvim-lualine/lualine.nvim",
        event = "VeryLazy",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {
            options = {
                theme = "onedark",
                globalstatus = true,                            -- 全局状态栏，与 laststatus=3 一致
                -- 尖箭头段分隔（U+E0B0 / U+E0B2）；组件分隔留空更干净
                -- 用字节转义写入，避免工具把私用区字符丢成空字符串
                component_separators = "",
                section_separators = { left = "\238\130\176", right = "\238\130\178" },
            },
            sections = {
                lualine_a = { "mode" },
                lualine_b = {
                    -- 不显式设 icon：lualine 默认的分支图标 U+E0A0 是 Nerd Font 标准字形，
                    -- 覆盖成别的私有区码点在部分字体里没有对应字形，会显示成空白
                    { "branch", color = { fg = "#67a659", bold = true } },  -- 初号机装甲绿（与 starship 分支色一致）
                    -- diff 数据由 gitsigns 提供（lualine 自动读取）
                    { "diff", symbols = { added = " ", modified = " ", removed = " " } },
                },
                lualine_c = {
                    -- path=1：显示相对路径，重名文件也能区分
                    { "filename", path = 1, symbols = { modified = " ●", readonly = " ", unnamed = "[No Name]" } },
                },
                lualine_x = {
                    {
                        "diagnostics",
                        symbols = { error = " ", warn = " ", info = " ", hint = " " },
                    },
                    -- 当前 buffer 已附着的 LSP 名称
                    {
                        function()
                            local names = {}
                            for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
                                names[#names + 1] = c.name
                            end
                            return #names > 0 and (" " .. table.concat(names, ",")) or ""
                        end,
                    },
                    { "filetype", icon_only = true },
                },
                lualine_y = { "progress" },
                lualine_z = { { "location", icon = "" } },
            },
            -- 特殊窗口换成各自专用的精简状态栏：不加时它们会套用上面这套通用配置，
            -- 显示无意义的相对路径和行列号（如 nvim-tree 里显示 "NvimTree_1 1:1"）
            extensions = { "nvim-tree", "toggleterm", "trouble", "lazy", "mason", "quickfix", "man" },
        },
    },
}
