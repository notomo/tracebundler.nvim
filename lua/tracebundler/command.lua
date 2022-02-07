local ReturnValue = require("tracebundler.lib.error_handler").ErrorHandler.for_return_value()

function ReturnValue.execute(f, raw_opts)
  local opts = require("tracebundler.core.option").new(raw_opts)
  local traces = require("tracebundler.core.traces").new(opts.path_filter)
  local err = require("tracebundler.core.tracer").execute(f, traces)
  if err then
    -- NOTE: show warning but no return.
    -- For tracing even if the code causes error.
    require("tracebundler.lib.message").warn(err)
  end
  return require("tracebundler.core.bundle").bundle(traces:all())
end

return ReturnValue:methods()
