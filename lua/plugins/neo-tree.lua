local preview_winbars = {}
local preview_buffer
local directory_startup = vim.fn.argc() == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1

local function refresh_bufferline()
    vim.api.nvim_exec_autocmds("User", { pattern = "NeoTreePreviewBufferChanged", modeline = false })
    vim.cmd("redrawtabline")
end

local function clear_preview_buffer(keep_listed)
    local buf = preview_buffer
    preview_buffer = nil
    if not buf or not vim.api.nvim_buf_is_valid(buf) then return false end

    vim.b[buf].neo_tree_preview = nil
    if not keep_listed then vim.bo[buf].buflisted = false end
    return true
end

local function set_preview_buffer(buf)
    if preview_buffer == buf then return false end

    local changed = clear_preview_buffer(false)
    if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buflisted then return changed end

    vim.bo[buf].buflisted = true
    vim.b[buf].neo_tree_preview = true
    preview_buffer = buf
    return true
end

local function sidebar_tree_win()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].filetype == "neo-tree" then return win, vim.b[buf].neo_tree_source end
    end
end

local function save_preview_winbar(win)
    if not vim.api.nvim_win_is_valid(win) then return end
    if preview_winbars[win] == nil then preview_winbars[win] = vim.wo[win].winbar end
end

local function set_preview_winbar(win)
    if not vim.api.nvim_win_is_valid(win) then return end
    require("dropbar.utils.bar").attach(vim.api.nvim_win_get_buf(win), win)
end

local function restore_preview_winbars()
    local target
    local target_winbar
    for win, winbar in pairs(preview_winbars) do
        if vim.api.nvim_win_is_valid(win) then
            vim.wo[win].winbar = winbar
            target = win
            target_winbar = winbar
        end
        preview_winbars[win] = nil
    end
    return target, target_winbar
end

local function open_filesystem_tree()
    require("neo-tree.command").execute({
        action = "focus",
        source = "filesystem",
        position = "left",
        reveal = true,
    })
end

local function revert_filesystem_preview()
    require("neo-tree.sources.common.commands").revert_preview()
    if clear_preview_buffer(false) then refresh_bufferline() end
    restore_preview_winbars()
end

local function preview_once(state)
    local node = state.tree:get_node()
    if node and node.type == "directory" then
        if state.name == "filesystem" then
            require("neo-tree.sources.filesystem.commands").toggle_node(state)
        else
            require("neo-tree.sources.common.commands").toggle_node(state)
        end
        return
    end

    local preview_win, is_tree_win = require("neo-tree.utils").get_appropriate_window(state)
    local previous_buf
    local preserve_previous_listing = false
    if preview_win and vim.api.nvim_win_is_valid(preview_win) and not is_tree_win then
        save_preview_winbar(preview_win)
        previous_buf = vim.api.nvim_win_get_buf(preview_win)
        preserve_previous_listing = vim.bo[previous_buf].buflisted and previous_buf ~= preview_buffer
        if vim.bo[previous_buf].filetype == "snacks_dashboard" then
            local placeholder = vim.api.nvim_create_buf(false, false)
            vim.bo[placeholder].bufhidden = "wipe"
            vim.api.nvim_win_set_buf(preview_win, placeholder)
        end
    end

    require("neo-tree.sources.common.commands").preview(state)
    if preserve_previous_listing and previous_buf then
        -- Neo-tree unlists the hidden target after its preview call returns.
        vim.defer_fn(function()
            if vim.api.nvim_buf_is_valid(previous_buf) then
                vim.bo[previous_buf].buflisted = true
                refresh_bufferline()
            end
        end, 20)
    end
    if preview_win and vim.api.nvim_win_is_valid(preview_win) and vim.w[preview_win].neo_tree_preview == 1 then
        set_preview_winbar(preview_win)
        if set_preview_buffer(vim.api.nvim_win_get_buf(preview_win)) then refresh_bufferline() end
    end
end

local function cancel_preview(state)
    require("neo-tree.sources.common.commands").cancel(state)
    if clear_preview_buffer(false) then refresh_bufferline() end
    restore_preview_winbars()
end

local function quit_preview()
    require("neo-tree.sources.common.commands").revert_preview()
    if clear_preview_buffer(false) then refresh_bufferline() end
    local target, winbar = restore_preview_winbars()
    if target then
        vim.api.nvim_set_current_win(target)
        vim.schedule(function()
            if vim.api.nvim_win_is_valid(target) then vim.wo[target].winbar = winbar end
        end)
    else
        vim.cmd("wincmd l")
    end
end

local function open_selected(state)
    local node = state.tree:get_node()
    local promoted_buffer
    if node and node.type ~= "directory" then
        local is_previewed = preview_buffer
            and vim.api.nvim_buf_is_valid(preview_buffer)
            and vim.api.nvim_buf_get_name(preview_buffer) == node.path
        promoted_buffer = is_previewed and preview_buffer or nil
        if clear_preview_buffer(is_previewed) then refresh_bufferline() end
        restore_preview_winbars()
    end
    if state.name == "filesystem" then
        require("neo-tree.sources.filesystem.commands").open(state)
    else
        require("neo-tree.sources.common.commands").open(state)
    end
    if promoted_buffer and vim.api.nvim_buf_is_valid(promoted_buffer) then
        vim.bo[promoted_buffer].buflisted = true
        refresh_bufferline()
    end
end

local function toggle_git_status()
    local _, source = sidebar_tree_win()
    if source == "git_status" then
        require("neo-tree.command").execute({ action = "close", source = "git_status", position = "left" })
        open_filesystem_tree()
        return
    end

    if source == "filesystem" then
        revert_filesystem_preview()
        require("neo-tree.command").execute({ action = "close", source = "filesystem", position = "left" })
    end
    require("neo-tree.command").execute({ action = "focus", source = "git_status", position = "left" })
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
                    if source == "git_status" then
                        require("neo-tree.command").execute({ action = "close", source = "git_status", position = "left" })
                        open_filesystem_tree()
                    elseif not tree_win then
                        open_filesystem_tree()
                    elseif tree_win == vim.api.nvim_get_current_win() then
                        revert_filesystem_preview()
                        require("neo-tree.command").execute({
                            action = "close",
                            source = "filesystem",
                            position = "left",
                        })
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
                        ["l"] = { preview_once, config = { use_float = false } },
                        ["<cr>"] = open_selected,
                        ["<esc>"] = cancel_preview,
                        ["q"] = quit_preview,
                        ["a"] = "add",
                        ["r"] = "rename",
                        ["d"] = "delete",
                        ["I"] = "toggle_hidden",
                        ["g"] = { toggle_git_status, nowait = false },
                        ["g?"] = "show_help",
                        ["R"] = function()
                            local id = "neo_tree_refresh"
                            local started = vim.uv.hrtime()
                            vim.notify("目录树刷新中…", vim.log.levels.INFO, { title = "Neo-tree", id = id })
                            vim.cmd("redraw")

                            local ok, err = pcall(require("neo-tree.sources.manager").refresh, "filesystem", function()
                                vim.schedule(function()
                                    local ms = (vim.uv.hrtime() - started) / 1e6
                                    vim.notify(("目录树已刷新（%.0f ms）"):format(ms), vim.log.levels.INFO,
                                        { title = "Neo-tree", id = id })
                                end)
                            end)
                            if not ok then
                                vim.notify(("目录树刷新失败: %s"):format(tostring(err)), vim.log.levels.ERROR,
                                    { title = "Neo-tree", id = id })
                            end
                        end,
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
                        ["l"] = { preview_once, config = { use_float = false } },
                        ["<cr>"] = open_selected,
                        ["<esc>"] = cancel_preview,
                        ["q"] = quit_preview,
                    },
                },
            },
        },
        config = function(_, opts)
            require("neo-tree").setup(opts)
            local group = vim.api.nvim_create_augroup("NeoTreePreviewWinbar", { clear = true })
            vim.api.nvim_create_autocmd("WinClosed", {
                group = group,
                callback = function(args)
                    local win = tonumber(args.match)
                    local was_preview = preview_winbars[win] ~= nil
                    preview_winbars[win] = nil
                    if was_preview and clear_preview_buffer(false) then refresh_bufferline() end
                end,
            })
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
