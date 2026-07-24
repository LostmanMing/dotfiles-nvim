return {
    -- Mason: LSP installer
    {
        "williamboman/mason.nvim",
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
        dependencies = { "williamboman/mason.nvim" },
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
        "williamboman/mason-lspconfig.nvim",
        lazy = false,
        dependencies = { "williamboman/mason.nvim" },
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
            vim.keymap.set("n", "gd",  vim.lsp.buf.definition, { desc = "跳转到定义" })
            vim.keymap.set("n", "grd", vim.lsp.buf.declaration, { desc = "跳转到声明" })
            vim.keymap.set("n", "grt", vim.lsp.buf.type_definition, { desc = "跳转到类型定义" })
            vim.keymap.set("n", "gri", vim.lsp.buf.implementation, { desc = "跳转到实现" })
            vim.keymap.set("n", "grr", "<cmd>Telescope lsp_references<CR>", { desc = "查找引用" })
            vim.keymap.set("n", "grn", vim.lsp.buf.rename, { desc = "重命名符号" })
            vim.keymap.set("n", "gra", vim.lsp.buf.code_action, { desc = "代码操作" })
            vim.keymap.set("n", "K",   vim.lsp.buf.hover, { desc = "悬浮文档" })
            vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, { desc = "参数签名提示" })
            vim.keymap.set("n", "<leader>cf", function()
                vim.lsp.buf.format({ async = true })
            end, { desc = "格式化代码" })

            -- ─── inlay hint 开关（<leader>th 已被水平终端占用，改用 code 组）───
            -- 用当前 buffer 作用域，和 on_attach 里 per-buffer 启用保持一致（避免状态不同步）
            vim.keymap.set("n", "<leader>ci", function()
                local b = 0
                vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = b }), { bufnr = b })
            end, { desc = "切换 inlay hints（当前 buffer）" })

            -- ─── on_attach / capabilities ───
            -- 判断是否真实磁盘文件 buffer：clangd 只支持 file URI，
            -- diffview://、gitsigns:// 等虚拟 buffer 会在 inlayHint 等请求上报 -32602 错误
            local function is_real_file(bufnr)
                if vim.bo[bufnr].buftype ~= "" then return false end
                local name = vim.api.nvim_buf_get_name(bufnr)
                if name == "" then return false end
                if name:find("://") then return false end
                return true
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

            local capabilities = require("cmp_nvim_lsp").default_capabilities()

            -- clangd 自定义 cmd：在通用循环 enable 之前设置，循环会合并 on_attach/capabilities
            vim.lsp.config("clangd", {
                cmd = {
                    "clangd",
                    "--background-index",
                    "--pch-storage=memory",
                    "--completion-style=detailed",
                    "--limit-results=20",
                    "--header-insertion=never",
                    "--query-driver=/usr/bin/c++,/usr/bin/g++,/usr/bin/gcc",
                    "-j=4",
                },
            })

            -- ─── 通用 server 启用（继承 nvim-lspconfig 预设 + 追加 capabilities/on_attach）───
            for _, server in ipairs(servers) do
                vim.lsp.config(server, {
                    on_attach = on_attach,
                    capabilities = capabilities,
                })
                vim.lsp.enable(server)
            end
        end,
    },

    -- nvim-lspconfig 提供所有 server 的预设 config
    {
        "neovim/nvim-lspconfig",
        lazy = false,
        dependencies = { "williamboman/mason-lspconfig.nvim" },
    },
}
