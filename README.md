# buf-mark

A Neovim plugin that provides vim-like marks for buffers.

![](./docs/buf-mark.gif)

Buf-marks turn buffer switching into muscle memory by assigning meaningful, mnemonic characters to buffers.

Mark your:
- `init.lua` with `i`
- `main.go` with `m`
- or your `README.md` with `r`

In doing so you create a personal shorthand that becomes a stable part of your workflow
in a way that's faster than fuzzy finding and more intentional than cycling.

### Features

- Buf-marks are persisted per working directory
- Supports migrating buf-marks between git worktrees
- Integrates with fuzzy finders like Telescope and fzf-lua
- Provides a status module for displaying buf-marks in statusline or tabline

### Differences from Native Vim Marks

| Feature | native marks | buf-marks |
|---------|------------------|----------|
| **Navigation** | Jump to fixed line/column | Jump to buffer + restore last cursor position |
| **Persistence** | Saved globally in shada file, shared across all sessions | Persisted per working directory |
| **Use Case** | Bookmarking locations within files | Quick buffer switching |

## Usage

The default keymaps mirror native marks but are prefixed with `<leader>`:

| keymap | function |
|--------|----------|
| `<leader>m{char}` | Set buf-mark `{char}` for the current buffer |
| `<leader>'{char}` | Jump to buf-mark `{char}` |

### Example Workflow

1. Open a file (e.g., `init.lua`)
2. Press `<leader>mi` to mark the current buffer with character `i`
3. Navigate to another file
4. Press `<leader>'i` to go back to `init.lua` where you left it
5. Close and reopen Neovim to find your marks are still there


## Installation

### [vim.pack](https://neovim.io/doc/user/pack.html) (Neovim 0.12+)

```lua
vim.pack.add({ 'https://github.com/ryanburda/buf-mark' })
require("buf-mark").setup()
```

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "ryanburda/buf-mark",
  config = function()
    require("buf-mark").setup()
  end,
}
```

### Setup Options

```lua
require("buf-mark").setup({
  -- Set to true to enable default keymaps
  keymaps = true,
  -- Set to true to persist marks between Neovim sessions.
  -- Marks will be saved per working directory
  -- (e.g., marks in ~/project-a are separate from ~/project-b)
  persist = true,
  -- Customize the optional status highlight groups. (See Status section of README for more details)
  -- By default, the status module uses `StatusLine` for the current buffer's mark
  -- and `StatusLineNC` for marks of non-current buffers. You can customize these
  -- highlight groups to match your colorscheme or configuration.
  status = {
    hl_current = 'StatusLine',       -- Highlight group for current buffer's mark
    hl_non_current = 'StatusLineNC', -- Highlight group for non-current buffers' marks
  }
})
```

For an alternative keymap configuration that repurposes native local mark keybindings for
buf-marks, see [Author's Keymap Preferences](docs/authors_keymaps.md).

### Optional Dependencies

- [fzf-lua](https://github.com/ibhagwan/fzf-lua) - Required if using fzf-lua pickers
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) - Required if using telescope pickers
- [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) or [mini.icons](https://github.com/echasnovski/mini.icons) - Colored file type icons in the pickers. Falls back gracefully if neither is installed.


## Usage

### User Commands

> #### `:BufMarkList`
> 
> Lists all buf-marks with their associated files. The output displays:
> - Mark character
> - File path (relative to current directory)
> 
> Example output:
> ```
> mark  file
>  a    src/config.lua
>  b    README.md
>  c    path/to/file.txt
> ```
> 
> #### `:BufMarkSet <char>`
> 
> Set a buf-mark for the current buffer using the specified character.
> 
> **Example:**
> ```
> :BufMarkSet a
> ```
> 
> #### `:BufMarkDelete <char>`
> 
> Delete the buf-mark for the specified character.
> 
> **Example:**
> ```
> :BufMarkDelete a
> ```
> 
> #### `:BufMarkGoto <char>`
> 
> Jump to the buffer associated with the specified mark character.
> 
> **Example:**
> ```
> :BufMarkGoto a
> ```
> 
> #### `:BufMarkNext [count]`
>
> Jump to the next buf-mark in sorted order. Wraps around to the first mark after the last. If the current buffer has no mark, jumps to the first mark.
>
> **Examples:**
> ```
> :BufMarkNext
> :BufMarkNext 3
> ```
>
> #### `:BufMarkPrev [count]`
>
> Jump to the previous buf-mark in sorted order. Wraps around to the last mark before the first. If the current buffer has no mark, jumps to the last mark.
>
> **Examples:**
> ```
> :BufMarkPrev
> :BufMarkPrev 2
> ```
>
> #### `:BufMarkDeleteAll`
>
> Delete all buf-marks for the current project. This will clear all marks in the current working directory if buf-marks are being persisted.
>
> **Example:**
> ```
> :BufMarkDeleteAll
> ```
>
> #### `:BufMarkGetStoragePath [path]`
>
> Print the storage file path for a working directory. Defaults to the current working directory if no path is provided.
>
> **Examples:**
> ```
> :BufMarkGetStoragePath
> :BufMarkGetStoragePath ~/code/my-project
> ```
>
> #### `:BufMarkRemoveStorageFile <path>`
>
> Delete the storage file for a working directory. This removes all persisted buf-marks for the given directory.
>
> **Example:**
> ```
> :BufMarkRemoveStorageFile ~/code/my-project
> ```

### Lua API

> #### `setup(opts)`
> 
> Initialize the plugin with optional configuration.
> 
> **Parameters:**
> - `opts` (table, optional): Configuration options
>   - `keymaps` (boolean): Enable/disable default keymaps (default: `true`)
>   - `persist` (boolean): Enable mark persistence between sessions, saved per working directory (default: `true`)
>   - `status` (table, optional): Status module configuration
>     - `hl_current` (string): Highlight group for current buffer's mark (default: `'StatusLine'`)
>     - `hl_non_current` (string): Highlight group for non-current buffers' marks (default: `'StatusLineNC'`)
> 
> **Example:**
> ```lua
> require("buf-mark").setup({
>   keymaps = true,
>   persist = true,
>   status = {
>     hl_current = 'StatusLine',
>     hl_non_current = 'StatusLineNC',
>   }
> })
> ```
> 
> #### `list()`
> 
> Returns all buf-marks as a table mapping characters to file paths.
> 
> **Returns:**
> - `table`: A table where keys are mark characters and values are file paths
> 
> **Example:**
> ```lua
> local marks = require("buf-mark").list()
> for char, path in pairs(marks) do
>   print("Mark " .. char .. " -> " .. path)
> end
> ```
> 
> #### `list_pretty()`
> 
> Display all buf-marks with their associated buffer information in a formatted view.
> 
> **Example:**
> ```lua
> require("buf-mark").list_pretty()
> ```
> 
> #### `set(char)`
> 
> Set a buf-mark for the current buffer.
> 
> **Parameters:**
> - `char` (string): A single character to use as the mark identifier
> 
> **Example:**
> ```lua
> require("buf-mark").set('a')
> ```
> 
> #### `delete(char)`
> 
> Delete a buf-mark.
> 
> **Parameters:**
> - `char` (string): The mark character to delete
> 
> **Example:**
> ```lua
> require("buf-mark").delete('a')
> ```
> 
> #### `goto(char)`
> 
> Jump to the buffer associated with the given mark.
> 
> **Parameters:**
> - `char` (string): The mark character to jump to
> 
> **Example:**
> ```lua
> require("buf-mark").goto('a')
> ```
> 
> #### `next(count)`
>
> Jump to the next buf-mark in sorted order. Wraps around.
>
> **Parameters:**
> - `count` (number, optional): Number of marks to skip forward (default: `1`)
>
> **Example:**
> ```lua
> require("buf-mark").next()
> require("buf-mark").next(3)
> ```
>
> #### `prev(count)`
>
> Jump to the previous buf-mark in sorted order. Wraps around.
>
> **Parameters:**
> - `count` (number, optional): Number of marks to skip backward (default: `1`)
>
> **Example:**
> ```lua
> require("buf-mark").prev()
> require("buf-mark").prev(2)
> ```
>
> #### `delete_all()`
> 
> Delete all buf-marks for the current project.
> 
> **Example:**
> ```lua
> require("buf-mark").delete_all()
> ```
>
> #### `get_storage_path(path)`
>
> Get the storage file path for a given working directory.
>
> **Parameters:**
> - `path` (string, optional): The working directory to get the storage path for. Defaults to the current working directory.
>
> **Returns:**
> - `string`: The absolute path to the JSON storage file
>
> **Example:**
> ```lua
> local storage_path = require("buf-mark").get_storage_path()
> -- e.g. "~/.local/share/nvim/buf_mark/abc123...def.json"
> ```
>
> #### `remove_storage_file(path)`
>
> Delete the storage file for a given working directory. This removes all persisted buf-marks for that directory.
>
> **Parameters:**
> - `path` (string): The working directory whose storage file should be deleted
>
> **Example:**
> ```lua
> require("buf-mark").remove_storage_file("~/code/my-project")
> ```
>
> #### `load_marks(path, opts)`
>
> Load buf-marks from a given working directory.
>
> **Parameters:**
> - `path` (string, optional): Path to the source working directory. Defaults to the current working directory.
> - `opts` (table, optional): Options table
>   - `force` (boolean): When `true`, overwrite existing marks. (default: `true`)
>   - `rebase` (boolean): When `true`, rebase file paths from the source directory to the current working directory. (default: `false`)
>
> **Examples:**
> ```lua
> -- Load marks for the current working directory (used internally at startup)
> require("buf-mark").load_marks()
>
> -- Load marks from another project without overwriting, rebasing paths.
> -- This can be used to load the buf-marks of another worktree of the same project into the current worktree.
> require("buf-mark").load_marks("~/code/my-project/other_worktree", { force = false, rebase = true })
> ```

## Events

A `BufMarkChanged` event is fired whenever:
- a buf-mark is added or deleted
- the user enters or deletes a buffer. (`BufEnter`, `BufDelete`)

You can respond to this event by creating an autocommand like so:
```lua
vim.api.nvim_create_autocmd("User", { pattern = "BufMarkChanged", ... }))
```

**Use cases:**
- Implement custom mark visualization similar to [Status](#status) shown below
- Display notifications when marks change

## Status

### `buf-mark.status`

The `buf-mark.status` module provides a function to display buf-marks **for currently open buffers**.
This is useful for integrating buf-mark information into statuslines, tablines, or other UI components.
Marks are shown in alphabetical order with the mark of the current buffer highlighted.

![](./docs/status1.jpg)

![](./docs/status2.jpg)

**Why only show marks for open buffers?**

Over time, you'll accumulate marks for many buffers across a given project. Displaying all marks would create
visual clutter and make it harder to find the information you need. By showing only marks for currently open
buffers, the status display provides focus and context for the specific problem you're working on right now.
If you need to see all marks, you can list them separately using `:BufMarkList` or by using one of
the [fuzzy finder integrations](#fuzzy-finder-integrations)


#### Usage with statusline

```lua
vim.o.statusline = '%{%v:lua.require("buf-mark.status").get()%} %f %m'
```

#### Usage with lualine

```lua
require('lualine').setup({
  sections = {
    lualine_a = {require('buf-mark.status').get},
  }
})
```


## Fuzzy Finder Integrations

Buf-marks contains pickers for [fzf-lua](https://github.com/ibhagwan/fzf-lua) and
[telescope.nvim](https://github.com/nvim-telescope/telescope.nvim). Both pickers show a
file preview at the current cursor position and support `ctrl-x` to delete the selected mark.

No additional setup is required for either picker. If you have Fzf-lua or Telescope installed,
you can call the corresponding `picker` function directly. Calling the `picker` function for a
fuzzy finder that is not installed will result in an error.

### fzf-lua

```lua
-- Browse and jump to buf-marks
require("buf-mark.fzf_lua").picker()
-- Load buf-marks from another git worktree
require("buf-mark.fzf_lua").worktree_picker()
-- Load buf-marks from another project
require("buf-mark.fzf_lua").project_picker()
```

### telescope.nvim

```lua
-- Browse and jump to buf-marks
require("buf-mark.telescope").picker()
-- Load buf-marks from another git worktree
require("buf-mark.telescope").worktree_picker()
-- Load buf-marks from another project
require("buf-mark.telescope").project_picker()
```

The `worktree_picker` functions list other git worktrees that have saved buf-marks. Selecting a
worktree will load its marks into the current project, rebasing file paths so they point to the
current working directory. Existing marks are not overwritten.

The `project_picker` functions list all other projects that have saved buf-marks. Selecting a
project will load its marks into the current session using the original file paths (no rebasing).
Existing marks are not overwritten.

## Do I need this plugin?

Native Vim marks can actually be used to achieve similar buffer-switching behavior. For an alternative
that doesn't require a plugin, see [Using Native Marks](docs/using_native_marks.md).

**TLDR:** This plugin provides additional features like ergonomic keymaps, mark persistence across sessions,
and status line integrations, but the native marks approach may be sufficient for many workflows.


## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
