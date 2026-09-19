-- 可选主题集：别人的主题导入入口。全部 lazy —— 不占启动开销，:colorscheme <名字>
-- 时由 lazy 自动加载提供者（它挂在 ColorSchemePre 上按名查找）。
-- 加主题 = 这里加一行；切换用 <leader>T（Telescope 实时预览），
-- 持久化 / 表面色跟随 / lualine 跟随见 config/theme.lua。
return {
    { "folke/tokyonight.nvim", lazy = true },
    { "catppuccin/nvim", name = "catppuccin", lazy = true },
    { "rebelot/kanagawa.nvim", lazy = true },
    { "ellisonleao/gruvbox.nvim", lazy = true },
}
