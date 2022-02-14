local M = {}

M.default = {
  trace = {
    path_filter = function()
      return true
    end,
    callback = function() end,
  },
  bundle = {
    enabled_file_loader = false,
    traced_marker = " TRACED",
  },
}

function M.new(raw_opts)
  vim.validate({ raw_opts = { raw_opts, "table", true } })
  raw_opts = raw_opts or {}
  return vim.tbl_deep_extend("force", M.default, raw_opts)
end

function M.new_bundle_opts(raw_bundle_opts)
  local raw_opts = { bundle = raw_bundle_opts }
  local opts = M.new(raw_opts)
  return opts.bundle
end

return M
