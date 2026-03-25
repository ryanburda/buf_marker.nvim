local T = {}

T.setup = function()
  local buf_mark = require('buf-mark')

  -- Register the :BufMarkList command
  vim.api.nvim_create_user_command('BufMarkList', function()
    buf_mark.list_pretty()
  end, { desc = 'List all buffer marks' })

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

  -- Register the :BufMarkDeleteAll command
  vim.api.nvim_create_user_command('BufMarkDeleteAll', function()
    buf_mark.delete_all()
  end, { desc = 'Delete all buffer marks for current project' })

end

return T
