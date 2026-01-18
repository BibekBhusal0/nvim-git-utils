local opts = require("nvim-git-utils").opts

return function(message, level)
  if opts.log.enabled then
    vim.notify(message, level or vim.log.levels.INFO)
  end
end
