-- 共享小工具
local M = {}

-- 是否为普通可写文件 buffer：可修改、buftype 为空、且有文件名
-- 供 autosave 和智能关闭 q 的写盘判断共用
function M.is_writable_file_buf(bufnr)
    bufnr = bufnr or 0
    return vim.bo[bufnr].modifiable
        and vim.bo[bufnr].buftype == ""
        and vim.api.nvim_buf_get_name(bufnr) ~= ""
end

return M
