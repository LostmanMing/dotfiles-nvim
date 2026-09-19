-- 主题规格：插件 / 主题名 / opts 都在 config/theme.lua（统一入口），这里只是 lazy 壳
local theme = require("config.theme")
return {
    {
        theme.colorscheme.plugin,
        lazy = false,
        priority = 1001,        -- 比 snacks（1000）高一档：等优先级时 lazy 加载顺序不确定，
                                -- 让配色确定地先于 snacks 加载
        config = function()
            theme.colorscheme.apply()
        end,
    },
}
