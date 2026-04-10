local T = {}

-- Dictionary mapping single characters to file paths (private)
local marks = {}

-- Dictionary mapping uppercase characters to file paths (global, cross-working-directory)
local global_marks = {}

-- Configuration options
T.config = {
  persist = true
}

-- Returns true if char is an uppercase letter (A-Z), indicating a global mark
local function is_global_mark(char)
  return char:match('^%u$') ~= nil
end

-- Comparator that sorts working directory marks before global marks,
-- alphabetically within each group.
T.mark_comparator = function(a, b)
  local a_global = is_global_mark(a)
  local b_global = is_global_mark(b)
  if a_global ~= b_global then
    return b_global
  end
  return a < b
end

-- Get the storage file path for a given working directory (defaults to cwd)
T.get_storage_file_path = function(path)
  local data_dir = vim.fn.stdpath('data')
  local storage_dir = data_dir .. '/buf_mark'

  -- Create directory if it doesn't exist
  vim.fn.mkdir(storage_dir, 'p')

  local dir = path or vim.fn.getcwd()
  local hash = vim.fn.sha256(dir)

  return storage_dir .. '/' .. hash .. '.json'
end

-- Get the storage file path for global marks
local function get_global_storage_path()
  local data_dir = vim.fn.stdpath('data')
  local storage_dir = data_dir .. '/buf_mark'

  -- Create directory if it doesn't exist
  vim.fn.mkdir(storage_dir, 'p')

  return storage_dir .. '/global.json'
end

-- Save working directory marks to disk
local function save_marks()
  if not T.config.persist then
    return
  end

  local storage_path = T.get_storage_file_path()
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

-- Read global marks from disk into memory
local function read_global_marks()
  local storage_path = get_global_storage_path()
  local file = io.open(storage_path, 'r')
  if not file then
    return
  end

  local content = file:read('*all')
  file:close()

  if content and content ~= '' then
    local ok, data = pcall(vim.json.decode, content)
    if ok and data then
      global_marks = data
    end
  end
end

-- Save global marks to disk, merging with any changes from other instances
local function save_global_marks()
  if not T.config.persist then
    return
  end

  -- Snapshot in-memory state before reading disk
  local local_marks = vim.deepcopy(global_marks)

  -- Re-read from disk to pick up changes from other Neovim instances
  local storage_path = get_global_storage_path()
  local file = io.open(storage_path, 'r')
  if file then
    local content = file:read('*all')
    file:close()
    if content and content ~= '' then
      local ok, disk_marks = pcall(vim.json.decode, content)
      if ok and disk_marks then
        -- Start from disk, overlay in-memory marks on top
        global_marks = vim.tbl_extend('force', disk_marks, local_marks)
        -- Remove keys that were deleted in-memory but still exist on disk
        for char, _ in pairs(disk_marks) do
          if local_marks[char] == nil then
            global_marks[char] = nil
          end
        end
      end
    end
  end

  local json_str = vim.json.encode(global_marks)
  file = io.open(storage_path, 'w')
  if file then
    file:write(json_str)
    file:close()
  end
end

-- Read a buf-mark storage file, returns the parsed data table or nil
T.read_storage_file = function(storage_path)
  local file = io.open(storage_path, 'r')
  if not file then
    return nil
  end

  local content = file:read('*all')
  file:close()

  if content and content ~= '' then
    local ok, data = pcall(vim.json.decode, content)
    if ok and data then
      return data
    end
  end
  return nil
end

-- Delete the storage file for a given working directory
T.remove_storage_file = function(path)
  if not path or type(path) ~= 'string' or path == '' then
    vim.api.nvim_echo({{"Please provide a working directory path", "ErrorMsg"}}, true, {})
    return
  end

  local abs_path = vim.fn.fnamemodify(path, ':p'):gsub('/$', '')
  local storage_path = T.get_storage_file_path(abs_path)

  if vim.fn.filereadable(storage_path) == 0 then
    vim.api.nvim_echo({{"No storage file found for: " .. abs_path, "WarningMsg"}}, true, {})
    return
  end

  os.remove(storage_path)
  vim.api.nvim_echo({{"Deleted storage file for: " .. abs_path, "Normal"}}, true, {})
end

-- Trigger a custom autocommand event when marks change
local function trigger_marks_changed_event()
  vim.api.nvim_exec_autocmds('User', {
    pattern = 'BufMarkChanged',
    modeline = false,
  })
end

-- Check if input is a single printable character (ASCII 33-126)
local function input_checker(char)
  if not char or type(char) ~= 'string' or vim.fn.strcharlen(char) ~= 1 then
    vim.api.nvim_echo({{"Please provide a single character mark", "ErrorMsg"}}, true, {})
    return false
  end
  local byte = string.byte(char)
  if byte < 33 or byte > 126 then
    return false
  end
  return true
end

-- Load marks from disk for a given path (defaults to cwd).
--
-- opts.force:  when true (default), overwrite existing marks.
-- opts.rebase: when false (default), use paths as-is.
--              when true, rebase file paths from the source directory to cwd.
T.load_marks = function(path, opts)
  opts = opts or {}
  local force = opts.force ~= false   -- default true
  local rebase = opts.rebase == true   -- default false

  -- Resolve path to absolute, strip trailing slash
  local source_dir
  if path then
    source_dir = vim.fn.fnamemodify(path, ':p'):gsub('/$', '')
  else
    source_dir = vim.fn.getcwd()
  end

  local storage_path = T.get_storage_file_path(source_dir)
  local data = T.read_storage_file(storage_path)
  if not data or not data.marks then
    return
  end
  local loaded = data.marks

  local cwd = vim.fn.getcwd()
  local source_prefix = source_dir .. '/'

  for char, file_path in pairs(loaded) do
    if force or not marks[char] then
      if rebase and file_path:sub(1, #source_prefix) == source_prefix then
        local relative = file_path:sub(#source_prefix + 1)
        marks[char] = cwd .. '/' .. relative
      else
        marks[char] = file_path
      end
    end
  end

  save_marks()
  trigger_marks_changed_event()
end

-- Unload marks of another working directory from the current session.
-- Only removes a mark if its file path still matches what the source
-- directory's storage file contains (possibly rebased), so marks that
-- were overwritten after loading are left untouched.
T.unload_marks = function(path, opts)
  opts = opts or {}
  local rebase = opts.rebase == true   -- default false

  if not path then
    vim.api.nvim_echo({{"Please provide a working directory path", "ErrorMsg"}}, true, {})
    return
  end

  local source_dir = vim.fn.fnamemodify(path, ':p'):gsub('/$', '')

  local storage_path = T.get_storage_file_path(source_dir)
  local data = T.read_storage_file(storage_path)
  if not data or not data.marks then
    return
  end

  local cwd = vim.fn.getcwd()
  local source_prefix = source_dir .. '/'

  for char, file_path in pairs(data.marks) do
    -- Determine the path that would have been written into marks when loaded
    local expected_path
    if rebase and file_path:sub(1, #source_prefix) == source_prefix then
      local relative = file_path:sub(#source_prefix + 1)
      expected_path = cwd .. '/' .. relative
    else
      expected_path = file_path
    end

    -- Only remove the mark if its current value matches the expected path
    if marks[char] == expected_path then
      marks[char] = nil
    end
  end

  save_marks()
  trigger_marks_changed_event()
end

-- Set a mark for a character to a filepath
T.set = function(char)
  if not char then
    char = vim.fn.getcharstr()
  end
  if not input_checker(char) then
    return
  end

  local filepath = vim.api.nvim_buf_get_name(0)

  if is_global_mark(char) then
    global_marks[char] = filepath
    save_global_marks()
  else
    marks[char] = filepath
    save_marks()
  end

  trigger_marks_changed_event()
  vim.api.nvim_echo({{"buf-mark set: " .. char, "Normal"}}, true, {})
end

-- Deletes a mark for a character to a filepath
T.delete = function(char)
  if not char then
    char = vim.fn.getcharstr()
  end
  if not input_checker(char) then
    return
  end

  if is_global_mark(char) then
    read_global_marks()
    if not global_marks[char] then
      vim.api.nvim_echo({{"buf-mark not set: " .. char, "WarningMsg"}}, true, {})
      return
    end
    global_marks[char] = nil
    save_global_marks()
  else
    if not marks[char] then
      vim.api.nvim_echo({{"buf-mark not set: " .. char, "WarningMsg"}}, true, {})
      return
    end
    marks[char] = nil
    save_marks()
  end

  trigger_marks_changed_event()
  vim.api.nvim_echo({{"buf-mark deleted: " .. char, "Normal"}}, true, {})
end

-- Goes to the buffer associated with a character
T.goto = function(char)
  if not char then
    char = vim.fn.getcharstr()
  end
  if not input_checker(char) then
    return
  end

  local path
  if is_global_mark(char) then
    read_global_marks()
    path = global_marks[char]
  else
    path = marks[char]
  end

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

-- Returns a sorted list of {char, path} entries from all marks (working directory and global).
local function sorted_marks()
  read_global_marks()
  local result = {}
  for char, path in pairs(marks) do
    table.insert(result, {char = char, path = path})
  end
  for char, path in pairs(global_marks) do
    table.insert(result, {char = char, path = path})
  end
  table.sort(result, function(a, b) return T.mark_comparator(a.char, b.char) end)
  return result
end

-- Goes to the next buf-mark (sorted order, wraps around)
T.next = function(count)
  count = count or 1
  local mark_list = sorted_marks()
  if #mark_list == 0 then
    vim.api.nvim_echo({{"No buf-marks set", "WarningMsg"}}, true, {})
    return
  end

  local current_path = vim.api.nvim_buf_get_name(0)
  for i, mark in ipairs(mark_list) do
    if mark.path == current_path then
      local target = mark_list[((i - 1 + count) % #mark_list) + 1]
      T.goto(target.char)
      return
    end
  end

  -- Current buffer has no mark; jump to the first mark
  T.goto(mark_list[1].char)
end

-- Goes to the previous buf-mark (sorted order, wraps around)
T.prev = function(count)
  count = count or 1
  local mark_list = sorted_marks()
  if #mark_list == 0 then
    vim.api.nvim_echo({{"No buf-marks set", "WarningMsg"}}, true, {})
    return
  end

  local current_path = vim.api.nvim_buf_get_name(0)
  for i, mark in ipairs(mark_list) do
    if mark.path == current_path then
      local target = mark_list[((i - 1 - count) % #mark_list) + 1]
      T.goto(target.char)
      return
    end
  end

  -- Current buffer has no mark; jump to the last mark
  T.goto(mark_list[#mark_list].char)
end

-- Returns all marks (working directory and global) as a table
T.list = function()
  read_global_marks()
  return vim.tbl_extend('keep', marks, global_marks)
end

-- Returns formatted mark lines for a given path (or current marks if nil).
-- Returns a list of strings suitable for display in a buffer or preview.
T.format_marks = function(path)
  local mark_list
  if path then
    local abs_path = vim.fn.fnamemodify(path, ':p'):gsub('/$', '')
    local storage_path = T.get_storage_file_path(abs_path)
    local data = T.read_storage_file(storage_path)
    if not data or not data.marks then
      return {}
    end
    mark_list = {}
    for char, file_path in pairs(data.marks) do
      table.insert(mark_list, {char = char, path = file_path})
    end
    table.sort(mark_list, function(a, b) return T.mark_comparator(a.char, b.char) end)
  else
    mark_list = sorted_marks()
  end

  if #mark_list == 0 then
    return {}
  end

  local lines = {}
  for _, mark in ipairs(mark_list) do
    local display_path = vim.fn.fnamemodify(mark.path, ':~:.')
    table.insert(lines, string.format(" %s    %s", mark.char, display_path))
  end
  return lines
end

-- Lists all marks with pretty formatting
T.list_pretty = function(path)
  local lines = T.format_marks(path)

  if #lines == 0 then
    vim.api.nvim_echo({{"No buf-marks set", "WarningMsg"}}, true, {})
    return
  end

  local output = {
    {"mark  file", "Title"},
    {"\n" .. table.concat(lines, "\n"), "Normal"}
  }
  vim.api.nvim_echo(output, true, {})
end

T.setup = function(opts)
  opts = opts or {}

  -- Update configuration
  T.config.persist = opts.persist or true

  -- Load existing marks if persistence is enabled
  if T.config.persist then
    T.load_marks()  -- defaults: path=cwd, force=true, rebase=false
    read_global_marks()
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
