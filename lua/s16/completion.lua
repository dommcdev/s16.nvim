local M = {}
local options = { assembler = "s16assembler" }

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
    local name, instruction, rest = line:match("^%s*([%a][%w_]*)%s+(%a+)%s+(.+)$")
    if name and instruction:upper() == "EQU" then
      local value = rest:match("^('\\'')") or rest:match("^('[^']')") or rest:match("^([^%s;]+)")
      if value then definitions[name] = { value = value, source = source } end
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
      kind = vim.lsp.protocol.CompletionItemKind.Constant,
      labelDetails = { description = "EQU " .. definition.value },
      detail = "EQU " .. definition.value,
      documentation = {
        kind = "markdown",
        value = "```s16\n" .. name .. " EQU " .. definition.value .. "\n```\n\nFrom " .. definition.source .. ".",
      },
    })
  end
  table.sort(items, function(a, b) return a.label < b.label end)
  return items
end

return M
