local Call = require("tracebundler.core.call")

local M = {}
M.__index = M

function M.new(raw_calls)
  local tbl = {
    _calls = raw_calls or {},
  }
  return setmetatable(tbl, M)
end

function M.add(self, name, current_row, first_row, last_row)
  local new_call = Call.new(name, first_row, last_row)
  local key = new_call:key()
  local call = self._calls[key] or new_call
  local calls = vim.tbl_extend("force", self._calls, { [key] = call:add(current_row) })
  return M.new(calls)
end

function M.ranged(self, lines)
  vim.validate({ lines = { lines, "table" } })
  local new_lines = {}
  for _, call in pairs(self._calls) do
    vim.list_extend(new_lines, call:ranged(lines))
  end
  return new_lines
end

return M
