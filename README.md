# dotfiles-nvim

My Neovim configuration, managed as a standalone repo.

Part of [LostmanMing/dotfiles](https://github.com/LostmanMing/dotfiles).

## Requirements

- Neovim >= 0.12（`vim.ui.clipboard.osc52`、`winborder`、`vim.lsp.document_color`、treesitter main 分支都要）
- Git
- A [Nerd Font](https://www.nerdfonts.com/) (for icons)
- [tree-sitter-cli](https://github.com/tree-sitter/tree-sitter) (for building parsers)
- [ripgrep](https://github.com/BurntSushi/ripgrep) —— telescope 的 `find_files` / `live_grep` 和 todo-comments 都要，**必需**

剪贴板：复制**同时**走 OSC 52 和本地剪贴板工具（`xclip`/`pbcopy` 等，探到才用），谁通算谁的；在 tmux 内还会经 tmux buffer 与 tmux 侧互通。终端支持 OSC 52 就什么都不用装，不支持则需要 X11 转发 + `xclip`。细节见 `AGENTS.md`。唯一的限制是本地机器复制的内容、远程 normal 模式下 `p` 拿不到，用终端的 Cmd+V 即可。

### macOS

```bash
brew install ripgrep
npm install -g tree-sitter-cli
brew install --cask font-jetbrains-mono-nerd-font
```

### Linux (Ubuntu/Debian)

```bash
sudo apt install ripgrep fonts-jetbrains-mono
npm install -g tree-sitter-cli
```

## Standalone Installation

```bash
git clone git@github.com:LostmanMing/dotfiles-nvim.git ~/.config/nvim
nvim
```

On first launch, lazy.nvim bootstraps itself and installs all plugins. LSP servers (pyright, clangd, lua_ls, etc.) are auto-installed via mason.

## As a dotfiles Submodule

```bash
# Clone dotfiles with all submodules
git clone --recurse-submodules git@github.com:LostmanMing/dotfiles.git ~/dotfiles

# Create symlink
ln -s ~/dotfiles/.config/nvim ~/.config/nvim
```

## Structure

```
nvim/
├── init.lua
├── lua/
│   ├── config/
│   │   ├── options.lua
│   │   ├── keymaps.lua
│   │   ├── lazy-setup.lua
│   │   └── util.lua
│   └── plugins/
│       ├── blink.lua
│       ├── bufferline.lua
│       ├── diffview.lua
│       ├── dropbar.lua
│       ├── flash.lua
│       ├── gitsigns.lua
│       ├── im-select.lua
│       ├── lsp.lua
│       ├── lualine.lua
│       ├── markdown.lua
│       ├── noice.lua
│       ├── nvim-tree.lua
│       ├── onedarkpro.lua
│       ├── pairs.lua
│       ├── sleuth.lua
│       ├── smear-cursor.lua
│       ├── snacks.lua
│       ├── surround.lua
│       ├── telescope.lua
│       ├── tmux.lua
│       ├── todo-comments.lua
│       ├── toggleterm.lua
│       ├── treesitter-context.lua
│       ├── treesitter.lua
│       ├── trouble.lua
│       └── which-key.lua
├── scripts/          # 启动页图案资源与生成脚本
└── lazy-lock.json
```

## Plugins

| Plugin | 功能 | 快捷键 |
|--------|------|--------|
| [lazy.nvim](https://github.com/folke/lazy.nvim) | 插件包管理器 | - |
| [onedarkpro.nvim](https://github.com/olimorris/onedarkpro.nvim) | OneDark 配色主题 | - |
| [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) | 底部状态栏 | - |
| [which-key.nvim](https://github.com/folke/which-key.nvim) | `<leader>` 后弹出快捷键提示 | `<leader>` |
| [bufferline.nvim](https://github.com/akinsho/bufferline.nvim) | 顶部 buffer 标签栏 | - |
| [nvim-tree.lua](https://github.com/nvim-tree/nvim-tree.lua) | 侧边文件树 | `Ctrl+n` |
| [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) | 模糊搜索（文件/文本/buffer/符号） | `<leader>f*` |
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | 语法高亮、增量选择、文本对象 | `vif/vaf`, `]f/[f` |
| [nvim-treesitter-context](https://github.com/nvim-treesitter/nvim-treesitter-context) | 把当前函数/循环的签名行钉在窗口顶部 | `<leader>cc`, `[C` |
| [dropbar.nvim](https://github.com/Bekaboo/dropbar.nvim) | 窗口顶部面包屑导航（路径 > 类 > 函数） | `<leader>cb` |
| [mason.nvim](https://github.com/mason-org/mason.nvim) | LSP 服务器自动安装管理 | `gd`, `gh`, `grr`, `<C-k>`, `<leader>cf/ci/ct` |
| [blink.cmp](https://github.com/saghen/blink.cmp) | 自动补全引擎（自带 LSP/路径/buffer/片段源，片段走内置 `vim.snippet`） | `Tab` / `S-Tab` / `CR` |
| [friendly-snippets](https://github.com/rafamadriz/friendly-snippets) | 通用代码片段集合（由 blink 读取） | - |
| [nvim-surround](https://github.com/kylechui/nvim-surround) | 添加/删除/替换包围字符 | `ys`, `ds`, `cs` |
| [mini.pairs](https://github.com/echasnovski/mini.pairs) | 自动配对括号和引号 | - |
| [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) | 行号旁 git 增删改标记，hunk 操作 | `<leader>gs/gr/gp/gb/gd` |
| [diffview.nvim](https://github.com/sindrets/diffview.nvim) | Git diff / 文件历史面板 | `<leader>gv/gV/gh/gH` |
| [flash.nvim](https://github.com/folke/flash.nvim) | 输入字符屏幕标记，一键跳转 | `<leader>s` / `<leader>S` |
| [trouble.nvim](https://github.com/folke/trouble.nvim) | 诊断列表面板 | `<leader>xx` |
| [toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim) | 内嵌终端，多方向多实例 | `<leader>tt/tf/th/tv` |
| [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator) | nvim ↔ tmux 面板无缝导航 | `Ctrl+hjkl` |
| [noice.nvim](https://github.com/folke/noice.nvim) | 命令行居中浮窗 + 通知美化（后端用 snacks.notifier） | `<leader>N*` |
| [snacks.nvim](https://github.com/folke/snacks.nvim) | 启动页（EVA 初号机图案）、缩进线、通知、大文件降级、引用高亮、statuscolumn（git 标记移到行号右侧） | `]]/[[`, `<leader>ci` |
| [todo-comments.nvim](https://github.com/folke/todo-comments.nvim) | TODO/FIX/HACK 等注释关键词高亮与检索 | `]t/[t`, `<leader>xt/ft` |
| [render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim) | Markdown 在编辑器内渲染（标题/表格/复选框） | `<leader>mt` |
| [smear-cursor.nvim](https://github.com/sphamba/smear-cursor.nvim) | 光标移动拖影动画 | - |
| [im-select.nvim](https://github.com/keaising/im-select.nvim) | 离开插入模式自动切回英文输入法 | - |
| [vim-sleuth](https://github.com/tpope/vim-sleuth) | 按文件自动检测缩进宽度 | - |


## Keybindings

### 通用

| Key | Action |
|-----|--------|
| `<Space>` | Leader key |
| `jj` | 退出插入模式 |
| `q` | 智能关闭（浮窗 → split → tab → buffer → 全部退出） |
| `<Esc>` | 清除搜索高亮 |

### 窗口

| Key | Action |
|-----|--------|
| `<C-h/j/k/l>` | 窗口导航（左/下/上/右） |
| `<S-Up/Down/Left/Right>` | 调整窗口大小 |
| `\` | 垂直分屏 |
| `-` | 水平分屏 |

### Tab（标签页）

想开新文件又不想拆掉当前分屏布局时用：分屏布局留在原 tab 里，新文件在新 tab 打开。
多个 tab 时 bufferline 右上角会显示 tab 编号。

**buffer 按 tab 隔离**（scope.nvim）：每个 tab 的 bufferline 只显示在这个 tab 里开过的
文件，`H`/`L` 也只在本 tab 内循环。没有这层隔离时每个 tab 的 tabline 长得完全一样，
在临时 tab 里按 `H`/`L` 切到主 tab 的文件后，很容易误以为分屏布局被破坏了。

| Key | Action |
|-----|--------|
| `<leader><Tab>n` | 新建 tab |
| `<leader><Tab>d` | 关闭当前 tab（先写盘本 tab 的改动） |
| `gt` / `gT` | 下一个 / 上一个 tab（原生） |
| `<leader>ff` 后 `<C-t>` | 把选中的文件开到新 tab（telescope 自带） |
| `<leader>fB` | 跨 tab 搜 buffer，选中会跳到它所在的 tab |
| `:ScopeList` | 排查哪个 buffer 归哪个 tab |
| `:ScopeMoveBuf` | 把当前 buffer 搬到别的 tab |

几点实测出来的行为，改这块前先看：

- `q` **不会**关 tab——它优先关 split、再关 buffer，只有当这个 tab 连 buffer 都没得
  显示时才顺带 `tabclose`。所以在分屏那个 tab 里连按 `q` 不会把布局所在的 tab 弄掉。
  要主动关 tab 用 `<leader><Tab>d`。
- 同一个文件在两个 tab 都开着时，`q` 只在当前 tab 取消列出、**不真删**。
  `nvim_buf_delete` 是全局的，真删会让它从另一个 tab 里一起消失。
- 关掉一个 tab 后，只属于它的 buffer 会变成「活着但哪儿都不列出」，`<leader>fB`
  也搜不到。文件本身在磁盘上，重新 `<leader>ff` 打开即可。

### Buffer

| Key | Action |
|-----|--------|
| `H` | 上一个 buffer（只在当前 tab 内循环） |
| `L` | 下一个 buffer（只在当前 tab 内循环） |
| `q` | 关闭当前 buffer（智能关闭） |

### 文件查找 (Telescope)

| Key | Action |
|-----|--------|
| `<leader>ff` | 搜文件名 |
| `<leader>fg` | 全局搜文本 (live grep) |
| `<leader>fb` | 搜已打开的 buffer |
| `<leader>fr` | 最近打开的文件 |
| `<leader>fs` | 当前文件符号（类/函数/变量） |
| `<leader>fd` | 诊断列表 |
| `<leader>fh` | 帮助文档 |
| `<leader>fo` | 恢复上次搜索 |

### LSP / 代码

| Key | Action |
|-----|--------|
| `gd` | 跳转到定义 |
| `grd` | 跳转到声明 |
| `grt` | 跳转到类型定义 |
| `gri` | 跳转到实现 |
| `grr` | 查找引用 (Telescope) |
| `grn` | 重命名符号 |
| `gra` | 代码操作 (code action) |
| `K` | 悬浮文档 |
| `gh` | 诊断 / 悬浮文档 |
| `<C-k>` (插入模式) | 参数签名提示 |
| `<leader>cf` | 格式化代码 |
| `<leader>ci` | 切换 inlay hints（参数名/类型显示，带通知） |
| `<leader>ct` | 切换色值圆点（LSP documentColor，0.12 内置） |
| `<leader>cc` | 切换粘性上下文（顶部钉住函数签名） |
| `<leader>cb` | 面包屑交互选择（在层级间跳转） |
| `[C` | 跳到当前上下文起始行 |
| `]]` / `[[` | 下一处 / 上一处引用（同一符号） |
| `[d` / `]d` | 上一个 / 下一个诊断 |
| `<leader>xx` | Trouble 诊断面板 |

### Git

| Key | Action |
|-----|--------|
| `<leader>gs` | Stage hunk |
| `<leader>gr` | Reset hunk |
| `<leader>gp` | 预览 hunk |
| `<leader>gb` | Blame 当前行 |
| `<leader>gd` | Diff against index |
| `[c` / `]c` | 上一个 / 下一个 hunk |
| `<leader>gv` / `<leader>gV` | 打开 / 关闭 Diffview |
| `<leader>gh` / `<leader>gH` | 当前文件历史 / 仓库历史 |

### TODO 注释

| Key | Action |
|-----|--------|
| `]t` / `[t` | 下一个 / 上一个 TODO |
| `<leader>xt` | TODO 列表（Trouble 面板） |
| `<leader>ft` | 搜索 TODO（Telescope，需要 ripgrep） |

支持的关键词：`TODO` `FIX` `HACK` `WARN` `PERF` `NOTE` `TEST`

### Markdown

| Key | Action |
|-----|--------|
| `<leader>mt` | 切换 markdown 渲染（看原始文本） |

打开 `.md` 文件自动渲染标题、表格、复选框、引用和代码块；进插入模式自动显示原始文本。

### Flash 快速跳转

| Key | Action |
|-----|--------|
| `<leader>s` | 输入字符 → 标签标记 → 按标签键跳转 |
| `<leader>S` | 选中语法节点（函数/类等） |
| `<leader>j` | 给下方各行首打标签，按标签跳到某行 |
| `<leader>k` | 给上方各行首打标签，按标签跳到某行 |

### 通知 / 消息 (Noice)

| Key | Action |
|-----|--------|
| `<leader>Nl` | 重新显示最后一条消息 |
| `<leader>Nh` | 打开消息历史 |
| `<leader>Nd` | 清掉当前所有通知 |

### Treesitter 文本对象 & 跳转

| Key | Action |
|-----|--------|
| `vif` / `vaf` | 选中函数内部 / 整个函数 |
| `vip` / `vap` | 选中参数内部 / 整个参数 |
| `vil` / `val` | 选中循环内部 / 整个循环 |
| `vic` / `vac` | 选中类内部 / 整个类 |
| `]f` / `[f` | 下一个 / 上一个函数 |
| `]p` / `[p` | 下一个 / 上一个参数 |
| `<leader>na` / `<leader>pa` | 参数与下一个 / 上一个互换 |
| `<Enter>` (n) | 开始增量选中语法节点 |
| `<Enter>` (v) | 扩大选中范围 |
| `<BS>` (v) | 缩小选中范围 |

### 终端 (Toggleterm)

| Key | Action |
|-----|--------|
| `<leader>tt` | 全屏终端（新 tab） |
| `<leader>tf` | 浮动终端 |
| `<leader>th` | 水平终端（底部） |
| `<leader>tv` | 垂直终端（右侧） |

终端内快捷键（仅 toggleterm 终端内生效）：

| Key | Action |
|-----|--------|
| `<C-n>` | 新建终端（继承当前方向） |
| `<C-]>` | 切换到下一个终端（环形） |
| `gf` / `gF` | 在编辑窗口打开光标下的文件 |
| `<Esc>` | 退出到 normal 模式 |

### 文件树 (nvim-tree)

| Key | Action |
|-----|--------|
| `<C-n>` | 切换目录树 |
| `l` (树上) | 预览文件 |
| `Enter` (树上) | 打开文件 |
| `q` (树上) | 聚焦到编辑窗口 |
| `a` (树上) | 新建文件/目录 |
| `r` (树上) | 重命名 |
| `d` (树上) | 删除 |
| `I` (树上) | 切换是否隐藏 `.gitignore` 排除的文件 |

默认**显示** `.gitignore` 排除的文件（带 `◌` 标记区分），按 `I` 可临时隐藏。

### 启动页 (Dashboard)

不带文件参数运行 `nvim` 时显示（EVA 初号机图案）。以下按键仅在启动页生效：

| Key | Action |
|-----|--------|
| `f` | 找文件 (Telescope) |
| `n` | 新建文件 |
| `g` | 全局搜文本 (live grep) |
| `c` | 打开配置 (init.lua) |
| `l` | 打开 Lazy 面板 |
| `q` | 退出 Neovim |
