local M = {}

M.default = {
  trace = {
    path_filter = function()
      return true
    end,
  },
  bundle = {
    enabled_file_loader = false,
  },
}

function M.new(raw_opts)
  vim.validate({ raw_opts = { raw_opts, "table", true } })
  raw_opts = raw_opts or {}
  return vim.tbl_deep_extend("force", M.default, raw_opts)
end

return M
