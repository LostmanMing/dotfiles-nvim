return {
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
        lazy = false,
        build = ":TSUpdate",
        config = function()
            local ts = require("nvim-treesitter")
            ts.setup({
                install_dir = vim.fn.stdpath("data") .. "/site",
            })

            local ensure = {
                "c", "cpp", "python", "lua", "bash", "cmake",
                "markdown", "markdown_inline", "vim", "vimdoc", "query",
            }
            pcall(function() ts.install(ensure) end)

            -- 启动高亮 + treesitter 折叠（同步/异步安装完成两条路径共用）
            local function start_ts(buf, lang)
                if not vim.api.nvim_buf_is_valid(buf) then return end
                pcall(vim.treesitter.start, buf, lang)
                for _, win in ipairs(vim.fn.win_findbuf(buf)) do
                    pcall(function()
                        vim.wo[win][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
                        vim.wo[win][0].foldmethod = "expr"
                    end)
                end
            end

            local available_cache   -- get_available() 结果缓存（closure local，避免 vim.g 拷贝开销）
            local installing = {}   -- 正在安装的语言，防止慢网络下重复发起 clone

            vim.api.nvim_create_autocmd("FileType", {
                callback = function(args)
                    local ft = vim.bo[args.buf].filetype
                    if ft == "" then return end
                    local lang = vim.treesitter.language.get_lang(ft) or ft

                    -- pcall：半下载/损坏的 parser .so 不弹错打断操作
                    local ok_add, has = pcall(vim.treesitter.language.add, lang)
                    if ok_add and has then
                        start_ts(args.buf, lang)
                        return
                    end

                    -- parser 缺失：可安装则后台装（按语言去重），装完再启动
                    if installing[lang] then return end
                    if not available_cache then
                        local ok, list = pcall(ts.get_available)
                        available_cache = ok and list or {}
                    end
                    if not vim.tbl_contains(available_cache, lang) then return end

                    local ok_inst, handle = pcall(ts.install, lang)
                    if ok_inst and handle and handle.await then
                        installing[lang] = true
                        vim.notify(("treesitter: 正在后台安装 %s parser…"):format(lang), vim.log.levels.INFO)
                        handle:await(function()
                            installing[lang] = nil
                            local ok2, has2 = pcall(vim.treesitter.language.add, lang)
                            if ok2 and has2 then
                                vim.notify(("treesitter: %s parser 安装完成"):format(lang), vim.log.levels.INFO)
                                start_ts(args.buf, lang)
                            else
                                vim.notify(("treesitter: %s parser 安装失败（网络？稍后 :TSInstall %s 重试）"):format(lang, lang), vim.log.levels.WARN)
                            end
                        end)
                    end
                end,
            })

            -- incremental selection（选区历史按 buffer 隔离，避免跨 buffer 用到失效节点）
            local sel_history = {}
            local function hist()
                local b = vim.api.nvim_get_current_buf()
                sel_history[b] = sel_history[b] or {}
                return sel_history[b]
            end
            local function set_visual(node)
                local sr, sc, er, ec = node:range()
                vim.fn.setpos("'<", { 0, sr + 1, sc + 1, 0 })
                vim.fn.setpos("'>", { 0, er + 1, ec, 0 })
                vim.cmd("normal! gv")
            end
            local function init_selection()
                local b = vim.api.nvim_get_current_buf()
                sel_history[b] = {}
                local node = vim.treesitter.get_node()
                if not node then return end
                table.insert(sel_history[b], node)
                set_visual(node)
            end
            local function node_incremental()
                local h = hist()
                local last = h[#h]
                if not last then return init_selection() end
                local parent = last:parent()
                if not parent then return vim.cmd("normal! gv") end
                table.insert(h, parent)
                set_visual(parent)
            end
            local function node_decremental()
                local h = hist()
                if #h <= 1 then return vim.cmd("normal! gv") end
                table.remove(h)
                set_visual(h[#h])
            end
            -- <CR> 用 expr：quickfix/cmdline-window 等特殊场景放行原生回车（跳转/执行）
            vim.keymap.set("n", "<CR>", function()
                if vim.bo.buftype ~= "" or vim.fn.getcmdwintype() ~= "" then
                    return "<CR>"
                end
                vim.schedule(init_selection)
                return "<Ignore>"
            end, { expr = true, desc = "TS init selection" })
            vim.keymap.set("x", "<CR>", node_incremental, { desc = "TS node incremental" })
            vim.keymap.set("x", "<BS>", node_decremental, { desc = "TS node decremental" })
        end,
    },

    {
        "nvim-treesitter/nvim-treesitter-textobjects",
        branch = "main",
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        lazy = false,
        config = function()
            require("nvim-treesitter-textobjects").setup({
                select = { lookahead = true },
                move = { set_jumps = true },
            })

            local ok_select, select = pcall(require, "nvim-treesitter-textobjects.select")
            local ok_move, move = pcall(require, "nvim-treesitter-textobjects.move")
            local ok_swap, swap = pcall(require, "nvim-treesitter-textobjects.swap")
            local map = vim.keymap.set

            if ok_select then
                local text_objects = {
                    ["af"] = "@function.outer", ["if"] = "@function.inner",
                    ["ac"] = "@class.outer",    ["ic"] = "@class.inner",
                    ["al"] = "@loop.outer",     ["il"] = "@loop.inner",
                    ["ap"] = "@parameter.outer",["ip"] = "@parameter.inner",
                }
                for key, query in pairs(text_objects) do
                    map({ "o", "x" }, key, function()
                        select.select_textobject(query, "textobjects")
                    end, { desc = query })
                end
            end

            if ok_move then
                map({ "n", "x", "o" }, "]f", function() move.goto_next_start("@function.outer", "textobjects") end, { desc = "下一个函数" })
                map({ "n", "x", "o" }, "[f", function() move.goto_previous_start("@function.outer", "textobjects") end, { desc = "上一个函数" })
                map({ "n", "x", "o" }, "]p", function() move.goto_next_start("@parameter.inner", "textobjects") end, { desc = "下一个参数" })
                map({ "n", "x", "o" }, "[p", function() move.goto_previous_start("@parameter.inner", "textobjects") end, { desc = "上一个参数" })
            end

            if ok_swap then
                map("n", "<leader>na", function() swap.swap_next("@parameter.inner") end, { desc = "交换到下一个参数" })
                map("n", "<leader>pa", function() swap.swap_previous("@parameter.inner") end, { desc = "交换到上一个参数" })
            end
        end,
    },
}
