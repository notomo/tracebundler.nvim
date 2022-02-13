local M = {}

--- Executes function and returns as a bundled lua chunk string.
--- The chunk includes executed files.
--- @param f function: trace target (current limitation: cannot include upvalues)
--- @param opts table|nil: |tracebundler.nvim-opts|
--- @return string: a lua chunk
function M.execute(f, opts)
  return require("tracebundler.command").execute(f, opts)
end

--- Returns as a bundled lua chunk string.
--- Mainly use in |tracebundler.nvim-trace-opts| callback.
--- @param traces table: trace info that is callback argument.
--- @param bundle_opts table|nil: |tracebundler.nvim-bundle-opts|
--- @return string: a lua chunk
function M.bundle(traces, bundle_opts)
  return require("tracebundler.command").bundle(traces, bundle_opts)
end

return M
