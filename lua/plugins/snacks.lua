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

-- 缩进线按层级循环上色（onedark 调色板）：数嵌套层级比单一灰色直观
-- 复用 snacks 自带的 SnacksIndentN 组名，覆盖它的默认色（默认只在 4 个诊断色间循环）
local INDENT_COLORS = {
    { "SnacksIndent1", "#e06c75" },     -- 红
    { "SnacksIndent2", "#d19a66" },     -- 橙
    { "SnacksIndent3", "#e5c07b" },     -- 黄
    { "SnacksIndent4", "#98c379" },     -- 绿
    { "SnacksIndent5", "#56b6c2" },     -- 青
    { "SnacksIndent6", "#61afef" },     -- 蓝
    { "SnacksIndent7", "#c678dd" },     -- 紫
}

local indent_hl = vim.tbl_map(function(c) return c[1] end, INDENT_COLORS)

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
                indent = {
                    char = "│",
                    hl = indent_hl,             -- 按层级循环上色
                },
                scope = {
                    char = "┃",                -- 光标所在作用域用粗字形区分
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
            local hl = {
                -- 作用域竖线：改用亮白加粗。原来的亮蓝已经是彩虹里的一级（SnacksIndent6），
                -- 继续用蓝色会和普通层级混在一起分不出当前代码块。
                SnacksIndentScope = { fg = "#ffffff", bold = true },
            }
            for _, c in ipairs(INDENT_COLORS) do
                hl[c[1]] = { fg = c[2] }
            end
            Snacks.util.set_hl(hl)
        end,
    },
}
