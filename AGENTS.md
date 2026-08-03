# AGENTS.md — dotfiles-nvim

本文件供 AI Agent 配置 Neovim 环境时参考。

**重要**: 先询问用户需要配置哪些部分，不要一次性全装。根据用户系统自动选择包管理器，本文件只列所需软件。

**规则**: 新增任何配置（插件、快捷键、选项）必须在对应文件中写注释说明用途。每个 keymap 必须带 `desc`。

**验证（强制）**: 任何修改 nvim 配置的改动，提交前必须实际运行 nvim 验证，禁止未运行就声称"已生效/已修复"。最快方式：运行 `skills/verify-nvim-config/verify.sh`（语法校验 + 启动烟测）；涉及键位 / UI / 终端 / 命令的改动，再按 `skills/verify-nvim-config/SKILL.md` 用 tmux 真实会话验证。

## Requirements

### 系统依赖

| 软件 | 用途 | 备注 |
|------|------|------|
| Neovim >= 0.12 | 编辑器本身 | nvim-treesitter main 分支要求 0.12+；配置用到 `winborder`/`pumborder`/`virtual_lines`/`vim.lsp.document_color` |
| Git | 插件管理 | lazy.nvim 需要 |
| Node.js >= 18 | LSP 运行时 | jsonls, yamlls 等需要 |
| ripgrep | Telescope live_grep | 搜索加速 |
| fd | Telescope 文件查找 | 可选，提升性能 |
| clangd | C/C++ LSP | mason 自动装插件，但 clangd 二进制需系统提供 |
| tree-sitter-cli >= 0.26.1 | parser 编译器 | **用系统包管理器装，不要用 npm**（treesitter main 分支的明确要求） |
| Nerd Font | 图标字体 | JetBrainsMono Nerd Font |
| reattach-to-user-namespace | macOS tmux 剪贴板互通 | `brew install reattach-to-user-namespace` |

### 版本过旧时的处理

部分系统仓库版本可能太旧（如 Ubuntu 的 tree-sitter），应优先检查 `--version`，不满足则源码/二进制安装：

- **tree-sitter-cli**: 需 >= 0.26.1，且上游要求**不要用 npm 装**。按平台选：
  `brew install tree-sitter-cli` / `pacman -S tree-sitter-cli` / `cargo install tree-sitter-cli`，
  或从 [tree-sitter releases](https://github.com/tree-sitter/tree-sitter/releases) 下二进制。
  Debian/Ubuntu 仓库里的 `tree-sitter` 通常远低于 0.26，别直接 apt。
- **Neovim**: 下载 GitHub Release 二进制或 appimage

## Installation

```bash
ln -sf ~/dotfiles/.config/nvim ~/.config/nvim
nvim  # 首次启动自动安装插件和 LSP
```

## LSP Servers

mason 自动安装：`clangd`, `lua_ls`, `pyright`, `bashls`, `neocmake`, `marksman`, `jsonls`, `yamlls`

## macOS + tmux 剪贴板

在 tmux 内使用 nvim 需要 `reattach-to-user-namespace`（`brew install`）才能读写系统剪贴板。

## 配置文档

快捷键、插件列表等详见 `README.md`。
