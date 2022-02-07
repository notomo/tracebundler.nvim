local util = require("genvdoc.util")
local plugin_name = vim.env.PLUGIN_NAME
local full_plugin_name = plugin_name .. ".nvim"

local example_path = ("./spec/lua/%s/example.lua"):format(plugin_name)
vim.o.runtimepath = vim.fn.getcwd() .. "," .. vim.o.runtimepath
dofile(example_path)
local example_lines = vim.tbl_map(function(line)
  return "-- " .. line
end, vim.api.nvim_buf_get_lines(0, 0, -1, false))
table.insert(example_lines, 1, "")
table.insert(example_lines, 1, "-- The following is the bundled chunk:")
table.insert(example_lines, 1, "")
local example_result = table.concat(example_lines, "\n")

require("genvdoc").generate(full_plugin_name, {
  chapters = {
    {
      name = function(group)
        return "Lua module: " .. group
      end,
      group = function(node)
        if not node.declaration then
          return nil
        end
        return node.declaration.module
      end,
    },
    {
      name = "TYPES",
      body = function(ctx)
        local opts_text
        do
          local descriptions = {
            path_filter = [[(function | nil): if return true, the chunk includes the file.
    default: `function(file_path) return true end`]],
          }
          local default = require("tracebundler.core.option").default
          local keys = vim.tbl_keys(default)
          local lines = util.each_keys_description(keys, descriptions, default)
          opts_text = table.concat(lines, "\n")
        end

        return util.sections(ctx, {
          { name = "options", tag_name = "opts", text = opts_text },
        })
      end,
    },
    {
      name = "EXAMPLES",
      body = function()
        local f = io.open(example_path, "r")
        local content = f:read("*a")
        f:close()
        return util.help_code_block(content .. example_result)
      end,
    },
  },
})

local gen_readme = function()
  local f = io.open(example_path, "r")
  local exmaple = f:read("*a")
  f:close()

  local content = ([[
# %s

bundles executed files as one lua chunk for debugging.

## Example

```lua
%s%s```]]):format(full_plugin_name, exmaple, example_result)

  local readme = io.open("README.md", "w")
  readme:write(content)
  readme:close()
end
gen_readme()
