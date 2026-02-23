# Author's Keymaps

This document describes an alternative keymap configuration that I prefer, which may serve as inspiration for your own setup.

## Philosophy

In typical Neovim usage, I rarely find myself using local marks. Most of the time I mark a few locations per
session and want to be able to jump to those marks from any buffer. This is why I generally prefer global marks.

Similarly, I don't find Vim's special marks 1-9 (which keep track of progressively older exit positions) useful
since they require remembering location that was up at the time you quit vim. Mark 0 (last exit location) however
is sometimes helpful.

This keymap configuration repurposes the local mark and special mark 1-9 keybindings for buf-marks instead,
making buffer navigation more ergonomic while still preserving navigation to vim's
[special marks](https://vimhelp.org/motion.txt.html#mark-motions) (`` `'".^[]<> ``)

## Keymap Strategy

- `m{lowercase1-9}` - Set buf-mark
- `m{uppercase}` - Set global mark (normal behavior)
- `'{lowercase1-9}` - Goto buf-mark
- `'{uppercase}` - Goto global mark (normal behavior)
- `'{other}` - Goto special mark (normal behavior)
- `'?` - List all buf-marks
- `'<Tab>` - Jump to alternate buffer
- `<leader>m{char}` - Set a native local mark (fallback for local marks if needed)
- `<leader>'{char}` - Jump to a native local mark (fallback for local marks if needed)

## Implementation

```lua
-- m{lowercase1-9} to set buf-mark
-- m{uppercase} to set global mark
vim.keymap.set(
  'n',
  'm',
  function()
    local char = vim.fn.getcharstr()
    if char:match("[%l1-9]") then
      -- set a buf-mark
      require('buf-mark').set(char)
    else
      -- set a global mark
      local ok, err = pcall(vim.cmd, 'normal! m' .. char)
      if not ok then
        local vim_err = err:match("Vim%([^)]+%):(.*)") or err
        vim.api.nvim_echo({{vim_err, "ErrorMsg"}}, true, {})
      end
    end
  end,
  { desc = 'Set buf-mark/global mark' }
)

-- '{lowercase1-9} to goto buf-mark
-- '{uppercase} to goto global mark
-- '{other} to goto special mark
vim.keymap.set(
  'n',
  "'",
  function()
    local char = vim.fn.getcharstr()
    if char:match("[%l1-9]") then
      -- goto a buf-mark
      require('buf-mark').goto(char)
    else
      -- goto a global mark or special mark
      local ok, err = pcall(vim.cmd, "normal! '" .. char)
      if not ok then
        local vim_err = err:match("Vim%([^)]+%):(.*)") or err
        vim.api.nvim_echo({{vim_err, "ErrorMsg"}}, true, {})
      end
    end
  end,
  { desc = 'Goto buf-mark/global mark' }
)

-- '? to list buf-marks
vim.keymap.set(
  'n',
  "'?",
  require('buf-mark').list_pretty,
  -- require("buf-mark.fzf_lua").picker,
  -- require("buf-mark.telescope").picker,
  { desc = 'List buf-marks' }
)

-- '<Tab> to jump to alternate buffer
vim.keymap.set(
  'n',
  "'<Tab>",
  ':b#<cr>',
  { desc = 'Alternate buffer' }
)

-- Keep keymaps around for local marks just in case.
-- m{char} to set native mark
vim.keymap.set(
  'n',
  '<leader>m',
  function()
    local char = vim.fn.getcharstr()
    -- set mark
    local ok, err = pcall(vim.cmd, 'normal! m' .. char)
    if not ok then
      local vim_err = err:match("Vim%([^)]+%):(.*)") or err
      vim.api.nvim_echo({{vim_err, "ErrorMsg"}}, true, {})
    end
  end,
  { desc = 'Set mark' }
)

-- '{char} to goto native mark
vim.keymap.set(
  'n',
  "<leader>'",
  function()
    local char = vim.fn.getcharstr()
    -- goto mark
    local ok, err = pcall(vim.cmd, "normal! '" .. char)
    if not ok then
      local vim_err = err:match("Vim%([^)]+%):(.*)") or err
      vim.api.nvim_echo({{vim_err, "ErrorMsg"}}, true, {})
    end
  end,
  { desc = 'Goto mark' }
)
```

## Setup Configuration

When using this keymap approach, disable the default keymaps in your buf-mark setup:

```lua
require("buf-mark").setup({
  keymaps = false,  -- Disable default keymaps
  persist = true,
})
```
