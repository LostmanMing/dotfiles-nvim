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

-- 文件自动刷新
vim.opt.autoread = true            -- 外部修改文件时自动重新读取

-- autoread 仅在 nvim 主动 checktime 时生效，加 autocmd 在常见时机触发检查
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
    group = vim.api.nvim_create_augroup("AutoReload", { clear = true }),
    pattern = "*",
    callback = function()
        if vim.fn.mode() ~= "c" and vim.bo.buftype == "" and vim.api.nvim_buf_get_name(0) ~= "" then
            vim.cmd("checktime")
        end
    end,
})

-- 磁盘文件被外部修改并重载后，给用户一行提示
local grp_filechanged = vim.api.nvim_create_augroup("FileChanged", { clear = true })
vim.api.nvim_create_autocmd("FileChangedShellPost", {
    group = grp_filechanged,
    pattern = "*",
    callback = function(args)
        vim.notify(("磁盘文件已变更，buffer 已重载: %s"):format(vim.fn.fnamemodify(args.file, ":~:.")), vim.log.levels.WARN)
    end,
})

-- 系统剪贴板：OSC 52 当唯一出口，tmux buffer 当中转站
--
--   nvim yank ──OSC52──┐
--                      ├─→ tmux 截获入 buffer ──OSC52 转发──→ 本地机器剪贴板
--   tmux 里按 y ───────┘         │
--                                └──→ nvim 的 p 读 `tmux save-buffer -`
--
-- **不能用 DISPLAY 判断有没有本地剪贴板**：SSH 开了 X11 转发时 DISPLAY 会是
-- localhost:10.0，那个 X server 的剪贴板既不是你本地机器的、也不进 tmux buffer。
-- 按 DISPLAY 判断会让远程机器错误地走 xclip，结果 nvim 复制的东西 tmux 和本地
-- 都粘不到（实测踩过）。真正的判据是 SSH_CONNECTION / SSH_TTY。
vim.opt.clipboard = "unnamedplus"
vim.api.nvim_create_autocmd("VimEnter", {
    once = true, -- 延迟设置，避免被插件覆盖
    callback = function()
        local in_tmux = (vim.env.TMUX or "") ~= ""
        local is_remote = (vim.env.SSH_CONNECTION or "") ~= "" or (vim.env.SSH_TTY or "") ~= ""

        local copy, paste

        -- 真本地（非 SSH）：直接用系统工具，不绕 OSC 52（Terminal.app 之类并不支持它）。
        -- 探测只在这个分支里做——远程时探了也用不上。
        if not is_remote then
            local c, p
            if vim.fn.has("mac") == 1 and vim.fn.executable("pbcopy") == 1 then
                c, p = "pbcopy", "pbpaste"
            elseif (vim.env.WAYLAND_DISPLAY or "") ~= "" and vim.fn.executable("wl-copy") == 1 then
                c, p = "wl-copy", "wl-paste --no-newline"
            elseif (vim.env.DISPLAY or "") ~= "" and vim.fn.executable("xclip") == 1 then
                c, p = "xclip -selection clipboard", "xclip -selection clipboard -o"
            end
            if c then
                copy = { ["+"] = c, ["*"] = c }
                paste = { ["+"] = p, ["*"] = p }
            end
        end

        -- 其余情况（远程，或本地但没有可用工具）：复制走内置 OSC 52，零 fork。
        -- 在 tmux 内会被 tmux 一并写进它自己的 buffer 再转发给外层终端，一次到位
        -- （前提是 tmux 的 set-clipboard 为 on，改成 external 就不入 buffer，
        -- nvim ↔ tmux 那条腿会断）。
        if not copy then
            local osc52 = require("vim.ui.clipboard.osc52")
            if in_tmux then
                -- 有 tmux 就不需要自己缓存：粘贴直接读 tmux buffer，既能拿到 nvim
                -- 自己 yank 的（已被 tmux 截获入库），也能拿到 tmux copy-mode 里按 y
                -- 复制的，两个来源在这里统一
                local from_tmux = { "tmux", "save-buffer", "-" }
                copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") }
                paste = { ["+"] = from_tmux, ["*"] = from_tmux }
            else
                -- 裸 SSH 且没开 tmux：**不用 osc52.paste**，它要等终端回应 OSC 52 读，
                -- 而绝大多数终端出于安全不回——runtime 源码里写死先等 1s 再等 9s，
                -- 每次 p 都会卡住。退化成会话内缓存：yank 照样能到本地剪贴板，
                -- 粘贴取自己刚复制的内容。
                local lines, regtype = { "" }, "v"
                local function wrap(reg)
                    local send = osc52.copy(reg)
                    return function(l, rt)
                        lines, regtype = l, rt
                        send(l, rt)
                    end
                end
                local function from_cache()
                    return lines, regtype
                end
                copy = { ["+"] = wrap("+"), ["*"] = wrap("*") }
                paste = { ["+"] = from_cache, ["*"] = from_cache }
            end
        end

        local mode, degraded
        if type(copy["+"]) == "string" then
            mode = "系统工具（本地）：" .. copy["+"]
        elseif in_tmux then
            mode = "OSC 52 复制 + tmux buffer 粘贴"
        else
            mode = "OSC 52 复制 + 会话内缓存粘贴"
            degraded = "剪贴板降级：远程会话但没开 tmux。复制照样能到本地剪贴板，"
                .. "但 p 只能取回本次 nvim 自己复制的内容。开 tmux 即可与 tmux buffer 互通。"
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
                ("通路：%s\n远程（SSH）：%s\ntmux 内：%s\n\n本地终端收不收 OSC 52 检测不到，"):format(
                    mode,
                    is_remote and "是" or "否",
                    in_tmux and "是" or "否"
                ) .. "要验就复制一段再到本地按 Cmd+V。",
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

-- 自动保存：尽可能缩小"已改未存"窗口，让外部 reload 安全
local function autosave()
    if vim.bo.modified and require("config.util").is_writable_file_buf() then
        pcall(vim.cmd, "silent! lockmarks write")
    end
end

vim.api.nvim_create_autocmd(
    { "BufLeave", "FocusLost", "InsertLeave", "TextChanged" },
    {
        group = vim.api.nvim_create_augroup("AutoSave", { clear = true }),
        pattern = "*",
        callback = autosave,
    }
)

-- 外部改文件时：未修改的自动 reload；已有未保存改动的弹提示，避免静默覆盖
-- 注意：触发时当前 buffer 不一定是变更的那个，必须用 args.buf 判断
vim.api.nvim_create_autocmd("FileChangedShell", {
    group = grp_filechanged,
    pattern = "*",
    callback = function(args)
        vim.v.fcs_choice = vim.bo[args.buf].modified and "ask" or "reload"
    end,
})


