local ReturnValue = require("tracebundler.lib.error_handler").ErrorHandler.for_return_value()

function ReturnValue.execute(f, raw_opts)
  local opts = require("tracebundler.core.option").new(raw_opts)
  local traces, err = require("tracebundler.core.traces").execute(f, opts.trace)
  if err then
    -- NOTE: show warning but no return.
    -- For tracing even if the code causes error.
    require("tracebundler.lib.message").warn(err)
  end
  return require("tracebundler.core.bundle").bundle(traces, opts.bundle)
end

return ReturnValue:methods()
