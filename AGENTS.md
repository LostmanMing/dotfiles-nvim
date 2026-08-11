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
| ripgrep | Telescope **必需** | `live_grep`/`grep_string` 只用 rg；`find_files` 的命令选择也是 rg 优先（`__files.lua` 里 `rg → fd → fdfind → find`）。没装会降级到 `find`，那就完全不认 `.gitignore` |
| fd | 仅 rg 不可用时的降级备选 | **rg 在的话一次都不会被调用**，别当成提速手段。Debian/Ubuntu 包名是 `fd-find`、二进制却叫 `fdfind`，而 telescope 先查 `fd` 再查 `fdfind`，所以只会命中后一个分支 |
| clangd | C/C++ LSP | mason 自动装插件，但 clangd 二进制需系统提供 |
| tree-sitter-cli >= 0.26.1 | parser 编译器 | **用系统包管理器装，不要用 npm**（treesitter main 分支的明确要求） |
| Nerd Font | 图标字体 | JetBrainsMono Nerd Font |

### 版本过旧时的处理

部分系统仓库版本可能太旧（如 Ubuntu 的 tree-sitter），应优先检查 `--version`，不满足则源码/二进制安装：

- **tree-sitter-cli**: 需 >= 0.26.1，且上游要求**不要用 npm 装**。按平台选：
  `brew install tree-sitter-cli` / `pacman -S tree-sitter-cli` / `cargo install tree-sitter-cli`，
  或从 [tree-sitter releases](https://github.com/tree-sitter/tree-sitter/releases) 下二进制。
  Debian/Ubuntu 仓库里的 `tree-sitter` 通常远低于 0.26，别直接 apt。
- **Neovim**: 下载 GitHub Release 二进制或 appimage

### 搜索为什么会命中 `.gitignore` 排除的文件

**ripgrep 和 fd 都只在 git 仓库内部才读 `.gitignore`**（两者用同一个 `ignore` 库）。实测同一个目录：

| 场景 | `rg --files` / `fd --type f` |
|------|---------------------------|
| 有 `.gitignore`、目录**不是** git 仓库 | `build/a.c ok.c x.log` —— `.gitignore` 被完全忽略 |
| 同一目录 `git init` 之后 | `ok.c` —— 正常过滤 |

所以在「只有 `.gitignore`、没有 `.git`」的目录里搜索，排除项照样会出现。三种解法：

1. **给那个目录加 `.ignore` 或 `.rgignore`** —— rg/fd 认这两个文件且**不要求 git**（实测非仓库里也生效）。最省事：`ln -s .gitignore .ignore`
2. **让 telescope 一律带 `--no-require-git`** —— 要改**两处**，`find_files` 和 `live_grep` 走的是不同参数：`defaults.vimgrep_arguments`（live_grep / grep_string 用）和 `pickers.find_files.find_command`
3. **`git init` 那个目录** —— 如果它本来就该是仓库

注意 `hidden = true` / `--hidden` 只放开隐藏文件，**不影响** gitignore 过滤，别混淆。另外 `oldfiles`（`<leader>fr`）和 `buffers`（`<leader>fb`）取的是 vim 自己的列表、根本不经过 rg，永远不受 `.gitignore` 约束。

### 剪贴板

配置在 `lua/config/options.lua`，与 tmux 侧配合成三方互通（本地机器 ↔ 远程 tmux ↔ 远程 nvim）：

| 方向 | 走什么 |
|------|--------|
| 复制 | **两条并行**：内置 `vim.ui.clipboard.osc52` 的 `copy`（零 fork，在 tmux 内会被 tmux 截获写进它自己的 buffer 再转发出去）**加上**探到的本地工具（`pbcopy`/`wl-copy`/`xclip`/`clip.exe`，用 `vim.system` 异步写）。谁通算谁的 |
| 粘贴（tmux 内） | `tmux save-buffer -` —— 能同时拿到 nvim 自己 yank 的和 tmux copy-mode 里 `y` 复制的 |
| 粘贴（无 tmux 但有工具） | `pbpaste` / `wl-paste` / `xclip -o` |
| 粘贴（都没有） | 会话内缓存 |

三条**不能改**的地方，都是踩过的：

1. **复制必须两条都发，不能二选一。** 曾经改成「有 `DISPLAY` 就只走 `xclip`」，结果 nvim 复制的东西既没进 tmux buffer 也没到本地；后来又反过来「远程就只发 OSC 52、不用工具」，结果那台本地终端**不接受 OSC 52** 的机器（一直靠 SSH X11 转发 + `xclip`）直接复制不出去。两次都是二选一造成的。现在并行，工具失败也不影响 OSC 52 那条。
2. **不能用 `osc52.paste`。** 它发 OSC 52 读请求后等终端回应，而绝大多数终端出于安全不回——runtime 源码里写死先等 1s、再等 9s，每次 `p` 都会卡住。
3. **`cache_enabled` 必须是 0。** 开了之后 nvim 只认自己上次复制的内容，tmux copy-mode 里新复制的东西 `p` 不出来。

依赖 tmux 侧 `set-clipboard on`（改成 `external` 就不写 tmux buffer，nvim ↔ tmux 那条腿会断）。终端支持 OSC 52 时不需要装任何工具；不支持则需要 X11 转发 + `xclip`。

`:ClipboardInfo` 可以随时查当前走的哪条路；只有在「没 tmux 也没工具」这种真降级时才会在启动后弹一条 WARN。**注意有一种问题检测不到**：终端拒收 OSC 52 时复制静默失败，OSC 52 是单向写、拿不到回执，只能手动复制后到本地 Cmd+V 验证。

## Installation

```bash
ln -sf ~/dotfiles/.config/nvim ~/.config/nvim
nvim  # 首次启动自动安装插件和 LSP
```

## LSP Servers

mason 自动安装：`clangd`, `lua_ls`, `pyright`, `bashls`, `neocmake`, `marksman`, `jsonls`, `yamlls`

## 配置文档

快捷键、插件列表等详见 `README.md`。
