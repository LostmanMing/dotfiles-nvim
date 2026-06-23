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

            -- ─── 按键 ───
            vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "跳转到定义" })
            vim.keymap.set("n", "grr", vim.lsp.buf.references, { desc = "查找引用" })
            vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "悬浮文档" })
            vim.keymap.set("n", "gra", vim.lsp.buf.code_action, { desc = "代码操作" })
            vim.keymap.set("n", "<leader>cf", function()
                vim.lsp.buf.format({ async = true })
            end, { desc = "格式化代码" })

            -- ─── on_attach / capabilities ───
            local on_attach = function(client, bufnr)
                vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")
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
