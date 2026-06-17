return {
    {
        "williamboman/mason.nvim",
        lazy = false,
        config = function()
            require("mason").setup()
        end,
    },

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

            vim.lsp.config("clangd", {
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

            vim.lsp.enable(servers)

            vim.keymap.set("n", "gra", vim.lsp.buf.code_action, { desc = "代码操作" })
            vim.keymap.set("n", "<leader>cf", function()
                vim.lsp.buf.format({ async = true })
            end, { desc = "格式化代码" })
        end,
    },
}
