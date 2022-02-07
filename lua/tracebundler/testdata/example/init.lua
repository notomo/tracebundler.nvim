local M = {}

function M.entry()
  local used = require("tracebundler.testdata.example.used").new()
  require("tracebundler.testdata.example.ignored").start()
  return used
end

return M
