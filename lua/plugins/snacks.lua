-- snacks.nvim：收编几个原本各自一个插件的小功能
-- 启用 dashboard（启动页）、indent（缩进线）、notifier（通知）、bigfile（大文件降级）
-- 未启用 scroll（平滑滚动）：与 smear-cursor 的光标拖影抢同一手势，已选后者
-- snacks 所有模块默认全关，opts 里出现哪个 key 才启用哪个，所以没列的模块一行代码都不跑

-- 图案：EVA 初号机头（彩色盲文点阵，含 ANSI 256 色码）
-- 由 ascii-image-converter -C --color-bg -b 预生成，源图 scripts/eva01-source.png
-- 彩色码只能走 terminal 段渲染（纯文本 header 段会把转义码当字面量显示）
local ART_W, ART_H = 64, 22      -- 与 eva01-splash.ans 的实际宽高一致

local function art_section(self)
    local size = self:size()
    -- 放不下就不显示：terminal 段是固定宽高的悬浮窗，超出窗口会折行错乱
    -- （例如开 nvim-tree 后 dashboard 变窄）。留 2 列/1 行余量避免贴边。
    if ART_W + 2 > size.width or ART_H + 1 > size.height then
        return nil
    end
    -- 居中偏移按 dashboard 布局宽度算（默认 60）。图比它宽时左边距偏大、
    -- 右侧顶出窗口而折行，所以把布局宽度对齐到图宽。
    -- resolve 在 layout 之前跑，此处赋值当次渲染即生效。
    self.opts.width = ART_W
    return {
        section = "terminal",
        cmd = ("cat %s/scripts/eva01-splash.ans"):format(vim.fn.stdpath("config")),
        width = ART_W,
        height = ART_H,
        -- ttl=0 禁用输出缓存：缓存重播走的终端宽度不等于本段宽度，
        -- 重新渲染（如开 nvim-tree）时会把长行折断。每次直接跑 cat 才对齐。
        ttl = 0,
    }
end

-- 当前作用域竖线按嵌套深度取色（onedark 调色板）：
-- 只有光标所在的那个作用域会上色，其它缩进层级保持默认灰色，不至于满屏彩线
local SCOPE_COLORS = {
    { "IndentScope1", "#e06c75" },      -- 红
    { "IndentScope2", "#d19a66" },      -- 橙
    { "IndentScope3", "#e5c07b" },      -- 黄
    { "IndentScope4", "#98c379" },      -- 绿
    { "IndentScope5", "#56b6c2" },      -- 青
    { "IndentScope6", "#61afef" },      -- 蓝
    { "IndentScope7", "#c678dd" },      -- 紫
}

local scope_hl = vim.tbl_map(function(c) return c[1] end, SCOPE_COLORS)

return {
    {
        "folke/snacks.nvim",
        priority = 1000,        -- 早于其它插件加载，保证启动即可接管空 buffer
        lazy = false,
        opts = {
            dashboard = {
                -- 启动页只放图，不显示菜单/启动耗时
                sections = { art_section },
            },
            indent = {
                indent = { char = "│" },        -- 普通层级：默认灰色，不上色
                scope = {
                    char = "┃",                -- 光标所在作用域用粗字形区分
                    hl = scope_hl,              -- 按嵌套深度取色
                },
                -- 关掉动画，保持和原来 indent-blankline 一致的静态观感
                animate = { enabled = false },
            },
            notifier = {
                timeout = 2500,
                top_down = false,               -- 通知从右下往上堆
                -- 注：原来 nvim-notify 的 stages="fade" 没有对应项，snacks 通知无动画
                -- style 默认已是 compact，与原配置一致
            },
            bigfile = {},                       -- 大文件自动关掉 treesitter/补全等重功能
        },
        config = function(_, opts)
            require("snacks").setup(opts)
            -- 用 Snacks.util.set_hl 而非 nvim_set_hl：它托管高亮组，换 colorscheme 后自动重挂
            local hl = {}
            for _, c in ipairs(SCOPE_COLORS) do
                hl[c[1]] = { fg = c[2], bold = true }
            end
            Snacks.util.set_hl(hl)
        end,
    },
}
