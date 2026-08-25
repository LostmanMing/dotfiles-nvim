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
                    preserve_window_proportions = true,
                },
                update_focused_file = {
                    enable = true,
                },
                filters = {
                    -- 不隐藏 .gitignore 排除的文件（默认 true=隐藏）。
                    -- 运行时按 I 可临时切换回隐藏
                    git_ignored = false,
                },
                git = {
                    enable = true,
                    timeout = 2000,           -- git 操作超时（ms）
                },
                renderer = {
                    icons = {
                        show = { git = true },
                    },
                    -- 按 git 状态给**文件名**上色（默认 "none" 不上色）。
                    -- gitignore 的文件走 NvimTreeGitFileIgnoredHL，它默认链到 Comment，
                    -- 所以自动是灰的——效果和 VSCode 里被忽略的文件变暗一致。
                    -- 用 "name" 而不是 "all"：图标有自己的颜色组，不用再上一遍。
                    highlight_git = "name",
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
                    -- R: 刷新。默认的 R 没有任何反馈，慢文件系统（virtiofs 之类）上
                    -- 按下去像没反应，所以套一层通知。
                    -- 做不了真进度条：nvim-tree 不暴露「已处理/总数」这类进度信号，
                    -- 只有开始和结束两个时刻可用。
                    vim.keymap.set("n", "R", function()
                        local nid = "nvim_tree_reload"
                        vim.notify("目录树刷新中…", vim.log.levels.INFO,
                            { title = "nvim-tree", id = nid })
                        -- 必须先 redraw：reload 是同步的，不先画出来这条通知会被
                        -- 一直压到刷新结束才显示，等于没有
                        vim.cmd("redraw")
                        local t0 = vim.uv.hrtime()
                        api.tree.reload()
                        local ms = (vim.uv.hrtime() - t0) / 1e6
                        -- 同一个 id 会就地替换上面那条，不会叠成两条
                        -- 耗时只覆盖文件系统这部分：git 状态是带回调异步跑的
                        -- （见 nvim-tree/git/init.lua），图标可能稍后才填上
                        vim.notify(("目录树已刷新（%.0f ms）"):format(ms), vim.log.levels.INFO,
                            { title = "nvim-tree", id = nid })
                    end, opts("Refresh"))
                end,
            })
        end,
    },
}
