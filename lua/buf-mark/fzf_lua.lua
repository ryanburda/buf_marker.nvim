local T = {}

T.pick = function()
  local fzf_lua = require("fzf-lua")
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

    table.insert(entries, string.format("%s:%d:%d:%s    %s", mark.path, line, col, mark.char, display_path))
  end

  fzf_lua.fzf_exec(entries, {
    prompt = "BufMarks> ",
    previewer = "builtin",
    fzf_opts = {
      ["--delimiter"] = ":",
      ["--with-nth"] = "4..",
      ["--header"] = "ctrl-x: delete mark",
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
          T.pick()
        end
      end,
    },
  })
end

return T
