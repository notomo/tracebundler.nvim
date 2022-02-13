# tracebundler.nvim

bundles executed files as one lua chunk for debugging.

## Example

```lua
local tracebundler = require("tracebundler")
local bundled = tracebundler.execute(function()
  return require("tracebundler.testdata.example").entry()
end, {
  path_filter = function(path)
    local matched = path:match("tracebundler")
    return matched and not path:match("ignored")
  end,
})

local bufnr = vim.api.nvim_create_buf(false, true)
local lines = vim.split(bundled, "\n", true)
vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
vim.bo[bufnr].filetype = "lua"
vim.cmd([[buffer ]] .. bufnr)

-- The following is the bundled chunk:

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

_tracebundler_require["tracebundler.example"] = function(...)
    return require("tracebundler.testdata.example").entry()
end

_tracebundler_require["tracebundler.testdata.example.init"] = function(...)
  local M = {}

  function M.entry()
    local used = require("tracebundler.testdata.example.used").new()
    require("tracebundler.testdata.example.ignored").start()
    return used
  end

  return M
end
_tracebundler_require["tracebundler.testdata.example"] = _tracebundler_require["tracebundler.testdata.example.init"]

_tracebundler_require["tracebundler.testdata.example.used"] = function(...)
  local M = {}

  function M.new()
    return {}
  end

  return M
end

return _tracebundler_require["tracebundler.example"]("tracebundler.example")
```