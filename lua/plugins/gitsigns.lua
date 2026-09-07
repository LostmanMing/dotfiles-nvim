return {
    {
        "lewis6991/gitsigns.nvim",
        event = { "BufReadPre", "BufNewFile" },
        opts = {
            sign_priority = 20,
            signs = {
                add          = { text = "▎" },
                change       = { text = "▎" },
                delete       = { text = "_" },
                topdelete    = { text = "‾" },
                changedelete = { text = "~" },
                untracked    = { text = "▎" },
            },
            signs_staged = {
                add          = { text = "▎" },
                change       = { text = "▎" },
                delete       = { text = "_" },
                topdelete    = { text = "‾" },
                changedelete = { text = "~" },
            },
            current_line_blame_opts = {
                virt_text_pos = "eol",
                delay = 300,
            },
            on_attach = function(bufnr)
                local gs = package.loaded.gitsigns
                local function map(mode, lhs, rhs, desc)
                    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
                end

                map("n", "]c", function()
                    if vim.wo.diff then
                        vim.cmd.normal({ "]c", bang = true })
                    else
                        gs.nav_hunk("next")
                    end
                end, "下一个 hunk")
                map("n", "[c", function()
                    if vim.wo.diff then
                        vim.cmd.normal({ "[c", bang = true })
                    else
                        gs.nav_hunk("prev")
                    end
                end, "上一个 hunk")

                map("n", "<leader>gs", gs.stage_hunk,        "Stage hunk")
                map("n", "<leader>gr", gs.reset_hunk,        "Reset hunk")
                map("v", "<leader>gs", function() gs.stage_hunk { vim.fn.line("."), vim.fn.line("v") } end, "Stage hunk")
                map("v", "<leader>gr", function() gs.reset_hunk { vim.fn.line("."), vim.fn.line("v") } end, "Reset hunk")
                map("n", "<leader>gS", gs.stage_buffer,      "Stage buffer")
                map("n", "<leader>gu", gs.stage_hunk,        "取消暂存 hunk（stage 的 toggle）")
                map("n", "<leader>gR", gs.reset_buffer,      "Reset buffer")
                map("n", "<leader>gp", gs.preview_hunk_inline, "Preview hunk (inline)")
                map("n", "<leader>gb", function() gs.blame_line { full = true } end, "Blame line")
                map("n", "<leader>gB", gs.toggle_current_line_blame, "Toggle line blame")
                map("n", "<leader>gd", gs.diffthis, "Diff against index (toggle)")
                map("n", "<leader>gD", function() gs.diffthis("~") end, "Diff against HEAD")

                map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Select hunk")
            end,
        },
        config = function(_, opts)
            require("gitsigns").setup(opts)

            local function set_git_highlights()
                for _, name in ipairs({ "GitSignsAdd", "GitSignsUntracked" }) do
                    vim.api.nvim_set_hl(0, name, { fg = "#81B88B" })
                end
                for _, name in ipairs({ "GitSignsStagedAdd", "GitSignsStagedUntracked" }) do
                    vim.api.nvim_set_hl(0, name, { fg = "#6A9955" })
                end
                for _, name in ipairs({ "GitSignsStagedChange", "GitSignsStagedChangedelete" }) do
                    vim.api.nvim_set_hl(0, name, { fg = "#8A6A28" })
                end
                for _, name in ipairs({ "GitSignsStagedDelete", "GitSignsStagedTopdelete" }) do
                    vim.api.nvim_set_hl(0, name, { fg = "#632F32" })
                end
            end
            set_git_highlights()
            vim.api.nvim_create_autocmd("ColorScheme", {
                group = vim.api.nvim_create_augroup("GitsignsGitHighlights", { clear = true }),
                callback = set_git_highlights,
            })
        end,
    },
}
