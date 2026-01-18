local icon = ""
local function get_title_from_message(message)
  local title = message:match("^([^\n]*)")
  return title or ""
end

local function run_git(cmd, args, action)
  local result = vim.system({ "git", cmd, unpack(args) }):wait()
  if result.code == 0 then
    local past_word = { Commit = "Committed", Amend = "Amended" }
    local title = get_title_from_message(args[2])
    vim.notify(string.format("%s %s: %s", icon, past_word[action], title), vim.log.levels.INFO)
    return true
  else
    local error_msg = result.stderr:match("[^\r\n]+") or ""
    if error_msg == "" then
      vim.notify(string.format("%s %s failed", icon, action), vim.log.levels.ERROR)
    else
      vim.notify(string.format("%s %s failed: %s", icon, action, error_msg), vim.log.levels.ERROR)
    end
    return false
  end
end

return run_git
