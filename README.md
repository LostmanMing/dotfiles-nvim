# dotfiles-nvim

My Neovim configuration, managed as a standalone repo.

Part of [LostmanMing/dotfiles](https://github.com/LostmanMing/dotfiles).

## Requirements

- Neovim >= 0.11
- Git
- A [Nerd Font](https://www.nerdfonts.com/) (for icons)
- [tree-sitter-cli](https://github.com/tree-sitter/tree-sitter) (for building parsers)
- [ripgrep](https://github.com/BurntSushi/ripgrep) (for telescope live grep)
- [lazygit](https://github.com/jesseduffield/lazygit) (for git UI)

### macOS

```bash
brew install ripgrep lazygit
npm install -g tree-sitter-cli
brew install --cask font-jetbrains-mono-nerd-font
```

### Linux (Ubuntu/Debian)

```bash
sudo apt install ripgrep fonts-jetbrains-mono
npm install -g tree-sitter-cli
sudo add-apt-repository ppa:lazygit-team/release
sudo apt update && sudo apt install lazygit
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
│       ├── lazygit.lua
│       ├── lsp.lua
│       ├── lualine.lua
│       ├── mini-diff.lua
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
| LSP | [mason.nvim](https://github.com/williamboman/mason.nvim) | `gd`, `gh`, `grr`, `grn` |
| Completion | [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) + [LuaSnip](https://github.com/L3MON4D3/LuaSnip) | `Tab` / `S-Tab` |
| Comments | [Comment.nvim](https://github.com/numToStr/Comment.nvim) | `gcc` |
| Surround | [nvim-surround](https://github.com/kylechui/nvim-surround) | `ys`, `ds`, `cs` |
| Auto Pairs | [mini.pairs](https://github.com/echasnovski/mini.pairs) | - |
| Git Signs | [snacks.nvim](https://github.com/folke/snacks.nvim) + [mini.diff](https://github.com/echasnovski/mini.diff) | `<leader>ga/gr` |
| Git Client | [lazygit.nvim](https://github.com/kdheepak/lazygit.nvim) | `<leader>gg` |
| Diagnostics | [trouble.nvim](https://github.com/folke/trouble.nvim) | `<leader>xx` |

## Keybindings

| Key | Action |
|-----|--------|
| `<Space>` | Leader key |
| `jj` | Exit insert mode |
| `q` | Smart close (window -> buffer -> quit) |
| `gb` | Alternate buffer |
| `gh` | Hover docs / diagnostics |
| `<C-h/j/k/l>` | Window navigation |
| `<S-arrows>` | Window resize |
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep |
| `<leader>fb` | Find buffers |
| `<leader>fr` | Recent files |
| `<C-n>` | Toggle file tree |
| `<leader>gg` | LazyGit |
| `<leader>tt` | Toggle terminal |
| `<C-n>` (terminal) | New terminal |
| `<C-]>` (terminal) | Next terminal |
| `<Esc>` (terminal) | Exit to normal mode |
| `<leader>xx` | Toggle diagnostics |
| `<leader>cf` | Format code |
| `gd` | Go to definition |
| `grr` | References |
| `grn` | Rename |
