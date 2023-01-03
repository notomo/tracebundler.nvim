# tracebundler.nvim

bundles executed files as one lua chunk for debugging.

## Example

```lua
local bundled = require("tracebundler").execute(function()
  return require("tracebundler.test.data.example").entry()
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
local lines = vim.split(bundled, "\n", { plain = true })
vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
vim.bo[bufnr].filetype = "lua"
vim.cmd.buffer(bufnr)
```

### Bundled chunk

```lua
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

_tracebundler_require["tracebundler.test.data.example.init"] = function(...)
  local M = {} -- TRACED

  function M.entry() -- TRACED
    local used = require("tracebundler.test.data.example.used").new() -- TRACED
    require("tracebundler.test.data.example.ignored").start() -- TRACED
    return used -- TRACED
  end -- TRACED

  return M -- TRACED
end
_tracebundler_require["tracebundler.test.data.example"] = _tracebundler_require["tracebundler.test.data.example.init"]

_tracebundler_require["tracebundler.test.data.example.used"] = function(...)
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
  return require("tracebundler.test.data.example").entry() -- TRACED
end
local _tracebundler = {
  execute = _tracebundler_entrypoint,
  modules = _tracebundler_require,
}
return _tracebundler.execute()
```