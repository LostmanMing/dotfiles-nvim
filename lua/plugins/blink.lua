-- 补全引擎：blink.cmp
-- 从 nvim-cmp 迁过来的原因：nvim-cmp 作者在 README 里明确写"这是业余项目、不要期待修复"，
-- 2026 全年只有 9 个 commit；社区接手的 fork（magazine.nvim）也已归档。
-- blink 自带 LSP / 路径 / buffer / snippet 源，所以 cmp-nvim-lsp、cmp-buffer、cmp-path、
-- cmp_luasnip、LuaSnip 五个插件一起删掉；snippet 走 nvim 内置 vim.snippet，
-- friendly-snippets 仍然保留（blink 直接读它的 VSCode 格式片段）。
return {
    {
        "saghen/blink.cmp",
        -- 钉在 1.x：V2 正在重写中，README 顶部挂着 breaking changes 警告，
        -- 且要求额外安装 blink.lib。稳定优先，等 V2 发布正式版再考虑。
        version = "1.*",
        event = "InsertEnter",
        dependencies = { "rafamadriz/friendly-snippets" },
        opts = {
            keymap = {
                -- preset=none：不用预设，完整保留原来 nvim-cmp 时期的三个键位语义
                preset = "none",
                -- 回车确认补全；没有选中任何项时 accept 不消费按键，落到 fallback 走原生换行
                ["<CR>"] = { "accept", "fallback" },
                -- Tab：菜单开着就往下选，否则尝试跳到 snippet 的下一个占位符，都不适用才是原生 Tab
                ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
                ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
                -- 上下键选择 + Ctrl-e 取消，保持和原生 pum 一致的直觉
                ["<Up>"] = { "select_prev", "fallback" },
                ["<Down>"] = { "select_next", "fallback" },
                ["<C-e>"] = { "cancel", "fallback" },
            },
            completion = {
                list = {
                    selection = {
                        -- 不预选第一项：等价于原来 completeopt 里的 noselect + confirm{select=false}，
                        -- 避免回车误选到不想要的补全项
                        preselect = false,
                        auto_insert = false,
                    },
                },
                menu = {
                    -- 与 winborder=rounded 的浮窗风格统一
                    border = "rounded",
                    draw = {
                        -- 加一列展示补全项类型（函数/变量/片段…），比纯文字列表好扫
                        columns = {
                            { "kind_icon", "label", gap = 1 },
                            { "kind" },
                        },
                    },
                },
                documentation = {
                    auto_show = true,
                    auto_show_delay_ms = 200,
                    window = { border = "rounded" },
                },
                -- 幽灵文字：把当前选中项的剩余部分以灰字预览在光标后
                ghost_text = { enabled = true },
            },
            -- 不启用 blink 的签名浮窗：lsp.lua 里已有自己的 InsertCharPre 触发逻辑
            -- 和 <C-k> 手动触发，两套会叠出双浮窗
            signature = { enabled = false },
            sources = {
                default = { "lsp", "snippets", "path", "buffer" },
            },
        },
    },
}
