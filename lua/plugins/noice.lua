return {
    {
        "folke/noice.nvim",
        event = "VeryLazy",
        dependencies = {
            "MunifTanjim/nui.nvim",
            -- 通知后端交给 snacks.notifier：noice 的 notify 视图里 snacks 后端优先级
            -- 在 nvim-notify 之前，启用了就自动走它，所以这里不再依赖 nvim-notify
        },
        opts = {
            cmdline = {
                view = "cmdline_popup",         -- : 命令行居中浮窗
            },
            lsp = {
                -- LSP 进度条：clangd 等索引大项目时右下角显示进度，不刷屏
                progress = { enabled = true },
                -- 用 treesitter 高亮 LSP 悬浮/签名里的 markdown 与代码
                override = {
                    ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                    ["vim.lsp.util.stylize_markdown"] = true,
                    ["cmp.entry.get_documentation"] = true,
                },
            },
            presets = {
                bottom_search = true,           -- / 搜索仍用底部（跨页搜索更顺手）
                command_palette = true,         -- : 命令行与补全菜单贴在一起
                long_message_to_split = true,   -- 超长消息用 split 显示
                lsp_doc_border = true,          -- 悬浮文档带边框
            },
            routes = {
                -- 写文件的 "xxL, xxB" 之类噪音消息不弹
                {
                    filter = { event = "msg_show", find = "%d+L, %d+B" },
                    opts = { skip = true },
                },
            },
        },
        keys = {
            { "<leader>snl", function() require("noice").cmd("last") end, desc = "Noice 最近消息" },
            { "<leader>snh", function() require("noice").cmd("history") end, desc = "Noice 消息历史" },
            { "<leader>snd", function() require("noice").cmd("dismiss") end, desc = "关闭所有通知" },
        },
    },
}
