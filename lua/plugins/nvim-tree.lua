return {
    {
        "nvim-tree/nvim-tree.lua",
        version = "*",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        keys = {
            { "<C-n>", function()
                local api = require("nvim-tree.api")
                if not api.tree.is_visible() then
                    api.tree.open()
                elseif api.tree.is_tree_buf() then
                    api.tree.close()
                else
                    api.tree.focus()
                end
            end, desc = "切换目录树" },
        },
        config = function()
            require("nvim-tree").setup({
                view = {
                    width = 30,
                },
                update_focused_file = {
                    enable = true,
                    update_root = false,
                },
                renderer = {
                    icons = {
                        show = { git = true },
                    },
                },
                on_attach = function(bufnr)
                    local api = require("nvim-tree.api")
                    local function opts(desc)
                        return { desc = "nvim-tree: " .. desc, buffer = bufnr, nowait = true }
                    end
                    -- l: 预览文件，buffer打开但光标留在tree
                    vim.keymap.set("n", "l", api.node.open.preview, opts("Preview"))
                    -- Enter: 打开文件，光标跳到文件buffer
                    vim.keymap.set("n", "<CR>", api.node.open.edit, opts("Open"))
                    -- q: 聚焦到右侧编辑窗口
                    vim.keymap.set("n", "q", "<C-w>l", opts("Focus right window"))
                end,
                actions = {
                    open_file = {
                        quit_on_open = false,
                    },
                },
            })
        end,
    },
}
