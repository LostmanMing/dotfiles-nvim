return {
    -- Mason: LSP installer
    {
        "mason-org/mason.nvim",
        lazy = false,
        config = function()
            require("mason").setup({
                ui = {
                    icons = {
                        package_installed = "✓",
                        package_pending = "➜",
                        package_uninstalled = "✗",
                    },
                },
            })
        end,
    },

    -- Mason tool installer：非 LSP 工具（仅在系统没装 tree-sitter 时下载）
    {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        lazy = false,
        dependencies = { "mason-org/mason.nvim" },
        config = function()
            if vim.fn.executable("tree-sitter") ~= 1 then
                require("mason-tool-installer").setup({
                    ensure_installed = { "tree-sitter-cli" },
                })
            end
        end,
    },

    -- Mason LSP config integration
    {
        "mason-org/mason-lspconfig.nvim",
        lazy = false,
        dependencies = {
            "mason-org/mason.nvim",
            "Crysthamus/nvim-file-operations",
        },
        config = function()
            local servers = {
                "lua_ls",
                "bashls",
                "pyright",
                "clangd",
                "neocmake",
                "marksman",
                "jsonls",
                "yamlls",
            }

            require("mason-lspconfig").setup({
                -- 关闭自动 enable：只启用下面循环里带 capabilities/on_attach 的 server，
                -- 避免 :Mason 另装的 server 被裸启用（缺补全能力和虚拟 buffer 守卫）
                automatic_enable = false,
                ensure_installed = servers,
            })

            -- ─── LSP 按键（gr 系列对齐 archibate）───
            -- gd 保持原来的 Telescope 定义跳转；gD 按当前窗口形状智能分屏查看定义。
            -- 其它多结果跳转仍走 Telescope（带预览列表），与 grr 引用界面一致。
            -- grd 声明保持原生：Telescope 没有 lsp_declarations picker，且声明几乎只有一处。
            local function goto_definition(open_cmd)
                local params = vim.lsp.util.make_position_params(0, nil)
                vim.lsp.buf_request_all(0, "textDocument/definition", params, function(results)
                    local location, offset_encoding
                    for client_id, response in pairs(results) do
                        local result = response.result
                        if result and not vim.tbl_isempty(result) then
                            local client = vim.lsp.get_client_by_id(client_id)
                            local locations = vim.islist(result) and result or { result }
                            location = locations[1]
                            offset_encoding = client and client.offset_encoding or "utf-16"
                            break
                        end
                    end
                    if not location then
                        vim.notify("未找到定义", vim.log.levels.INFO, { title = "LSP" })
                        return
                    end
                    if open_cmd then
                        vim.cmd(open_cmd)
                    end
                    vim.lsp.util.show_document(location, offset_encoding, { focus = true, reuse_win = false })
                end)
            end

            vim.keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", { desc = "跳转到定义" })
            vim.keymap.set("n", "gD", function()
                local width = vim.api.nvim_win_get_width(0)
                local height = vim.api.nvim_win_get_height(0)
                local open_cmd = width >= height * 2 and "rightbelow vsplit" or "rightbelow split"
                goto_definition(open_cmd)
            end, { desc = "智能分屏查看定义" })
            vim.keymap.set("n", "grd", vim.lsp.buf.declaration, { desc = "跳转到声明" })
            vim.keymap.set("n", "grt", "<cmd>Telescope lsp_type_definitions<CR>", { desc = "跳转到类型定义" })
            vim.keymap.set("n", "gri", "<cmd>Telescope lsp_implementations<CR>", { desc = "跳转到实现" })
            vim.keymap.set("n", "grr", "<cmd>Telescope lsp_references<CR>", { desc = "查找引用" })
            vim.keymap.set("n", "grn", vim.lsp.buf.rename, { desc = "重命名符号" })
            vim.keymap.set("n", "gra", vim.lsp.buf.code_action, { desc = "代码操作" })
            -- K 悬浮文档：0.11+ 内置在 LSP attach 时 buffer-local 映射，无需全局设
            -- （全局映射会让非 LSP buffer 的 K 失去 man/keywordprg 查询）
            vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, { desc = "参数签名提示" })
            vim.keymap.set("n", "<leader>cf", function()
                vim.lsp.buf.format({ async = true })
            end, { desc = "格式化代码" })
            vim.keymap.set("n", "<leader>ct", function()
                vim.lsp.document_color.enable(not vim.lsp.document_color.is_enabled(0), 0, { style = "● " })
            end, { desc = "切换色值圆点" })

            -- inlay hint 开关移到 snacks.lua：用 Snacks.toggle.inlay_hints()（同为 bufnr=0
            -- 作用域，但多了通知和 which-key 图标），键位仍是 <leader>ci

            -- ─── on_attach / capabilities ───
            -- clangd 只支持真实磁盘文件；共享判断也排除 URI、目录和特殊 buffer。
            local function is_real_file(bufnr)
                return require("config.util").is_file_buf(bufnr)
            end

            -- 参数签名自动触发用的共享 augroup（buffer-local 注册，见 on_attach）
            local sig_group = vim.api.nvim_create_augroup("LspSignatureHelp", { clear = true })

            local on_attach = function(client, bufnr)
                -- 虚拟 buffer：clangd 不支持非 file URI，直接卸载该 client 避免报错
                if not is_real_file(bufnr) then
                    vim.schedule(function()
                        pcall(vim.lsp.buf_detach_client, bufnr, client.id)
                    end)
                    return
                end
                -- 注：Neovim 0.11+ 会在 attach 时自动设置 omnifunc，无需手动设
                if client:supports_method("textDocument/inlayHint") then
                    vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
                end
                -- 色值预览是 0.12 内置能力（不需要 nvim-highlight-colors 这类插件）。
                -- 但默认 style="background" 会把色值文字整段涂成色块并把前景反白，
                -- 直接盖掉 treesitter 的字符串高亮；改成在色值前面加一个该颜色的圆点，
                -- 原文的语法高亮保持不变。
                if client:supports_method("textDocument/documentColor") then
                    vim.lsp.document_color.enable(true, bufnr, { style = "● " })
                end
                -- 参数签名自动触发：仅在支持 signatureHelp 的 buffer 上，限定 buffer-local
                if client:supports_method("textDocument/signatureHelp") then
                    vim.api.nvim_clear_autocmds({ group = sig_group, buffer = bufnr })
                    vim.api.nvim_create_autocmd("InsertCharPre", {
                        group = sig_group,
                        buffer = bufnr,
                        callback = function()
                            local ch = vim.v.char
                            if ch == "(" or ch == "," then
                                vim.schedule(vim.lsp.buf.signature_help)
                            end
                        end,
                    })
                end
            end

            -- 补全 capabilities 不用手动传：blink.cmp 在 0.11+ 会自己调
            -- vim.lsp.config('*', { capabilities = ... })，而 vim.lsp.config 会把 '*'
            -- 的配置合并进每个具体 server，所以下面只需要给 on_attach。
            -- 文件操作 capability 必须在 vim.lsp.enable() 前宣告，Neo-tree 重命名/移动时
            -- 才能让支持 workspace.fileOperations 的 LSP 返回 import/path 更新。
            vim.lsp.config("*", {
                capabilities = require("nvim-file-operations.config").default_capabilities(),
            })

            -- clangd 自定义 cmd：在通用循环 enable 之前设置，循环会合并 on_attach
            vim.lsp.config("clangd", {
                cmd = {
                    "clangd",
                    "--background-index",
                    "--pch-storage=memory",
                    "--completion-style=detailed",
                    "--limit-results=20",
                    "--header-insertion=never",
                    "--query-driver=/usr/bin/c++,/usr/bin/g++,/usr/bin/gcc",
                    -- 优先在项目 build/ 找 compile_commands.json；没有时仍会向上逐级搜索
                    "--compile-commands-dir=build",
                    "-j=4",
                },
            })

            -- ─── 通用 server 启用（继承 nvim-lspconfig 预设 + 追加 on_attach）───
            for _, server in ipairs(servers) do
                vim.lsp.config(server, {
                    on_attach = on_attach,
                })
                vim.lsp.enable(server)
            end
        end,
    },

    -- nvim-lspconfig 提供所有 server 的预设 config
    {
        "neovim/nvim-lspconfig",
        lazy = false,
        dependencies = { "mason-org/mason-lspconfig.nvim" },
    },
}
