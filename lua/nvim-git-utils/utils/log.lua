return function(message, level)
  -- print('DEBUGPRINT[115]: log.lua:1: message=' .. vim.inspect(message))
  local opts = require("nvim-git-utils.opts").opts
  if opts.log.enabled then
    vim.notify(opts.log.icon .. " " .. message, level or vim.log.levels.INFO)
  end
end
