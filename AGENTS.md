# AGENTS.md — dotfiles-nvim

本文件供 AI Agent 配置 Neovim 环境时参考。

**重要**: 先询问用户需要配置哪些部分，不要一次性全装。根据用户系统自动选择包管理器，本文件只列所需软件。

**规则**: 新增任何配置（插件、快捷键、选项）必须在对应文件中写注释说明用途。每个 keymap 必须带 `desc`。

**开发 Skill**: 修改本仓库时使用 `/develop-neovim`；它负责安装、修改、排错和真实交互验收，并复用下方已有的 `verify-nvim-config`。

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
| debugpy | Python DAP adapter | `nvim-dap-python` 使用系统 `python3` 中的模块；安装命令见下 |
| lldb-vscode | C/C++ DAP adapter | Ubuntu 22.04 由 `lldb-14` 提供，二进制通常是 `lldb-vscode-14` |
| tree-sitter-cli >= 0.26.1 | parser 编译器 | **用系统包管理器装，不要用 npm**（treesitter main 分支的明确要求） |
| Nerd Font | 图标字体 | JetBrainsMono Nerd Font |

### 版本过旧时的处理

部分系统仓库版本可能太旧（如 Ubuntu 的 tree-sitter），应优先检查 `--version`，不满足则源码/二进制安装：

- **tree-sitter-cli**: 需 >= 0.26.1，且上游要求**不要用 npm 装**。按平台选：
  `brew install tree-sitter-cli` / `pacman -S tree-sitter-cli` / `cargo install tree-sitter-cli`，
  或从 [tree-sitter releases](https://github.com/tree-sitter/tree-sitter/releases) 下二进制。
  Debian/Ubuntu 仓库里的 `tree-sitter` 通常远低于 0.26，别直接 apt。
- **Neovim**: 下载 GitHub Release 二进制或 appimage

### 调试依赖

`lazy.nvim` 会自动安装 `nvim-dap` 和 `nvim-dap-python` 插件；调试 adapter 需单独安装：

```bash
python3 -m pip install --user debugpy
apt-get install -y lldb-14
python3 -m debugpy --version
command -v lldb-vscode-14
```

Python 调试使用当前 `python3` 环境中的 debugpy；C/C++ 与 Python→C++ 混合调试使用 `lldb-vscode-14`。容器内 attach/launch 还需要 `CAP_SYS_PTRACE`，缺少该权限时 LLDB 会启动但无法控制目标进程。

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

### buffer 按 tab 隔离（scope.nvim）

`lua/plugins/scope.lua`。机制是 **TabLeave 时把当前 tab 的 buffer 全部置为
`buflisted=false` 并缓存，TabEnter 时把进入的那个 tab 的恢复成 `true`**。因为动的是
`buflisted` 本身，bufferline、`:ls`、`:bnext`，以及 `q` 的关闭逻辑（它数
`buflisted`）全都自动变成 tab 作用域。`H`/`L` 读取同一份 BufferLine 顺序，但额外跳过目录和工具 buffer，避免切换到非文件内容。

不要改成 bufferline 的 `custom_filter` 手写 tab 隔离：那样只有 bufferline 是隔离的、
`:ls`/telescope/`q` 仍是全局，反而割裂。bufferline README 的
「How do I see only buffers per tab?」也是指向这个插件。

两条改 `q` 时容易踩的：

1. **`nvim_buf_delete` 是全局的。** 同一文件在两个 tab 都开着时直接删，会让它从另一个
   tab 的 bufferline 里一起消失（实测过）。所以 `keymaps.lua` 里先用
   `open_in_other_tab()` 查 `scope.core.cache`，命中就只设 `buflisted = false`。
2. **`tabclose` 必须排在删 buffer 之后。** 排前面会导致「有 2+ 个 tab」时 `q` 完全关不掉
   buffer（一直堆积），而且在分屏那个 tab 里收到最后一个窗口再按 `q` 会把正在用的 tab
   关掉、人被丢到另一个 tab。

关掉一个 tab 后，只属于它的 buffer 会变成「活着但哪儿都不列出」，连 `<leader>fB` 都搜
不到（文件在磁盘上，重开即可）。`restore_state` 保持默认 `false`——上游自己标注 session
恢复是实验性的。

### Neo-tree 文件树

`lua/plugins/neo-tree.lua` 启用 filesystem 与 git_status source，必须 `lazy=false` 并显式 `hijack_netrw_behavior="open_default"`，让 `nvim <目录>` 在 Netrw 前打开左侧树；右侧空白内容占位是预期行为，但单目录启动时必须在 Neo-tree 窗口打开后设为 unlisted，避免出现文件夹或 `[No Name]` Bufferline tab。`<C-n>` 是三态：未打开时打开并 reveal，已打开但焦点在代码窗时只 focus 现有树窗口，焦点在树上时关闭；Git-status 视图中则切回 filesystem。两种 source 中的 `g` 均在两视图间切换，切换时只关闭当前 source，保留 filesystem 的展开状态和宽度；`g` mapping 必须 `nowait=false`，既保留 filesystem 的 `g?` help，也保留 Git-status 的 `ga`/`gu`/`gr` 操作前缀。filesystem 专用 mappings 必须放在 `filesystem.window.mappings`，不要覆盖 Git-status 的 stage/unstage/revert 命令。

`l` 在目录上调用 filesystem `toggle_node` 展开/折叠，不触发 preview；在文件上才是一次性非浮动 preview：按下时只预览当前选中项，之后 `j/k` 不更新预览；焦点必须留在树。此 preview mapping 同时用于 Git-status source。`preview_once()` 的文件路径必须调用原生 `preview`，不能改回订阅 CursorMoved 的 `toggle_preview`。preview target 必须保存原 winbar，并挂 Dropbar 显示面包屑；q、Esc、Enter、`<C-n>` close 和 WinClosed 后恢复原值。树内 `q` 先 revert preview 再回 preview target；Enter 则正式打开**当前选中**项并聚焦编辑窗。ignored 文件默认可见，`I` 只切换 ignored，不要把 dotfile/hidden 过滤混进来。`R` 的开始/完成通知使用同一 ID。最后内容窗口关闭时仍由 `keymaps.lua` 保存并退出，不能启用 Neo-tree 的 `close_if_last_window` 取代它。

Dashboard 不能直接成为非浮动 preview 的旧 buffer：Neo-tree 会把它的 `bufhidden=wipe` 改成 `hide`，导致 EVA terminal 浮窗残留且退出 preview 后 Dashboard 被恢复。`preview_once()` 必须先把 Dashboard 窗口交给一次性 unlisted buffer，再调用 Neo-tree 原生 preview；普通文件不能走这个特判。

Neo-tree 设置 `use_popups_for_input=false` 后，`a/r` 等文本操作走 `vim.ui.input`，由 `snacks.lua` 的 `input = {}` 接管为全局 Snacks Input；插入态单次 Esc 直接取消，避免补全内容误提交。Snacks setup 后的 adapter 只剥离精确的 `Neo-tree Popup\n` cmdheight=0 兼容前缀，避免多行标题截断；其它全局输入必须原样转发。不要改写 `add`/`rename` 映射或用 Telescope 重做输入：当前链路保留 Neo-tree 的选中路径、`/` 建目录、嵌套/brace 创建、Tab 补全、取消、重复目标错误与刷新。

`config.autosave` 是保存、reload、外部冲突和 LSP WorkspaceEdit 保存的唯一所有者；通过 `setup()` 的 `save.events`、`save.workspace_edits`、`save.background_modified_buffers`、`reload.checktime_events` 和 `notifications` 配置，不要在 options/plugins 中重复注册保存 autocmd。它只写普通磁盘文件，不 force write，成功 WorkspaceEdit 才逐个调度实际修改目标；失败/部分失败编辑必须保持 modified、不得自动落盘。后台程序化改动只保存非当前 buffer，当前用户编辑仍走常规事件。`q`/tab/quit 的显式 `silent write` 是保留的退出路径，暂不并入模块。

`nvim-file-operations` 只监听 Neo-tree event 并通知支持 `workspace.fileOperations` 的 LSP；Neo-tree 始终是唯一文件操作入口，不调用该插件当前主线的直接 `rename/create/delete` API。它必须在 `vim.lsp.enable()` 前声明 global capability，且 `auto_save=false`，继续由 `config.autosave` 处理成功 workspace edit 的安全保存。LuaLS 单文件重命名会给出更新 `require` 的确认；目录/其它语言的 import 更新属于 server 能力，不能承诺。前置 workspace edit 与文件系统操作之间没有自动回滚，失败时用 undo 或 VCS 恢复。

侧栏 filetype 是 `neo-tree`；非浮动 preview 会暂时把真实文件放进编辑窗并设置 `w:neo_tree_preview=1`，只有浮动 preview 才是 `neo-tree-preview`。侧栏参与智能 `q`/窗口计数排除和 `winfixbuf`；preview 保持 Dropbar 面包屑。真实预览文件仍是普通文件 buffer，不要为了 preview 破坏它的 autosave/LSP/H-L 语义。

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
