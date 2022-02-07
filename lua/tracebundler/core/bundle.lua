local M = {}
M.__index = M

function M.bundle(raw_traces)
  -- TODO: loadfile, dofile
  -- TODO: require once

  local bundled = [[
local _tracebundler_require = {}

local global_require = require
local require = function(name)
  local f = _tracebundler_require[name]
  if not f then
    return global_require(name)
  end
  return f(name)
end
]]

  for _, trace in ipairs(raw_traces) do
    local lines = trace:lines()
    if not lines then
      goto continue
    end
    local module = trace:module()
    bundled = ([=[
%s
_tracebundler_require["%s"] = function(...)
%send
]=]):format(bundled, module, M.indent(lines, 2))

    local alias_module = trace:alias_module()
    if alias_module then
      bundled = ([=[
%s
_tracebundler_require["%s"] = _tracebundler_require["%s"]
]=]):format(bundled, alias_module, module)
    end

    ::continue::
  end

  local entrypoint_trace = raw_traces[1]
  if entrypoint_trace then
    local module_name = entrypoint_trace:module()
    bundled = ([=[
%s
return _tracebundler_require["%s"]("%s")]=]):format(bundled, module_name, module_name)
  end

  return bundled
end

function M.indent(lines, depth)
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
