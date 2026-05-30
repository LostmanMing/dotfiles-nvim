return {
    -- LSP 包管理器：一键安装/管理语言服务器
    {
        "williamboman/mason.nvim",
        lazy = false,
        config = function()
            require("mason").setup()
        end,
    },

    -- 桥接 mason 和 lspconfig
    {
        "williamboman/mason-lspconfig.nvim",
        lazy = false,
        dependencies = { "williamboman/mason.nvim" },
        config = function()
            local servers = {
                "lua_ls",       -- Lua
                "bashls",       -- Shell/Bash
                "pyright",      -- Python
                "clangd",       -- C/C++
                "neocmake",     -- CMake
                "marksman",     -- Markdown
                "jsonls",       -- JSON
                "yamlls",       -- YAML
            }

            require("mason-lspconfig").setup({
                automatic_installation = true,
                ensure_installed = servers,
            })

            -- LSP 快捷键
            vim.keymap.set("n", "gra", vim.lsp.buf.code_action, { desc = "代码操作" })
            vim.keymap.set("n", "<leader>cf", function()
                vim.lsp.buf.format({ async = true })
            end, { desc = "格式化代码" })
        end,
    },

}
