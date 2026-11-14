local M = {}

---Ensure treesitter injection for gitcommit exists so git commit message buffers
---get markdown styling for the message body (the same injection pattern used by render-markdown.nvim).
function M.setup_injection()
  local ok, _ = pcall(vim.treesitter.language.add, "gitcommit")
  if not ok then
    return
  end

  local injection_query = [[
((message) @injection.content
  (#set! injection.language "markdown")
  (#set! injection.include-children))
]]

  pcall(function()
    local existing = vim.treesitter.query.get("gitcommit", "injections")
    if not existing then
      vim.treesitter.query.set("gitcommit", "injections", injection_query)
    end
  end)
end

---Enable treesitter highlighter on a gitcommit buffer
---@param buf integer
function M.attach(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  M.setup_injection()

  pcall(vim.treesitter.start, buf, "gitcommit")
end

return M
