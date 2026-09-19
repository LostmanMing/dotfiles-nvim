-- 主题统一入口：调色板 + 全部自定义高亮组 + colorscheme 配置 + 多主题切换/持久化。
-- 改颜色 / 风格只动这个文件；插件文件不写颜色字面量，一律引用 theme.palette。
-- 高亮组由 M.setup() 统一经 Snacks.util.set_hl 注册（托管重挂），setup 在 snacks 的 config 里调用。
-- 多主题（整体照抄 Youthdreamer/nvim 的路子：手工清单 + 选中即应用 + "name:style" 持久化，
-- 见其 lua/features/switch-theme.lua）：
--   * 可用主题插件在 plugins/themes.lua（lazy，:colorscheme 时由 lazy 自动加载）；
--   * 主题清单 = 下面的 themes 表：只列真实存在的 colorscheme 名、可带 style；装新主题插件后在这里加名字；
--   * <leader>T 选择器只做"选中→应用→关闭"，不做实时预览——预览机制（set_selection 补丁）
--     是历次 bug 的来源（打开随机跳色、Esc 还原竞态），勿加回；
--   * 持久化格式 "name:style" 写 stdpath("state")/theme，启动时先设 'background' 再 :colorscheme；
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

-- ══════════ 多主题：手工清单 + 选择器 + "name:style" 持久化 ══════════
-- 清单只列真实存在、可加载的 colorscheme 名（对照各插件 colors/ 目录核对过）。
-- style 用于加载前设置 'background'：gruvbox、*-day、*-latte、*-lotus、onelight 这类
-- 主题的深浅由 background 决定，不指定会出现"名字和实际配色对不上"。
-- 不要改回扫描式候选（getcompletion / lazy glob）：会混入 vim 自带主题（zellner 等）
-- 和 catppuccin-nvim 这种过时 stub 名，且无法表达 style。
local themes = {
    -- onedarkpro（默认主题）
    onedark = { style = "dark" },
    onedark_dark = { style = "dark" },
    onedark_vivid = { style = "dark" },
    onelight = { style = "light" },
    -- tokyonight
    ["tokyonight-night"] = {},
    ["tokyonight-storm"] = {},
    ["tokyonight-moon"] = {},
    ["tokyonight-day"] = { style = "light" },
    -- catppuccin
    ["catppuccin-frappe"] = {},
    ["catppuccin-macchiato"] = {},
    ["catppuccin-mocha"] = {},
    ["catppuccin-latte"] = { style = "light" },
    -- kanagawa
    ["kanagawa-wave"] = {},
    ["kanagawa-dragon"] = {},
    ["kanagawa-lotus"] = { style = "light" },
    -- gruvbox
    gruvbox = { style = "dark" },
}

local state_file = vim.fn.stdpath("state") .. "/theme"

function M.save()
    local name = vim.g.colors_name
    if not name or name == "" then return end
    local f = io.open(state_file, "w")
    if f then
        f:write(name .. ":" .. (vim.o.background or "dark"))
        f:close()
    end
end

function M.load()
    local f = io.open(state_file, "r")
    if not f then return end
    local data = f:read("*a") or ""
    f:close()
    local name, style = data:match("([^:]+):?(.*)")
    if not name or name == "" then return end
    if style and style ~= "" then vim.o.background = style end
    if not pcall(vim.cmd.colorscheme, name) then
        vim.notify(("持久化的主题 %s 加载失败，回退默认"):format(name), vim.log.levels.WARN, { title = "Theme" })
        M.colorscheme.apply()
    end
end

-- 主题选择器：结构照抄 Youthdreamer/nvim（telescope dropdown、选中即应用、无预览）。
-- 两处本地化调整（都是实测踩出来的，勿回退）：
--   * initial_mode = "insert"：telescope.lua 全局是 normal，普通模式打字过滤不可靠，
--     且普通模式 ⏎ 会命中山默认的 select_default——把主题名当文件 :edit（"回车打开了
--     一个 buffer"）；插入模式是验证过的稳定路径；
--   * ⏎ 用 actions.select_default:replace 在动作层接管（i / n / 鼠标点击全覆盖），
--     不要只 map("<i>", "<CR>")。
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
    local telescope_themes = require("telescope.themes")

    local names = vim.tbl_keys(themes)
    table.sort(names)

    pickers.new(
        telescope_themes.get_dropdown({
            layout_config = { width = 0.5, height = 0.4 },
            initial_mode = "insert",
        }),
        {
            prompt_title = "Colorscheme",
            finder = finders.new_table({ results = names }),
            sorter = conf.generic_sorter({}),
            attach_mappings = function(prompt_bufnr, _)
                actions.select_default:replace(function()
                    local sel = action_state.get_selected_entry()
                    if not sel then
                        actions.close(prompt_bufnr)
                        return
                    end
                    -- 先设 'background' 再加载主题（顺序见清单区注释）
                    local info = themes[sel.value] or {}
                    if info.style then
                        vim.o.background = info.style
                        vim.g.theme_style = info.style
                    end
                    local ok2, err = pcall(vim.cmd.colorscheme, sel.value)
                    if not ok2 then
                        vim.notify(("主题 %s 加载失败: %s"):format(sel.value, err), vim.log.levels.ERROR, { title = "Theme" })
                    end
                    actions.close(prompt_bufnr)
                end)
                return true
            end,
        }
    ):find()
end

-- ══════════ 统一注册 + 运行时钩子（在 snacks 的 config 里调用） ══════════
function M.setup()
    derive_surfaces()
    M.hl = build_hl()
    Snacks.util.set_hl(M.hl)

    local grp = vim.api.nvim_create_augroup("ThemeRuntime", { clear = true })
    -- 换主题：重派生表面色 + 重注册高亮，并持久化（与 Youthdreamer 的 detect_theme_change 等价）
    vim.api.nvim_create_autocmd("ColorScheme", {
        group = grp,
        callback = function()
            vim.schedule(function()
                M.setup()
                M.save()
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
