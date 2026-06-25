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
                    enable = true,        -- 自动定位到当前 buffer 对应的文件
                    update_root = false,  -- 不改 nvim-tree 的根，只是高亮+展开到该文件
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
                    -- l 打开文件（不关树）
                    vim.keymap.set("n", "l", api.node.open.edit, opts("Open"))
                    -- Enter: 文件夹展开/折叠，文件打开并关闭树
                    vim.keymap.set("n", "<CR>", function()
                        api.node.open.edit()
                        local node = api.tree.get_node_under_cursor()
                        if node and node.type ~= "directory" then
                            api.tree.close()
                        end
                    end, opts("Open"))
                    -- 覆盖默认 q（默认 close tree）：focus 到右侧代码窗
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
