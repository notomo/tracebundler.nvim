# tracebundler.nvim

bundles executed files as one lua chunk for debugging.

## Example

```lua
local tracebundler = require("tracebundler")
local bundled = tracebundler.execute(function()
  return require("tracebundler.testdata.example").entry()
end, {
  trace = {
    path_filter = function(path)
      local matched = path:match("tracebundler")
      return matched and not path:match("ignored")
    end,
  },
  bundle = {
    enalbed_file_loader = false,
    traced_marker = " TRACED",
  },
})

local bufnr = vim.api.nvim_create_buf(false, true)
local lines = vim.split(bundled, "\n", true)
vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
vim.bo[bufnr].filetype = "lua"
vim.cmd([[buffer ]] .. bufnr)
```

### Bundled chunk

```lua
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

_tracebundler_require["tracebundler.testdata.example.init"] = function(...)
  local M = {} -- TRACED

  function M.entry() -- TRACED
    local used = require("tracebundler.testdata.example.used").new() -- TRACED
    require("tracebundler.testdata.example.ignored").start() -- TRACED
    return used -- TRACED
  end -- TRACED

  return M -- TRACED
end
_tracebundler_require["tracebundler.testdata.example"] = _tracebundler_require["tracebundler.testdata.example.init"]

_tracebundler_require["tracebundler.testdata.example.used"] = function(...)
  local M = {} -- TRACED

  function M.new() -- TRACED
    if false then -- TRACED
      return {}
    end
    return {} -- TRACED
  end -- TRACED

  function M.unused() -- TRACED
    return {}
  end -- TRACED

  return M -- TRACED
end

local _tracebundler_entrypoint = function()
  return require("tracebundler.testdata.example").entry() -- TRACED
end
return _tracebundler_entrypoint()
```