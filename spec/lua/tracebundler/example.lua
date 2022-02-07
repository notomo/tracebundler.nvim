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
