local log = require("nvim-git-utils.utils.log")

local function emojify(text)
  if not vim.fn.executable("devmoji") == 1 then
    log("Devmoji executable not found", vim.log.levels.ERROR)
    return text
  end

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
