return {
    {
        "sphamba/smear-cursor.nvim",
        -- 暂时禁用：snacks.scroll 靠反复恢复插值后的视口做平滑滚动，而那个记录含光标行，
        -- 一次滚动会被拆成约 20 步、每步都动光标 → smear 会给每一步都画拖影，两层动画叠在同一手势上。
        -- 想换回光标拖影就把这行删掉，同时关掉 snacks 的 scroll 模块。
        enabled = false,
        event = "VeryLazy",
        opts = {
            -- 光标移动拖影效果
            cursor_color = "#d3cdc3",       -- 拖影颜色（浅灰）
            stiffness = 0.8,                -- 拖影硬度，越大拖影越短
            trailing_stiffness = 0.5,       -- 尾部硬度
            distance_stop_animating = 0.5,  -- 小于此距离不触发动画
        },
    },
}
