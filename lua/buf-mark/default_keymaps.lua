local T = {}

T.setup = function()
  local buf_mark = require('buf-mark')

  -- <leader>m{char} set buf-mark
  vim.keymap.set(
    'n',
    '<leader>m',
    function()
      -- The next character typed will be the buffer mark character to use
      local char = vim.fn.getcharstr()
      buf_mark.set(char)
    end,
    { desc = 'BufMark: Set' }
  )

  -- <leader>'{char} goto buf-mark
  vim.keymap.set(
    'n',
    "<leader>'",
    function()
      -- The next character typed will be the buffer mark character to use
      local char = vim.fn.getcharstr()
      buf_mark.goto(char)
    end,
    { desc = 'BufMark: Goto' }
  )
end

return T
