-- EVA 初号机启动页：dashboard sections 构建（从 plugins/snacks.lua 拆出）。
-- 图案/菜单/启动耗时是纯展示逻辑，与 snacks spec 无关；模块顶层不 require 插件
-- （snacks spec import 期即被加载）。
local M = {}

-- 图案：EVA 初号机头（彩色盲文点阵，含 ANSI 256 色码）
-- 由 ascii-image-converter -C --color-bg -b 预生成，源图 scripts/eva01-source.png
-- 彩色码只能走 terminal 段渲染（纯文本 header 段会把转义码当字面量显示）
local ART_W, ART_H = 64, 22      -- 与 eva01-splash.ans 的实际宽高一致

local function art_section(self)
    local size = self:size()
    -- 放不下就不显示：terminal 段是固定宽高的悬浮窗，超出窗口会折行错乱
    -- （例如开 Neo-tree 后 dashboard 变窄）。留 2 列/1 行余量避免贴边。
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
        -- 重新渲染（如开 Neo-tree）时会把长行折断。每次直接跑 cat 才对齐。
        ttl = 0,
    }
end

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

M.sections = { art_section, menu_section, startup_section }

return M
