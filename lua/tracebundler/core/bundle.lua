local M = {}
M.__index = M

function M.bundle(traces, bundle_opts)
  local bundled = [[
local _tracebundler_require = {}
local _tracebundler_loaded = {}

local global_require = require
local require = function(name)
  if not name then
    return global_require(name)
  end
  local loaded = _tracebundler_loaded[name]
  if loaded then
    return loaded
  end
  local f = _tracebundler_require[name:gsub("/", "%.")]
  if not f then
    return global_require(name)
  end
  local result = f(name)
  _tracebundler_loaded[name] = result or package.loaded[name] or true
  return _tracebundler_loaded[name]
end

local _tracebundler_original_vim = vim
local vim = setmetatable({}, {
  __index = function(_, k)
    local v = rawget(require("vim.shared"), k)
    if v then
      return v
    end
    return _tracebundler_original_vim[k]
  end,
})
]]

  if bundle_opts.enabled_file_loader then
    bundled = bundled
      .. [[

local _tracebundler_file = {}

local global_dofile = dofile
local dofile = function(path)
  if not path then
    return global_dofile()
  end
  local f = _tracebundler_file[path]
  if not f then
    return global_dofile()
  end
  return f()
end

local global_loadfile = loadfile
local loadfile = function(path)
  if not path then
    return global_loadfile()
  end
  local f = _tracebundler_file[path]
  if not f then
    return global_loadfile()
  end
  return f
end
]]
  end

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
return _tracebundler_entrypoint()]=]):format(
    bundled,
    M._indent(entrypoint:ranged_lines(bundle_opts.traced_marker), 0)
  )

  return bundled
end

function M._bundle_one(trace, bundle_opts)
  local lines = trace:lines(bundle_opts.traced_marker)
  if not lines then
    return nil
  end

  local bundled
  local traced_module = require("tracebundler.core.module").new(trace.path)
  if traced_module then
    bundled = M._bundle_require(traced_module, lines, bundle_opts)
  else
    bundled = M._bundle_file(trace.path, lines, bundle_opts)
  end

  return bundled .. "\n"
end

function M._bundle_require(traced_module, lines, bundle_opts)
  local bundled = ([=[

_tracebundler_require["%s"] = function(...)
%send]=]):format(traced_module.name, M._indent(lines, 2))

  if traced_module.alias then
    bundled = ([=[
%s
_tracebundler_require["%s"] = _tracebundler_require["%s"]]=]):format(
      bundled,
      traced_module.alias,
      traced_module.name
    )
  end

  if bundle_opts.enabled_file_loader then
    bundled = ([=[
%s
_tracebundler_file["%s"] = _tracebundler_require["%s"]]=]):format(bundled, traced_module.path, traced_module.name)
  end

  return bundled
end

function M._bundle_file(path, lines, bundle_opts)
  if not bundle_opts.enabled_file_loader then
    return ""
  end
  return ([=[

_tracebundler_file["%s"] = function(...)
%send]=]):format(path, M._indent(lines, 2))
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
