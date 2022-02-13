local M = {}
M.__index = M

function M.bundle(traces, bundle_opts)
  local bundled = [[
local _tracebundler_require = {}
local _tracebundler_loaded = {}

local global_require = require
local require = function(name)
  local loaded = _tracebundler_loaded[name]
  if loaded then
    return loaded
  end
  local f = _tracebundler_require[name]
  if not f then
    return global_require(name)
  end
  local result = f(name)
  _tracebundler_loaded[name] = result or package.loaded[name] or true
  return _tracebundler_loaded[name]
end

local _tracebundler_file = {}

local global_dofile = dofile
local dofile = function(name)
  if not name then
    return global_dofile()
  end
  local f = _tracebundler_file[name]
  if not f then
    return global_dofile()
  end
  return f()
end

local global_loadfile = loadfile
local loadfile = function(name)
  if not name then
    return global_loadfile()
  end
  local f = _tracebundler_file[name]
  if not f then
    return global_loadfile()
  end
  return f
end
]]

  local entrypoint, others = traces:all()
  for _, trace in ipairs(others) do
    local one = M._bundle_one(trace, bundle_opts)
    if one then
      bundled = bundled .. one
    end
  end

  bundled = ([=[
%s
local _tracebundler_entrypoint = function()
%send
return _tracebundler_entrypoint()]=]):format(bundled, M._indent(entrypoint:ranged_lines(), 0))

  return bundled
end

function M._bundle_one(trace, bundle_opts)
  local lines = trace:lines()
  if not lines then
    return nil
  end

  local module_path = trace:module()
  local bundled = ([=[

_tracebundler_require["%s"] = function(...)
%send]=]):format(module_path, M._indent(lines, 2))

  local alias_module = trace:alias_module()
  if alias_module then
    bundled = ([=[
%s
_tracebundler_require["%s"] = _tracebundler_require["%s"]]=]):format(bundled, alias_module, module_path)
  end

  if bundle_opts.enabled_file_loader then
    bundled = ([=[
%s
_tracebundler_file["%s"] = _tracebundler_require["%s"]]=]):format(bundled, trace.path, module_path)
  end

  return bundled .. "\n"
end

function M._indent(lines, depth)
  local indent = (" "):rep(depth)
  local new_lines = {}
  for _, line in ipairs(lines) do
    if line == "" then
      table.insert(new_lines, line)
    else
      table.insert(new_lines, ("%s%s"):format(indent, line))
    end
  end
  local str = table.concat(new_lines, "\n")
  if vim.endswith(str, "\n") then
    return str
  end
  return str .. "\n"
end

return M
