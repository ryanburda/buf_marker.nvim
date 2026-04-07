local T = {}

T.setup = function()
  local buf_mark = require('buf-mark')

  -- Register the :BufMarkList command
  vim.api.nvim_create_user_command('BufMarkList', function(opts)
    local path = opts.args ~= '' and opts.args or nil
    buf_mark.list_pretty(path)
  end, { nargs = '?', complete = 'dir', desc = 'List all buffer marks (optionally for a given working directory)' })

  -- Register the :BufMarkSet command
  vim.api.nvim_create_user_command('BufMarkSet', function(opts)
    buf_mark.set(opts.args)
  end, { nargs = 1, desc = 'Set buffer mark for character' })

  -- Register the :BufMarkDelete command
  vim.api.nvim_create_user_command('BufMarkDelete', function(opts)
    buf_mark.delete(opts.args)
  end, { nargs = 1, desc = 'Delete buffer mark for character' })

  -- Register the :BufMarkGoto command
  vim.api.nvim_create_user_command('BufMarkGoto', function(opts)
    buf_mark.goto(opts.args)
  end, { nargs = 1, desc = 'Go to buffer mark for character' })

  -- Register the :BufMarkNext command
  vim.api.nvim_create_user_command('BufMarkNext', function(opts)
    buf_mark.next(opts.count)
  end, { count = 1, desc = 'Go to next buffer mark' })

  -- Register the :BufMarkPrev command
  vim.api.nvim_create_user_command('BufMarkPrev', function(opts)
    buf_mark.prev(opts.count)
  end, { count = 1, desc = 'Go to previous buffer mark' })

  -- Register the :BufMarkGetStoragePath command
  vim.api.nvim_create_user_command('BufMarkGetStoragePath', function(opts)
    local path = opts.args ~= '' and opts.args or nil
    local storage_path = buf_mark.get_storage_file_path(path)
    vim.api.nvim_echo({{storage_path, "Normal"}}, true, {})
  end, { nargs = '?', complete = 'dir', desc = 'Print the storage file path for a working directory' })

  -- Register the :BufMarkRemoveStorageFile command
  vim.api.nvim_create_user_command('BufMarkRemoveStorageFile', function(opts)
    buf_mark.remove_storage_file(opts.args)
  end, { nargs = 1, complete = 'dir', desc = 'Delete the storage file for a working directory' })

end

return T
