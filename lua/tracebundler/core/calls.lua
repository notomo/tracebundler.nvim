local Call = require("tracebundler.core.call")
local vim = vim

local M = {}
M.__index = M

function M.new(raw_calls, rows)
  local tbl = {
    _calls = raw_calls or {},
    _rows = rows or {},
  }
  return setmetatable(tbl, M)
end

function M.add(self, name, current_row, first_row, last_row)
  local new_call = Call.new(name, first_row, last_row)
  local key = new_call:key()
  local call = self._calls[key] or new_call
  local calls = vim.tbl_extend("force", self._calls, { [key] = call })
  local rows = vim.tbl_extend("force", self._rows, { [current_row] = true })
  return M.new(calls, rows)
end

function M.ranged(self, lines)
  vim.validate({ lines = { lines, "table" } })
  local new_lines = {}
  for _, call in pairs(self._calls) do
    vim.list_extend(new_lines, call:ranged(lines))
  end
  return new_lines
end

function M.is_traced(self, row)
  return self._rows[row] ~= nil
end

return M
