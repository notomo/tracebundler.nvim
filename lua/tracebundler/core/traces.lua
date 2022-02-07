local Trace = require("tracebundler.core.trace")

local M = {}
M.__index = M

function M.new(path_filter)
  vim.validate({ path_filter = { path_filter, "function" } })
  local tbl = {
    _traces = require("tracebundler.lib.ordered_dict").new(),
    _path_filter = path_filter,
  }
  return setmetatable(tbl, M)
end

function M.add(self, info, is_entrypoint)
  if info.source == "" or info.what == "C" then
    return
  end

  local path = info.source:sub(2)
  if not self._path_filter(path) then
    return
  end

  local trace = self._traces[path] or Trace.new(path, is_entrypoint)
  self._traces[path] = trace:add(info.name, info.currentline, info.linedefined, info.lastlinedefined)
end

function M.all(self)
  local raw_traces = {}
  for _, trace in self._traces:iter() do
    table.insert(raw_traces, trace)
  end
  return { unpack(raw_traces, 2) } -- 2 to exclude tracer's trace
end

return M
