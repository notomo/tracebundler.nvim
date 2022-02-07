local M = {}

function M.get_first_tree_root(bufnr, language)
  if not vim.treesitter.language.require_language(language, nil, true) then
    return nil, ("not found tree-sitter parser for `%s`"):format(language)
  end
  local parser = vim.treesitter.get_parser(bufnr, language)
  local trees = parser:parse()
  return trees[1]:root()
end

function M.contains(scope, node)
  if not scope then
    return false
  end

  local parent_sr, parent_sc, parent_er, parent_ec = scope:range()
  local child_sr, child_sc, child_er, child_ec = node:range()
  if child_sr < parent_sr or parent_er < child_er then
    return false
  end

  if parent_sr < child_sr and child_er < parent_er then
    return true
  end

  return parent_sc <= child_sc and child_ec <= parent_ec
end

function M.contains_row(scope, row)
  local s, _, e, _ = scope:range()
  return s <= row and row <= e
end

function M.get_captures(match, query, handlers)
  local captures = {}
  for id, node in pairs(match) do
    local captured = query.captures[id]
    local f = handlers[captured]
    if f then
      f(captures, node)
    end
  end
  return captures
end

return M
