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
  "buffer RW",
  "words rw 10",
  "message DS \"hello; world\"",
  "count DW 42",
  "loop INCR R1",
  "done RET",
  "; ignored RW",
  "LDR R1,count",
})
local source = require("s16.blink").new()
assert(source:enabled())
source:get_completions({ bufnr = buf }, function(result)
  local by_name = {}
  for _, item in ipairs(result.items) do by_name[item.label] = item end
  assert(by_name.SVC_READ_FROM_TERMINAL.insertText == "SVC_READ_FROM_TERMINAL")
  assert(by_name.SVC_READ_FROM_TERMINAL.detail == "EQU 300")
  assert(by_name.SVC_RANDOM.detail == "EQU 42")
  assert(by_name.character.detail == "EQU ';'")
  assert(by_name.buffer.detail == "RW")
  assert(by_name.words.detail == "RW 10")
  assert(by_name.message.detail == 'DS "hello; world"')
  assert(by_name.count.detail == "DW 42")
  assert(by_name.loop.detail == "INCR R1")
  assert(by_name.done.detail == "RET")
  assert(not by_name.ignored and not by_name.SVC_IGNORED and not by_name.R1)
  assert(by_name.LDR.detail == "S16 instruction")
  assert(by_name.ADJSP.detail == "S16 instruction")
  assert(by_name.DATASEGMENT.detail == "S16 directive")
end)
vim.api.nvim_buf_set_lines(buf, 0, 1, false, { "SVC_RANDOM EQU 43" })
local items = completion.items(buf)
local found = false
for _, item in ipairs(items) do
  if item.label == "SVC_RANDOM" then assert(item.detail == "EQU 43"); found = true end
end
assert(found)
vim.fn.delete(file)
assert(#completion.items(buf) == #items - 1, "Missing external file should preserve buffer completions")
vim.bo.filetype = "lua"
assert(not source:enabled())
print("S16 completion checks passed")
vim.cmd("qa!")
