local emojify = require("nvim-git-utils.utils.emojify")
local M = {}
M.opts = {
  log = { enabled = true, icon = "" },
  commit_input = { max_length = 72, format_message = emojify, hints = true },
  ai_commit = {
    prompt = "Generate a git commit message for the following diff. Keep the title under {max_length} characters and use the body for details when needed. Use conventional commits format (e.g., feat:, fix:, chore:, docs:, perf:, refactor:, style:, test:). Return only the commit message with no surrounding quotes or backticks.",
  },
}

return M
