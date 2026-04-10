# Keymap Suggestions

The default keymaps use `<leader>m{char}` to set and `<leader>'{char}` to jump. These work fine,
but switching buffers is one of the most frequent actions in a Neovim workflow, so it's worth
experimenting to find what feels best for you. The following sections are meant as inspiration
for personalizing your keymaps, not as prescriptive setups.

When using any of the custom keymap approaches below, disable the default keymaps in your setup:

```lua
require("buf-mark").setup({
  keymaps = false,
  persist = true,
})
```

## Using `s` instead of `<leader>'` (Author's preference)

Repurposing `s` and `S` gives you two-keystroke buf-mark access. `s{char}` jumps and `S{char}` sets.

These keymaps also reserve some local buf-mark characters so they can be used to execute their own
dedicated functions (e.g., `s?` to list buf-marks) while still letting `sf`, for example, set a
buf-mark with character `f`.

**NOTE:** Remapping `s` means you lose the default "delete character and enter insert mode" behavior
(`s` is equivalent to `cl`). Similarly, `S` normally deletes the entire line and enters insert mode
(equivalent to `cc`). If you use [vim-sneak](https://github.com/justinmk/vim-sneak) or
[leap.nvim](https://github.com/ggandor/leap.nvim), note that these plugins also remap `s`/`S`.

```lua
---------------
-- Buf-marks --
---------------
-- `s;` - Jump to alternate buffer
-- `s?` - List all buf-marks
-- `s[` - Previous buf-mark
-- `s]` - Next buf-mark
-- `s/` - Load buf-marks from another worktree
-- `s'` - Load buf-marks from another project
-- `s"` - Unload buf-marks from another project
-- `S{char}` - Set buf-mark
-- `s{char}` - Goto buf-mark

local buf_mark = require('buf-mark')
local reserved = {}

reserved[';'] = true
vim.keymap.set('n', 's;', ':b#<cr>', { desc = 'Alternate buffer' })

reserved['?'] = true
vim.keymap.set('n', 's?', require('buf-mark.fzf_lua').list, { desc = 'List buf-marks' })
-- vim.keymap.set('n', 's?', require('buf-mark.telescope').list, { desc = 'List buf-marks' })
-- vim.keymap.set('n', 's?', buf_mark.list_pretty, { desc = 'List buf-marks' })

reserved['['] = true
vim.keymap.set('n', 's[', require('buf-mark.status').prev, { desc = 'Previous open buf-mark' })
-- vim.keymap.set('n', 's[', buf_mark.prev, { desc = 'Previous buf-mark' })

reserved[']'] = true
vim.keymap.set('n', 's]', require('buf-mark.status').next, { desc = 'Next open buf-mark' })
-- vim.keymap.set('n', 's]', buf_mark.next, { desc = 'Next buf-mark' })

reserved['/'] = true
vim.keymap.set('n', 's/', require('buf-mark.fzf_lua').load_worktree, { desc = 'Load buf-marks of another git worktree' })
-- vim.keymap.set('n', 's/', require('buf-mark.telescope').load_worktree, { desc = 'Load buf-marks of another git worktree' })

reserved["'"] = true
vim.keymap.set('n', "s'", require('buf-mark.fzf_lua').load_project, { desc = 'Load buf-marks of another project' })
-- vim.keymap.set('n', "s'", require('buf-mark.telescope').load_project, { desc = 'Load buf-marks of another project' })

reserved['"'] = true
vim.keymap.set('n', 's"', require('buf-mark.fzf_lua').unload_project, { desc = 'Unload buf-marks of another project' })
-- vim.keymap.set('n', 's"', require('buf-mark.telescope').unload_project, { desc = 'Unload buf-marks of another project' })

vim.keymap.set('n', 'S', function()
  local char = vim.fn.getcharstr()
  if reserved[char] then
    vim.api.nvim_echo({ { 'buf-mark: ' .. char .. ' is reserved', 'WarningMsg' } }, true, {})
    return
  end
  buf_mark.set(char)
end, { desc = 'Set buf-mark' })

vim.keymap.set('n', 's', function()
  local char = vim.fn.getcharstr()
  if reserved[char] then
    vim.api.nvim_feedkeys('s' .. char, 'm', false)
    return
  end
  buf_mark.goto(char)
end, { desc = 'Goto buf-mark' })
```

## Swapping Native Marks and Buf-marks

Native marks use `m{char}` to set and `'{char}` to jump. You can swap these so that the
unprefixed keys operate on buf-marks and the `<leader>`-prefixed keys fall back to native marks:

```lua
-- Buf-marks on the native mark keys
vim.keymap.set('n', 'm', require('buf-mark').set, { desc = 'Set buf-mark' })
vim.keymap.set('n', "'", require('buf-mark').goto, { desc = 'Goto buf-mark' })

-- Native marks behind leader
vim.keymap.set('n', '<leader>m', function()
  local char = vim.fn.getcharstr()
  vim.cmd('normal! m' .. char)
end, { desc = 'Set native mark' })

vim.keymap.set('n', "<leader>'", function()
  local char = vim.fn.getcharstr()
  vim.cmd("normal! '" .. char)
end, { desc = 'Goto native mark' })
```
