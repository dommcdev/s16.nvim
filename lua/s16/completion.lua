local M = {}
local options = { assembler = "s16assembler" }
local instructions = {}
for word in ([[
  NOOP JMP JMPN JMPNN JMPZ JMPNZ JMPP JMPNP JMPT JMPF CALL RET SVC DEBUG
  ADDR SUBR INCR DECR ZEROR LSRR ASRR SLR CMPR CMPUR ANDR ORR XORR NOTR
  NEGR MULR DIVR MODR LDR LDAR STR COPYR PUSHR POPR SWAPR PUSHFB POPFB SETFB ADJSP
]]):gmatch("%S+") do
  instructions[word] = true
end
local directives = { CODESEGMENT = true, DATASEGMENT = true, END = true, EQU = true, RW = true, DW = true, DS = true }

local function reserved(name)
  name = name:upper()
  return instructions[name] or directives[name] or name == "FB" or name == "TRUE" or name == "FALSE"
    or name:match("^R[0-9]$") or name:match("^R1[0-5]$")
end

function M.setup(opts)
  options = opts
end

local function definition_file()
  if options.definitions then return vim.fn.expand(options.definitions) end
  local executable = vim.fn.exepath(vim.fn.expand(options.assembler))
  if executable == "" then return end
  local directory = vim.fs.dirname(executable)
  for _, parent in ipairs({ directory, vim.fs.dirname(directory) }) do
    local path = parent .. "/svcdefinitions.s16"
    if vim.fn.filereadable(path) == 1 then return path end
  end
end

-- Read EQU operands without treating semicolons inside character literals as comments.
local function collect(lines, source, definitions)
  for _, line in ipairs(lines) do
    local name, instruction, rest = line:match("^%s*([%a][%w_]*)%s+([%a][%w_]*)(.*)$")
    if name and not reserved(name) then
      instruction = instruction:upper()
      rest = vim.trim(rest)
      local detail, kind
      if instruction == "EQU" then
        local value = rest:match("^('\\'')") or rest:match("^('[^']')") or rest:match("^([^%s;]+)")
        if value then detail, kind = "EQU " .. value, vim.lsp.protocol.CompletionItemKind.Constant end
      elseif instruction == "RW" or instruction == "DW" or instruction == "DS" or instructions[instruction] then
        detail = instruction .. (rest ~= "" and " " .. rest or "")
        kind = instructions[instruction] and vim.lsp.protocol.CompletionItemKind.Reference
          or vim.lsp.protocol.CompletionItemKind.Variable
      end
      if detail then definitions[name] = { detail = detail, kind = kind, source = source } end
    end
  end
end

function M.items(buf)
  local definitions = {}
  local path = definition_file()
  if path and vim.fn.filereadable(path) == 1 then
    collect(vim.fn.readfile(path), "svcdefinitions.s16", definitions)
  end
  collect(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "current buffer", definitions)
  local items = {}
  for name, definition in pairs(definitions) do
    table.insert(items, {
      label = name,
      insertText = name,
      kind = definition.kind,
      labelDetails = { description = definition.detail },
      detail = definition.detail,
      documentation = {
        kind = "markdown",
        value = "```s16\n" .. name .. " " .. definition.detail .. "\n```\n\nFrom " .. definition.source .. ".",
      },
    })
  end
  for _, category in ipairs({ { instructions, "S16 instruction" }, { directives, "S16 directive" } }) do
    for name in pairs(category[1]) do
      table.insert(items, {
        label = name,
        insertText = name,
        kind = vim.lsp.protocol.CompletionItemKind.Keyword,
        detail = category[2],
        labelDetails = { description = category[2] },
      })
    end
  end
  table.sort(items, function(a, b) return a.label < b.label end)
  return items
end

return M
