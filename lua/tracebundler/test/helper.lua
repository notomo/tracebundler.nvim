local plugin_name = vim.split((...):gsub("%.", "/"), "/", true)[1]
local M = require("vusted.helper")

M.root = M.find_plugin_root(plugin_name)
local runtimepath = vim.o.runtimepath

function M.before_each()
  vim.o.runtimepath = runtimepath
end

function M.after_each()
  vim.cmd("silent %bwipeout!")
  M.cleanup_loaded_modules(plugin_name)
  print(" ")
end

function M.path_filter(path)
  local matched = path:match("/busted/")
  return not matched
end

function M.set_lines(str)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(str, "\n"))
end

function M.get_row(pattern)
  local saved = vim.fn.winsaveview()
  local row = vim.fn.search(pattern)
  if row == 0 then
    error(("not found pattern: `%s`"):format(pattern))
  end
  vim.fn.winrestview(saved)
  return row
end

function M.use_parsers()
  vim.o.runtimepath = M.root .. "/spec/lua/nvim-treesitter," .. vim.o.runtimepath
  vim.cmd([[runtime plugin/nvim-treesitter.*]])
end

function M.install_parser(language)
  M.use_parsers()
  if not vim.treesitter.language.require_language(language, nil, true) then
    vim.cmd([[TSInstallSync ]] .. language)
  end
end

local asserts = require("vusted.assert").asserts

asserts.create("test_values"):register_same(function(tests)
  return vim.tbl_map(function(test)
    local row = test.scope_node:start()
    return { name = test.name, row = row + 1 }
  end, tests)
end)

asserts.create("test_value"):register_same(function(test)
  local row = test.scope_node:start()
  return { name = test.name, row = row + 1 }
end)

return M
