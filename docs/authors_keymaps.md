# Author's Keymaps

Switching buffers is one of the most frequent actions in a Neovim workflow, so the keymaps for it should be as
ergonomic as possible. This keymap configuration lets you jump to a specific buffer in just 2 keystrokes.

It works by repurposing `s` and `S` for buf-mark setting and jumping.

**NOTE:** Remapping `s` means you lose the default "delete character and enter insert mode" behavior
(`s` is equivalent to `cl`). Similarly, `S` normally deletes the entire line and enters insert mode
(equivalent to `cc`). If you use [vim-sneak](https://github.com/justinmk/vim-sneak) or
[leap.nvim](https://github.com/ggandor/leap.nvim), note that these plugins also remap `s`/`S`.

## Keymap Strategy

- `S{char}` - Set buf-mark
- `s{char}` - Goto buf-mark
- `s?` - List all buf-marks
- `s[` - Previous buf-mark
- `s]` - Next buf-mark
- `s/` - Load buf-marks from another worktree
- `s'` - Load buf-marks from another working directory
- `s;` - Jump to alternate buffer

## Implementation

```lua
-- Characters reserved for dedicated s{char} keymaps below.
-- The s mapping ignores these so the dedicated keymaps can fire.
local reserved = { ['?'] = true, ['/'] = true, [';'] = true, ["'"] = true, ['['] = true, [']'] = true }

-- S{char} to set buf-mark
vim.keymap.set(
  'n',
  'S',
  function()
    local char = vim.fn.getcharstr()
    require('buf-mark').set(char)
  end,
  { desc = 'Set buf-mark' }
)

-- s{char} to goto buf-mark
vim.keymap.set(
  'n',
  's',
  function()
    local char = vim.fn.getcharstr()
    if reserved[char] then
      -- Feed back as s{char} so the dedicated keymap fires
      vim.api.nvim_feedkeys('s' .. char, 'm', false)
      return
    end
    require('buf-mark').goto(char)
  end,
  { desc = 'Goto buf-mark' }
)

-- s? to list buf-marks
vim.keymap.set(
  'n',
  's?',
  require("buf-mark.fzf_lua").picker,
  -- require("buf-mark.telescope").picker,
  -- require('buf-mark').list_pretty,
  { desc = 'List buf-marks' }
)

-- s[ to go to previous buf-mark
vim.keymap.set(
  'n',
  's[',
  require('buf-mark').prev,
  { desc = 'Previous buf-mark' }
)

-- s] to go to next buf-mark
vim.keymap.set(
  'n',
  's]',
  require('buf-mark').next,
  { desc = 'Next buf-mark' }
)

-- s/ to load buf-marks from another worktree
vim.keymap.set(
  'n',
  's/',
  require("buf-mark.fzf_lua").worktree_picker,
  -- require("buf-mark.telescope").worktree_picker,
  { desc = 'Load buf-marks from worktree' }
)

-- s' to load buf-marks from another working directory
vim.keymap.set(
  'n',
  "s'",
  require("buf-mark.fzf_lua").project_picker,
  -- require("buf-mark.telescope").project_picker,
  { desc = 'Load buf-marks from working directory' }
)

-- s; to jump to alternate buffer
vim.keymap.set(
  'n',
  's;',
  ':b#<cr>',
  { desc = 'Alternate buffer' }
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
