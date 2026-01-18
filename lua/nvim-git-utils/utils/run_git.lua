local log = require("nvim-git-utils.utils.log")
local function get_title_from_message(message)
  local title = message:match("^([^\n]*)")
  return title or ""
end

local function run_git(cmd, args, action)
  local result = vim.system({ "git", cmd, unpack(args) }):wait()
  if result.code == 0 then
    local past_word = { Commit = "Committed", Amend = "Amended" }
    local title = get_title_from_message(args[#args])
    log(string.format("%s: %s", past_word[action], title))
    return true
  else
    local error_msg = result.stderr:match("[^\r\n]+") or ""
    if error_msg == "" then
      log(string.format("%s failed", action), vim.log.levels.ERROR)
    else
      log(string.format("%s failed: %s", action, error_msg), vim.log.levels.ERROR)
    end
    return false
  end
end

return run_git
