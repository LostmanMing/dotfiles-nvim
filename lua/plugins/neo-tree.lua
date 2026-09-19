-- 文件树与 git_status 侧栏。预览机制（preview_once / winbar / 跨 tab 可见性信号）
-- 已拆到 config/neo-tree-preview.lua；本文件只留 spec、source 切换、复制路径与刷新。
local preview = require("config.neo-tree-preview")
local directory_startup = vim.fn.argc() == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1

local function sidebar_tree_win()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].filetype == "neo-tree" then return win, vim.b[buf].neo_tree_source end
    end
end

local function open_filesystem_tree()
    require("neo-tree.command").execute({
        action = "focus",
        source = "filesystem",
        position = "left",
        reveal = true,
    })
end

local function toggle_git_status()
    local _, source = sidebar_tree_win()
    if source == "git_status" then
        require("neo-tree.command").execute({ action = "close", source = "git_status", position = "left" })
        open_filesystem_tree()
        return
    end

    if source == "filesystem" then
        preview.revert_filesystem_preview()
        require("neo-tree.command").execute({ action = "close", source = "filesystem", position = "left" })
    end
    require("neo-tree.command").execute({ action = "focus", source = "git_status", position = "left" })
end

local function copy_selected_path(state)
    local node = state.tree:get_node()
    if not node or node.type == "message" then return end

    require("neo-tree.sources.common.commands").copy_to_clipboard(state)
    vim.fn.setreg("+", node.path or node:get_id(), "c")
end

local function refresh_source(state)
    local source = state.name
    local label = source == "git_status" and "Git 状态" or "目录树"
    local id = "neo_tree_refresh_" .. source
    local started = vim.uv.hrtime()
    vim.notify(label .. "刷新中…", vim.log.levels.INFO, { title = "Neo-tree", id = id })
    vim.cmd("redraw")

    local ok, err = pcall(require("neo-tree.sources.manager").refresh, source, function()
        vim.schedule(function()
            local ms = (vim.uv.hrtime() - started) / 1e6
            vim.notify(("%s已刷新（%.0f ms）"):format(label, ms), vim.log.levels.INFO,
                { title = "Neo-tree", id = id })
        end)
    end)
    if not ok then
        vim.notify(("%s刷新失败: %s"):format(label, tostring(err)), vim.log.levels.ERROR,
            { title = "Neo-tree", id = id })
    end
end

return {
    {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        lazy = false,
        dependencies = {
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
            "nvim-tree/nvim-web-devicons",
        },
        keys = {
            {
                "<C-n>",
                function()
                    local tree_win, source = sidebar_tree_win()
                    if not tree_win then
                        open_filesystem_tree()
                    elseif tree_win == vim.api.nvim_get_current_win() then
                        preview.revert_filesystem_preview()
                        require("neo-tree.command").execute({ action = "close", source = source, position = "left" })
                    else
                        vim.api.nvim_set_current_win(tree_win)
                    end
                end,
                desc = "切换目录树",
            },
        },
        opts = {
            use_popups_for_input = false,
            sources = { "filesystem", "git_status" },
            close_if_last_window = false,
            enable_git_status = true,
            window = {
                position = "left",
                width = 30,
                auto_expand_width = false,
            },
            filesystem = {
                window = {
                    mappings = {
                        ["l"] = { preview.preview_once, config = { use_float = false } },
                        ["<cr>"] = preview.open_selected,
                        ["<esc>"] = preview.cancel_preview,
                        ["q"] = preview.quit_preview,
                        ["a"] = "add",
                        ["r"] = "rename",
                        ["d"] = "delete",
                        ["y"] = copy_selected_path,
                        ["I"] = "toggle_hidden",
                        ["g"] = { toggle_git_status, nowait = false },
                        ["g?"] = "show_help",
                        ["R"] = refresh_source,
                    },
                },
                hijack_netrw_behavior = "open_default",
                follow_current_file = {
                    enabled = true,
                    leave_dirs_open = false,
                },
                filtered_items = {
                    visible = true,
                    hide_dotfiles = false,
                    hide_gitignored = true,
                    hide_ignored = false,
                    ignore_files = {},
                    hide_hidden = false,
                    hide_by_name = {},
                    hide_by_pattern = {},
                },
            },
            git_status = {
                window = {
                    mappings = {
                        ["g"] = { toggle_git_status, nowait = false },
                        ["y"] = copy_selected_path,
                        ["l"] = { preview.preview_once, config = { use_float = false } },
                        ["<cr>"] = preview.open_selected,
                        ["<esc>"] = preview.cancel_preview,
                        ["q"] = preview.quit_preview,
                        ["R"] = refresh_source,
                    },
                },
            },
        },
        config = function(_, opts)
            require("neo-tree").setup(opts)
            preview.setup()

            if directory_startup then
                local events = require("neo-tree.events")
                local id = "NeoTreeDirectoryStartupPlaceholder"
                events.unsubscribe({ id = id })
                events.subscribe({
                    id = id,
                    event = events.NEO_TREE_WINDOW_AFTER_OPEN,
                    handler = function()
                        vim.schedule(function()
                            for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
                                local buf = vim.api.nvim_win_get_buf(win)
                                if vim.bo[buf].filetype == "" and vim.api.nvim_buf_get_name(buf) == "" then
                                    vim.bo[buf].buflisted = false
                                    events.unsubscribe({ id = id })
                                    return
                                end
                            end
                        end)
                    end,
                })
            end
        end,
    },
}
