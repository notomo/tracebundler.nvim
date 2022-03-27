local ReturnValue = require("tracebundler.vendor.misclib.error_handler").for_return_value()

function ReturnValue.execute(f, raw_opts)
  local opts = require("tracebundler.core.option").new(raw_opts)
  local traces, err = require("tracebundler.core.traces").execute(f, opts.trace)
  if err then
    -- NOTE: show warning but no return.
    -- For tracing even if the code causes error.
    require("tracebundler.vendor.misclib.message").warn(err)
  end
  return require("tracebundler.core.bundle").bundle(traces, opts.bundle)
end

function ReturnValue.bundle(traces, raw_bundle_opts)
  local bundle_opts = require("tracebundler.core.option").new_bundle_opts(raw_bundle_opts)
  return require("tracebundler.core.bundle").bundle(traces, bundle_opts)
end

return ReturnValue:methods()
