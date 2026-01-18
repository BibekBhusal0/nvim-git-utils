# nvim-git-utils

Simple commands to make life easier while working with git.

## Features

- **Interactive Commit Messages** - Beautiful popup UI for writing commit messages with:
  - Title/body split layout
  - Character counter
  - Visual warning when over limit
  - Keyboard hints
  - Automatic emojification (with devmoji)
- **Quick Staging & Commit** - Stage all changes and commit in one command
- **Amend Commits** - Easily change the last commit message
- **Open Changed Files** - Load all modified and untracked files into buffers
- **Telescope and Diffview Integration** - Browse file history and compare branches via telescope and diffview

## Commands

| Command                                | Description                          |
| -------------------------------------- | ------------------------------------ |
| `:GitCommit`                           | Commit staged changes with a message |
| `:GitAddCommit`                        | Stage all changes and commit         |
| `:GitChangeLastCommit`                 | Amend the last commit message        |
| `:GitChanges` / `:GitOpenChangedFiles` | Open all changed files into buffers  |
| `:DiffviewFileHistoryTelescope`        | Select a file and view its history   |
| `:DiffviewCompareBranchesTelescope`    | Compare branches in diffview         |

## Installation

Using LazyVim:

```lua
return {
  "bibekbhusal0/nvim-git-utils",
  opts = {}, -- Your config here, see down for options and default settings
  cmd = {
    "GitAddCommit",
    "GitCommit",
    "GitChangeLastCommit",
    "GitChanges",
    "DiffviewCompareBranchesTelescope",
    "DiffviewFileHistoryTelescope",
  },
  keys = { -- Set custom keymaps for your liking
    { "<leader>gc", ":GitAddCommit<CR>", desc = "Git add and commit" },
    { "<leader>gC", ":GitCommit<CR>", desc = "Git commit" },
    { "<leader>ge", ":GitChangeLastCommit<CR>", desc = "Git change last commit message" },
    { "<leader>gg", ":GitChanges<CR>", desc = "Git open changed files" },
    { "<leader>gdb", ":DiffviewCompareBranchesTelescope<CR>", desc = "Diffview compare branches" },
    {
      "<leader>gdF",
      ":DiffviewFileHistoryTelescope<CR>",
      desc = "Diffview file history telescope",
    },
  },
}
```

## Default Values

```lua
require("nvim-git-utils").setup({
  log = { enabled = true, icon = "" },
  commit_input = {
    max_length = 72,
    format_message = require("nvim-git-utils.utils.emojify"), -- Uses devmoji to add emojis to commit messages
    hints = true,
  },
})
```

## Setup

Configure nvim-git-utils with the following options:

```lua
require("nvim-git-utils").setup({
  -- Logging configuration
  log = {
    enabled = true, -- Enable/disable notifications. Set to false to disable all log messages
    icon = "", -- Icon prefix displayed before log messages in notifications
  },

  -- Commit input popup configuration
  commit_input = {
    max_length = 72, -- Maximum character limit for commit title
                     -- Set to 0 or nil to disable the character counter entirely

    -- Function to transform commit message before committing
    -- Set to nil to disable message formatting (returns message as-is)
    -- Example with devmoji (this function is also available at require("nvim-git-utils.utils.emojify")):
    -- format_message = function(msg)
    --   local handle = io.popen("devmoji --text " .. vim.fn.shellescape(msg))
    --   local result = handle:read("*a")
    --   handle:close()
    --   return result:match("^%s*(.-)%s*$")
    -- end,
    format_message = nil,

    hints = true, -- Show keyboard shortcuts hints at the bottom of the popup
                  -- Set to false to hide the hints bar
  },
})
```

## Credits

Main inspiration came from [commitpad.nvim](https://github.com/Sengoku11/commitpad.nvim).

## Similar Plugins

[commitpad.nvim](https://github.com/Sengoku11/commitpad.nvim)

### How is this different from commitpad?

Commitpad is a simple and nice plugin for creating new commit messages. This plugin has additional functionalities like:

- Changing the last commit message
- Staging all files and committing in one step
- Integration with devmoji

Commitpad has a nice UI for committing but lacks customization. This plugin allows customizing:

- Max character length for commit titles
- Hiding keyboard hints

## Dependencies

- [nui.nvim](https://github.com/MunifTanjim/nui.nvim) - UI components
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) - Fuzzy finder
- [diffview.nvim](https://github.com/sindrets/diffview.nvim) - Diff viewer
- [devmoji](https://github.com/folke/devmoji) (optional) - Emojify your commit messages

## License

MIT
