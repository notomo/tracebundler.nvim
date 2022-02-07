local M = {}
M.__index = M

function M.new()
  local tbl = { _data = {}, _indexes = {}, _index = 0 }
  return setmetatable(tbl, M)
end

function M.iter(self)
  local items = {}
  for k, v in pairs(self._data) do
    table.insert(items, { value = v, key = k, index = self._indexes[k] })
  end
  table.sort(items, function(a, b)
    return a.index < b.index
  end)

  local i = 1
  return function()
    while true do
      local item = items[i]
      if not item then
        return
      end
      i = i + 1
      return item.key, item.value
    end
  end
end

function M.__index(self, k)
  local method = M[k]
  if method then
    return method
  end
  return rawget(self._data, k)
end

function M.__newindex(self, k, v)
  if not self._indexes[k] then
    self._index = self._index + 1
    self._indexes[k] = self._index
  end
  self._data[k] = v
end

return M
