local Popup = require "nui.popup"
local Layout = require "nui.layout"

local TITLE_MAX_LENGTH = 72

vim.api.nvim_set_hl(0, "CommitTitleOverLimit", { fg = "#ff5f5f", default = true })

local function commit_input(title, callback, initial_value)
  local initial_title = ""
  local initial_body = ""

  if initial_value then
    local split_idx = initial_value:find "\n"
    if split_idx then
      initial_title = initial_value:sub(1, split_idx - 1)
      initial_body = initial_value:sub(split_idx + 1) or ""
    else
      initial_title = initial_value or ""
    end
  end

  if vim.o.columns < 60 or vim.o.lines < 12 then
    vim.notify("Terminal too small for commit input", vim.log.levels.WARN)
    return
  end

  local prev_win = vim.api.nvim_get_current_win()

  local columns = vim.o.columns
  local terminal_lines = vim.o.lines

  local width = math.min(80, math.max(60, columns - 10))
  local height = math.min(16, math.max(12, terminal_lines - 6))

  local title_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[title_buf].buftype = "nofile"
  vim.bo[title_buf].swapfile = false
  vim.bo[title_buf].bufhidden = "wipe"
  vim.bo[title_buf].filetype = "gitcommit"
  vim.b[title_buf].cmp_enabled = false

  local body_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[body_buf].buftype = "nofile"
  vim.bo[body_buf].swapfile = false
  vim.bo[body_buf].bufhidden = "wipe"
  vim.bo[body_buf].filetype = "markdown"
  vim.b[body_buf].cmp_enabled = false

  vim.api.nvim_buf_set_lines(title_buf, 0, -1, false, { initial_title })
  vim.api.nvim_buf_set_lines(
    body_buf,
    0,
    -1,
    false,
    initial_body ~= "" and vim.split(initial_body, "\n", { plain = true }) or { "" }
  )

  local title_popup = Popup {
    border = {
      style = "single",
      text = { title, top_align = "center" },
    },
    enter = true,
    focusable = true,
    bufnr = title_buf,
  }

  local body_popup = Popup {
    border = {
      style = "single",
      text = { top = " Commit Body ", top_align = "center" },
    },
    enter = false,
    focusable = true,
    bufnr = body_buf,
  }

  local ns_id = vim.api.nvim_create_namespace "commitpad_counter"

  local function update_title()
    if not vim.api.nvim_buf_is_valid(title_buf) then
      return
    end

    local lines = vim.api.nvim_buf_get_lines(title_buf, 0, -1, false)

    if #lines > 1 then
      local joined = table.concat(lines, " ")
      vim.api.nvim_buf_set_lines(title_buf, 0, -1, false, { joined })
      if vim.api.nvim_get_mode().mode == "i" then
        vim.api.nvim_win_set_cursor(0, { 1, #joined })
      end
      lines = { joined }
    end

    local line = lines[1] or ""
    local count = #line
    local hl = count > TITLE_MAX_LENGTH and "CommitTitleOverLimit" or "Comment"

    vim.api.nvim_buf_clear_namespace(title_buf, ns_id, 0, -1)
    vim.api.nvim_buf_set_extmark(title_buf, ns_id, 0, 0, {
      virt_text = { { string.format(" %d/%d ", count, TITLE_MAX_LENGTH), hl } },
      virt_text_pos = "right_align",
      hl_mode = "combine",
    })
  end

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    buffer = title_buf,
    callback = update_title,
  })

  local layout = Layout(
    {
      relative = "editor",
      position = "50%",
      size = { width = width, height = height },
    },
    Layout.Box({
      Layout.Box(title_popup, { size = 3 }),
      Layout.Box(body_popup, { grow = 1 }),
    }, { dir = "col" })
  )

  local function close()
    layout:unmount()
    if vim.api.nvim_buf_is_valid(title_buf) then
      pcall(vim.api.nvim_buf_delete, title_buf, { force = true })
    end
    if vim.api.nvim_buf_is_valid(body_buf) then
      pcall(vim.api.nvim_buf_delete, body_buf, { force = true })
    end
    if prev_win and vim.api.nvim_win_is_valid(prev_win) then
      pcall(vim.api.nvim_set_current_win, prev_win)
      pcall(vim.api.nvim_feedkeys, vim.keycode "<Esc>", "n", false)
    end
  end

  local function focus_title(insert_mode)
    vim.api.nvim_set_current_win(title_popup.winid)
    if insert_mode then
      vim.cmd "startinsert"
      local buf_lines = vim.api.nvim_buf_get_lines(title_buf, 0, -1, false)
      local line = buf_lines[1] or ""
      vim.api.nvim_win_set_cursor(0, { 1, #line })
    end
  end

  local function focus_body(insert_mode)
    vim.api.nvim_set_current_win(body_popup.winid)
    if insert_mode then
      vim.cmd "startinsert"
      local buf_lines = vim.api.nvim_buf_get_lines(body_buf, 0, -1, false)
      local last_line = buf_lines[#buf_lines] or ""
      vim.api.nvim_win_set_cursor(0, { #buf_lines, #last_line })
    end
  end

  local function toggle_focus()
    local cur = vim.api.nvim_get_current_win()
    local mode = vim.api.nvim_get_mode().mode == "i"

    if cur == title_popup.winid then
      focus_body(mode)
    else
      focus_title(mode)
    end
  end

  local function submit()
    local title_lines = vim.api.nvim_buf_get_lines(title_buf, 0, -1, false)
    local title_text = (title_lines[1] or "")

    local body_lines = vim.api.nvim_buf_get_lines(body_buf, 0, -1, false)
    while #body_lines > 0 and body_lines[#body_lines] == "" do
      table.remove(body_lines)
    end
    local body_text = table.concat(body_lines, "\n")

    if title_text == "" and body_text == "" then
      close()
      return
    end

    local full_message
    if body_text and body_text ~= "" then
      full_message = title_text .. "\n\n" .. body_text
    else
      full_message = title_text
    end

    callback(full_message)
    close()
  end

  vim.api.nvim_buf_set_var(body_buf, "commit_submit_func", submit)
  vim.api.nvim_buf_set_var(title_buf, "commit_submit_func", submit)

  local function map(buf, lhs, rhs, desc, mode)
    vim.keymap.set(
      mode or "n",
      lhs,
      rhs,
      { buffer = buf, silent = true, nowait = true, desc = desc }
    )
  end

  for _, buf in ipairs { title_buf, body_buf } do
    map(buf, "<Esc>", close, "Close")
    map(buf, "<Tab>", toggle_focus, "Toggle focus", { "n", "i" })
  end

  map(title_buf, "<CR>", submit, "Submit commit", { "n", "i" })
  map(body_buf, "<CR>", submit, "Submit commit", "n")

  layout:mount()

  if vim.go.spell then
    pcall(vim.api.nvim_set_option_value, "spell", true, { win = title_popup.winid })
    pcall(vim.api.nvim_set_option_value, "spell", true, { win = body_popup.winid })
  end

  update_title()
  focus_title(true)
end

return commit_input
