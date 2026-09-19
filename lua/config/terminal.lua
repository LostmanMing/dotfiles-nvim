-- toggleterm 状态机（从 plugins/toggleterm.lua 拆出）：
--   方向感知的"最近聚焦"记忆（<leader>tt/tf 回到刚才那个终端）、同方向环形切换、
--   终端内 gf 在编辑窗口打开文件、退出终端后聚焦同方向剩余终端。
-- 原先这些逻辑分散在 spec 的 config 里、靠 _G.toggleterm_open_dir 全局与 keys/on_exit
-- 互通，现在收拢成一个模块。模块顶层不 require 插件；M.setup() 在 spec 的 config 里调用。
local M = {}

local last_id = {}

-- 打开某方向终端：优先回到该方向最近聚焦的终端，否则用默认 id
function M.open_dir(direction, default_id)
    local terminal = require("toggleterm.terminal")
    local id = last_id[direction]
    local t = id and terminal.get(id)
    -- id 可能被其它方向的终端复用，方向不符时回退默认
    if not t or t.direction ~= direction then id = default_id end
    vim.cmd(id .. "ToggleTerm direction=" .. direction)
end

-- 终端里 gf 打开文件：默认会在终端窗口内打开，覆盖终端 buffer 却不更新
-- toggleterm 的窗口跟踪，导致之后 <c-\> 关闭时 close_tab 拿到失效窗口句柄
-- 报 Invalid window id。改为关闭当前终端、回到编辑窗口后再打开文件。
local function term_open_file(edit_cmd)
    local cfile = vim.fn.expand("<cfile>")
    if cfile == nil or cfile == "" then return end
    local terminal = require("toggleterm.terminal")
    local cur = terminal.get(tonumber(vim.b.toggle_number))
    -- 解析路径：优先按 nvim cwd，失败再按终端自身工作目录
    local target = cfile
    if vim.fn.filereadable(cfile) == 0 and cur and cur.dir then
        local joined = cur.dir .. "/" .. cfile
        if vim.fn.filereadable(joined) == 1 then target = joined end
    end
    if cur then cur:close() end
    vim.cmd(edit_cmd .. " " .. vim.fn.fnameescape(target))
end

-- 同方向终端按 id 升序（切换顺序稳定）；exclude_id 用于"退出后找剩余的"
local function same_dir(direction, exclude_id)
    local terminal = require("toggleterm.terminal")
    local terms = {}
    for _, t in ipairs(terminal.get_all()) do
        if t.direction == direction and t.id ~= exclude_id then
            terms[#terms + 1] = t
        end
    end
    table.sort(terms, function(a, b) return a.id < b.id end)
    return terms
end

-- 在同方向终端间切换：tab 终端只在 tab 之间切，float 只在 float 之间切
local function cycle(step)
    local terminal = require("toggleterm.terminal")
    local ui = require("toggleterm.ui")
    local cur = terminal.get(tonumber(vim.b.toggle_number))
    if not cur then return end
    local terms = same_dir(cur.direction, nil)
    local idx
    for i, t in ipairs(terms) do
        if t.id == cur.id then idx = i break end
    end
    if #terms < 2 or not idx then return end
    local target = terms[(idx - 1 + step) % #terms + 1]
    if cur.direction == "tab" then
        -- tab 终端各在独立 tabpage 且都开着：只聚焦目标，
        -- 不关旧开新，避免 open_tab 重复建 tab 并使 window 句柄失效
        if ui.term_has_open_win(target) then
            target:focus()
        else
            target:open()
        end
    else
        cur:close()
        target:open()
    end
end

-- 新建终端：取最大 id + 1，避免与已存在终端（如 tab 用 id=4）撞号
local function new_term()
    local terminal = require("toggleterm.terminal")
    local cur = terminal.get(tonumber(vim.b.toggle_number))
    local dir = (cur and cur.direction) or "float"
    local new_id = 1
    for _, t in ipairs(terminal.get_all()) do
        if t.id >= new_id then new_id = t.id + 1 end
    end
    vim.cmd(new_id .. "ToggleTerm direction=" .. dir)
end

-- 退出终端时：若同方向还有其它终端，聚焦到剩余的最后一个；
-- 只有同方向终端全没了，才自然返回普通 buffer（spec 的 opts.on_exit 调这里）
function M.on_exit(term)
    local dir = term.direction
    local exited_id = term.id
    vim.schedule(function()
        local ui = require("toggleterm.ui")
        local rest = same_dir(dir, exited_id)
        if #rest == 0 then return end
        local target = rest[#rest]
        if ui.term_has_open_win(target) then
            target:focus()
        else
            target:open()
        end
    end)
end

-- 在 spec 的 config 里调用（toggleterm 已 setup）：注册 TermEnter/TermOpen 两组 autocmd
function M.setup()
    local terminal = require("toggleterm.terminal")
    local grp = vim.api.nvim_create_augroup("MyToggleterm", { clear = true })
    -- 记录每个 direction 最近聚焦的终端 id，用于 <leader>tt/tf 切回时回到刚才那个
    vim.api.nvim_create_autocmd("TermEnter", {
        group = grp,
        callback = function()
            local id = tonumber(vim.b.toggle_number)
            if not id then return end
            local t = terminal.get(id)
            if t then last_id[t.direction] = id end
        end,
    })

    -- 终端按键全部 buffer-local（仅 toggleterm buffer），不污染全局：
    -- 之前全局绑 <C-[> 会劫持 Esc（同一个键），<C-]> 会挡原生 tag 跳转
    vim.api.nvim_create_autocmd("TermOpen", {
        group = grp,
        pattern = { "term://*#toggleterm#*", "term://*::toggleterm::*" },
        callback = function(args)
            local buf = args.buf
            local function bmap(mode, lhs, rhs, desc)
                vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
            end
            bmap("n", "gf", function() term_open_file("edit") end, "gf: 在编辑窗口打开文件（不占用终端窗口）")
            bmap("n", "gF", function() term_open_file("edit") end, "gF: 在编辑窗口打开文件（不占用终端窗口）")
            -- C-] 单键环形切换（仅终端 buffer 内生效，不影响代码 buffer 的 tag 跳转）
            bmap({ "t", "n" }, "<C-]>", function() cycle(1) end, "切换到下一个同方向终端（环形）")
            bmap("t", "<C-n>", new_term, "新建终端（继承当前方向）")
            bmap("t", "<Esc>", [[<C-\><C-n>]], "退出到 normal 模式")
        end,
    })
end

return M
