-- 让 buffer 按 tab 隔离：每个 tab 只"拥有"在它里面开过的文件。
--
-- 为什么需要：bufferline 的 buffers 模式渲染的是**全局** buffer 列表，每个 tab 的
-- tabline 长得一模一样（实测纯文本完全相同，唯一区别是最右角那个小数字的颜色）。
-- 于是在临时 tab 里按 H/L 落到主 tab 的文件上时，画面和"主 tab 但分屏没了"无法区分，
-- 很容易误判成分屏布局被破坏。
--
-- 这个能力 **neovim 原生没有**——tab 被设计成"一组窗口布局"，不是 buffer 作用域。
-- bufferline README 的「How do I see only buffers per tab?」一节就指向这个插件。
--
-- 机制（读过源码 lua/scope/core.lua）：TabLeave 时把当前 tab 的 buffer 全部
-- 置为 buflisted=false 并缓存下来，TabEnter 时再把进入的那个 tab 的恢复成 true。
-- 因为动的是 buflisted 本身，所以 bufferline、H/L、`:ls`、`:bnext`，以及
-- keymaps.lua 里 q 的关闭逻辑（它数 buflisted）全都自动变成 tab 作用域，
-- 不需要各处分别打补丁——这也是没有自己用 custom_filter 手写的原因：
-- 那样只有 bufferline 是隔离的、其余仍是全局，反而割裂。
--
-- 代价：buffer 在别的 tab 里是 unlisted，`<leader>fb` 只看得到当前 tab 的。
-- 所以下面注册了 telescope 扩展，`<leader>fB` 可以跨 tab 找并**自动跳到那个 tab**。
-- 排查归属用 `:ScopeList`，搬 buffer 到别的 tab 用 `:ScopeMoveBuf`。
--
-- restore_state 保持默认 false：上游自己标注 session 恢复是实验性的，不碰。
return {
    {
        "tiagovla/scope.nvim",
        lazy = false,       -- 要在用户开始切 tab 前就挂上 TabLeave/TabEnter
        opts = {},
        config = function(_, opts)
            require("scope").setup(opts)
            -- 扩展放在这里加载而不是 telescope.lua：它 require("scope.core")，
            -- 必须在 scope 起来之后才 load，否则报错
            require("telescope").load_extension("scope")
            vim.keymap.set("n", "<leader>fB", "<cmd>Telescope scope buffers<CR>",
                { desc = "跨 tab 搜 buffer（会跳到所在 tab）" })
        end,
    },
}
