local M = {}
M.__index = M

function M.new(name, first_row, last_row, rows)
  local tbl = {
    _name = name,
    _first_row = first_row,
    _last_row = last_row,
    _rows = rows or {},
  }
  return setmetatable(tbl, M)
end

function M.add(self, row)
  local rows = vim.tbl_extend("force", self._rows, { [row] = true })
  return M.new(self._name, self._first_row, self._last_row, rows)
end

function M.key(name, first_row, last_row)
  return ("%d_%d_%s"):format(first_row, last_row, name)
end

function M.ranged(self, lines)
  return vim.list_slice(lines, self._first_row + 1, self._last_row - 1)
end

return M
