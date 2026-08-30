-- nvim-dap：调试核心 + Python(debugpy)/C-C++(lldb-vscode) 适配器
-- C/C++ 没用 codelldb（得从 GitHub Releases 下几十 MB 的 vsix，网络差的环境下不动），
-- 也没用 gdb（apt 装的 12.1 版没编译 --interpreter=dap，那是 GDB 14+ 才有的特性）。
-- 改用 apt 装 lldb-14 自带的 lldb-vscode 二进制：本身就是按 DAP 协议说话的 adapter，
-- 不需要额外下载/包装层，nvim-dap 官方文档里的 LLDB 推荐用法就是它。
-- 混合调试（如 PyTorch：Python 层断点卡住后，再看 C++ 层栈）：
--   1. 先用 <leader>dc 走 Python 配置正常起 debugpy，卡在断点
--   2. 另开一个调试会话，<leader>dA 选 "Attach to running process"，
--      在弹出的进程列表里选中同一个 python 进程 PID，lldb attach 上去看 C++ 侧
--   nvim-dap 原生支持这样叠会话（断点信号共享，两边各自维护自己的栈/变量视图）
return {
    {
        "mfussenegger/nvim-dap",
        dependencies = {
            "mfussenegger/nvim-dap-python",
        },
        keys = {
            { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "切换断点" },
            { "<leader>dc", function() require("dap").continue() end, desc = "继续/开始调试" },
            { "<leader>do", function() require("dap").step_over() end, desc = "单步跳过" },
            { "<leader>di", function() require("dap").step_into() end, desc = "单步进入" },
            { "<leader>dO", function() require("dap").step_out() end, desc = "单步跳出" },
            { "<leader>dr", function() require("dap").repl.toggle() end, desc = "调试 REPL" },
            { "<leader>dq", function() require("dap").terminate() end, desc = "终止调试" },
            {
                "<leader>dA",
                function()
                    local dap = require("dap")
                    local cfg = vim.tbl_filter(function(c)
                        return c.name == "Attach to running process (pid)"
                    end, dap.configurations.cpp)[1]
                    if cfg then
                        dap.run(cfg)
                    end
                end,
                desc = "lldb attach 到进程（混合调试）",
            },
        },
        config = function()
            local dap = require("dap")
            local sign = vim.fn.sign_define
            sign("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
            sign("DapStopped", { text = "▶", texthl = "DiagnosticWarn" })

            -- debugpy 走系统 python3（mason 装 debugpy 需要 python3.10-venv，环境缺这个包），
            -- 已 pip install debugpy 到系统 python，直接指过去用
            require("dap-python").setup("python3")

            -- lldb-vscode 走系统 $PATH（apt install lldb-14），它本身就是个 DAP server，
            -- 不需要像 codelldb 那样额外包一层；Ubuntu 22.04 装出来的二进制名带版本号后缀
            local lldb_vscode = vim.fn.exepath("lldb-vscode")
            if lldb_vscode == "" then
                lldb_vscode = vim.fn.exepath("lldb-vscode-14")
            end
            dap.adapters.lldb = {
                type = "executable",
                command = lldb_vscode,
                name = "lldb",
            }

            local cpp_configs = {
                {
                    name = "Launch",
                    type = "lldb",
                    request = "launch",
                    program = function()
                        return vim.fn.input("可执行文件路径: ", vim.fn.getcwd() .. "/", "file")
                    end,
                    cwd = "${workspaceFolder}",
                    stopOnEntry = false,
                    args = {},
                },
                {
                    name = "Attach to running process (pid)",
                    type = "lldb",
                    request = "attach",
                    pid = require("dap.utils").pick_process,
                    cwd = "${workspaceFolder}",
                },
            }
            dap.configurations.cpp = cpp_configs
            dap.configurations.c = cpp_configs
        end,
    },
}
