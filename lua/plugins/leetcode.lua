-- 登录守卫：未登录时不直接报 "User not logged-in"，
-- 而是提示去浏览器拿 cookie 并弹出输入框，粘贴后自动执行原命令
local function leet_guard(cmd_name)
    return function()
        local config = require("leetcode.config")
        if config.auth.is_signed_in then
            vim.cmd("Leet " .. cmd_name)
        else
            vim.notify(
                "尚未登录 leetcode.cn：浏览器登录后 F12 → Console 输入 document.cookie 回车并复制，"
                    .. "粘贴到弹出的输入框中即可",
                vim.log.levels.WARN,
                { title = "leetcode.nvim" }
            )
            require("leetcode.command").cookie_prompt(function(ok)
                if ok then
                    vim.cmd("Leet " .. cmd_name)
                end
            end)
        end
    end
end

return {
    {
        "kawre/leetcode.nvim",
        build = ":TSUpdate html",
        cmd = { "Leet" },
        dependencies = {
            "nvim-telescope/telescope.nvim",
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
            "nvim-treesitter/nvim-treesitter",
            "nvim-tree/nvim-web-devicons",
        },
        opts = {
            cn = { enabled = true }, -- 中文站 leetcode.cn
            lang = "cpp",
        },
        config = function(_, opts)
            require("leetcode").setup(opts)
            -- setup() 只注册了 nargs=0 的启动器 :Leet（start_with_cmd），
            -- 带子命令的 :Leet（list/daily/random/...）由 cmd.setup() 注册，
            -- 而它只在 leetcode.start()（进仪表盘）时被调用。此处补注册，
            -- 否则 <leader>ll 这类 :Leet list 会报 E488: Trailing characters。
            -- 同时初始化 config.storage（cookie 缓存等依赖它，setup() 只 apply 不 setup）
            require("leetcode.config").setup()
            require("leetcode.command").setup()
            -- 登录成功回调会调 start_user_session()（切到仪表盘菜单页），它假定
            -- 仪表盘已挂载（_Lc_state.menu）；我们走命令流没有 menu，直接替换为
            -- 安全实现。登录后的真正动作由 guard 的回调执行原命令。
            require("leetcode.command").start_user_session = function() end

            -- 用已存储的 cookie 恢复登录态（config.auth 是内存态，新会话为空；
            -- Auth.user 会用存的 cookie 验证并写回 config.auth，cookie 过期则
            -- 内部自动清除并返回 err，pcall 兜底）
            local config = require("leetcode.config")
            local cookie_file = config.storage.cache:joinpath("cookie_cn"):absolute()
            if vim.fn.filereadable(cookie_file) == 1 then
                vim.schedule(function()
                    pcall(require("leetcode.api.auth").user)
                end)
            end
        end,
        keys = {
            { "<leader>ld", leet_guard("daily"), desc = "每日一题" },
            { "<leader>ll", leet_guard("list"), desc = "题目列表" },
            { "<leader>lr", leet_guard("random"), desc = "随机一题" },
        },
    },
}
