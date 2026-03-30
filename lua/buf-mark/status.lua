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

-- Returns sorted marks filtered to only currently open buffers.
local function open_marks()
  local buf_mark = require('buf-mark')
  local all_marks = {}
  for mark_char, mark_path in pairs(buf_mark.list() or {}) do
    table.insert(all_marks, {char = mark_char, path = mark_path})
  end
  local comparator = buf_mark.mark_comparator
  table.sort(all_marks, function(a, b) return comparator(a.char, b.char) end)

  local buffers = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      buffers[vim.api.nvim_buf_get_name(bufnr)] = true
    end
  end

  local result = {}
  for _, mark in ipairs(all_marks) do
    if buffers[mark.path] then
      table.insert(result, mark)
    end
  end
  return result
end

local function update()
  local s = ''
  local current_buf_name = vim.api.nvim_buf_get_name(0)

  for _, mark in ipairs(open_marks()) do
    if mark.path == current_buf_name then
      s = s .. '%#' .. config.hl_current .. '#'
    else
      s = s .. '%#' .. config.hl_non_current .. '#'
    end
    s = s .. ' ' .. mark.char .. ' '
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

function M.next(count)
  count = count or 1
  local buf_mark = require('buf-mark')
  local mark_list = open_marks()
  if #mark_list == 0 then
    vim.api.nvim_echo({{"No open buf-marks", "WarningMsg"}}, true, {})
    return
  end

  local current_path = vim.api.nvim_buf_get_name(0)
  for i, mark in ipairs(mark_list) do
    if mark.path == current_path then
      local target = mark_list[((i - 1 + count) % #mark_list) + 1]
      buf_mark.goto(target.char)
      return
    end
  end

  buf_mark.goto(mark_list[1].char)
end

function M.prev(count)
  count = count or 1
  local buf_mark = require('buf-mark')
  local mark_list = open_marks()
  if #mark_list == 0 then
    vim.api.nvim_echo({{"No open buf-marks", "WarningMsg"}}, true, {})
    return
  end

  local current_path = vim.api.nvim_buf_get_name(0)
  for i, mark in ipairs(mark_list) do
    if mark.path == current_path then
      local target = mark_list[((i - 1 - count) % #mark_list) + 1]
      buf_mark.goto(target.char)
      return
    end
  end

  buf_mark.goto(mark_list[#mark_list].char)
end

return M
