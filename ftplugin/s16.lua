vim.bo.commentstring = "; %s"
vim.bo.comments = ":;"
vim.b.undo_ftplugin = "setlocal commentstring< comments<"
require("s16").attach(vim.api.nvim_get_current_buf())
