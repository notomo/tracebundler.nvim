local util = require("genvdoc.util")
local plugin_name = vim.env.PLUGIN_NAME
local full_plugin_name = plugin_name .. ".nvim"

pcall(require, "tracebundler") -- to load if exists
vim.opt.runtimepath:prepend(vim.fn.getcwd())

local example_path = ("./spec/lua/%s/example.lua"):format(plugin_name)
dofile(example_path)
local example_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
local example_f, err = loadstring(table.concat(example_lines, "\n"))
if err then
  error(err)
end
assert(example_f)
example_f()
local example_result = table.concat(example_lines, "\n")

require("genvdoc").generate(full_plugin_name, {
  source = { patterns = { ("lua/%s/init.lua"):format(plugin_name) } },
  chapters = {
    {
      name = function(group)
        return "Lua module: " .. group
      end,
      group = function(node)
        if node.declaration == nil or node.declaration.type ~= "function" then
          return nil
        end
        return node.declaration.module
      end,
    },
    {
      name = "STRUCTURE",
      group = function(node)
        if node.declaration == nil or node.declaration.type ~= "class" then
          return nil
        end
        return "STRUCTURE"
      end,
    },
    {
      name = "LIMITATION",
      body = function(ctx)
        local chunk_text = [[
- Bundled functions are not called if `require()` is called by Ex command.
- Bundled `require()` is not influenced by `package.loaded[key] = nil`.]]

        return util.sections(ctx, {
          { name = "chunk limitation", tag_name = "chunk-limitation", text = chunk_text },
        })
      end,
    },
    {
      name = "EXAMPLES",
      body = function()
        local content = util.read_all(example_path)
        return ([[
%s

The following is the bundled chunk.

%s]]):format(
          util.help_code_block(vim.fn.trim(content, "\n", 2), { language = "lua" }),
          util.help_code_block(example_result, { language = "lua" })
        )
      end,
    },
  },
})

local gen_readme = function()
  local exmaple = util.read_all(example_path)

  local content = ([[
# %s

bundles executed files as one lua chunk for debugging.

## Example

```lua
%s```

### Bundled chunk

```lua
%s
```]]):format(full_plugin_name, exmaple, example_result)

  util.write("README.md", content)
end
gen_readme()
