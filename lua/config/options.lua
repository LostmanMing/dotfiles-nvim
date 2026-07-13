-- ==========================================
-- 基础编辑器设置
-- ==========================================

-- 行号
vim.opt.number = true              -- 显示绝对行号
vim.opt.relativenumber = true      -- 显示相对行号（方便做 5j 10k 这类跳转）

-- 缩进
vim.opt.expandtab = true           -- Tab 键插入空格而非真正的 Tab 字符
vim.opt.shiftwidth = 4             -- >>  <<  缩进/反缩进 4 格
vim.opt.tabstop = 4                -- Tab 字符在屏幕上显示为 4 个空格宽度

-- 鼠标
vim.opt.mouse = "a"                -- 所有模式下允许鼠标（点击定位、滚轮、拖动窗格）

-- 文件自动刷新
vim.opt.autoread = true            -- 外部修改文件时自动重新读取

-- autoread 仅在 nvim 主动 checktime 时生效，加 autocmd 在常见时机触发检查
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
    group = vim.api.nvim_create_augroup("AutoReload", { clear = true }),
    pattern = "*",
    callback = function()
        if vim.fn.mode() ~= "c" and vim.fn.bufexists(0) == 1 then
            vim.cmd("checktime")
        end
    end,
})

-- 磁盘文件被外部修改并重载后，给用户一行提示
vim.api.nvim_create_autocmd("FileChangedShellPost", {
    pattern = "*",
    callback = function()
        vim.notify("File changed on disk. Buffer reloaded.", vim.log.levels.WARN)
    end,
})

-- 系统剪贴板：根据 OS 和环境自动选择，延迟到插件加载后避免被覆盖
vim.opt.clipboard = "unnamedplus"
vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = function()
        local copy_cmd, paste_cmd
        if vim.fn.has("mac") == 1 then
            -- macOS: tmux 内需要 reattach，直接裸调也兼容非 tmux
            copy_cmd = "reattach-to-user-namespace pbcopy"
            paste_cmd = "reattach-to-user-namespace pbpaste"
        elseif vim.fn.executable("wl-copy") == 1 then
            copy_cmd = "wl-copy"
            paste_cmd = "wl-paste"
        else
            copy_cmd = "xclip -selection clipboard"
            paste_cmd = "xclip -selection clipboard -o"
        end
        vim.g.clipboard = {
            name = "OS-clipboard",
            copy = { ["+"] = copy_cmd, ["*"] = copy_cmd },
            paste = { ["+"] = paste_cmd, ["*"] = paste_cmd },
            cache_enabled = 0,
        }
    end,
})

-- 搜索
vim.opt.hlsearch = true            -- 搜索匹配项高亮
vim.opt.ignorecase = true          -- 搜索时忽略大小写
vim.opt.smartcase = true           -- 但如果搜索词包含大写字母，则区分大小写

-- 窗口分割
vim.opt.splitbelow = true          -- :split  新窗口开在下方
vim.opt.splitright = true          -- :vsplit 新窗口开在右侧

-- 文件安全
vim.opt.swapfile = false           -- 不产生 .swp 交换文件（减少磁盘杂物）
vim.opt.backup = false             -- 不产生 ~ 备份文件
vim.opt.undofile = true            -- 持久化撤销记录（关掉重开还能 u 撤销）

-- 视觉
vim.opt.signcolumn = "yes"           -- sign 列：git 标记

-- 诊断显示：行尾虚拟文字 + 波浪下划线，不放 W/E 到 sign 列
vim.diagnostic.config({
    virtual_text = true,
    signs = false,
    underline = true,
})

vim.opt.cursorline = true          -- 高亮当前光标行
vim.opt.showmode = false           -- 不显示 --INSERT-- 等模式提示（状态栏会显示）

-- 滚动
vim.opt.scrolloff = 8              -- 光标距离屏幕上下边缘至少 8 行时开始滚动
vim.opt.sidescrolloff = 8          -- 光标距离屏幕左右边缘至少 8 列时开始滚动
vim.opt.wrap = true                -- 长行自动折行，不截断

-- 响应时间
vim.opt.updatetime = 300           -- 光标停 0.3 秒后触发 CursorHold 事件（影响 LSP/git 标记刷新速度）
vim.opt.timeoutlen = 300           -- 按键序列等待时间（如 <leader>ff 要在 0.3 秒内按完）

-- 补全菜单
vim.opt.pumheight = 10             -- 补全弹窗最多显示 10 行
vim.opt.completeopt = {            -- 补全行为
    "menuone",                     --   即使只有 1 个匹配也显示菜单
    "noselect",                    --   不自动选中第一项（Enter 不会误选）
}

-- 颜色
vim.opt.termguicolors = true       -- 启用 24-bit 真彩色（装 colorscheme 的前提）

-- 文件末尾换行
vim.opt.fixendofline = false       -- 保存时不自动在文件末尾补换行符

-- 自动保存：尽可能缩小"已改未存"窗口，让外部 reload 安全
local function autosave()
    if vim.bo.modified
        and vim.bo.modifiable
        and vim.bo.buftype == ""
        and vim.api.nvim_buf_get_name(0) ~= "" then
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

-- 外部改文件时直接 reload，不弹 y/n（依赖上面的自动保存把 buffer 写到磁盘）
vim.api.nvim_create_autocmd("FileChangedShell", {
    pattern = "*",
    callback = function()
        vim.v.fcs_choice = "reload"
    end,
})


