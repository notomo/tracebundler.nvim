local util = require("genvdoc.util")
local plugin_name = vim.env.PLUGIN_NAME
local full_plugin_name = plugin_name .. ".nvim"

local example_path = ("./spec/lua/%s/example.lua"):format(plugin_name)
vim.o.runtimepath = vim.fn.getcwd() .. "," .. vim.o.runtimepath
dofile(example_path)
local example_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
local example_f, err = loadstring(table.concat(example_lines, "\n"))
if err then
  error(err)
end
example_f()
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
            trace = [[(table): |tracebundler.nvim-trace-opts|]],
            bundle = [[(table): |tracebundler.nvim-bundle-opts|]],
          }
          local default = require("tracebundler.core.option").default
          local keys = vim.tbl_keys(default)
          local lines = util.each_keys_description(keys, descriptions, default)
          opts_text = table.concat(lines, "\n")
        end

        local trace_opts_text
        do
          local descriptions = {
            path_filter = [[(function): if return true, the chunk includes the file.
    default: `function(file_path) return true end`]],
            callback = [[(function): called after every trace.
    default: `function(traces) end`]],
          }
          local default = require("tracebundler.core.option").default.trace
          local keys = vim.tbl_keys(default)
          local lines = util.each_keys_description(keys, descriptions, default)
          trace_opts_text = table.concat(lines, "\n")
        end

        local bundle_opts_text
        do
          local descriptions = {
            enabled_file_loader = [[(boolean): if true, chunk supports dofile, loadfile.
    default: %s]],
            traced_marker = [[(string): if not empty, adds to traced line as comment.
    default: %s]],
          }
          local default = require("tracebundler.core.option").default.bundle
          local keys = vim.tbl_keys(default)
          local lines = util.each_keys_description(keys, descriptions, default)
          bundle_opts_text = table.concat(lines, "\n")
        end

        return util.sections(ctx, {
          { name = "options", tag_name = "opts", text = opts_text },
          { name = "bundle options", tag_name = "bundle-opts", text = bundle_opts_text },
          { name = "trace options", tag_name = "trace-opts", text = trace_opts_text },
        })
      end,
    },
    {
      name = "EXAMPLES",
      body = function()
        local f = io.open(example_path, "r")
        local content = f:read("*a")
        f:close()
        return ([[
%s

The following is the bundled chunk.

%s]]):format(util.help_code_block(vim.fn.trim(content, 2)), util.help_code_block(example_result))
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
%s```

### Bundled chunk

```lua
%s
```]]):format(full_plugin_name, exmaple, example_result)

  local readme = io.open("README.md", "w")
  readme:write(content)
  readme:close()
end
gen_readme()
