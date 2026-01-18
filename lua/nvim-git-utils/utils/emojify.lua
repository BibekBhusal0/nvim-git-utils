local function emojify(text)
  local handle = io.popen("devmoji --text " .. vim.fn.shellescape(text))
  if handle then
    local emojified_text = handle:read("*a")
    handle:close()
    emojified_text = emojified_text:match("^%s*(.-)%s*$")
    return emojified_text
  else
    return text
  end
end

return emojify
