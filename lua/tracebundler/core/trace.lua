local Calls = require("tracebundler.core.calls")

local M = {}
M.__index = M

function M.new(path, is_entrypoint, calls)
  local tbl = {
    _path = path,
    _is_entrypoint = is_entrypoint,
    _calls = calls or Calls.new(),
  }
  return setmetatable(tbl, M)
end

function M.add(self, name, current_row, first_row, last_row)
  local calls = self._calls:add(name, current_row, first_row, last_row)
  return M.new(self._path, self._is_entrypoint, calls)
end

function M.lines(self)
  local f = io.open(self._path, "r")
  if not f then
    return nil
  end
  local content = f:read("*a")
  f:close()
  local lines = vim.split(content, "\n", true)
  if self._is_entrypoint then
    -- HACK
    return self._calls:ranged(lines)
  end
  return lines
end

function M.module(self)
  local path = self._path:gsub("\\", "/")
  local relative = vim.split(path, "/lua/")[2]
  if not relative then
    return ""
  end
  relative = relative:gsub("%.lua$", "")
  relative = relative:gsub("/", ".")
  return relative
end

local suffix = ".init"
function M.alias_module(self)
  local module = self:module()
  if not vim.endswith(module, suffix) then
    return nil
  end
  local alias = module:sub(1, #module - #suffix)
  return alias
end

return M
