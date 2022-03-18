local M = {}

function M.entry()
  local used = require("tracebundler.test.data.example.used").new()
  require("tracebundler.test.data.example.ignored").start()
  return used
end

return M
