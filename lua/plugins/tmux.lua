return {
    {
        -- nvim ↔ tmux 无缝导航（Ctrl+hjkl）
        -- tmux 侧是 tmux.conf 里的原生 is_vim 绑定，不依赖 TPM
        "christoomey/vim-tmux-navigator",
        lazy = false,                   -- 不懒加载：按键映射需启动即生效
        keys = {
            { "<C-h>", "<cmd>TmuxNavigateLeft<cr>",  desc = "左移窗口/tmux 面板" },
            { "<C-j>", "<cmd>TmuxNavigateDown<cr>",  desc = "下移窗口/tmux 面板" },
            { "<C-k>", "<cmd>TmuxNavigateUp<cr>",    desc = "上移窗口/tmux 面板" },
            { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "右移窗口/tmux 面板" },
        },
        init = function()
            -- 禁用插件默认映射：它会映射 <C-\>（跳上一面板），与 toggleterm 的开关键冲突
            vim.g.tmux_navigator_no_mappings = 1
        end,
    },
}
