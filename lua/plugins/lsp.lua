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
                automatic_installation = true,
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

            -- ─── 参数签名自动触发 ───
            vim.api.nvim_create_autocmd("InsertCharPre", {
                group = vim.api.nvim_create_augroup("LspSignatureHelp", { clear = true }),
                callback = function()
                    local char = vim.v.char
                    if char == "(" or char == "," then
                        vim.schedule(vim.lsp.buf.signature_help)
                    end
                end,
            })

            -- ─── inlay hint 开关（<leader>th 已被水平终端占用，改用 code 组）───
            vim.keymap.set("n", "<leader>ci", function()
                vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
            end, { desc = "切换 inlay hints" })

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

            local on_attach = function(client, bufnr)
                -- 虚拟 buffer：clangd 不支持非 file URI，直接卸载该 client 避免报错
                if not is_real_file(bufnr) then
                    vim.schedule(function()
                        pcall(vim.lsp.buf_detach_client, bufnr, client.id)
                    end)
                    return
                end
                vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")
                if client.supports_method("textDocument/inlayHint") then
                    vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
                end
            end

            local capabilities = require("cmp_nvim_lsp").default_capabilities()

            -- ─── 通用 server 启用（继承 nvim-lspconfig 预设 + 追加 capabilities/on_attach）───
            for _, server in ipairs(servers) do
                vim.lsp.config(server, {
                    on_attach = on_attach,
                    capabilities = capabilities,
                })
                vim.lsp.enable(server)
            end

            -- ─── clangd 自定义参数（覆盖通用配置）───
            vim.lsp.config("clangd", {
                on_attach = on_attach,
                capabilities = capabilities,
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
        end,
    },

    -- nvim-lspconfig 提供所有 server 的预设 config
    {
        "neovim/nvim-lspconfig",
        lazy = false,
        dependencies = { "williamboman/mason-lspconfig.nvim" },
    },

    -- Cmp LSP capabilities
    {
        "hrsh7th/cmp-nvim-lsp",
        event = "VeryLazy",
    },
}
