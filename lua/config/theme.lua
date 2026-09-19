-- 主题统一入口：调色板 + 全部自定义高亮组 + colorscheme 配置 + 多主题切换/持久化。
-- 改颜色 / 风格只动这个文件；插件文件不写颜色字面量，一律引用 theme.palette。
-- 高亮组由 M.setup() 统一经 Snacks.util.set_hl 注册（托管重挂），setup 在 snacks 的 config 里调用。
-- 多主题（借鉴 Youthdreamer/nvim 的思路）：
--   * 可用主题集在 plugins/themes.lua（lazy，:colorscheme 时由 lazy 自动加载）；
--   * <leader>T 打开选择器（移动实时预览、⏎ 采纳、Esc 还原，实现见 M.pick）；
--   * 选择结果持久化到 stdpath("state")/theme，VimEnter 时自动还原；
--   * 换主题后：表面色跟随当前 colorscheme 重新派生、自定义高亮重注册、lualine 主题自动跟随。
-- 模块顶层不 require 插件：spec import 期即被加载。
local M = {}

-- ══════════ 调色板：所有颜色的唯一真源 ══════════
-- 语义色固定（不随主题变）；表面色随当前 colorscheme 派生（这里只是取不到时的兜底 = OneDark 值）
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
    -- 中性灰（固定；#5c6370 是经典 OneDark 注释灰，比 onedarkpro 的 Comment #7f848e 略深，
    -- 是手工挑过的"分隔符/行号"观感，不随主题派生）
    grey_sep    = "#5c6370",
    grey_accent = "#6b7280",        -- 当前作用域竖线（比缺省缩进灰 #3b4048 更亮）
    cursor_trail = "#d3cdc3",       -- 光标拖影
    -- 表面色（派生；兜底为 OneDark 对应值）
    bg_main    = "#282c34",
    bg_raised  = "#2f343f",
}

-- ══════════ 自定义高亮组：所有 set_hl 的定义处（由调色板组装） ══════════
local function build_hl()
    local c = M.palette
    return {
        -- 启动页（config/dashboard.lua 的 section 按名字引用）
        EvaYellow = { fg = c.eva_yellow },
        EvaPurple = { fg = c.eva_purple, bold = true },
        EvaGreen  = { fg = c.eva_green },
        -- 缩进作用域（snacks indent.scope.hl 按名字引用）
        IndentScopeActive = { fg = c.grey_accent },
        -- Git 分档：亮绿=未暂存新增/未跟踪；深绿/深黄/深砖红=staged 各状态。
        -- 上游 staged sign 默认带 50% 前景色，OneDark 上会变成看不清的墨绿。
        GitSignsAdd = { fg = c.git_unstaged },
        GitSignsUntracked = { fg = c.git_unstaged },
        GitSignsStagedAdd = { fg = c.git_staged_add },
        GitSignsStagedUntracked = { fg = c.git_staged_add },
        GitSignsStagedChange = { fg = c.git_staged_change },
        GitSignsStagedChangedelete = { fg = c.git_staged_change },
        GitSignsStagedDelete = { fg = c.git_staged_delete },
        GitSignsStagedTopdelete = { fg = c.git_staged_delete },
        -- 覆写 OneDark 默认灰为可见绿（Ignored 保持灰）
        NeoTreeGitUntracked = { fg = c.git_unstaged },
        -- bufferline：Explorer 标题用初号机紫；分隔符 │ 用主底对齐 Neo-tree 行
        BufferLineExplorer = { fg = c.eva_purple, bold = true },
        BufferLineOffsetSeparator = { fg = c.grey_sep, bg = c.bg_main },
        -- 粘性上下文：钉住块比正文底色亮一档形成"浮起"色块；行号列同底色才连续
        TreesitterContext = { bg = c.bg_raised },
        TreesitterContextLineNumber = { fg = c.grey_sep, bg = c.bg_raised },
    }
end

-- 表面色跟随当前 colorscheme（换主题不打架）：bg_main←Normal.bg、
-- bg_raised←bg_main 按明暗提亮/加深一档（形成"浮起"块）；取不到就保留兜底值。
local function derive_surfaces()
    local c = M.palette
    local bg = vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg
    if bg then c.bg_main = ("#%06x"):format(bg) end
    local r = tonumber(c.bg_main:sub(2, 3), 16)
    local g = tonumber(c.bg_main:sub(4, 5), 16)
    local b = tonumber(c.bg_main:sub(6, 7), 16)
    local delta = (r * 0.299 + g * 0.587 + b * 0.114) < 128 and 10 or -10  -- 暗底提亮、亮底加深
    local function clamp(v) return math.max(0, math.min(255, v)) end
    c.bg_raised = ("#%02x%02x%02x"):format(clamp(r + delta), clamp(g + delta), clamp(b + delta))
end

-- ══════════ colorscheme：换默认主题改这里 ══════════
M.colorscheme = {
    plugin = "olimorris/onedarkpro.nvim",
    name = "onedark",
    lualine = "onedark",                 -- lualine 内置主题名（默认主题用）
    opts = {
        options = { cursorline = true },
    },
    apply = function()
        require("onedarkpro").setup(M.colorscheme.opts)
        vim.cmd.colorscheme(M.colorscheme.name)
    end,
}

-- lualine 的 theme 选项（以函数引用传给 plugins/lualine.lua）：lualine 自带
-- ColorScheme 重跑 setup，所以换主题自动跟随——默认主题用它内置的 onedark，其它用 auto 推导
function M.lualine_theme()
    local name = vim.g.colors_name
    if name == nil or name == M.colorscheme.name then
        return M.colorscheme.lualine
    end
    return "auto"
end

-- ══════════ 多主题：持久化 + 选择器 ══════════
local state_file = vim.fn.stdpath("state") .. "/theme"

function M.save()
    local name = vim.g.colors_name
    if not name or name == "" then return end
    local f = io.open(state_file, "w")
    if f then
        f:write(name)
        f:close()
    end
end

function M.load()
    local f = io.open(state_file, "r")
    if not f then return end
    local name = f:read("*l")
    f:close()
    if not name or name == "" or name == vim.g.colors_name then return end
    if not pcall(vim.cmd.colorscheme, name) then
        vim.notify(("持久化的主题 %s 加载失败，回退默认"):format(name), vim.log.levels.WARN, { title = "Theme" })
        M.colorscheme.apply()
    end
end

-- 主题选择器：自己用 telescope 原语搭（不用内置 colorscheme picker——它自带的
-- "Esc 还原"实测会被关闭阶段的收尾回调覆盖，停在最后一个预览上）。
-- 行为：移动光标即实时预览；⏎ 采纳并关闭；Esc / 取消 恢复打开前的主题。
-- 预览期间 ColorScheme 频发：_picking 挡掉持久化写入；返回后统一保存最终值。
-- 依赖 lazy 的模块加载拦截同步加载 telescope（require 路径；:Telescope 命令路径
-- 经 cmd handler 重派发、异步时序不可靠）。
function M.pick()
    local ok, pickers = pcall(require, "telescope.pickers")
    if not ok then
        vim.notify("Telescope 未就绪，无法切换主题", vim.log.levels.WARN, { title = "Theme" })
        return
    end
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    -- 候选 = 当前 + 已装 + lazy 未加载的（与 Telescope 内置 colorscheme picker 同款来源）
    local colors = { vim.g.colors_name or M.colorscheme.name }
    local function add(name)
        if name ~= "" and not vim.tbl_contains(colors, name) then
            colors[#colors + 1] = name
        end
    end
    for _, c in ipairs(vim.fn.getcompletion("", "color")) do add(c) end
    local lazy_util = package.loaded["lazy.core.util"]
    if lazy_util and lazy_util.get_unloaded_rtp then
        for _, f in ipairs(vim.fn.globpath(table.concat(lazy_util.get_unloaded_rtp(""), ","), "colors/*", 1, 1)) do
            add(vim.fn.fnamemodify(f, ":t:r"))
        end
    end

    local before = vim.g.colors_name
    local accepted = false
    local closed = false   -- find() 返回后的收尾期：stray 回调不再应用

    local picker = pickers.new({}, {
        prompt_title = "Colorscheme",
        finder = finders.new_table({ results = colors }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, map)
            map("i", "<CR>", function()
                local sel = action_state.get_selected_entry()
                accepted = true
                actions.close(prompt_bufnr)
                if sel then pcall(vim.cmd.colorscheme, sel.value) end
            end)
            return true
        end,
    })
    -- 移动即预览（与内置同款：挂 set_selection；关闭后的 stray 调用被 closed 挡住）
    local set_selection = picker.set_selection
    picker.set_selection = function(self, row)
        set_selection(self, row)
        if closed then return end
        local sel = action_state.get_selected_entry()
        if sel then pcall(vim.cmd.colorscheme, sel.value) end
    end

    M._picking = true
    picker:find()
    closed = true
    M._picking = false
    if not accepted and before and before ~= "" then
        pcall(vim.cmd.colorscheme, before)   -- 取消：恢复到打开前的主题
    end
    M.save()
end

-- ══════════ 统一注册 + 运行时钩子（在 snacks 的 config 里调用） ══════════
function M.setup()
    derive_surfaces()
    M.hl = build_hl()
    Snacks.util.set_hl(M.hl)

    local grp = vim.api.nvim_create_augroup("ThemeRuntime", { clear = true })
    -- 换主题（含选择器实时预览）：重派生表面色 + 重注册高亮；非预览时段才持久化
    vim.api.nvim_create_autocmd("ColorScheme", {
        group = grp,
        callback = function()
            vim.schedule(function()
                M.setup()
                if not M._picking then M.save() end
            end)
        end,
    })
    -- 启动还原：VimEnter 之后、且必须 vim.schedule——VimEnter 的 autocmd 上下文里
    -- lazy 的 colorscheme 按需加载不生效（实测 E185），挪到主循环里就正常
    if vim.v.vim_did_enter == 0 then
        vim.api.nvim_create_autocmd("VimEnter", {
            group = grp,
            once = true,
            callback = function() vim.schedule(function() M.load() end) end,
        })
    end
end

return M
