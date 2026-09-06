-- 共享小工具
local M = {}

-- 是否为普通磁盘文件 buffer：排除特殊 buffer、URI 和目录
function M.is_file_buf(bufnr)
    bufnr = bufnr or 0
    if bufnr == 0 then bufnr = vim.api.nvim_get_current_buf() end
    if not vim.api.nvim_buf_is_valid(bufnr) then return false end

    local name = vim.api.nvim_buf_get_name(bufnr)
    return vim.bo[bufnr].buftype == ""
        and name ~= ""
        and not name:find("://", 1, true)
        and vim.fn.isdirectory(name) == 0
end

-- 是否为普通可写文件 buffer：供 autosave 和智能关闭 q 的写盘判断共用
function M.is_writable_file_buf(bufnr)
    bufnr = bufnr or 0
    if bufnr == 0 then bufnr = vim.api.nvim_get_current_buf() end
    return M.is_file_buf(bufnr) and vim.bo[bufnr].modifiable and not vim.bo[bufnr].readonly
end

return M
