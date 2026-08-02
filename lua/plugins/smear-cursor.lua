return {
    {
        "sphamba/smear-cursor.nvim",
        -- 与 snacks 的 scroll 模块二选一：scroll 靠反复恢复含光标行的插值视口做平滑滚动，
        -- 一次滚动约 20 步都会触发拖影，两层动画会叠在同一手势上。这里选拖影，故 scroll 不启用。
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
