local M = {}

local defaults = {
    enabled = true,
    save = {
        events = { "BufLeave", "FocusLost", "InsertLeave", "TextChanged" },
        workspace_edits = true,
        background_modified_buffers = true,
    },
    reload = {
        checktime_events = { "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" },
    },
    notifications = {
        enabled = true,
        title = "AutoSave",
    },
}

local config = vim.deepcopy(defaults)
local file_util = require("config.util")
local autosave_state = {}
local disk_signatures = {}
local disk_signature_known = {}
local failed_workspace_ticks = {}
local pending_saves = {}
local attached_buffers = {}
local workspace_depth = 0
local workspace_stack = {}
local original_apply_workspace_edit
local original_apply_text_edits
local workspace_edit_wrapper
local text_edits_wrapper

local function pack(...)
    return { n = select("#", ...), ... }
end

local unpack_values = table.unpack or unpack

local group_names = {
    "ConfigAutoSaveDiskState",
    "ConfigAutoSaveReload",
    "ConfigAutoSaveFileChanged",
    "ConfigAutoSave",
}

local function clear_groups()
    for _, name in ipairs(group_names) do
        vim.api.nvim_create_augroup(name, { clear = true })
    end
end

local function group(name)
    return vim.api.nvim_create_augroup(name, { clear = true })
end

local function notify(message, level)
    if config.notifications.enabled then
        vim.notify(message, level or vim.log.levels.WARN, { title = config.notifications.title })
    end
end

local function reset_autosave_state(buf)
    autosave_state[buf] = nil
end

local function get_autosave_state(buf)
    autosave_state[buf] = autosave_state[buf] or {}
    return autosave_state[buf]
end

local function disk_signature(buf)
    return vim.uv.fs_stat(vim.api.nvim_buf_get_name(buf))
end

local function remember_disk_signature(buf)
    disk_signatures[buf] = disk_signature(buf)
    disk_signature_known[buf] = true
end

local function disk_has_changed(buf)
    local current = disk_signature(buf)
    if not disk_signature_known[buf] then
        disk_signatures[buf] = current
        disk_signature_known[buf] = true
        return false
    end

    local known = disk_signatures[buf]
    if known == nil or current == nil then return known ~= current end
    return known.size ~= current.size
        or known.mtime.sec ~= current.mtime.sec
        or known.mtime.nsec ~= current.mtime.nsec
end

local function forget_disk_signature(buf)
    disk_signatures[buf] = nil
    disk_signature_known[buf] = nil
    failed_workspace_ticks[buf] = nil
    pending_saves[buf] = nil
end

local function notify_once(buf, kind, message, level)
    local state = get_autosave_state(buf)
    local tick = vim.api.nvim_buf_get_changedtick(buf)
    if state.notice_kind == kind and state.notice_tick == tick then return end

    state.notice_kind = kind
    state.notice_tick = tick
    notify(message, level)
end

local function buffer_name(buf)
    return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":~:.")
end

local function error_message(err)
    local message = tostring(err)
    return message:match("(E%d+:[^\n]+)") or message:match("([^\n]+)") or message
end

local function workspace_edit_failed(buf)
    local failed_tick = failed_workspace_ticks[buf]
    if not failed_tick then return false end

    if failed_tick == vim.api.nvim_buf_get_changedtick(buf) then return true end
    failed_workspace_ticks[buf] = nil
    return false
end

function M.save(buf)
    buf = buf or vim.api.nvim_get_current_buf()
    if not config.enabled or not vim.api.nvim_buf_is_valid(buf) then return false end
    if workspace_edit_failed(buf) then return false end
    if not vim.bo[buf].modified or not file_util.is_file_buf(buf) then return false end

    if vim.bo[buf].readonly then
        notify_once(buf, "readonly", ("自动保存已跳过（只读）: %s"):format(buffer_name(buf)))
        return false
    end
    if not vim.bo[buf].modifiable then return false end
    if autosave_state[buf] and autosave_state[buf].external_conflict then return false end

    if disk_has_changed(buf) then
        get_autosave_state(buf).external_conflict = true
        local checked, check_error = pcall(vim.cmd, "checktime " .. buf)
        if not checked then
            notify_once(buf, "checktime", ("外部变更检查失败: %s\n%s"):format(buffer_name(buf), error_message(check_error)), vim.log.levels.ERROR)
        else
            notify_once(buf, "external_change", ("自动保存已暂停：磁盘文件发生外部修改\n%s"):format(buffer_name(buf)))
        end
        return false
    end

    local written, write_error = pcall(vim.api.nvim_buf_call, buf, function()
        vim.cmd("silent lockmarks write")
    end)
    if written then
        remember_disk_signature(buf)
        reset_autosave_state(buf)
        return true
    end

    notify_once(buf, "write", ("自动保存失败: %s\n%s"):format(buffer_name(buf), error_message(write_error)), vim.log.levels.ERROR)
    return false
end

function M.schedule_save(buf)
    if not config.enabled or not vim.api.nvim_buf_is_valid(buf) or pending_saves[buf] then return end

    pending_saves[buf] = true
    vim.schedule(function()
        pending_saves[buf] = nil
        if vim.api.nvim_buf_is_valid(buf) then M.save(buf) end
    end)
end

local function attach_buffer(buf)
    if attached_buffers[buf]
        or not vim.api.nvim_buf_is_valid(buf)
        or not vim.api.nvim_buf_is_loaded(buf)
        or not file_util.is_file_buf(buf) then
        return
    end

    local attached = vim.api.nvim_buf_attach(buf, false, {
        on_lines = function()
            if config.save.background_modified_buffers
                and workspace_depth == 0
                and buf ~= vim.api.nvim_get_current_buf() then
                M.schedule_save(buf)
            end
        end,
        on_detach = function()
            attached_buffers[buf] = nil
        end,
    })
    if attached then attached_buffers[buf] = true end
end

local function remember_workspace_buffer(tx, buf)
    if not vim.api.nvim_buf_is_valid(buf) or not file_util.is_file_buf(buf) then return end
    if not disk_signature_known[buf] then remember_disk_signature(buf) end
    tx.buffers[buf] = true
end

local function restore_workspace_wrappers()
    if workspace_edit_wrapper and vim.lsp.util.apply_workspace_edit == workspace_edit_wrapper then
        vim.lsp.util.apply_workspace_edit = original_apply_workspace_edit
    end
    if text_edits_wrapper and vim.lsp.util.apply_text_edits == text_edits_wrapper then
        vim.lsp.util.apply_text_edits = original_apply_text_edits
    end
    workspace_edit_wrapper = nil
    text_edits_wrapper = nil
    original_apply_workspace_edit = nil
    original_apply_text_edits = nil
    workspace_depth = 0
    workspace_stack = {}
end

local function install_workspace_wrappers()
    if workspace_edit_wrapper then return end

    original_apply_workspace_edit = vim.lsp.util.apply_workspace_edit
    original_apply_text_edits = vim.lsp.util.apply_text_edits

    text_edits_wrapper = function(text_edits, buf, ...)
        local tx = workspace_stack[#workspace_stack]
        local before = vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_changedtick(buf) or nil
        if tx then remember_workspace_buffer(tx, buf) end

        local result = pack(pcall(original_apply_text_edits, text_edits, buf, ...))
        local after = vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_changedtick(buf) or nil
        if before ~= after then
            attach_buffer(buf)
            if tx then
                tx.buffers[buf] = true
            elseif result[1] and config.save.workspace_edits then
                M.schedule_save(buf)
            elseif not result[1] and vim.api.nvim_buf_is_valid(buf) then
                failed_workspace_ticks[buf] = after
            end
        end
        if not result[1] then error(result[2], 0) end
        return unpack_values(result, 2, result.n)
    end

    workspace_edit_wrapper = function(...)
        if workspace_depth > 0 then return original_apply_workspace_edit(...) end

        workspace_depth = workspace_depth + 1
        local tx = { buffers = {} }
        table.insert(workspace_stack, tx)
        local result = pack(pcall(original_apply_workspace_edit, ...))
        table.remove(workspace_stack)
        workspace_depth = workspace_depth - 1

        if result[1] then
            for buf in pairs(tx.buffers) do
                M.schedule_save(buf)
            end
        else
            for buf in pairs(tx.buffers) do
                if vim.api.nvim_buf_is_valid(buf) then
                    failed_workspace_ticks[buf] = vim.api.nvim_buf_get_changedtick(buf)
                end
            end
            error(result[2], 0)
        end
        return unpack_values(result, 2, result.n)
    end

    vim.lsp.util.apply_text_edits = text_edits_wrapper
    vim.lsp.util.apply_workspace_edit = workspace_edit_wrapper
end

local function seed_buffers()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if file_util.is_file_buf(buf) then
            remember_disk_signature(buf)
            attach_buffer(buf)
        end
    end
end

local function setup_autocmds()
    local disk_state = group("ConfigAutoSaveDiskState")
    vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile", "BufFilePost" }, {
        group = disk_state,
        pattern = "*",
        callback = function(args)
            if file_util.is_file_buf(args.buf) then
                remember_disk_signature(args.buf)
                attach_buffer(args.buf)
            end
            reset_autosave_state(args.buf)
        end,
    })
    if vim.v.vim_did_enter == 1 then
        seed_buffers()
    else
        vim.api.nvim_create_autocmd("VimEnter", {
            group = disk_state,
            once = true,
            callback = seed_buffers,
        })
    end

    vim.api.nvim_create_autocmd(config.reload.checktime_events, {
        group = group("ConfigAutoSaveReload"),
        pattern = "*",
        callback = function(args)
            if vim.fn.mode() ~= "c" and file_util.is_file_buf(args.buf) then
                vim.cmd("checktime " .. args.buf)
            end
        end,
    })

    local file_changed = group("ConfigAutoSaveFileChanged")
    vim.api.nvim_create_autocmd("FileChangedShellPost", {
        group = file_changed,
        pattern = "*",
        callback = function(args)
            if file_util.is_file_buf(args.buf) then
                remember_disk_signature(args.buf)
                attach_buffer(args.buf)
            end
            reset_autosave_state(args.buf)
            notify(("磁盘文件已变更，buffer 已重载: %s"):format(vim.fn.fnamemodify(args.file, ":~:.")), vim.log.levels.WARN)
        end,
    })
    vim.api.nvim_create_autocmd("FileChangedShell", {
        group = file_changed,
        pattern = "*",
        callback = function(args)
            if file_util.is_file_buf(args.buf) and vim.bo[args.buf].modified then
                get_autosave_state(args.buf).external_conflict = true
                vim.v.fcs_choice = "ask"
            else
                vim.v.fcs_choice = "reload"
            end
        end,
    })

    local autosave = group("ConfigAutoSave")
    vim.api.nvim_create_autocmd(config.save.events, {
        group = autosave,
        pattern = "*",
        callback = function(args)
            M.schedule_save(args.buf)
        end,
    })
    vim.api.nvim_create_autocmd("BufWritePost", {
        group = autosave,
        pattern = "*",
        callback = function(args)
            if file_util.is_file_buf(args.buf) then
                remember_disk_signature(args.buf)
                attach_buffer(args.buf)
            end
            reset_autosave_state(args.buf)
        end,
    })
    vim.api.nvim_create_autocmd("BufWipeout", {
        group = autosave,
        pattern = "*",
        callback = function(args)
            reset_autosave_state(args.buf)
            forget_disk_signature(args.buf)
            attached_buffers[args.buf] = nil
        end,
    })
end

function M.setup(opts)
    config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
    clear_groups()
    restore_workspace_wrappers()
    if not config.enabled then return end

    setup_autocmds()
    if config.save.workspace_edits then install_workspace_wrappers() end
end

function M.get_config()
    return vim.deepcopy(config)
end

return M
