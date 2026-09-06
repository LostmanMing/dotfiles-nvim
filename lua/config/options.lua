-- ==========================================
-- 基础编辑器设置
-- ==========================================

-- 行号
vim.opt.number = true              -- 显示绝对行号
vim.opt.relativenumber = true      -- 显示相对行号（方便做 5j 10k 这类跳转）

-- 缩进
vim.opt.expandtab = true           -- Tab 键插入空格而非真正的 Tab 字符
vim.opt.shiftwidth = 4             -- 默认回落 4 格（实际按文件风格由 vim-sleuth 检测）
vim.opt.tabstop = 4                -- 默认回落 4 格（同上）

-- 鼠标
vim.opt.mouse = "a"                -- 所有模式下允许鼠标（点击定位、滚轮、拖动窗格）

-- 禁用终端响铃，避免窗口/面板已到边界时 Ctrl+hjkl 在部分终端触发整屏闪烁
vim.opt.visualbell = false
vim.opt.errorbells = false
vim.opt.belloff = "all"

-- 文件自动刷新；具体检查、冲突保护与保存行为由 config.autosave 配置
vim.opt.autoread = true            -- 外部修改文件时自动重新读取

-- 系统剪贴板：OSC 52 与本地剪贴板工具**并行**，谁通算谁的
--
--   nvim yank ─┬─OSC52──→ tmux 截获入 buffer ──转发──→ 支持 OSC 52 的终端
--              └─工具───→ xclip/pbcopy/... （给不支持 OSC 52 的终端兜底）
--   tmux 里按 y ────────→ tmux buffer ──→ nvim 的 p 读 `tmux save-buffer -`
--
-- 两条腿都要留。曾经只留 OSC 52、把工具当多余删掉，结果那台本地终端不认 OSC 52 的
-- 机器直接复制不出去了——它一直靠 SSH X11 转发 + xclip。**不要再删。**
-- 也不要拿 SSH_CONNECTION 排除工具：远程恰恰是最需要这条兜底的场景。
--
-- 但**判断有没有本地剪贴板不能只看 DISPLAY**：以前据此二选一地走 xclip、不发 OSC 52，
-- 于是 nvim 复制的东西既没进 tmux buffer、也没到本地。现在是并行，不再二选一。
vim.opt.clipboard = "unnamedplus"
vim.api.nvim_create_autocmd("VimEnter", {
    once = true, -- 延迟设置，避免被插件覆盖
    callback = function()
        local in_tmux = (vim.env.TMUX or "") ~= ""

        -- 本地剪贴板工具，argv 形式（copy 用 vim.system 异步写，paste 用命令字符串）
        local tool_copy, tool_paste
        if vim.fn.executable("pbcopy") == 1 then
            tool_copy, tool_paste = { "pbcopy" }, "pbpaste"
        elseif (vim.env.WAYLAND_DISPLAY or "") ~= "" and vim.fn.executable("wl-copy") == 1 then
            tool_copy, tool_paste = { "wl-copy" }, "wl-paste --no-newline"
        elseif (vim.env.DISPLAY or "") ~= "" and vim.fn.executable("xclip") == 1 then
            tool_copy = { "xclip", "-selection", "clipboard" }
            tool_paste = "xclip -selection clipboard -o"
        elseif vim.fn.executable("clip.exe") == 1 then
            tool_copy, tool_paste = { "clip.exe" }, nil
        end

        -- 复制：OSC 52 + 工具，两条都发。OSC 52 零 fork 且在 tmux 内会被截获入 buffer，
        -- 工具那份只有存在时才多一次异步 spawn（失败也无所谓，另一条还在）。
        local osc52 = require("vim.ui.clipboard.osc52")
        local cache_lines, cache_regtype = { "" }, "v"
        local function make_copy(reg)
            local send = osc52.copy(reg)
            return function(lines, regtype)
                cache_lines, cache_regtype = lines, regtype
                send(lines, regtype)
                if tool_copy then
                    pcall(vim.system, tool_copy, { stdin = table.concat(lines, "\n") })
                end
            end
        end
        local copy = { ["+"] = make_copy("+"), ["*"] = make_copy("*") }

        -- 粘贴优先级：tmux buffer（能同时拿到 nvim 自己的 yank 和 tmux 侧的复制）
        -- > 本地工具 > 会话内缓存
        local paste, mode, degraded
        if in_tmux then
            local from_tmux = { "tmux", "save-buffer", "-" }
            paste = { ["+"] = from_tmux, ["*"] = from_tmux }
            mode = "OSC 52" .. (tool_copy and " + " .. tool_copy[1] or "") .. " 复制，tmux buffer 粘贴"
        elseif tool_paste then
            paste = { ["+"] = tool_paste, ["*"] = tool_paste }
            mode = "OSC 52 + " .. tool_copy[1] .. " 复制，" .. tool_copy[1] .. " 粘贴"
        else
            -- **不用 osc52.paste**：它等终端回应 OSC 52 读，多数终端出于安全不回，
            -- runtime 源码里写死先等 1s 再等 9s，每次 p 都会卡住。
            local function from_cache()
                return cache_lines, cache_regtype
            end
            paste = { ["+"] = from_cache, ["*"] = from_cache }
            mode = "OSC 52 复制，会话内缓存粘贴"
            degraded = "剪贴板降级：没开 tmux、也没有可用的本地剪贴板工具。复制照样会发 "
                .. "OSC 52，但 p 只能取回本次 nvim 自己复制的内容。开 tmux 即可与 tmux buffer 互通。"
        end

        vim.g.clipboard = {
            name = "osc52+tmux",
            copy = copy,
            paste = paste,
            -- 不能开缓存：开了之后 nvim 只认自己上次复制的内容，
            -- tmux copy-mode 里新复制的东西 p 不出来
            cache_enabled = 0,
        }

        -- 只在真正降级时提醒一次。挂 User VeryLazy 而不是就地 notify：noice 是
        -- VeryLazy 才加载、并把 vim.notify 交给 snacks.notifier，在 VimEnter 里发太早，
        -- 会走默认通知、被启动信息刷掉。
        --
        -- 注意有一种问题**检测不到**：本地终端拒收 OSC 52 时复制会静默失败，
        -- nvim 这边没有任何回执可查（OSC 52 是单向写）。那种情况只能手动验证——
        -- 复制一段然后在本地按 Cmd+V。
        if degraded then
            vim.api.nvim_create_autocmd("User", {
                pattern = "VeryLazy",
                once = true,
                callback = function()
                    vim.notify(degraded, vim.log.levels.WARN, { title = "Clipboard" })
                end,
            })
        end

        -- 多机环境下常要确认「这台到底走的哪条路」，给个按需自查的命令
        vim.api.nvim_create_user_command("ClipboardInfo", function()
            vim.notify(
                ("通路：%s\ntmux 内：%s\n本地剪贴板工具：%s\n\n"):format(
                    mode,
                    in_tmux and "是" or "否",
                    tool_copy and table.concat(tool_copy, " ") or "无（只靠 OSC 52）"
                )
                    .. "OSC 52 和工具是并行的，谁通算谁的。终端收不收 OSC 52 检测不到，"
                    .. "要验就复制一段再到本地按 Cmd+V。",
                degraded and vim.log.levels.WARN or vim.log.levels.INFO,
                { title = "Clipboard" }
            )
        end, { desc = "显示当前剪贴板通路" })
    end,
})

-- 搜索
vim.opt.hlsearch = true            -- 搜索匹配项高亮
vim.opt.ignorecase = true          -- 搜索时忽略大小写
vim.opt.smartcase = true           -- 但如果搜索词包含大写字母，则区分大小写

-- 窗口分割
vim.opt.splitbelow = true          -- :split  新窗口开在下方
vim.opt.splitright = true          -- :vsplit 新窗口开在右侧
vim.opt.splitkeep = "screen"       -- 开关分屏时保持已有窗口的屏幕行不动（默认 cursor 会让文本上下跳一下）

-- 文件安全
vim.opt.swapfile = false           -- 不产生 .swp 交换文件（减少磁盘杂物）
vim.opt.backup = false             -- 不产生 ~ 备份文件
vim.opt.undofile = true            -- 持久化撤销记录（关掉重开还能 u 撤销）

-- 视觉
vim.opt.signcolumn = "yes"           -- 保留 sign 列宽度；具体排布由 snacks.statuscolumn 接管
                                     -- （git 标记在行号右侧，这一列留给 TODO 图标和书签）

-- 全局浮窗边框：一处设置，LSP 悬浮/诊断浮窗/:Lazy/:Mason 等所有浮窗统一圆角
vim.opt.winborder = "rounded"

-- 诊断显示：只在光标所在行用 virtual_lines 展开——另起一行、用 └── 箭头精确指到出错的列，
-- 比行尾 virtual_text 好定位（实测超长消息在窗口右边缘仍会截断，完整内容看 gh 或 trouble）。
-- 关掉 virtual_text：每行行尾都挂一段文字太吵，且会被代码本身挤到看不见。
-- 非当前行仍有波浪下划线标记位置，数量看 lualine，明细用 <leader>xx (trouble) 或 <leader>fd。
-- 不放 W/E 到 sign 列：那一列留给 gitsigns。
vim.diagnostic.config({
    virtual_text = false,
    virtual_lines = { current_line = true },
    signs = false,
})

vim.opt.cursorline = true          -- 高亮当前光标行
vim.opt.showmode = false           -- 不显示 --INSERT-- 等模式提示（状态栏会显示）

-- 全局状态栏：分屏时只留一条底部状态栏；同时规避 noice 在 nvim 0.12-dev 下
-- cmdheight=0 打开无状态栏浮窗（如 :Lazy）时 redraw_ruler 断言崩溃的问题
vim.opt.laststatus = 3

-- 滚动
vim.opt.scrolloff = 8              -- 光标距离屏幕上下边缘至少 8 行时开始滚动
vim.opt.sidescrolloff = 8          -- 光标距离屏幕左右边缘至少 8 列时开始滚动
vim.opt.wrap = true                -- 长行自动折行，不截断
vim.opt.smoothscroll = true        -- 折行按屏幕行滚动：wrap 开启时 <C-e>/<C-d> 不再整段跳过长行

-- 响应时间
vim.opt.updatetime = 300           -- 光标停 0.3 秒后触发 CursorHold 事件（影响 LSP/git 标记刷新速度）
vim.opt.timeoutlen = 300           -- 按键序列等待时间（如 <leader>ff 要在 0.3 秒内按完）

-- 补全菜单
vim.opt.pumheight = 10             -- 补全弹窗最多显示 10 行
vim.opt.pumborder = "rounded"      -- 补全弹窗圆角边框，与 winborder 的浮窗风格统一
vim.opt.pummaxwidth = 60           -- 限制弹窗最大宽度，避免超长补全项（如 C++ 模板签名）撑满屏幕
vim.opt.completeopt = {            -- 补全行为
    "menuone",                     --   即使只有 1 个匹配也显示菜单
    "noselect",                    --   不自动选中第一项（Enter 不会误选）
}

-- 颜色
vim.opt.termguicolors = true       -- 启用 24-bit 真彩色（装 colorscheme 的前提）

-- 文件末尾换行
vim.opt.fixendofline = false       -- 保存时不自动在文件末尾补换行符

-- 折叠：默认全部展开（treesitter 提供折叠表达式，按需手动折）
vim.opt.foldenable = false
vim.opt.foldlevel = 99

-- 工具窗口固定显示自己的 buffer，避免 :edit、LSP 跳转等把侧栏内容替换掉
vim.api.nvim_create_autocmd("BufWinEnter", {
    group = vim.api.nvim_create_augroup("FixedToolBuffers", { clear = true }),
    pattern = "*",
    callback = function()
        local fixed_filetypes = {
            ["neo-tree"] = true,
            OverseerList = true,
        }
        if fixed_filetypes[vim.bo.filetype] then
            vim.opt_local.winfixbuf = true
        end
    end,
})

