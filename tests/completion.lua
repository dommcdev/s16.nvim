vim.opt.rtp:prepend(vim.fn.getcwd())
local completion = require("s16.completion")
local file = vim.fn.tempname()
vim.fn.writefile({
  "SVC_READ_FROM_TERMINAL EQU 300",
  "SVC_RANDOM EQU 2 ; comment",
  "; SVC_IGNORED EQU 99",
}, file)
completion.setup({ definitions = file })
local buf = vim.api.nvim_get_current_buf()
vim.bo.filetype = "s16"
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
  "SVC_RANDOM equ 42",
  "character EQU ';' ; comment",
  "SVC_R",
})
local source = require("s16.blink").new()
assert(source:enabled())
source:get_completions({ bufnr = buf }, function(result)
  assert(#result.items == 3)
  local by_name = {}
  for _, item in ipairs(result.items) do by_name[item.label] = item end
  assert(by_name.SVC_READ_FROM_TERMINAL.insertText == "SVC_READ_FROM_TERMINAL")
  assert(by_name.SVC_READ_FROM_TERMINAL.detail == "EQU 300")
  assert(by_name.SVC_RANDOM.detail == "EQU 42")
  assert(by_name.character.detail == "EQU ';'")
end)
vim.api.nvim_buf_set_lines(buf, 0, 1, false, { "SVC_RANDOM EQU 43" })
local items = completion.items(buf)
assert(items[1].label == "SVC_RANDOM" and items[1].detail == "EQU 43")
vim.fn.delete(file)
assert(#completion.items(buf) == 2, "Missing external file should preserve buffer completions")
vim.bo.filetype = "lua"
assert(not source:enabled())
print("S16 completion checks passed")
vim.cmd("qa!")
