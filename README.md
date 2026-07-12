# dotfiles-nvim

My Neovim configuration, managed as a standalone repo.

Part of [LostmanMing/dotfiles](https://github.com/LostmanMing/dotfiles).

## Requirements

- Neovim >= 0.11
- Git
- A [Nerd Font](https://www.nerdfonts.com/) (for icons)
- [tree-sitter-cli](https://github.com/tree-sitter/tree-sitter) (for building parsers)
- [ripgrep](https://github.com/BurntSushi/ripgrep) (for telescope live grep)

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
│   │   └── lazy-setup.lua
│   └── plugins/
│       ├── bufferline.lua
│       ├── cmp.lua
│       ├── comment.lua
│       ├── flash.lua
│       ├── gitsigns.lua
│       ├── lsp.lua
│       ├── lualine.lua
│       ├── nvim-tree.lua

│       ├── onedarkpro.lua
│       ├── pairs.lua
│       ├── surround.lua
│       ├── telescope.lua
│       ├── toggleterm.lua
│       ├── treesitter.lua
│       ├── trouble.lua
│       └── which-key.lua
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
| [mason.nvim](https://github.com/williamboman/mason.nvim) | LSP 服务器自动安装管理 | `gd`, `gh`, `grr`, `<C-k>`, `<leader>cf/th` |
| [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) | 自动补全引擎 | `Tab` / `S-Tab` |
| [LuaSnip](https://github.com/L3MON4D3/LuaSnip) | 代码片段引擎 | - |
| [Comment.nvim](https://github.com/numToStr/Comment.nvim) | `gcc` 注释行，`gc` + text object 注释范围 | `gcc` |
| [nvim-surround](https://github.com/kylechui/nvim-surround) | 添加/删除/替换包围字符 | `ys`, `ds`, `cs` |
| [mini.pairs](https://github.com/echasnovski/mini.pairs) | 自动配对括号和引号 | - |
| [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) | 行号旁 git 增删改标记，hunk 操作 | `<leader>gs/gr/gp/gb/gd` |
| [lazygit.nvim](https://github.com/kdheepak/lazygit.nvim) | 打开 lazygit TUI | `<leader>gg` |
| [flash.nvim](https://github.com/folke/flash.nvim) | 输入字符屏幕标记，一键跳转 | `<leader>s` / `<leader>S` |
| [trouble.nvim](https://github.com/folke/trouble.nvim) | 诊断列表面板 | `<leader>xx` |
| [toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim) | 内嵌终端，多方向多实例 | `<leader>tt/tf/th/tv` |


## Keybindings

### 通用

| Key | Action |
|-----|--------|
| `<Space>` | Leader key |
| `jj` | 退出插入模式 |
| `q` | 智能关闭（浮窗 → split → buffer → 全部退出） |
| `gb` | 切回上一个 buffer |
| `<Esc>` | 清除搜索高亮 |

### 窗口

| Key | Action |
|-----|--------|
| `<C-h/j/k/l>` | 窗口导航（左/下/上/右） |
| `<S-Up/Down/Left/Right>` | 调整窗口大小 |

### Buffer

| Key | Action |
|-----|--------|
| `<leader>h` | 上一个 buffer |
| `<leader>l` | 下一个 buffer |
| `<leader>q` | 关闭当前 buffer |

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
| `grr` | 查找引用 (Telescope) |
| `K` | 悬浮文档 |
| `gh` | 诊断 / 悬浮文档 |
| `gra` | 代码操作 (code action) |
| `<C-k>` (插入模式) | 参数签名提示 |
| `<leader>cf` | 格式化代码 |
| `<leader>th` | 切换 inlay hints（参数名显示） |
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
| `<leader>gg` | LazyGit |
| `[c` / `]c` | 上一个 / 下一个 hunk |

### Flash 快速跳转

| Key | Action |
|-----|--------|
| `<leader>s` | 输入字符 → 标签标记 → 按标签键跳转 |
| `<leader>S` | 选中语法节点（函数/类等） |

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

终端内快捷键：

| Key | Action |
|-----|--------|
| `<C-n>` | 新建终端（继承当前方向） |
| `<C-]>` | 下一个终端 |
| `<C-[>` | 上一个终端 |
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
