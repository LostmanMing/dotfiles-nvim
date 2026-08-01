---
name: verify-nvim-config
description: >-
  修改本仓库 Neovim 配置后，必须实际运行 nvim 验证效果，不能假设或凭读代码判断。
  触发：编辑 init.lua、lua/config/*、lua/plugins/*、插件、keymap、options 等任何 nvim 配置，
  或声称"已修复/已生效"时。适用于任何 LLM/agent。
---

# verify-nvim-config

**改了配置就跑 nvim 验证，用真实输出说话。没验证过，不许说"已生效/已修复"。**

改完运行（最快路径，一条命令覆盖语法 + 启动）：

```bash
skills/verify-nvim-config/verify.sh
```

绿 = 语法和启动没问题。**但这不等于效果对**——涉及键位 / UI / 终端 / 命令的改动，必须再用真实会话看实际行为：

```bash
tmux new-session -d -s v -x 150 -y 40
tmux send-keys -t v 'nvim' Enter; sleep 4
tmux send-keys -t v ':你要验证的命令' Enter; sleep 3
tmux capture-pane -t v -p | tail -8      # 亲眼确认结果，别猜
tmux kill-session -t v
```

提交前 `git diff` 核对改动，提交后 `git status -sb` 确认已同步。只报告真实跑出来的结果。
