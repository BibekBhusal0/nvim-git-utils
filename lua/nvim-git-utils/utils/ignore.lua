local M = {}

-- Binary media that Neovim has no business opening. Images are intentionally
-- left out: they are often editable assets (svg) and sometimes openable as well.
local DEFAULT_EXTENSIONS = {
  -- video
  "mp4",
  "mkv",
  "webm",
  "avi",
  "mov",
  "wmv",
  "flv",
  "m4v",
  "mpg",
  "mpeg",
  "3gp",
  "ogv",
  "vob",
  "m2ts",
  "mts",
  -- audio
  "mp3",
  "wav",
  "flac",
  "ogg",
  "oga",
  "m4a",
  "aac",
  "wma",
  "opus",
  "aiff",
  "alac",
  "mid",
  "midi",
  "amr",
}

local function is_listed(ext, extensions)
  for _, candidate in ipairs(extensions) do
    if candidate:lower() == ext then
      return true
    end
  end
  return false
end

function M.is_ignored(file)
  local ext = file:match("%.([%w]+)$")
  if not ext then
    return false
  end
  ext = ext:lower()

  local opts = require("nvim-git-utils.opts").opts
  local extra = (opts.ignore and opts.ignore.extensions) or {}
  return is_listed(ext, DEFAULT_EXTENSIONS) or is_listed(ext, extra)
end

return M
