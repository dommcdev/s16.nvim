vim.opt.rtp:prepend(vim.fn.getcwd())
vim.cmd("filetype plugin on")
vim.cmd("syntax on")
vim.cmd("runtime plugin/s16.lua")
local s16 = require("s16")
s16.setup({ assembler = assert(vim.env.S16_ASSEMBLER, "Set S16_ASSEMBLER") })
local ns = vim.api.nvim_create_namespace("s16")
local buf = vim.api.nvim_get_current_buf()
vim.api.nvim_buf_set_name(buf, "test.s16")
local function check(lines, expected)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.diagnostic.reset(ns, buf)
  s16.check(buf)
  if expected then
    assert(vim.wait(5000, function() return #vim.diagnostic.get(buf, { namespace = ns }) > 0 end), "No diagnostic")
    local found = false
    for _, d in ipairs(vim.diagnostic.get(buf, { namespace = ns })) do
      if d.message:find(expected, 1, true) then found = true end
    end
    assert(found, vim.inspect(vim.diagnostic.get(buf, { namespace = ns })))
  else
    -- Wait for publication even when the result is empty.
    local original, done = vim.diagnostic.set, false
    vim.diagnostic.set = function(...)
      done = true
      return original(...)
    end
    assert(vim.wait(5000, function() return done end), "Check did not finish")
    vim.diagnostic.set = original
    assert(#vim.diagnostic.get(buf, { namespace = ns }) == 0, vim.inspect(vim.diagnostic.get(buf)))
  end
end
check({ "CODESEGMENT", "LDR R1,#42", "SVC #100", "DATASEGMENT", 'msg DS "hi; ""there"""', "END" })
check({ "CODESEGMENT", "ADDR R1 R2", "DATASEGMENT", "END" }, "Missing ','")
assert(vim.diagnostic.get(buf, { namespace = ns })[1].lnum == 1)
check({ "CODESEGMENT", "JMP missing", "DATASEGMENT", "END" }, "Undefined label")
check({ "CODESEGMENT", "LDR R16,#1", "DATASEGMENT", "END" }, "Missing Rn")
check({ "CODESEGMENT", "NOOP", "END" }, "DATASEGMENT missing")
check({ "; empty" }, "CODESEGMENT missing")
check({ "CODESEGMENT", "NOOP", "DATASEGMENT", "END" })
vim.bo.filetype = "s16"
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
  "LDR R15,#-0xAB ; comment", 'msg DS "hello; ""world"""', "ch DW '\\''",
})
local function syntax(line, col, name)
  assert(vim.fn.synIDattr(vim.fn.synID(line, col, 1), "name") == name,
    string.format("Expected %s at %d:%d, got %s", name, line, col,
      vim.fn.synIDattr(vim.fn.synID(line, col, 1), "name")))
end
syntax(1, 1, "s16Instruction")
syntax(1, 5, "s16Register")
syntax(1, 10, "s16Number")
syntax(1, 16, "s16Comment")
syntax(2, 14, "s16String")
syntax(3, 7, "s16Character")
assert(vim.bo.commentstring == "; %s")
print("S16 diagnostics and syntax checks passed")
vim.cmd("qa!")
