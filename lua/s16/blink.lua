local source = {}

function source.new()
  return setmetatable({}, { __index = source })
end

function source:enabled()
  return vim.bo.filetype == "s16"
end

function source:get_completions(ctx, callback)
  callback({
    items = require("s16.completion").items(ctx.bufnr),
    is_incomplete_forward = false,
    is_incomplete_backward = false,
  })
end

return source
