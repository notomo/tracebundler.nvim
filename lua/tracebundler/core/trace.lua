local Calls = require("tracebundler.core.calls")

local M = {}
M.__index = M

function M.new(path, calls)
  vim.validate({ path = { path, "string" } })
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

function M.lines(self)
  local f = io.open(self.path, "r")
  if not f then
    return nil
  end
  local content = f:read("*a")
  f:close()
  return vim.split(content, "\n", true)
end

function M.ranged_lines(self)
  local lines = self:lines()
  return self._calls:ranged(lines)
end

function M.module(self)
  local path = self.path:gsub("\\", "/")
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
