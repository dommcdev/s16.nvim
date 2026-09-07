if vim.g.loaded_s16 then return end
vim.g.loaded_s16 = true
vim.filetype.add({ extension = { s16 = "s16" } })
