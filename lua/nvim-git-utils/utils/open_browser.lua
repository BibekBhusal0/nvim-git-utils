-- https://github.com/lalitmee/browse.nvim/blob/main/lua/browse/utils.lua
local get_os_name = function()
  local os = vim.loop.os_uname()
  local os_name = os.sysname
  return os_name
end

-- WSL
local is_wsl = function()
  local output = vim.fn.systemlist("uname -r")
  return not not string.find(output[1] or "", "WSL")
end

-- get open cmd
local get_open_cmd = function()
  local os_name = get_os_name()
  local open_cmd = nil
  if os_name == "Windows_NT" or os_name == "Windows" then
    open_cmd = { "cmd", "/c", "start" }
  elseif os_name == "Darwin" then
    open_cmd = { "open" }
  else
    if is_wsl() then
      open_cmd = { "wsl-open" }
    else
      open_cmd = { "xdg-open" }
    end
  end
  return open_cmd
end

-- start the browser job
local open_browser = function(target)
  target = vim.fn.trim(target)
  local open_cmd = vim.fn.extend(get_open_cmd(), { target })
  vim.fn.jobstart(open_cmd, { detach = true })
end

return open_browser
