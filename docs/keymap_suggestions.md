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

## Reserving Characters

The default keymaps use `<leader>m` and `<leader>'` as prefixes. Since these wait for a second
character via `vim.fn.getcharstr()`, every character you type after the prefix is consumed by
buf-mark. If you want certain characters to trigger their own dedicated keymaps instead (e.g.,
`<leader>'?` to open a picker, `<leader>'[` / `<leader>']` to cycle marks), you can check the
character against a reserved set and feed it back so the dedicated keymap fires:

```lua
local buf_mark = require('buf-mark')
local reserved = { [';'] = true, ['['] = true, [']'] = true, ['?'] = true, ['/'] = true, ["'"] = true  }

vim.keymap.set('n', "<leader>'", function()
  local char = vim.fn.getcharstr()
  if reserved[char] then
    vim.api.nvim_feedkeys("<leader>'" .. char, 'm', false)
    return
  end
  buf_mark.goto(char)
end, { desc = 'Goto buf-mark' })

-- Now these fire independently of the <leader>' mapping
vim.keymap.set('n', "<leader>';", ':b#<cr>', { desc = 'Alternate buffer' })

vim.keymap.set('n', "<leader>'[", buf_mark.prev, { desc = 'Previous buf-mark' })
-- vim.keymap.set('n', "<leader>'[", require('buf-mark.status').prev, { desc = 'Previous open buf-mark' })

vim.keymap.set('n', "<leader>']", buf_mark.next, { desc = 'Next buf-mark' })
-- vim.keymap.set('n', "<leader>']", require('buf-mark.status').next, { desc = 'Next open buf-mark' })

vim.keymap.set('n', "<leader>'?", require('buf-mark.fzf_lua').list, { desc = 'Fuzzy find buf-marks' })
-- vim.keymap.set('n', "<leader>'?", require('buf-mark.telescope').list, { desc = 'Fuzzy find buf-marks' })
-- vim.keymap.set('n', "<leader>'?", buf_mark.list_pretty, { desc = 'List buf-marks' })

vim.keymap.set('n', "<leader>'/", require('buf-mark.fzf_lua').worktrees, { desc = 'Fuzzy find worktrees' })
-- vim.keymap.set('n', "<leader>'/", require('buf-mark.telescope').worktrees, { desc = 'Fuzzy find worktrees' })

vim.keymap.set('n', "<leader>''", require('buf-mark.fzf_lua').projects, { desc = 'Fuzzy find projects' })
-- vim.keymap.set('n', "<leader>''", require('buf-mark.telescope').projects, { desc = 'Fuzzy find projects' })
```

## Using `s` as the Prefix (Author's preference)

Repurposing `s` and `S` gives you two-keystroke buf-mark access. `s{char}` jumps and `S{char}` sets.

**NOTE:** Remapping `s` means you lose the default "delete character and enter insert mode" behavior
(`s` is equivalent to `cl`). Similarly, `S` normally deletes the entire line and enters insert mode
(equivalent to `cc`). If you use [vim-sneak](https://github.com/justinmk/vim-sneak) or
[leap.nvim](https://github.com/ggandor/leap.nvim), note that these plugins also remap `s`/`S`.

```lua
---------------
-- Buf-marks --
---------------
-- `S{char}` - Set buf-mark
-- `s{char}` - Goto buf-mark
-- `s?` - List all buf-marks
-- `s[` - Previous buf-mark
-- `s]` - Next buf-mark
-- `s/` - Load buf-marks from another worktree
-- `s'` - Load buf-marks from another project
-- `s;` - Jump to alternate buffer

local buf_mark = require('buf-mark')
local reserved = { [';'] = true, ['['] = true, [']'] = true, ['?'] = true, ['/'] = true, ["'"] = true }

vim.keymap.set('n', 'S', function()
  buf_mark.set(vim.fn.getcharstr())
end, { desc = 'Set buf-mark' })

vim.keymap.set('n', 's', function()
  local char = vim.fn.getcharstr()
  if reserved[char] then
    vim.api.nvim_feedkeys('s' .. char, 'm', false)
    return
  end
  buf_mark.goto(char)
end, { desc = 'Goto buf-mark' })

vim.keymap.set('n', 's;', ':b#<cr>', { desc = 'Alternate buffer' })

-- vim.keymap.set('n', 's[', buf_mark.prev, { desc = 'Previous buf-mark' })
vim.keymap.set('n', 's[', require('buf-mark.status').prev, { desc = 'Previous open buf-mark' })

-- vim.keymap.set('n', 's]', buf_mark.next, { desc = 'Next buf-mark' })
vim.keymap.set('n', 's]', require('buf-mark.status').next, { desc = 'Next open buf-mark' })

vim.keymap.set('n', 's?', require('buf-mark.fzf_lua').list, { desc = 'Fuzzy find buf-marks' })
-- vim.keymap.set('n', 's?', require('buf-mark.telescope').list, { desc = 'Fuzzy find buf-marks' })
-- vim.keymap.set('n', 's?', buf_mark.list_pretty, { desc = 'List buf-marks' })

vim.keymap.set('n', 's/', require('buf-mark.fzf_lua').worktrees, { desc = 'Fuzzy find worktrees' })
-- vim.keymap.set('n', 's/', require('buf-mark.telescope').worktrees, { desc = 'Fuzzy find worktrees' })

vim.keymap.set('n', "s'", require('buf-mark.fzf_lua').projects, { desc = 'Fuzzy find projects' })
-- vim.keymap.set('n', "s'", require('buf-mark.telescope').projects, { desc = 'Fuzzy find projects' })
```

## Swapping Native Marks and Buf-marks

Native marks use `m{char}` to set and `'{char}` to jump. You can swap these so that the
unprefixed keys operate on buf-marks and the `<leader>`-prefixed keys fall back to native marks:

```lua
-- Buf-marks on the native mark keys
vim.keymap.set('n', 'm', function()
  require('buf-mark').set(vim.fn.getcharstr())
end, { desc = 'Set buf-mark' })

vim.keymap.set('n', "'", function()
  require('buf-mark').goto(vim.fn.getcharstr())
end, { desc = 'Goto buf-mark' })

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
