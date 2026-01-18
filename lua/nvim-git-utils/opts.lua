local emojify = require("nvim-git-utils.utils.emojify")
local M = {}
M.opts = {
  log = { enabled = true, icon = "" },
  commit_input = { max_length = 72, format_message = emojify, hints = true },
}

return M
