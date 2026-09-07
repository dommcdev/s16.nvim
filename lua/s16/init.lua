local M = {}
local ns = vim.api.nvim_create_namespace("s16")
local options = { assembler = "s16assembler", debounce_ms = 500, timeout_ms = 3000 }
local generations = {}

function M.setup(opts)
  options = vim.tbl_extend("force", options, opts or {})
end

local function diagnostic(lines, line, message)
  local row = math.max(1, math.min(line, #lines))
  local text = lines[row] or ""
  return {
    lnum = row - 1,
    col = #(text:match("^%s*") or ""),
    end_lnum = row - 1,
    end_col = #text,
    severity = vim.diagnostic.severity.ERROR,
    source = "s16assembler",
    message = message,
  }
end

-- The listing has a fixed-width 20-character object-code field, then
-- a four-character source line number. Error rows follow their source row.
function M.parse_listing(listing, lines)
  local result, line = {}, 1
  for row in listing:gmatch("[^\n]+") do
    local number = tonumber(row:sub(21, 24))
    if number then line = number end
    local message = row:match("^%s*%^%^%^%^%s+(.+)")
    if message then table.insert(result, diagnostic(lines, line, message)) end
  end
  return result
end

function M.check(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf) then return end
  generations[buf] = (generations[buf] or 0) + 1
  local generation = generations[buf]
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local function publish(items)
    if vim.api.nvim_buf_is_valid(buf) and generations[buf] == generation
        and vim.api.nvim_buf_get_changedtick(buf) == tick then
      vim.diagnostic.set(ns, buf, items)
    end
  end

  -- Pass one of the teaching assembler crashes on missing segment headers.
  -- Check these first; also avoid its fixed-size source-line truncation.
  local structural, segments = {}, {}
  local first
  for i, line in ipairs(lines) do
    local word = line:match("^%s*([%a][%w_]*)")
    if word then
      word = word:upper()
      first = first or { word, i }
      if word == "CODESEGMENT" or word == "DATASEGMENT" or word == "END" then
        segments[word] = segments[word] or i
      end
    end
    if #line > 510 then
      table.insert(structural, diagnostic(lines, i, "Source line is too long (maximum 510 bytes)"))
    end
  end
  if not first or first[1] ~= "CODESEGMENT" then
    table.insert(structural, diagnostic(lines, first and first[2] or 1, "CODESEGMENT missing at start of program"))
  end
  if not segments.DATASEGMENT or segments.DATASEGMENT < (segments.CODESEGMENT or 1) then
    table.insert(structural, diagnostic(lines, #lines, "DATASEGMENT missing after CODESEGMENT"))
  end
  if not segments.END or segments.END < (segments.DATASEGMENT or 1) then
    table.insert(structural, diagnostic(lines, #lines, "END missing after DATASEGMENT"))
  end
  if #structural > 0 then publish(structural); return end

  local executable = vim.fn.exepath(vim.fn.expand(options.assembler))
  if executable == "" then
    publish({ diagnostic(lines, 1, "Assembler not found: set require('s16').setup({ assembler = '/path/to/s16assembler' })") })
    return
  end
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir .. "/bin", "p")
  vim.fn.writefile(lines, dir .. "/input.s16")
  local ok, err = pcall(vim.system, { executable, "input" }, {
    cwd = dir, text = true, timeout = options.timeout_ms,
  }, function(result)
    vim.schedule(function()
      local listing = dir .. "/bin/input.listing"
      local content = vim.fn.filereadable(listing) == 1 and table.concat(vim.fn.readfile(listing), "\n") or ""
      vim.fn.delete(dir, "rf")
      local items = M.parse_listing(content, lines)
      for message, number in (result.stdout or ""):gmatch("([^\n\7]+) near source line #%s*(%d+)") do
        table.insert(items, diagnostic(lines, tonumber(number), message))
      end
      if result.code ~= 0 and #items == 0 then
        table.insert(items, diagnostic(lines, 1, "Assembler failed or timed out (exit " .. result.code .. ")"))
      end
      publish(items)
    end)
  end)
  if not ok then
    vim.fn.delete(dir, "rf")
    publish({ diagnostic(lines, 1, tostring(err)) })
  end
end

function M.attach(buf)
  if vim.b[buf].s16_attached then return end
  vim.b[buf].s16_attached = true
  vim.diagnostic.config({ underline = true, signs = true }, ns)
  vim.api.nvim_buf_create_user_command(buf, "S16Check", function() M.check(buf) end, {})
  local group = vim.api.nvim_create_augroup("s16_" .. buf, { clear = true })
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufWritePost" }, {
    group = group, buffer = buf,
    callback = function()
      generations[buf] = (generations[buf] or 0) + 1
      local generation = generations[buf]
      vim.diagnostic.reset(ns, buf)
      vim.defer_fn(function()
        if generations[buf] == generation then M.check(buf) end
      end, options.debounce_ms)
    end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group, buffer = buf, once = true,
    callback = function()
      generations[buf] = nil
      vim.api.nvim_del_augroup_by_id(group)
    end,
  })
  vim.schedule(function() M.check(buf) end)
end

return M
