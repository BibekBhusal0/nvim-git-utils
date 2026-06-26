local run_git = require("nvim-git-utils.utils.run_git")
local opts = require("nvim-git-utils.opts").opts
local log = require("nvim-git-utils.utils.log")
local commit_input = require("nvim-git-utils.utils.commit_input")

local M = {}

local function parseMessage(text)
  if type(opts.commit_input.format_message) == "function" then
    return (opts.commit_input.format_message(text))
  end
  return text
end

M.commit_with_message = function()
  commit_input(" Commit Changes ", function(text)
    run_git("commit", { "-m", parseMessage(text) }, "Commit")
  end)
end

M.open_file_in_browser = function()
  local open_browser = require("nvim-git-utils.utils.open_browser")
  local file = vim.fn.expand("%:p")
  if file == "" then
    return
  end

  local file_dir = vim.fn.fnamemodify(file, ":h")

  local is_git_repo = vim.fn.systemlist(
    "git -C " .. vim.fn.shellescape(file_dir) .. " rev-parse --is-inside-work-tree"
  )[1]
  if is_git_repo ~= "true" then
    return
  end

  local root =
    vim.fn.systemlist("git -C " .. vim.fn.shellescape(file_dir) .. " rev-parse --show-toplevel")[1]
  if not root or root == "" then
    return
  end

  local branch =
    vim.fn.systemlist("git -C " .. vim.fn.shellescape(root) .. " branch --show-current")[1]
  if branch == nil or branch == "" then
    branch = vim.fn.systemlist("git -C " .. vim.fn.shellescape(root) .. " rev-parse HEAD")[1]
  end

  local remote =
    vim.fn.systemlist("git -C " .. vim.fn.shellescape(root) .. " remote get-url origin")[1]
  if not remote or remote == "" then
    return
  end

  local relpath = file
  if relpath:sub(1, #root + 1) == root .. "/" then
    relpath = relpath:sub(#root + 2)
  else
    return
  end

  local remote_url = remote:gsub("%.git$", "")
  if remote_url:match("^git@") then
    remote_url = remote_url:gsub("^git@", "https://"):gsub(":", "/", 1)
  elseif remote_url:match("^ssh://git@") then
    remote_url = remote_url:gsub("^ssh://git@", "https://"):gsub(":", "/", 1)
  end

  local url
  if remote_url:match("github%.com") then
    url = remote_url .. "/blob/" .. branch .. "/" .. relpath
  elseif remote_url:match("gitlab%.com") then
    url = remote_url .. "/-/blob/" .. branch .. "/" .. relpath
  elseif remote_url:match("codeberg%.org") or remote_url:match("forgejo") then
    url = remote_url .. "/src/branch/" .. branch .. "/" .. relpath
  else
    url = remote_url .. "/blob/" .. branch .. "/" .. relpath
  end

  open_browser(url)
end

M.commit_all_with_message = function()
  commit_input(" Add and Commit ", function(text)
    local result = vim.system({ "git", "add", "." }):wait()
    if result.code ~= 0 then
      log("Failed to add", vim.log.levels.ERROR)
      return
    end
    run_git("commit", { "-m", parseMessage(text) }, "Commit")
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
  commit_input(" Change Commit Message ", function(text)
    run_git("commit", { "--amend", "-m", parseMessage(text) }, "Amend")
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

    if
      vim.fn.filereadable(first_file) == 1
      and vim.fn.systemlist("git diff --name-only -- " .. vim.fn.shellescape(first_file))[1]
    then
      local output = vim.fn.systemlist("git diff --unified=0 -- " .. vim.fn.shellescape(first_file))
      for _, l in ipairs(output) do
        local line = l:match("^@@ .+%+(%d+)")
        if line then
          vim.api.nvim_win_set_cursor(0, { tonumber(line), 0 })
          vim.schedule(function()
            vim.cmd("normal! zz")
          end)
          break
        end
      end
    end
  else
    log("No changed files to open.", vim.log.levels.WARN)
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
    prompt_title = "Select Branch",
    previewer = false,
    attach_mappings = function()
      actions.select_default:replace(function(prompt_bufnr)
        local picker = action_state.get_current_picker(prompt_bufnr)
        local selections = picker:get_multi_selection()
        actions.close(prompt_bufnr)
        if #selections > 2 then
          log("Must select 1 or 2 branches", vim.log.levels.WARN)
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
