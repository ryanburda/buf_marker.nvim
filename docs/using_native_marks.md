# Using Native Marks

Marks in Vim natively support jumping between buffers while preserving cursor location.

## A Quick Overview of Marks

### Local marks
Local marks are bookmarks that work within a single buffer.
  - Created using lowercase letters (a-z): `ma`, `mb`, etc.
  - Jump to a local mark with `'a` (single quote) or `` `a ``
  - Remembers the exact position (line and column) within
  the current buffer
  - Only accessible within the buffer where they were set
  - Lost when the buffer is deleted

### Global Marks
Global marks are bookmarks that work across different files.
  - Created using uppercase letters (A-Z): `mA`, `mB`, etc.
  - Jump to a global mark with `'A` (single quote) or `` `A ``
  - Remembers both the file and the exact position (line and column)
  - Can jump to them from any buffer

### Automatic Marks
Vim automatically keeps track of several marks for you.
  - `'` - Position before the latest jump within the current file
  - `` ` `` - Position of the cursor when last editing this file
  - `"` - Position where the cursor was when last exiting the file
  - `[` - First character of previously changed or yanked text
  - `]` - Last character of previously changed or yanked text
  - `<` - First character of last visual selection
  - `>` - Last character of last visual selection
  - `^` - Position where the cursor was last time when Insert mode was stopped
  - `.` - Position of last change

### Difference between `'` and `` ` `` when jumping to marks
Backtick (`` `{mark} ``) jumps to the exact position (line and column) where the mark was set, while
single quote (`'{mark}`) jumps to the first non-blank character of that line.
- Use backtick for precise positioning
- Use single quote when you only care about getting to the right line

**Example:**

Suppose you have a line of code with indentation:
```
    const myVariable = "hello world";
          ^
```
And you set mark `a` when your cursor is on the `m` in `myVariable` (shown by `^`).

- `` `a `` - Jumps directly to the `m` character (column 10)
- `'a` - Jumps to the `c` in `const` (first non-blank character on that line, column 4)

Both commands take you to the same line, but backtick preserves the exact column position while single quote moves to the start of the actual content.

## Solution 1
This means we can use a combination of:
- Global marks (A-Z)
- The `"` mark
- precise positioning, `` ` ``, when jumping to marks

to jump between buffers while preserving cursor location.

For example:
  - `mA` to set global mark `A`
  - `` 'A`" `` to jump to the buffer marked by `A` at the last cursor position
    - `'A` jumps to global mark `A`
    - `` `" `` jumps to the exact cursor position when last exiting the file

#### Problems
Jumping between buffers should be easy since we plan on doing it often. This
solution of typing `` '{mark}`" `` requires a bit of keyboard gymnastics.

... we can do better

## Solution 2
We can create a keymap to make `` '{mark}'` `` more ergonomic.

There are several ways this can be done. The following maps `<leader>'` to jump to a global mark and
automatically restore cursor position.

```lua
vim.keymap.set(
  'n',
  "<leader>'",
  function()
    -- Get the next character that is typed
    local char = vim.fn.getcharstr()

    -- Only handle uppercase (global) marks
    if not char:match("%u") then
      return
    end

    -- Go to mark
    local ok, err = pcall(vim.cmd, "normal! '" .. char)
    if not ok then
      local vim_err = err:match("Vim%([^)]+%):(.*)") or err
      vim.api.nvim_echo({{vim_err, "ErrorMsg"}}, true, {})
      return
    end

    -- Go to the position where the cursor was when last exiting the file
    vim.api.nvim_feedkeys('`"', 'n', false)
  end,
  { desc = 'Go to buffer' }
)
```

Here's what it does:

1. Captures the next character: When you press `<leader>'`, it waits for you to type a mark character (like `A`).
2. Ignores non-uppercase characters, since only global marks (A-Z) are used for cross-buffer navigation.
3. Jumps to the specified global mark.
4. Error handling: If the mark doesn't exist, it catches the error and displays a cleaned-up error message.
5. After jumping to the mark's line, it executes `` `" `` which jumps to the exact position where the
cursor was when you last exited that file.

## Then why use `buf-mark`?

If marks work just fine, why should I use this plugin?
 
Sometimes the simple solution is the best solution. The solutions above acomplish
what most people need and is what I recommend for simple cases.

One thing I find a bit tricky about global marks is how they are persisted between nvim instances.
While, global marks are not shared between different running instances of Vim (a good thing),
they are persisted to the `.viminfo` (or `.shada` for Neovim) file **when you quit Vim**. When you
start a new Vim instance, it reads the global marks from this file, which creates the appearance
of sharing marks across sessions - but it's actually sequential persistence, not real-time sharing.

Key points:
- During runtime: Two simultaneously running Vim instances do not share marks in real-time.
Each has its own independent mark state.
- Between sessions: Global marks are saved when you quit Vim and loaded when you start Vim,
so marks set in one session will be available in the next session (but only after the previous
instance has exited and written to viminfo).
- Conflicts: If you run two Vim instances simultaneously and set different global marks in each,
**whichever instance quits last will have its marks saved to viminfo**, potentially overwriting marks
set by the other instance.

`buf-mark` solves this problem by persisting buf-marks across sessions on a working directory level.
This means buf-marks made in `~/project_a` are separate from `~/project_b` which is a more intuitive 
and predictable default when your workflow involves having a Neovim instance open per project.

`buf-mark` also:
- ships with UI integrations like [status](../README.md#status)
- provides a buffer marking solution that is **not** built upon marks so that marks can continue
to be used in the way they were intended
