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

-- local _tracebundler_require = {}
-- 
-- local global_require = require
-- local require = function(name)
--   local f = _tracebundler_require[name]
--   if not f then
--     return global_require(name)
--   end
--   return f(name)
-- end
-- 
-- _tracebundler_require["tracebundler.example"] = function(...)
--     return require("tracebundler.testdata.example").entry()
-- end
-- 
-- _tracebundler_require["tracebundler.testdata.example.init"] = function(...)
--   local M = {}
-- 
--   function M.entry()
--     local used = require("tracebundler.testdata.example.used").new()
--     require("tracebundler.testdata.example.ignored").start()
--     return used
--   end
-- 
--   return M
-- end
-- 
-- _tracebundler_require["tracebundler.testdata.example"] = _tracebundler_require["tracebundler.testdata.example.init"]
-- 
-- _tracebundler_require["tracebundler.testdata.example.used"] = function(...)
--   local M = {}
-- 
--   function M.new()
--     return {}
--   end
-- 
--   return M
-- end
-- 
-- return _tracebundler_require["tracebundler.example"]("tracebundler.example")
```