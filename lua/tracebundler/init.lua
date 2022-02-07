local M = {}

--- Executes function and returns as a bundled lua chunk string.
--- The chunk includes executed files.
--- @param f function: trace target (current limitation: cannot include upvalues)
--- @param opts table|nil: |tracebundler.nvim-opts|
--- @return string: a lua chunk
function M.execute(f, opts)
  return require("tracebundler.command").execute(f, opts)
end

return M
