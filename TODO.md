# TODO — dotfiles-nvim

想要的新特性 / 升级待办。动某项前先在此补上实测结论与决策点；完成后勾掉，结论归档进 commit 或 AGENTS.md。

## 等 Neovim 0.13 正式版（milestone due 2026-10-15，预计 10 月中）

- [ ] 升级 0.13 正式版：官方 tarball（走 NJU 镜像）→ `~/.local/opt/nvim-0.13.x` + `~/.local/bin/nvim` 软链（0.12.5 同款流程：sha256 对官方 digest 校验）
- [ ] 实测 0.13 autoread 即时刷新（uv_fs_event 驱动、纯被动秒级刷新），确认后精简 options.lua 的 `AutoReload`（FocusGained/CursorHold 那套变冗余）

## ui2（`vim._core.ui2`）替代 noice —— 0.12.5 起可用，**刻意缓做**（等 0.13 升级时一并评估）

2026-09 实测结论：ui2 能接走"命令行 + 消息呈现"主干（cmd/msg/pager/dialog 四窗口）；正式替换前需补齐以下缺口：

- [ ] LSP 进度条：noice `lsp.progress` 无 ui2 对应 → 候选 fidget.nvim
- [ ] hover / 签名帮助的 markdown 高亮：noice `lsp.override` 无 ui2 对应（会丢）
- [ ] msg 噪音过滤（写入提示 `%d+L, %d+B`）：ui2 只按类别路由、不按内容过滤 → 需 autocmd 另做
- [ ] `<leader>Nl/Nh/Nd` 重映射（`:messages` 走 pager；dismiss 改 snacks 侧）
- [ ] 决策点：命令面板（`:` 自动弹补全）在 ui2 下的替代方案；长消息 split → `[+x]` spill 的行为变化是否接受

回退方案：noice spec 加一行 `enabled = false` 即可，随时可试。

## 内置补全替代 blink —— **两轮试用后回退（2026-09-19），结论归档**

- 两轮试用均回退，blink 继续在用。第一轮作废（交互会话跑旧 0.12.0-dev 二进制、两版 `vim.lsp.completion` 相差 745 行，属无效环境）；第二轮在系统统一 0.12.5 后，从全配置试到最小形态（只加 `autocomplete = true`）。
- **决定性短板（实测）**：0.12.5 的 autocomplete 菜单**不遵守 `pumheight`/`pummaxwidth`**——pumheight=10 时弹出 20 行菜单、pummaxwidth=60 时铺到约 92 列，浮窗尺寸无法约束、挡代码；blink 自绘浮窗（max_height 配置被遵守）故无此问题。本版上游行为，配置层无解。
- 其他差距（与版本无关，先前实测）：菜单刷新依赖服务端 `isIncomplete`（lua_ls 在未分析工作区退化）、无 snippet/路径源、无 ghost text。
- 复评条件：nvim 修复该菜单的尺寸控制（日后升 0.13 时顺手验证）/ 出现 snippet 源机制。**重试步骤**：`options.lua` 加一行 `vim.opt.autocomplete = true`（要 LSP 项再加 `vim.lsp.completion.enable(autotrigger=true)` 到 lsp.lua 的 on_attach），并把 `lua/plugins/blink.lua` 的 spec 注释掉（return {}）。

## 既存问题（先前发现，未处理）

- [ ] lua_ls 缺 globals 配置：全仓库文件都有 `Undefined global vim` 诊断（旧文件同样存在）
- [ ] 系统 tree-sitter-cli 0.22.6 < AGENTS 要求的 0.26.1（parser 源码编译可能受影响）
