--[[
Shows buf-marks for buffers that are currently open.
  - Marks are shown in alphabetical order
  - Highlights mark of current buffer
  - Can be used in places like statusline, winbar, or tabline
]]
local M = {}

local Info = ''

-- Default configuration
local config = {
  hl_current = 'StatusLine',
  hl_non_current = 'StatusLineNC',
}

local function update()
  local s = ''

  -- Get all buf-marks (working directory and global)
  local buf_mark = require('buf-mark')
  local sorted_marks = {}
  for mark_char, mark_path in pairs(buf_mark.list() or {}) do
    table.insert(sorted_marks, {char = mark_char, path = mark_path})
  end
  local comparator = buf_mark.mark_comparator
  table.sort(sorted_marks, function(a, b) return comparator(a.char, b.char) end)

  -- Get buffers
  local buffers = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      buffers[vim.api.nvim_buf_get_name(bufnr)] = true
    end
  end

  -- Get current buffer name
  local current_buf_name = vim.api.nvim_buf_get_name(0)

  for _, mark in ipairs(sorted_marks) do
    if buffers[mark.path] then
      if mark.path == current_buf_name then
        s = s .. '%#' .. config.hl_current .. '#'
      else
        s = s .. '%#' .. config.hl_non_current .. '#'
      end
      s = s .. ' ' .. mark.char .. ' '
    end
  end

  Info = s .. '%*'
end

function M.setup(opts)
  -- Merge user options with defaults
  config = vim.tbl_extend('force', config, opts or {})

  -- Listen for specific events to know when to update.
  vim.api.nvim_create_autocmd('User', {
    pattern = 'BufMarkChanged',
    callback = update
  })
end

function M.get()
  return Info
end

return M
