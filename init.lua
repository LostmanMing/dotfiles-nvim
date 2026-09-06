-- nvim 入口文件，启动时第一个执行
require("config.options")
require("config.autosave").setup({
    save = {
        workspace_edits = true,
        background_modified_buffers = true,
    },
})
require("config.keymaps")
require("config.lazy-setup")

