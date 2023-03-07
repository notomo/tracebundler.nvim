local M = {}

--- @class TracebundlerOption
--- @field bundle TracebundlerBundleOption |TracebundlerBundleOption|
--- @field trace TracebundlerTraceOption |TracebundlerTraceOption|

--- @class TracebundlerBundleOption
--- @field enabled_file_loader boolean? if true, chunk supports dofile, loadfile. default: false
--- @field return_table boolean? if true, chunk returns {modules = {modules}, execute = {f}}, if false, chunk returns {f}(). default: false
--- @field traced_marker string? if not empty, adds to traced line as comment. default: " TRACED"

--- @class TracebundlerTraceOption
--- @field callback fun(traces:TracebundlerTraces)? called after every trace. default: `function(traces) end`
--- @field path_filter (fun(path:string):boolean)? if return true, the chunk includes the file. default: `function(file_path) return true end`

--- @class TracebundlerTraces

--- Executes function and returns as a bundled lua chunk string.
--- The chunk includes executed files.
--- Limitation:
--- - `f` cannot include upvalues.
--- - `f` must not be one line closure: `function() require('something') end`
--- @param f fun():any trace target
--- @param opts TracebundlerOption?: |TracebundlerOption|
--- @return string # a lua chunk |tracebundler.nvim-chunk-limitation|
function M.execute(f, opts)
  return require("tracebundler.command").execute(f, opts)
end

--- Returns as a bundled lua chunk string.
--- Mainly use in |TracebundlerTraceOption| callback.
--- @param traces TracebundlerTraces: trace info that is callback argument.
--- @param bundle_opts TracebundlerBundleOption?: |TracebundlerBundleOption|
--- @return string # a lua chunk |tracebundler.nvim-chunk-limitation|
function M.bundle(traces, bundle_opts)
  return require("tracebundler.command").bundle(traces, bundle_opts)
end

return M
