return {
    {
        "akinsho/toggleterm.nvim",
        version = "*",
        keys = {
            { "<leader>tt", function() _G.toggleterm_open_dir("tab", 4) end, desc = "全屏终端" },
            { "<leader>tf", function() _G.toggleterm_open_dir("float", 1) end, desc = "浮动终端" },
            { "<leader>th", function() _G.toggleterm_open_dir("horizontal", 2) end, desc = "水平终端" },
            { "<leader>tv", function() _G.toggleterm_open_dir("vertical", 3) end, desc = "垂直终端" },
        },
        config = function(_, opts)
            require("toggleterm").setup(opts)
            local terminal = require("toggleterm.terminal")
            local ui = require("toggleterm.ui")

            -- 记录每个 direction 最近聚焦的终端 id，用于 <leader>tt/tf 切回时回到刚才那个
            local last_id = {}
            vim.api.nvim_create_autocmd("TermEnter", {
                callback = function()
                    local id = tonumber(vim.b.toggle_number)
                    if not id then return end
                    local t = terminal.get(id)
                    if t then last_id[t.direction] = id end
                end,
            })

            -- 打开某方向终端：优先回到该方向最近聚焦的终端，否则用默认 id
            function _G.toggleterm_open_dir(direction, default_id)
                local id = last_id[direction]
                if not id or not terminal.get(id) then id = default_id end
                vim.cmd(id .. "ToggleTerm direction=" .. direction)
            end

            -- 终端里 gf 打开文件：默认会在终端窗口内打开，覆盖终端 buffer 却不更新
            -- toggleterm 的窗口跟踪，导致之后 <c-\> 关闭时 close_tab 拿到失效窗口句柄
            -- 报 Invalid window id。改为关闭当前终端、回到编辑窗口后再打开文件。
            local function term_open_file(edit_cmd)
                local cfile = vim.fn.expand("<cfile>")
                if cfile == nil or cfile == "" then return end
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

            vim.api.nvim_create_autocmd("TermOpen", {
                pattern = { "term://*#toggleterm#*", "term://*::toggleterm::*" },
                callback = function(args)
                    local buf = args.buf
                    vim.keymap.set("n", "gf", function() term_open_file("edit") end,
                        { buffer = buf, desc = "gf: 在编辑窗口打开文件（不占用终端窗口）" })
                    vim.keymap.set("n", "gF", function() term_open_file("edit") end,
                        { buffer = buf, desc = "gF: 在编辑窗口打开文件（不占用终端窗口）" })
                end,
            })

            -- 只返回与当前终端 direction 相同的终端，按 id 升序保证切换顺序稳定
            local function same_dir_terms()
                local cur = terminal.get(tonumber(vim.b.toggle_number))
                if not cur then return nil, nil end
                local terms = {}
                for _, t in ipairs(terminal.get_all()) do
                    if t.direction == cur.direction then
                        terms[#terms + 1] = t
                    end
                end
                table.sort(terms, function(a, b) return a.id < b.id end)
                local idx
                for i, t in ipairs(terms) do
                    if t.id == cur.id then idx = i break end
                end
                return terms, cur, idx
            end

            -- 在同方向终端间切换：tab 终端只在 tab 之间切，float 只在 float 之间切
            local function cycle(step)
                local terms, cur, idx = same_dir_terms()
                if not terms or #terms < 2 or not idx then return end
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

            vim.keymap.set({ "t", "n" }, "<C-]>", function() cycle(1) end, { desc = "下一个同方向终端" })
            vim.keymap.set({ "t", "n" }, "<C-[>", function() cycle(-1) end, { desc = "上一个同方向终端" })
            vim.keymap.set("t", "<C-n>", function()
                local cur = terminal.get(tonumber(vim.b.toggle_number))
                local dir = (cur and cur.direction) or "float"
                -- 取最大 id + 1，避免与已存在终端（如 tab 用 id=4）撞号
                -- 否则 ToggleTerm 会误判为 toggle 已有终端而非新建
                local new_id = 1
                for _, t in ipairs(terminal.get_all()) do
                    if t.id >= new_id then new_id = t.id + 1 end
                end
                vim.cmd(new_id .. "ToggleTerm direction=" .. dir)
            end, { desc = "新建终端（继承当前方向）" })
            vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { desc = "退出到 normal 模式" })
        end,
        opts = {
            size = 20,
            open_mapping = [[<c-\>]],
            hide_numbers = true,
            persist_mode = true,
            persist_size = true,
            direction = "float",
            close_on_exit = true,
            shell = vim.o.shell,
            -- 退出终端时：若同方向还有其它终端，聚焦到剩余的最后一个；
            -- 只有同方向终端全没了，才自然返回普通 buffer
            on_exit = function(term, _, _, _)
                local dir = term.direction
                local exited_id = term.id
                vim.schedule(function()
                    local terminal = require("toggleterm.terminal")
                    local ui = require("toggleterm.ui")
                    local rest = {}
                    for _, t in ipairs(terminal.get_all()) do
                        if t.direction == dir and t.id ~= exited_id then
                            rest[#rest + 1] = t
                        end
                    end
                    if #rest == 0 then return end
                    table.sort(rest, function(a, b) return a.id < b.id end)
                    local target = rest[#rest]
                    if ui.term_has_open_win(target) then
                        target:focus()
                    else
                        target:open()
                    end
                end)
            end,
            float_opts = {
                border = "curved",
                winblend = 0,
            },
        },
    },
}
