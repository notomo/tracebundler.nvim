local Trace = require("tracebundler.core.trace")
local vim = vim

local M = {}
M.__index = M

--- @param path_filter function
--- @param entrypoint table
--- @param raw_traces table?
function M.new(path_filter, entrypoint, raw_traces)
  local tbl = {
    _traces = raw_traces or require("tracebundler.vendor.misclib.collection.ordered_dict").new(),
    _entrypoint = entrypoint,
    _path_filter = path_filter,
  }
  return setmetatable(tbl, M)
end

function M.add(self, info)
  if info.source == "" or info.what == "C" then
    return self
  end

  local path = M._path(info)
  if path == self._entrypoint.path then
    local entrypoint = self._entrypoint:add(info)
    return M.new(self._path_filter, entrypoint, self._traces)
  end

  if not self._path_filter(path) then
    return self
  end

  local trace = self._traces[path] or Trace.new(path)
  local traces = self._traces:merge({
    [path] = trace:add(info),
  })
  return M.new(self._path_filter, self._entrypoint, traces)
end

function M.all(self)
  local raw_traces = self._traces:values()
  return self._entrypoint, { unpack(raw_traces, 2) } -- 2 to exclude own trace
end

--- @param f function
--- @param trace_opts table
function M.execute(f, trace_opts)
  local entrypoint_path = M._path(debug.getinfo(f))
  local traces = M.new(trace_opts.path_filter, Trace.new(entrypoint_path))

  local original_hook = debug.gethook()
  debug.sethook(function()
    local info = debug.getinfo(2)
    traces = traces:add(info)
    trace_opts.callback(traces)
  end, "l")

  local ok, err = pcall(f)
  debug.sethook(original_hook)
  if not ok then
    return traces, err
  end
  return traces, nil
end

function M._path(info)
  local path = info.source:sub(2)
  if vim.startswith(path, "vim/") and vim.endswith(path, ".lua") then
    return vim.env.VIMRUNTIME .. "/lua/" .. path
  end
  return path
end

return M
