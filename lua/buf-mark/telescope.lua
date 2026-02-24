local T = {}

local function get_file_icon(filename)
  local ok, devicons = pcall(require, "nvim-web-devicons")
  if ok then
    return devicons.get_icon(filename, nil, { default = true })
  end
  local ok2, mini_icons = pcall(require, "mini.icons")
  if ok2 then
    local _, icon, hl = mini_icons.get("file", filename)
    return icon, hl
  end
  return nil, nil
end

T.picker = function(opts)
  opts = opts or {}

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local previewers = require("telescope.previewers")
  local from_entry = require("telescope.from_entry")
  local entry_display = require("telescope.pickers.entry_display")
  local buf_mark = require("buf-mark")

  local marks = buf_mark.list()

  -- Collect and sort marks alphabetically
  local mark_list = {}
  for char, path in pairs(marks) do
    table.insert(mark_list, { char = char, path = path })
  end
  table.sort(mark_list, function(a, b) return a.char < b.char end)

  if #mark_list == 0 then
    vim.api.nvim_echo({ { "No buf-marks set", "WarningMsg" } }, true, {})
    return
  end

  local current_buf_path = vim.api.nvim_buf_get_name(0)

  -- Resolve cursor positions for each mark
  for _, mark in ipairs(mark_list) do
    local line = 1
    local col = 1

    if mark.path == current_buf_path then
      -- Current buffer: use live cursor position (BufLeave hasn't fired yet)
      local pos = vim.api.nvim_win_get_cursor(0)
      line = pos[1]
      col = pos[2] + 1
    else
      -- Other buffers: use saved cursor position from BufLeave autocmd
      local bufnr = vim.fn.bufnr(mark.path)
      if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
        local buf_mark_data = vim.b[bufnr].buf_mark
        if buf_mark_data and buf_mark_data.last_cursor_position then
          line = buf_mark_data.last_cursor_position[1]
          col = buf_mark_data.last_cursor_position[2] + 1
        end
      end
    end

    mark.line = line
    mark.col = col
  end

  local has_icons = get_file_icon("x") ~= nil

  local displayer = entry_display.create(has_icons
    and {
      separator = " ",
      items = {
        { width = 4 },
        { width = 2 },
        { remaining = true },
      },
    }
    or {
      separator = "    ",
      items = {
        { width = 1 },
        { remaining = true },
      },
    })

  local make_display = function(entry)
    local display_path = vim.fn.fnamemodify(entry.value.path, ":~:.")
    if has_icons then
      local file_icon, icon_hl = get_file_icon(vim.fn.fnamemodify(entry.value.path, ":t"))
      return displayer({
        entry.value.char,
        { file_icon or "", icon_hl },
        display_path,
      })
    end
    return displayer({
      entry.value.char,
      display_path,
    })
  end

  pickers.new(opts, {
    prompt_title = "Buf-marks (<ctrl-x> to delete)",

    finder = finders.new_table({
      results = mark_list,
      entry_maker = function(item)
        return {
          value = item,
          display = make_display,
          ordinal = item.char .. " " .. vim.fn.fnamemodify(item.path, ":~:."),
          path = item.path,
          lnum = item.line,
          col = item.col,
        }
      end,
    }),

    sorter = conf.generic_sorter(opts),

    previewer = previewers.new_buffer_previewer({
      title = "Buf-Mark Preview",
      define_preview = function(self, entry)
        local filepath = from_entry.path(entry, true, false)
        if not filepath or filepath == "" then
          return
        end
        conf.buffer_previewer_maker(filepath, self.state.bufnr, {
          bufname = self.state.bufname,
          winid = self.state.winid,
          preview = opts.preview,
          callback = function(bufnr)
            if entry.lnum and entry.lnum > 0 then
              pcall(vim.api.nvim_buf_add_highlight,
                bufnr, -1, "TelescopePreviewLine", entry.lnum - 1, 0, -1)
              pcall(vim.api.nvim_win_set_cursor,
                self.state.winid, { entry.lnum, 0 })
              vim.api.nvim_buf_call(bufnr, function()
                vim.cmd("norm! zz")
              end)
            end
          end,
        })
      end,
    }),

    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection then
          buf_mark.goto(selection.value.char)
        end
      end)

      map({ "i", "n" }, "<C-x>", function()
        local selection = action_state.get_selected_entry()
        if selection then
          buf_mark.delete(selection.value.char)
          actions.close(prompt_bufnr)
          vim.schedule(function()
            T.picker(opts)
          end)
        end
      end)

      return true
    end,
  }):find()
end

return T
