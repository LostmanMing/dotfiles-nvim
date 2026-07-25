return {
    {
        -- 离开插入模式（回 normal）/离开命令行时自动切英文输入法，进插入模式恢复上次输入法
        -- 检测交给插件自带逻辑（fcitx5/fcitx/ibus/macism/im-select 全覆盖，比手写更准）
        -- 注意：SSH 到远程时 nvim 无法控制本地输入法，此功能仅本地 nvim 有效
        "keaising/im-select.nvim",
        event = "VeryLazy",
        opts = {
            -- 这些时机都切回英文：启动/重新聚焦/离开插入模式/离开命令行
            -- → 保证 normal 模式和命令模式都是英文
            set_default_events = { "VimEnter", "FocusGained", "InsertLeave", "CmdlineLeave" },
            -- 只有进插入模式才恢复上次输入法（方便继续打中文）
            set_previous_events = { "InsertEnter" },
            -- 没装切换工具的机器（如服务器）静默跳过，不报错
            keep_quiet_on_no_binary = true,
        },
        main = "im_select",
    },
}
