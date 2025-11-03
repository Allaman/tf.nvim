local M = {}

local StateViewer = require("tf.state_viewer")
local util = require("tf.util")
local Config = require("tf.config")

-- Track active viewer instance (singleton pattern)
local active_viewer = nil

--- Check if terraform is available in PATH
--- @return boolean
local function is_terraform_available()
  return vim.fn.executable(Config.get().terraform.bin) == 1
end

function M.configure(opts)
  if not opts then
    return
  end
  Config.extend({ state = opts })
end

--- Close the active viewer if one exists
local function close_active_viewer()
  if active_viewer then
    active_viewer:close()
    active_viewer = nil
  end
end

--- Open terraform state viewer
function M.open()
  if not is_terraform_available() then
    util.notify("terraform command not found in PATH", "error")
    return
  end

  local source_bufnr = vim.api.nvim_get_current_buf()
  local root = util.find_root({ bufnr = source_bufnr })

  if not root then
    util.notify("Not in a terraform directory", "warn")
    return
  end

  -- Close any existing viewer before creating a new one
  close_active_viewer()

  -- Create new state viewer instance
  local viewer = StateViewer:new()
  viewer.source_bufnr = source_bufnr
  viewer.root = root

  local bufnr = viewer:get_or_create_buffer()
  viewer:open_window(bufnr)
  viewer:setup_keymaps(bufnr)

  -- Set up buffer autocmd to clean up when buffer is deleted
  vim.api.nvim_create_autocmd("BufDelete", {
    buffer = bufnr,
    once = true,
    callback = function()
      if active_viewer and active_viewer.bufnr == bufnr then
        close_active_viewer()
      end
    end,
  })

  -- Track as the active viewer
  active_viewer = viewer

  viewer:refresh()
end

--- Helper functions exposed for testing
M._test = {
  apply_filter = function(resources, filter, opts)
    local viewer = StateViewer:new()
    opts = opts or {}

    if opts.case_sensitive ~= nil then
      local state_opts = Config.get().state
      state_opts.filter = state_opts.filter or {}
      state_opts.filter.case_sensitive = opts.case_sensitive
    end

    viewer:set_filter(filter)
    return viewer:apply_filter(resources)
  end,
  first_nonempty_line = function(value)
    local lines = util.sanitize_cli_lines(value)
    return lines[1]
  end,
  split_lines = function(value)
    if not value or value == "" then
      return {}
    end
    return vim.split(value, "\n", { plain = true })
  end,
}

return M
