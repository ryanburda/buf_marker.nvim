local T = {}

local function get_file_icon(filename)
  local ok, devicons = pcall(require, "nvim-web-devicons")
  if ok then
    return devicons.get_icon(filename, nil, { default = true })
  end
  local ok2, mini_icons = pcall(require, "mini.icons")
  if ok2 then
    local _, icon, hl = mini_icons.get("file", filename)
    return icon, hl
  end
  return nil, nil
end

T.picker = function()
  local fzf_lua = require("fzf-lua")
  local fzf_utils = require("fzf-lua.utils")
  local buf_mark = require("buf-mark")

  local marks = buf_mark.list()

  -- Collect and sort marks alphabetically
  local mark_list = {}
  for char, path in pairs(marks) do
    table.insert(mark_list, { char = char, path = path })
  end
  table.sort(mark_list, function(a, b) return a.char < b.char end)

  if #mark_list == 0 then
    vim.api.nvim_echo({ { "No buf-marks set", "WarningMsg" } }, true, {})
    return
  end

  local current_buf_path = vim.api.nvim_buf_get_name(0)

  -- Format entries as {path}:{line}:{col}:{char}    {display_path}
  -- The path:line:col prefix is parsed by fzf-lua's builtin previewer
  -- --with-nth=4.. hides it from the display, showing only the mark char and filename
  local entries = {}
  for _, mark in ipairs(mark_list) do
    local display_path = vim.fn.fnamemodify(mark.path, ":~:.")
    local line = 1
    local col = 1

    if mark.path == current_buf_path then
      -- Current buffer: use live cursor position (BufLeave hasn't fired yet)
      local pos = vim.api.nvim_win_get_cursor(0)
      line = pos[1]
      col = pos[2] + 1
    else
      -- Other buffers: use saved cursor position from BufLeave autocmd
      local bufnr = vim.fn.bufnr(mark.path)
      if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
        local buf_mark_data = vim.b[bufnr].buf_mark
        if buf_mark_data and buf_mark_data.last_cursor_position then
          line = buf_mark_data.last_cursor_position[1]
          col = buf_mark_data.last_cursor_position[2] + 1
        end
      end
    end

    local icon_str = ""
    local icon, icon_hl = get_file_icon(vim.fn.fnamemodify(mark.path, ":t"))
    if icon and icon_hl then
      icon_str = fzf_utils.ansi_from_hl(icon_hl, icon) .. " "
    end

    table.insert(entries, string.format("%s:%d:%d:%s    %s%s", mark.path, line, col, mark.char, icon_str, display_path))
  end

  fzf_lua.fzf_exec(entries, {
    prompt = "> ",
    previewer = "builtin",
    winopts = {
      title = " Buf-marks ",
      title_pos = "center",
    },
    fzf_opts = {
      ["--delimiter"] = ":",
      ["--with-nth"] = "4..",
      ["--header"] = string.format(":: <%s> to %s",
        fzf_utils.ansi_from_hl("FzfLuaHeaderBind", "ctrl-x"),
        fzf_utils.ansi_from_hl("FzfLuaHeaderText", "delete")),
    },
    actions = {
      ["default"] = function(selected)
        local char = selected[1]:match("^[^:]*:[^:]*:[^:]*:(%S+)")
        if char then
          buf_mark.goto(char)
        end
      end,
      ["ctrl-x"] = function(selected)
        local char = selected[1]:match("^[^:]*:[^:]*:[^:]*:(%S+)")
        if char then
          buf_mark.delete(char)
          T.picker()
        end
      end,
    },
  })
end

T.worktree_picker = function()
  local fzf_lua = require("fzf-lua")
  local buf_mark = require("buf-mark")

  local worktrees = require("buf-mark.sources").worktrees()

  if #worktrees == 0 then
    vim.api.nvim_echo({ { "No other worktrees with buf-marks found", "WarningMsg" } }, true, {})
    return
  end

  local entries = {}
  for _, path in ipairs(worktrees) do
    table.insert(entries, vim.fn.fnamemodify(path, ":~"))
  end

  fzf_lua.fzf_exec(entries, {
    prompt = "> ",
    previewer = false,
    winopts = {
      title = " Load buf-marks from worktree ",
      title_pos = "center",
    },
    actions = {
      ["default"] = function(selected)
        local path = vim.fn.expand(selected[1])
        buf_mark.load_marks(path, { force = false, rebase = true })
      end,
    },
  })
end

return T
