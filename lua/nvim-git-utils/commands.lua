local run_git = require("nvim-git-utils.utils.run_git")
local log = require("nvim-git-utils.utils.log")

local M = {}

M.commit_with_message = function()
  require("utils.commit_input")(" Commit Changes ", function(text)
    run_git("commit", { "-m", text }, "Commit")
  end)
end

M.commit_all_with_message = function()
  require("utils.commit_input")(" Add and Commit ", function(text)
    local result = vim.system({ "git", "add", "." }):wait()
    if result.code ~= 0 then
      log("Failed to add", vim.log.levels.ERROR)
      return
    end
    run_git("commit", { "-m", text }, "Commit")
  end)
end

M.change_last_commit_message = function()
  local handle = io.popen("git log -1 --pretty=%B")
  if not handle then
    return
  end
  local message = handle:read("*a")
  handle:close()
  local m = message:match("^%s*(.-)%s*$")
  if not m then
    return
  end
  require("utils.commit_input")(" Change Commit Message ", function(text)
    run_git("commit", { "--amend", "-m", text }, "Amend")
  end, m)
end

M.open_changed_files = function()
  -- Get the list of changed and untracked files from git
  local handle = io.popen("git ls-files --modified --others --exclude-standard")
  if not handle then
    return
  end
  local result = handle:read("*a")
  handle:close()

  local count = 0
  for file in result:gmatch("[^\r\n]+") do
    -- Check if file exists (prevents errors on deleted files)
    if vim.fn.filereadable(file) == 1 then
      vim.cmd("badd " .. vim.fn.fnameescape(file))
      count = count + 1
    end
  end

  if count > 0 then
    log("Opened " .. count .. " changed files into buffers.")
    local first_file = result:match("[^\r\n]+")
    vim.cmd("edit " .. vim.fn.fnameescape(first_file))
  else
    log("No changed files to open." , vim.log.levels.WARN)
  end
end

M.diffViewTelescopeFileHistory = function()
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local themes = require("telescope.themes")
  local builtin = require("telescope.builtin")
  builtin.git_files(themes.get_dropdown({
    prompt_title = "Select File for History",
    previewer = false,
    attach_mappings = function()
      actions.select_default:replace(function(prompt_bufnr)
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection then
          vim.cmd("DiffviewFileHistory " .. selection.path)
        end
      end)
      return true
    end,
  }))
end

M.diffViewTelescopeCompareBranches = function()
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local themes = require("telescope.themes")
  local builtin = require("telescope.builtin")

  builtin.git_branches(themes.get_dropdown({
    prompt_title = "Select First Branch",
    previewer = false,
    attach_mappings = function()
      actions.select_default:replace(function(prompt_bufnr)
        local picker = action_state.get_current_picker(prompt_bufnr)
        local selections = picker:get_multi_selection()
        actions.close(prompt_bufnr)
        if #selections > 2 then
          log("Must select 1 or 2 branches",vim.log.levels.WARN )
          return
        end
        local old = #selections == 0 and action_state.get_selected_entry().ordinal
          or selections[1].value
        if #selections == 2 then
          local new = string.sub(selections[2].value, 1, 8)
          vim.cmd(string.format("DiffviewOpen %s..%s", old, new))
        else
          vim.cmd(string.format("DiffviewOpen %s", old))
        end
        vim.cmd([[stopinsert]])
      end)
      return true
    end,
  }))
end

return M
