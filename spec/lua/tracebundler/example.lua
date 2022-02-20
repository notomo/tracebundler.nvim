local bundled = require("tracebundler").execute(function()
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
