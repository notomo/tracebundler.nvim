local M = {}

function M.entry()
  local used = require("tracebundler.example.used").new()
  require("tracebundler.example.ignored").start()
  return used
end

return M
