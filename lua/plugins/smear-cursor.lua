return {
    {
        "sphamba/smear-cursor.nvim",
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
