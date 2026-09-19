-- Neo-tree 非浮动预览机制（从 plugins/neo-tree.lua 拆出）。
-- 契约（勿改）：
--   * 跨模块引用：事件名 NeoTreePreviewBufferChanged 与 vim.b[buf].neo_tree_preview
--     被 bufferline（可见性与 Preview 分组）依赖；
--   * 文件路径的预览必须走 Neo-tree 原生 preview（不是订阅 CursorMoved 的 toggle_preview）；
--   * Dashboard 特例：preview_once 必须先把 Dashboard 窗口交给一次性 unlisted buffer，
--     否则 Neo-tree 会把它的 bufhidden=wipe 改成 hide，导致 EVA 浮窗残留；
--   * preview 窗口被关闭（:close 等）时由 M.setup() 注册的 WinClosed 清理状态。
-- 模块顶层不 require 插件：spec import 期即被加载（plugins/neo-tree.lua 头部）。
local M = {}

local preview_winbars = {}
local preview_buffer

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

function M.revert_filesystem_preview()
    require("neo-tree.sources.common.commands").revert_preview()
    if clear_preview_buffer(false) then refresh_bufferline() end
    restore_preview_winbars()
end

function M.preview_once(state)
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

function M.cancel_preview(state)
    require("neo-tree.sources.common.commands").cancel(state)
    if clear_preview_buffer(false) then refresh_bufferline() end
    restore_preview_winbars()
end

function M.quit_preview()
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

function M.open_selected(state)
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

-- 在 spec 的 config 里调用：注册 preview 窗口关闭时的状态清理
function M.setup()
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
end

return M
