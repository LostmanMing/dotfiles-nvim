-- nvim 0.11 兼容：telescope 需要 ft_to_lang 但新版 nvim 已改名为 get_lang
vim.treesitter.language.ft_to_lang = vim.treesitter.language.get_lang

-- nvim 入口文件，启动时第一个执行
require("config.options")
require("config.keymaps")
require("config.lazy-setup")

