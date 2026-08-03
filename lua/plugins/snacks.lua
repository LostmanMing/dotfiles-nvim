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

-- 初号机配色：色值直接从 scripts/eva01-source.png 取样，不是凭感觉调的
local EVA = {
    purple = "#9888d1",     -- 机体主色
    yellow = "#e3c645",     -- 下颚 / 角
    green  = "#67a659",     -- 装甲配件
}

-- 底部启动耗时。不用内置 startup 段：它把图标和文字放进同一个 chunk，没法分开上色。
-- 数据来源相同（lazy.stats）。padding 是 {底部, 顶部}，留一行和菜单分开。
local function startup_section()
    local stats = require("lazy.stats").stats()
    local ms = math.floor(stats.startuptime * 100 + 0.5) / 100
    return {
        align = "center",
        padding = { 0, 1 },
        text = {
            { "⚡ ", hl = "EvaYellow" },
            { "Neovim loaded ", hl = "EvaGreen" },
            { stats.loaded .. "/" .. stats.count, hl = "EvaPurple" },
            { " plugins in ", hl = "EvaGreen" },
            { ms .. "ms", hl = "EvaPurple" },
        },
    }
end

-- 启动页菜单：多项排一行省空间。
-- 不用内置 keys 段（它一项一行、占太高），改成自己排版的文本 + hidden 项：
-- hidden 项不渲染但按键照样注册，排版与按键因此解耦。
local MENU = {
    { "f", "find file", ":Telescope find_files" },
    { "n", "new file",  ":ene | startinsert" },
    { "g", "find text", ":Telescope live_grep" },
    { "c", "config",    ":e " .. vim.fn.stdpath("config") .. "/init.lua" },
    { "l", "lazy",      ":Lazy" },
    -- snacks 默认把启动页的 q 映射成 :bd，这里覆盖成整体退出（item 按键注册在那之后）
    { "q", "quit",      ":qa" },
}
local MENU_COLS, CELL_W = 3, 21     -- 3 列 × 21 宽 = 63，正好放进 64 宽的版面

local function menu_section()
    local items = {}
    for row = 1, math.ceil(#MENU / MENU_COLS) do
        local text = {}
        for col = 1, MENU_COLS do
            local m = MENU[(row - 1) * MENU_COLS + col]
            if m then
                table.insert(text, { " " .. m[1] .. "  ", hl = "EvaYellow" })
                table.insert(text, { m[2] .. string.rep(" ", CELL_W - 4 - #m[2]), hl = "EvaPurple" })
            end
        end
        -- 每行左对齐：版面整体仍居中，但末行格子数少，逐行居中会导致列对不齐
        -- 第一行加两个顶部空行，和上面的图分开
        table.insert(items, { align = "left", text = text, padding = row == 1 and { 0, 2 } or nil })
    end
    for _, m in ipairs(MENU) do
        table.insert(items, { key = m[1], action = m[3], hidden = true })
    end
    return items
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
                -- 图 + 菜单 + 底部启动耗时（初号机配色）
                sections = {
                    art_section,
                    menu_section,
                    startup_section,
                },
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
            -- 光标停住时用 LSP documentHighlight 高亮同一符号的所有出现位置，
            -- 改名前先扫一眼影响范围很方便。跳转键位在下面 config 里注册（模块本身不建键位）
            words = {
                debounce = 200,                 -- 比 updatetime(300) 短，光标停下就出高亮
            },
            -- 接管 statuscolumn：把 git 标记从最左边挪到行号右侧、紧贴代码，
            -- 定位改动行时视线不用在行号和代码之间来回跳。
            -- 左右各住着什么（实测）：
            --   left  = todo-comments 的 TODO/FIX/HACK 图标（它默认 signs=true）+ m{a-z} 书签
            --   right = 折叠箭头 + gitsigns 的 ▎ 标记
            -- 左边没标记时看着是空的，但那是预留位不是浪费：实测两种布局（分区 / 全放右边）
            -- gutter 都是 6 列，snacks 按固定宽度补齐，否则标记一出现代码就会左右抖动。
            statuscolumn = {
                left = { "mark", "sign" },      -- 注解类：TODO 图标、书签
                right = { "fold", "git" },      -- 结构与版本控制类：折叠箭头、git 标记
                folds = { open = true },        -- 显示折叠展开/收起箭头（可折的行才画）
            },
            bigfile = {},                       -- 大文件自动关掉 treesitter/补全等重功能
        },
        config = function(_, opts)
            require("snacks").setup(opts)
            -- 用 Snacks.util.set_hl 而非 nvim_set_hl：它托管高亮组，换 colorscheme 后自动重挂
            local hl = {
                EvaYellow = { fg = EVA.yellow },
                EvaPurple = { fg = EVA.purple, bold = true },
                EvaGreen = { fg = EVA.green },
            }
            for _, c in ipairs(SCOPE_COLORS) do
                hl[c[1]] = { fg = c[2], bold = true }
            end
            Snacks.util.set_hl(hl)

            -- inlay hints 开关（从 lsp.lua 迁来）：Snacks.toggle 带通知和 which-key 图标，
            -- 作用域同为 bufnr=0，行为和原来一致
            Snacks.toggle.inlay_hints():map("<leader>ci")

            -- words 的引用跳转：占 ]]/[[ 是因为原生的 section 移动基本用不到，
            -- 且不与已有的 ]c(hunk) / ]f(函数) / ]t(todo) / ]p(参数) 撞键
            for key, dir in pairs({ ["]]"] = 1, ["[["] = -1 }) do
                vim.keymap.set({ "n", "x", "o" }, key, function()
                    Snacks.words.jump(dir, true)    -- true: 循环，跳到末尾后回到第一个
                end, { desc = dir == 1 and "下一处引用" or "上一处引用" })
            end
        end,
    },
}
