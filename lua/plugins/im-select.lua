return {
    {
        -- 离开插入模式（回 normal）自动切英文输入法，进插入模式恢复上次输入法
        -- 按 OS + 可用工具自动选择切换命令；检测不到则不启用（不报错）
        -- 注意：SSH 到远程时 nvim 无法控制本地输入法，此功能仅本地 nvim 有效
        "keaising/im-select.nvim",
        event = "VeryLazy",
        config = function()
            local sysname = (vim.loop or vim.uv).os_uname().sysname
            local function has(bin) return vim.fn.executable(bin) == 1 end

            local cmd
            if sysname == "Darwin" then
                cmd = (has("macism") and "macism")
                    or (has("im-select") and "im-select")
            elseif sysname:match("Windows") then
                cmd = has("im-select.exe") and "im-select.exe"
            else -- Linux / WSL
                if vim.fn.has("wsl") == 1 and has("im-select.exe") then
                    cmd = "im-select.exe"
                elseif has("fcitx5-remote") then
                    cmd = "fcitx5-remote"
                elseif has("fcitx-remote") then
                    cmd = "fcitx-remote"
                elseif has("ibus") then
                    cmd = "ibus"
                end
            end

            if not cmd then return end  -- 没有可用切换工具：跳过，避免插件报错
            require("im_select").setup({
                default_command = cmd,
                -- 这些时机都切回英文：启动/重新聚焦/离开插入模式/离开命令行
                -- → 保证 normal 模式和命令模式都是英文
                set_default_events = { "VimEnter", "FocusGained", "InsertLeave", "CmdlineLeave" },
                -- 只有进插入模式才恢复上次输入法（方便继续打中文）
                set_previous_events = { "InsertEnter" },
            })
        end,
    },
}
