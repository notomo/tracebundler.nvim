local M = {}
M.__index = M

function M.new(name, first_row, last_row)
  local tbl = {
    _name = name or "",
    _first_row = first_row,
    _last_row = last_row,
  }
  return setmetatable(tbl, M)
end

function M.key(self)
  return ("%d_%d_%s"):format(self._first_row, self._last_row, self._name)
end

function M.ranged(self, lines)
  return vim.list_slice(lines, self._first_row + 1, self._last_row - 1)
end

return M
