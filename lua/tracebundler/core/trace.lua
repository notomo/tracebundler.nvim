local Calls = require("tracebundler.core.calls")

local M = {}
M.__index = M

--- @param path string
function M.new(path, calls)
  local tbl = {
    path = path,
    _calls = calls or Calls.new(),
  }
  return setmetatable(tbl, M)
end

function M.add(self, info)
  local calls = self._calls:add(info.name, info.currentline, info.linedefined, info.lastlinedefined)
  return M.new(self.path, calls)
end

--- @param traced_marker string
function M.lines(self, traced_marker)
  local f = io.open(self.path, "r")
  if not f then
    return nil
  end
  local content = f:read("*a")
  f:close()
  local lines = vim.split(content, "\n", { plain = true })
  if traced_marker == "" then
    return lines
  end

  local i = 0
  return vim
    .iter(lines)
    :map(function(line)
      i = i + 1
      if not self._calls:is_traced(i) then
        return line
      end
      return line .. " --" .. traced_marker
    end)
    :totable()
end

function M.ranged_lines(self, traced_marker)
  local lines = self:lines(traced_marker)
  return self._calls:ranged(lines)
end

return M
