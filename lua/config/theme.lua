-- 主题统一入口：调色板 + 全部自定义高亮组 + colorscheme 配置。
-- 改颜色 / 风格只动这个文件；插件文件不写颜色字面量，一律引用 theme.palette。
-- 高亮组由 M.setup() 统一经 Snacks.util.set_hl 注册（托管重挂，换 colorscheme 自动重设），
-- setup 在 snacks 的 config 里调用（那时 Snacks 必然已加载）。
-- 模块顶层不 require 插件：spec import 期即被加载。
local M = {}

-- ══════════ 调色板：所有颜色的唯一真源 ══════════
M.palette = {
    -- 初号机（启动页美术取样自 scripts/eva01-source.png，不是凭感觉调的）
    eva_purple = "#9888d1",         -- 机体主色
    eva_yellow = "#e3c645",         -- 下颚 / 角
    eva_green  = "#67a659",         -- 装甲配件
    -- Git 分档（VS Code 系）
    git_unstaged = "#81B88B",       -- 未暂存新增 / 未跟踪
    git_staged_add = "#6A9955",     -- staged 新增
    git_staged_change = "#8A6A28",  -- staged 修改
    git_staged_delete = "#632F32",  -- staged 删除
    -- 中性灰与底色
    grey_sep    = "#5c6370",        -- 分隔符 / 注释级灰
    grey_accent = "#6b7280",        -- 当前作用域竖线（比缺省缩进灰 #3b4048 更亮）
    bg_main     = "#282c34",        -- OneDark 主底
    bg_raised   = "#2f343f",        -- 比主底亮一档（粘性上下文浮起块）
    -- 光标拖影
    cursor_trail = "#d3cdc3",
}

-- ══════════ 自定义高亮组：所有 set_hl 的定义处 ══════════
M.hl = {
    -- 启动页（config/dashboard.lua 的 section 按名字引用）
    EvaYellow = { fg = M.palette.eva_yellow },
    EvaPurple = { fg = M.palette.eva_purple, bold = true },
    EvaGreen  = { fg = M.palette.eva_green },
    -- 缩进作用域（snacks indent.scope.hl 按名字引用）
    IndentScopeActive = { fg = M.palette.grey_accent },
    -- Git 分档：亮绿=未暂存新增/未跟踪；深绿/深黄/深砖红=staged 各状态。
    -- 上游 staged sign 默认带 50% 前景色，OneDark 上会变成看不清的墨绿。
    GitSignsAdd = { fg = M.palette.git_unstaged },
    GitSignsUntracked = { fg = M.palette.git_unstaged },
    GitSignsStagedAdd = { fg = M.palette.git_staged_add },
    GitSignsStagedUntracked = { fg = M.palette.git_staged_add },
    GitSignsStagedChange = { fg = M.palette.git_staged_change },
    GitSignsStagedChangedelete = { fg = M.palette.git_staged_change },
    GitSignsStagedDelete = { fg = M.palette.git_staged_delete },
    GitSignsStagedTopdelete = { fg = M.palette.git_staged_delete },
    -- 覆写 OneDark 默认灰为可见绿（Ignored 保持灰）
    NeoTreeGitUntracked = { fg = M.palette.git_unstaged },
    -- bufferline：Explorer 标题用初号机紫；分隔符 │ 用主底对齐 Neo-tree 行
    -- （默认背景是 BufferLineFill 近黑，与 Neo-tree 每行的 │ 底色不一致，会看着被一块黑侵入）
    BufferLineExplorer = { fg = M.palette.eva_purple, bold = true },
    BufferLineOffsetSeparator = { fg = M.palette.grey_sep, bg = M.palette.bg_main },
    -- 粘性上下文：钉住块比正文底色亮一档形成"浮起"色块；行号列同底色，整块才是连续的
    TreesitterContext = { bg = M.palette.bg_raised },
    TreesitterContextLineNumber = { fg = M.palette.grey_sep, bg = M.palette.bg_raised },
}

-- ══════════ colorscheme：换主题改这里 ══════════
M.colorscheme = {
    plugin = "olimorris/onedarkpro.nvim",
    name = "onedark",
    lualine = "onedark",                 -- lualine 内置主题名（随配色一起改）
    opts = {
        options = { cursorline = true },
    },
    apply = function()
        require("onedarkpro").setup(M.colorscheme.opts)
        vim.cmd.colorscheme(M.colorscheme.name)
    end,
}

-- 统一注册全部自定义高亮组；在 snacks 的 config 里调用
function M.setup()
    Snacks.util.set_hl(M.hl)
end

return M
