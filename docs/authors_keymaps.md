# Author's Keymaps

Switching buffers is one of the most frequent actions in a Neovim workflow, so the keymaps for it should be as
ergonomic as possible. This keymap configuration lets you jump to a specific buffer in just 2 keystrokes.

It works by repurposing keybindings that I find less useful in practice. I rarely use local marks since most of
the time I mark a few locations per session and want to jump to them from any buffer, making global marks the
better fit. Similarly, Vim's automatic marks 1-9 (which track progressively older exit positions) require
remembering what was open when you last quit Vim, which I never do. Mark 0 (last exit location) is sometimes
helpful, though.

By reassigning the local mark and automatic mark 1-9 keybindings to buf-marks, buffer navigation becomes a quick
2-keystroke operation while still preserving access to global marks and Vim's
[automatic marks](./using_native_marks.md#automatic-marks) (`` `'".^[]<> ``)

## Keymap Strategy

- `m{lowercase1-9}` - Set buf-mark
- `m{uppercase}` - Set global mark (normal behavior)
- `'{lowercase1-9}` - Goto buf-mark
- `'{uppercase}` - Goto global mark (normal behavior)
- `'{other}` - Goto automatic mark (normal behavior)
- `'?` - List all buf-marks
- `'/` - Load buf-marks from another worktree
- `';` - Load buf-marks from another project
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
-- '{other} to goto automatic mark
vim.keymap.set(
  'n',
  "'",
  function()
    local char = vim.fn.getcharstr()
    if char:match("[%l1-9]") then
      -- goto a buf-mark
      require('buf-mark').goto(char)
    else
      -- goto a global mark or automatic mark
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
  require("buf-mark.fzf_lua").picker,
  -- require("buf-mark.telescope").picker,
  -- require('buf-mark').list_pretty,
  { desc = 'List buf-marks' }
)

-- '/ to load buf-marks from another worktree
vim.keymap.set(
  'n',
  "'/",
  require("buf-mark.fzf_lua").worktree_picker,
  -- require("buf-mark.telescope").worktree_picker,
  { desc = 'Load buf-marks from worktree' }
)

-- '; to load buf-marks from another project
vim.keymap.set(
  'n',
  "';",
  require("buf-mark.fzf_lua").project_picker,
  -- require("buf-mark.telescope").project_picker,
  { desc = 'Load buf-marks from project' }
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
