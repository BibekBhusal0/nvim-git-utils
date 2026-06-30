local log = require("nvim-git-utils.utils.log")
local opts = require("nvim-git-utils.opts").opts

local M = {}

function M.get_diff(mode)
  local function read_diff(cmd)
    local handle = io.popen(cmd)
    if not handle then
      return nil
    end
    local diff = handle:read("*a")
    handle:close()
    return diff
  end

  local diff = nil
  if mode == "staged" then
    diff = read_diff("git diff --cached --no-color")
  end

  if mode == "all" then
    diff = read_diff("git diff HEAD --no-color") or nil
  end

  if diff == "" then
    return nil
  else
    return diff
  end
end

function M.generate(diff, callback)
  local max_length = opts.commit_input.max_length
  if not max_length or max_length <= 0 then
    max_length = 72
  end

  local prompt = opts.ai_commit.prompt:gsub("{max_length}", tostring(max_length))
  local input = prompt .. "\n\n```diff\n" .. diff .. "\n```"

  local tmpfile = vim.fn.tempname()
  vim.fn.writefile(vim.split(input, "\n"), tmpfile)

  local parts = {}

  vim.fn.jobstart({
    "sh",
    "-c",
    "opencode run --format json < " .. vim.fn.shellescape(tmpfile),
  }, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(parts, line)
          end
        end
      end
    end,
    on_exit = function(_, code)
      pcall(vim.fn.delete, tmpfile)
      vim.schedule(function()
        if code ~= 0 then
          log("AI commit generation failed", vim.log.levels.ERROR)
          callback(nil)
          return
        end

        local text_parts = {}
        for _, line in ipairs(parts) do
          local ok, parsed = pcall(vim.json.decode, line)
          if ok and parsed.type == "text" and parsed.part and parsed.part.text then
            table.insert(text_parts, parsed.part.text)
          end
        end

        local message = table.concat(text_parts):match("^%s*(.-)%s*$") or table.concat(text_parts)
        if message == "" then
          log("AI returned empty message", vim.log.levels.WARN)
          callback(nil)
          return
        end

        log("AI commit message generated", vim.log.levels.INFO)
        callback(message)
      end)
    end,
  })
end

return M
