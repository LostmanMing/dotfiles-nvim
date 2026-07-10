return {
    {
        "akinsho/toggleterm.nvim",
        version = "*",
        keys = {
            { "<leader>tt", "<cmd>4ToggleTerm direction=tab<CR>", desc = "全屏终端" },
            { "<leader>tf", "<cmd>1ToggleTerm direction=float<CR>", desc = "浮动终端" },
            { "<leader>th", "<cmd>2ToggleTerm direction=horizontal<CR>", desc = "水平终端" },
            { "<leader>tv", "<cmd>3ToggleTerm direction=vertical<CR>", desc = "垂直终端" },
        },
        config = function(_, opts)
            require("toggleterm").setup(opts)
            local terminal = require("toggleterm.terminal")
            local ui = require("toggleterm.ui")

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

            vim.keymap.set("t", "<C-]>", function() cycle(1) end, { desc = "下一个同方向终端" })
            vim.keymap.set("t", "<C-[>", function() cycle(-1) end, { desc = "上一个同方向终端" })
            vim.keymap.set("t", "<C-n>", function()
                local terminal = require("toggleterm.terminal")
                local cur = terminal.get(tonumber(vim.b.toggle_number))
                local dir = (cur and cur.direction) or "float"
                local new_id = #terminal.get_all() + 1
                vim.cmd(new_id .. "ToggleTerm direction=" .. dir)
                vim.schedule(function() vim.cmd("startinsert") end)
            end, { desc = "新建终端（继承当前方向）" })
            vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { desc = "退出到 normal 模式" })
        end,
        opts = {
            size = 20,
            open_mapping = [[<c-\>]],
            hide_numbers = true,
            start_in_insert = true,
            insert_mappings = true,
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
                    vim.cmd("startinsert")
                end)
            end,
            float_opts = {
                border = "curved",
                winblend = 0,
            },
        },
    },
}
