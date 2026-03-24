local T = {}

-- Dictionary mapping single characters to file paths (private)
local marks = {}

-- Configuration options
T.config = {
  persist = true
}

-- Get the storage file path for current working directory
local function get_storage_path()
  local data_dir = vim.fn.stdpath('data')
  local storage_dir = data_dir .. '/buf_mark'

  -- Create directory if it doesn't exist
  vim.fn.mkdir(storage_dir, 'p')

  -- Generate a hash of the current working directory
  local cwd = vim.fn.getcwd()
  local hash = vim.fn.sha256(cwd)

  return storage_dir .. '/' .. hash .. '.json'
end

-- Save marks to disk
local function save_marks()
  if not T.config.persist then
    return
  end

  local storage_path = get_storage_path()
  local data = {
    cwd = vim.fn.getcwd(),
    marks = marks
  }

  local json_str = vim.json.encode(data)
  local file = io.open(storage_path, 'w')
  if file then
    file:write(json_str)
    file:close()
  end
end

-- Read marks from a storage file, returns a table or nil
local function read_marks_file(storage_path)
  local file = io.open(storage_path, 'r')
  if not file then
    return nil
  end

  local content = file:read('*all')
  file:close()

  if content and content ~= '' then
    local ok, data = pcall(vim.json.decode, content)
    if ok and data and data.marks then
      return data.marks
    end
  end
  return nil
end

-- Load marks from disk
local function load_marks()
  local storage_path = get_storage_path()
  local loaded = read_marks_file(storage_path)
  if loaded then
    marks = loaded
  end
end

-- Trigger a custom autocommand event when marks change
local function trigger_marks_changed_event()
  vim.api.nvim_exec_autocmds('User', {
    pattern = 'BufMarkChanged',
    modeline = false,
  })
end

-- Check if input is a single character
local function input_checker(char)
  if not char or type(char) ~= 'string' or vim.fn.strcharlen(char) ~= 1 then
    vim.api.nvim_echo({{"Please provide a single character mark", "ErrorMsg"}}, true, {})
    return false
  end
  return true
end

-- Set a mark for a character to a filepath
T.set = function(char)
  if not input_checker(char) then
    return
  end

  marks[char] = vim.api.nvim_buf_get_name(0)
  save_marks()
  trigger_marks_changed_event()
  vim.api.nvim_echo({{"buf-mark set: " .. char, "Normal"}}, true, {})
end

-- Deletes a mark for a character to a filepath
T.delete = function(char)
  if not input_checker(char) then
    return
  end

  if not marks[char] then
    vim.api.nvim_echo({{"buf-mark not set: " .. char, "WarningMsg"}}, true, {})
    return
  end

  marks[char] = nil
  save_marks()
  trigger_marks_changed_event()
  vim.api.nvim_echo({{"buf-mark deleted: " .. char, "Normal"}}, true, {})
end

-- Deletes all marks for the current project
T.delete_all = function()
  marks = {}
  save_marks()
  trigger_marks_changed_event()
  vim.api.nvim_echo({{"buf-mark deleted all", "Normal"}}, true, {})
end

-- Goes to the buffer associated with a character
T.goto = function(char)
  if not input_checker(char) then
    return
  end

  local path = marks[char]

  if not path then
    vim.api.nvim_echo({{"buf-mark not set: " .. char, "WarningMsg"}}, true, {})
    return
  end

  local bufnr = vim.fn.bufnr(path)

  if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
    -- If the buffer exists and is loaded, switch to it
    vim.api.nvim_set_current_buf(bufnr)
  else
    -- Otherwise, open the file in a new buffer
    -- Use relative path if file is within current working directory
    local relative_path = vim.fn.fnamemodify(path, ':.')
    vim.cmd('edit ' .. vim.fn.fnameescape(relative_path))
  end
end

-- Returns all buffer marks as a table
T.list = function()
  return marks
end

-- Lists all buffer marks with pretty formatting
T.list_pretty = function()
  -- Collect all marks and sort them
  local mark_list = {}
  for char, path in pairs(marks) do
    table.insert(mark_list, {char = char, path = path})
  end

  -- Sort by character
  table.sort(mark_list, function(a, b) return a.char < b.char end)

  if #mark_list == 0 then
    vim.api.nvim_echo({{"No buf-marks set", "WarningMsg"}}, true, {})
    return
  end

  -- Build output lines
  local lines = {}
  for _, mark in ipairs(mark_list) do
    -- Get relative path or full path
    local display_path = vim.fn.fnamemodify(mark.path, ':~:.')

    local line = string.format(" %s    %s", mark.char, display_path)
    table.insert(lines, line)
  end

  -- Display in a message
  local output = {
    {"mark  file", "Title"},
    {"\n" .. table.concat(lines, "\n"), "Normal"}
  }
  vim.api.nvim_echo(output, true, {})
end

-- List git worktrees (excluding the current working directory) that have buf-mark storage files
T.list_worktrees = function()
  local result = vim.fn.systemlist('git worktree list --porcelain')
  if vim.v.shell_error ~= 0 then
    return {}
  end

  local cwd = vim.fn.getcwd()
  local data_dir = vim.fn.stdpath('data')
  local storage_dir = data_dir .. '/buf_mark'
  local worktrees = {}

  for _, line in ipairs(result) do
    local path = line:match('^worktree (.+)$')
    if path and path ~= cwd then
      local hash = vim.fn.sha256(path)
      local storage_path = storage_dir .. '/' .. hash .. '.json'
      if vim.fn.filereadable(storage_path) == 1 then
        table.insert(worktrees, path)
      end
    end
  end

  return worktrees
end

-- Load buf-marks from another worktree path, without overwriting existing marks
T.load_worktree = function(worktree_path)
  if not worktree_path or type(worktree_path) ~= 'string' or worktree_path == '' then
    vim.api.nvim_echo({{"Please provide a worktree path", "ErrorMsg"}}, true, {})
    return
  end

  -- Resolve to absolute path
  local abs_path = vim.fn.fnamemodify(worktree_path, ':p')
  -- Remove trailing slash for consistent hashing
  abs_path = abs_path:gsub('/$', '')

  local data_dir = vim.fn.stdpath('data')
  local storage_dir = data_dir .. '/buf_mark'
  local hash = vim.fn.sha256(abs_path)
  local storage_path = storage_dir .. '/' .. hash .. '.json'

  local loaded = read_marks_file(storage_path)
  if not loaded then
    vim.api.nvim_echo({{"No buf-marks found for: " .. abs_path, "WarningMsg"}}, true, {})
    return
  end

  -- Rebase paths from the source worktree to the current worktree
  local cwd = vim.fn.getcwd()
  -- Ensure trailing slash for prefix matching
  local source_prefix = abs_path .. '/'

  local count = 0
  for char, path in pairs(loaded) do
    if not marks[char] then
      -- Replace the source worktree prefix with the current working directory
      if path:sub(1, #source_prefix) == source_prefix then
        local relative = path:sub(#source_prefix + 1)
        marks[char] = cwd .. '/' .. relative
      else
        marks[char] = path
      end
      count = count + 1
    end
  end

  if count > 0 then
    save_marks()
    trigger_marks_changed_event()
  end

  vim.api.nvim_echo({{"Loaded " .. count .. " buf-mark(s) from: " .. abs_path, "Normal"}}, true, {})
end

T.setup = function(opts)
  opts = opts or {}

  -- Update configuration
  T.config.persist = opts.persist or true

  -- Load existing marks for this directory if persistence is enabled
  if T.config.persist then
    load_marks()
  end

  -- Fire BufMarkChanged when the user switches buffers.
  vim.api.nvim_create_autocmd('BufEnter', {
    callback = trigger_marks_changed_event,
  })

  -- Fire BufMarkChanged when the user deletes a buffer.
  --
  -- BufDelete fires before the deletion takes place.
  -- Scheduling the update allows enough time for the
  -- buffer to be deleted before updating the status.
  vim.api.nvim_create_autocmd({'BufDelete'}, {
    callback = function()
      vim.schedule(trigger_marks_changed_event)
    end
  })

  -- Cursor position autocommands.
  vim.api.nvim_create_augroup('BufMarkSaveCursorPos', { clear = true })

  -- Create an autocommand to update the last known cursor position
  vim.api.nvim_create_autocmd({'BufLeave'}, {
    group = 'BufMarkSaveCursorPos',
    pattern = '*',
    callback = function()
      -- Get the current buffer number and the cursor position
      local bufnr = vim.api.nvim_get_current_buf()
      local cursor_position = vim.api.nvim_win_get_cursor(0)

      -- Save the cursor position to a buffer variable
      if not vim.b[bufnr].buf_mark then
        vim.b[bufnr].buf_mark = {}
      end

      vim.b[bufnr].buf_mark.last_cursor_position = cursor_position
    end,
  })

  -- user commands
  require('buf-mark.user_commands').setup()

  -- status
  require('buf-mark.status').setup(opts.status)

  -- default keymaps
  if opts.keymaps ~= false then
    require('buf-mark.default_keymaps').setup()
  end

end

return T
