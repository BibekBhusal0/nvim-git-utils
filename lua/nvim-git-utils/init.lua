local commands = require("nvim-git-utils.commands")
local opts = require("nvim-git-utils.opts")

local M = {}

M.setup = function(o)
  opts.opts = vim.tbl_deep_extend("force", opts.opts, o)
  local function create_command(name, fn)
    vim.api.nvim_create_user_command(name, fn, {})
  end

  create_command("GitCommit", commands.commit_with_message)
  create_command("GitAddCommit", commands.commit_all_with_message)
  create_command("GitChangeLastCommit", commands.change_last_commit_message)
  create_command("GitOpenChangedFiles", commands.open_changed_files)
  create_command("GitChanges", commands.open_changed_files)
  create_command("DiffviewFileHistoryTelescope", commands.diffViewTelescopeFileHistory)
  create_command("DiffviewCompareBranchesTelescope", commands.diffViewTelescopeCompareBranches)
end

return M
