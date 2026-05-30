-- lazy.nvim 自动安装 + 初始化

-- 1. 检查 lazy.nvim 是否已安装，没有就自动 git clone
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    vim.api.nvim_echo({
        { "正在安装 lazy.nvim...\n\n", "DiagnosticInfo" },
    }, true, {})
    local out = vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        lazypath,
    })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "安装 lazy.nvim 失败\n", "ErrorMsg" },
            { vim.trim(out or ""), "WarningMsg" },
            { "\n按任意键退出...", "MoreMsg" },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)

-- 2. 加载所有插件（从 lua/plugins/ 目录自动导入）
require("lazy").setup({
    { import = "plugins" },      -- 自动扫描 lua/plugins/*.lua
}, {
    defaults = {
        lazy = true,             -- 所有插件默认延迟加载
        version = false,         -- 使用最新版（不锁 semver）
    },
    install = {
        colorscheme = { "tokyonight" },  -- 启动时就安装的 colorscheme
    },
    checker = {
        enabled = true,          -- 自动检查插件更新
        notify = false,          -- 不弹更新通知
    },
    change_detection = {
        notify = false,          -- 配置文件变更不弹通知
    },
})
