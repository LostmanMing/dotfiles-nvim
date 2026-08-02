-- 特殊 buffer（Telescope 等）里不激活 flash；终端的普通模式允许
local function usable()
    return vim.bo.buftype == "" or vim.bo.buftype == "terminal"
end

-- 行跳转：把每行行首当匹配点，给每行发一个标签
-- max_length=0 防止敲字母后退化成普通搜索；label.after 让标签贴在行首
local function jump_line(forward)
    return function()
        if not usable() then return end
        require("flash").jump({
            pattern = "^",
            label = { after = { 0, 0 } },
            search = { mode = "search", max_length = 0, forward = forward, wrap = false },
        })
    end
end

return {
    {
        "folke/flash.nvim",
        event = "VeryLazy",
        opts = {},
        keys = {
            { "<leader>s", mode = { "n", "x", "o" }, function()
                if not usable() then return end
                require("flash").jump()
            end, desc = "Flash 字符跳转" },
            { "<leader>S", mode = { "n", "x", "o" }, function()
                if not usable() then return end
                require("flash").treesitter()
            end, desc = "Flash 选中语法节点" },
            { "<leader>j", mode = { "n", "x", "o" }, jump_line(true), desc = "Flash 跳到下方某行" },
            { "<leader>k", mode = { "n", "x", "o" }, jump_line(false), desc = "Flash 跳到上方某行" },
        },
    },
}
