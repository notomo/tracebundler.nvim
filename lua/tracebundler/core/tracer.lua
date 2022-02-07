local M = {}

function M.execute(f, traces)
  vim.validate({ f = { f, "function" }, traces = { traces, "table" } })

  local original_hook = debug.gethook()
  local entrypoint = debug.getinfo(f).source
  debug.sethook(function()
    local info = debug.getinfo(2)
    traces:add(info, entrypoint == info.source)
  end, "l")

  local ok, err = pcall(f)
  debug.sethook(original_hook)
  if not ok then
    return err
  end
  return nil
end

return M
