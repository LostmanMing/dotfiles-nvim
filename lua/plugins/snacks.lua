-- snacks.nvim：收编几个原本各自一个插件的小功能
-- 启用 dashboard（启动页）、input（统一输入框）、indent（缩进线）、notifier（通知）、bigfile（大文件降级）
-- 未启用 scroll（平滑滚动）：与 smear-cursor 的光标拖影抢同一手势，已选后者
-- snacks 所有模块默认全关，opts 里出现哪个 key 才启用哪个，所以没列的模块一行代码都不跑

local dashboard = require("config.dashboard")

-- 作用域竖线：只标记光标所在的「当前」作用域（颜色在 config/theme.lua，统一入口）。
-- 不用彩色——像 VSCode 那样，普通缩进线是暗灰，当前作用域只是同一系灰、亮度高一点。
local scope_hl = "IndentScopeActive"

return {
    {
        "folke/snacks.nvim",
        priority = 1000,        -- 早于其它插件加载，保证启动即可接管空 buffer
        lazy = false,
        opts = {
            dashboard = {
                -- 图 + 菜单 + 底部启动耗时（初号机配色，构建函数在 config/dashboard.lua）
                sections = dashboard.sections,
            },
            indent = {
                indent = { char = "│" },        -- 普通层级：默认灰色，不上色
                scope = {
                    char = "┃",                -- 光标所在作用域用粗字形区分
                    hl = scope_hl,              -- 按嵌套深度取色
                },
                -- 关掉动画，保持和原来 indent-blankline 一致的静态观感
                animate = { enabled = false },
            },
            notifier = {
                timeout = 2500,
                top_down = false,               -- 通知从右下往上堆
                -- 注：原来 nvim-notify 的 stages="fade" 没有对应项，snacks 通知无动画
                -- style 默认已是 compact，与原配置一致
            },
            picker = {
                ui_select = true,
            },
            input = {
                win = {
                    keys = {
                        i_esc = { "<esc>", "cancel", mode = "i" },
                    },
                },
            }, -- 接管 vim.ui.input；Esc 直接取消，供 Neo-tree 等统一显示输入框
            -- 光标停住时用 LSP documentHighlight 高亮同一符号的所有出现位置，
            -- 改名前先扫一眼影响范围很方便。跳转键位在下面 config 里注册（模块本身不建键位）
            words = {
                debounce = 200,                 -- 比 updatetime(300) 短，光标停下就出高亮
            },
            -- 接管 statuscolumn：把 git 标记从最左边挪到行号右侧、紧贴代码，
            -- 定位改动行时视线不用在行号和代码之间来回跳。
            -- 左右各住着什么（实测）：
            --   left  = todo-comments 的 TODO/FIX/HACK 图标（它默认 signs=true）+ m{a-z} 书签
            --   right = 折叠箭头 + gitsigns 的 ▎ 标记
            -- 左边没标记时看着是空的，但那是预留位不是浪费：实测两种布局（分区 / 全放右边）
            -- gutter 都是 6 列，snacks 按固定宽度补齐，否则标记一出现代码就会左右抖动。
            statuscolumn = {
                left = { "mark", "sign" },      -- 注解类：TODO 图标、书签
                right = { "fold", "git" },      -- 结构与版本控制类：折叠箭头、git 标记
                folds = { open = true },        -- 显示折叠展开/收起箭头（可折的行才画）
            },
            bigfile = {},                       -- 大文件自动关掉 treesitter/补全等重功能
        },
        config = function(_, opts)
            require("snacks").setup(opts)

            local adapter_installed = false
            local function install_neotree_input_adapter()
                if adapter_installed or vim.ui.input ~= Snacks.input.input then return end

                local snacks_input = vim.ui.input
                local prefix = "Neo-tree Popup\n"
                vim.ui.input = function(input_opts, on_confirm)
                    if type(input_opts) == "table" and type(input_opts.prompt) == "string"
                        and vim.startswith(input_opts.prompt, prefix) then
                        input_opts = vim.tbl_extend("force", {}, input_opts)
                        input_opts.prompt = input_opts.prompt:sub(#prefix + 1)
                    end
                    return snacks_input(input_opts, on_confirm)
                end
                adapter_installed = true
            end

            if vim.v.vim_did_enter == 1 then
                install_neotree_input_adapter()
            else
                vim.api.nvim_create_autocmd("UIEnter", {
                    once = true,
                    callback = function() vim.schedule(install_neotree_input_adapter) end,
                })
            end

            -- 统一主题入口：全部自定义高亮组（EVA / git 分档 / bufferline / 粘性上下文…）
            -- 都在这里一次性注册；Snacks.util.set_hl 托管重挂，换 colorscheme 自动重设
            require("config.theme").setup()

            -- inlay hints 开关（从 lsp.lua 迁来）：Snacks.toggle 带通知和 which-key 图标，
            -- 作用域同为 bufnr=0，行为和原来一致
            Snacks.toggle.inlay_hints():map("<leader>ci")

            -- words 的引用跳转：占 ]]/[[ 是因为原生的 section 移动基本用不到，
            -- 且不与已有的 ]c(hunk) / ]f(函数) / ]t(todo) / ]p(参数) 撞键
            for key, dir in pairs({ ["]]"] = 1, ["[["] = -1 }) do
                vim.keymap.set({ "n", "x", "o" }, key, function()
                    Snacks.words.jump(dir, true)    -- true: 循环，跳到末尾后回到第一个
                end, { desc = dir == 1 and "下一处引用" or "上一处引用" })
            end
        end,
    },
}
