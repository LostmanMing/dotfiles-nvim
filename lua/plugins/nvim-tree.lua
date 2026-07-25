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
                },
                git = {
                    enable = true,
                    timeout = 2000,           -- git 操作超时（ms）
                },
                renderer = {
                    icons = {
                        show = { git = true },
                    },
                },
                on_attach = function(bufnr)
                    local api = require("nvim-tree.api")
                    -- 先挂默认键（g? 帮助、I 切 git-ignore、R 刷新、x/c/p 文件操作等），再覆盖自定义
                    api.config.mappings.default_on_attach(bufnr)
                    local function opts(desc)
                        return { desc = "nvim-tree: " .. desc, buffer = bufnr, nowait = true }
                    end
                    -- l: 预览文件，buffer打开但光标留在tree
                    vim.keymap.set("n", "l", api.node.open.preview, opts("Preview"))
                    -- Enter: 打开文件，光标跳到文件buffer
                    vim.keymap.set("n", "<CR>", api.node.open.edit, opts("Open"))
                    -- q: 聚焦到右侧编辑窗口
                    vim.keymap.set("n", "q", "<C-w>l", opts("Focus right window"))
                    -- a: 新建文件（光标在目录上）或新建同级文件（光标在文件上）
                    vim.keymap.set("n", "a", api.fs.create, opts("Create"))
                    -- r: 重命名
                    vim.keymap.set("n", "r", api.fs.rename, opts("Rename"))
                    -- d: 删除
                    vim.keymap.set("n", "d", api.fs.remove, opts("Delete"))
                end,
            })
        end,
    },
}
