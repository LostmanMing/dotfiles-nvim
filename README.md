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
│       ├── cmp.lua
│       ├── comment.lua
│       ├── diffview.lua
│       ├── flash.lua
│       ├── gitsigns.lua
│       ├── lsp.lua
│       ├── lualine.lua
│       ├── nvim-tree.lua
│       ├── oil.lua
│       ├── onedarkpro.lua
│       ├── pairs.lua
│       ├── snacks.lua
│       ├── surround.lua
│       ├── telescope.lua
│       ├── toggleterm.lua
│       ├── treesitter.lua
│       ├── trouble.lua
│       └── which-key.lua
└── lazy-lock.json
```

## Plugins

| Category | Plugin | Keybinding |
|----------|--------|------------|
| Package Manager | [lazy.nvim](https://github.com/folke/lazy.nvim) | - |
| Colorscheme | [onedarkpro.nvim](https://github.com/olimorris/onedarkpro.nvim) | - |
| Statusline | [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) | - |
| Key Hints | [which-key.nvim](https://github.com/folke/which-key.nvim) | `<leader>` |
| Terminal | [toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim) | `Ctrl+\` |
| File Explorer | [oil.nvim](https://github.com/stevearc/oil.nvim) | `-` |
| File Tree | [nvim-tree.lua](https://github.com/nvim-tree/nvim-tree.lua) | `Ctrl+n` |
| Fuzzy Finder | [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) | `<leader>f*` |
| Syntax | [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | - |
| LSP | [mason.nvim](https://github.com/williamboman/mason.nvim) | `gd`, `gh`, `grr`, `<leader>cf` |
| Completion | [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) + [LuaSnip](https://github.com/L3MON4D3/LuaSnip) | `Tab` / `S-Tab` |
| Comments | [Comment.nvim](https://github.com/numToStr/Comment.nvim) | `gcc` |
| Surround | [nvim-surround](https://github.com/kylechui/nvim-surround) | `ys`, `ds`, `cs` |
| Auto Pairs | [mini.pairs](https://github.com/echasnovski/mini.pairs) | - |
| Git Signs | [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) | `<leader>gs/gr/gp/gb/gd` |
| Git Diff | [diffview.nvim](https://github.com/sindrets/diffview.nvim) | `<leader>gv/gh/gH` |
| Fast Jump | [flash.nvim](https://github.com/folke/flash.nvim) | `<leader>s` / `<leader>S` |
| Diagnostics | [trouble.nvim](https://github.com/folke/trouble.nvim) | `<leader>xx` |
| Misc | [snacks.nvim](https://github.com/folke/snacks.nvim) | - |

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
| `<leader>fs` | Git 状态（变更文件） |
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
| `<leader>cf` | 格式化代码 |
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
| `<leader>gv` | Diffview 打开 |
| `<leader>gh` | 当前文件 commit 历史 |
| `<leader>gH` | 仓库 commit 历史 |
| `[c` / `]c` | 上一个 / 下一个 hunk |

### Flash 快速跳转

| Key | Action |
|-----|--------|
| `<leader>s` | 输入字符 → 标签标记 → 按标签键跳转 |
| `<leader>S` | 选中语法节点（函数/类等） |

### 终端 (Toggleterm)

| Key | Action |
|-----|--------|
| `Ctrl+\` | 切换终端（默认浮动窗口） |
| `<leader>tt` | 切换终端 |
| `<leader>tf` | 浮动终端 |
| `<leader>th` | 水平终端 |
| `<leader>tv` | 垂直终端 |

终端内快捷键：

| Key | Action |
|-----|--------|
| `<C-n>` | 新建终端 |
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
