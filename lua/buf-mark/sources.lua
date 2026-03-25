--[[
Functions that discover external directories with saved buf-marks.

Each function returns a list of absolute paths that can be passed
to `require("buf-mark").load_marks(path, opts)` to load marks
from another project or worktree into the current session.

These are mainly used in the fzf-lua and telescope integrations.
]]
local T = {}

-- List git worktrees (excluding the current working directory) that have buf-mark storage files
T.worktrees = function()
  local result = vim.fn.systemlist('git worktree list --porcelain')
  if vim.v.shell_error ~= 0 then
    return {}
  end

  local buf_mark = require('buf-mark')
  local cwd = vim.fn.getcwd()
  local worktrees = {}

  for _, line in ipairs(result) do
    local path = line:match('^worktree (.+)$')
    if path and path ~= cwd then
      local storage_path = buf_mark.get_storage_path(path)
      if vim.fn.filereadable(storage_path) == 1 then
        table.insert(worktrees, path)
      end
    end
  end

  return worktrees
end

-- List all projects (excluding the current working directory) that have buf-mark storage files
T.projects = function()
  local buf_mark = require('buf-mark')
  local data_dir = vim.fn.stdpath('data')
  local storage_dir = data_dir .. '/buf_mark'
  local cwd = vim.fn.getcwd()

  local files = vim.fn.glob(storage_dir .. '/*.json', false, true)
  local projects = {}

  for _, filepath in ipairs(files) do
    local data = buf_mark.read_storage_file(filepath)
    if data and data.cwd and data.cwd ~= cwd then
      table.insert(projects, data.cwd)
    end
  end

  table.sort(projects)
  return projects
end

return T
