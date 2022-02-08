local Trace = require("tracebundler.core.trace")

local M = {}
M.__index = M

function M.new(path_filter, raw_traces)
  vim.validate({ path_filter = { path_filter, "function" }, raw_traces = { raw_traces, "table", true } })
  local tbl = {
    _traces = raw_traces or require("tracebundler.lib.ordered_dict").new(),
    _path_filter = path_filter,
  }
  return setmetatable(tbl, M)
end

function M.add(self, info, is_entrypoint)
  if info.source == "" or info.what == "C" then
    return self
  end

  local path = info.source:sub(2)
  if not self._path_filter(path) then
    return self
  end

  local trace = self._traces[path] or Trace.new(path, is_entrypoint)
  local traces = self._traces:merge({
    [path] = trace:add(info.name, info.currentline, info.linedefined, info.lastlinedefined),
  })
  return M.new(self._path_filter, traces)
end

function M.all(self)
  local raw_traces = self._traces:values()
  return { unpack(raw_traces, 2) } -- 2 to exclude own trace
end

function M.execute(f, opts)
  vim.validate({ f = { f, "function" }, opts = { opts, "table" } })

  local traces = M.new(opts.path_filter)
  local original_hook = debug.gethook()
  local entrypoint = debug.getinfo(f).source
  debug.sethook(function()
    local info = debug.getinfo(2)
    traces = traces:add(info, entrypoint == info.source)
  end, "l")

  local ok, err = pcall(f)
  debug.sethook(original_hook)
  if not ok then
    return traces, err
  end
  return traces, nil
end

return M
