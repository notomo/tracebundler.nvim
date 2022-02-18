local M = {}

function M.new(path)
  vim.validate({ path = { path, "string" } })
  local name = M._find_from_runtime(path) or M._find_from_packages(path)
  if not name then
    return nil
  end
  local tbl = {
    name = name,
    path = path,
    alias = M._to_alias(name),
  }
  return setmetatable(tbl, M)
end

function M._find_from_runtime(path)
  path = path:gsub("\\", "/")
  local splitted = vim.split(path, "/lua/")
  for i = 2, #splitted do
    local relative = splitted[i]
    local found_path = vim.api.nvim_get_runtime_file("lua/" .. relative, false)[1]
    if found_path == path then
      local name = relative:gsub("%.lua$", "")
      name = name:gsub("/", ".")
      return name
    end
  end
end

function M._find_from_packages(path)
  local lua_paths = vim.split(package.path, ";", true)
  for _, lua_path in ipairs(lua_paths) do
    local name = M._find_from_package(lua_path, path)
    if name then
      return name
    end
  end
end

function M._find_from_package(lua_path, path)
  local prefix, suffix = unpack(vim.split(lua_path, "?", true))
  if not vim.startswith(path, prefix) then
    return nil
  end
  if not vim.endswith(path, suffix) then
    return nil
  end
  local name = path:sub(1, #path - #suffix)
  name = name:sub(#prefix + 1)
  name = name:gsub("/", ".")
  return name
end

local suffix = ".init"
function M._to_alias(name)
  if not vim.endswith(name, suffix) then
    return nil
  end
  local alias = name:sub(1, #name - #suffix)
  return alias
end

return M
