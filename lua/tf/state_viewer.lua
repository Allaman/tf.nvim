--- StateViewer instance - manages a single state viewer window
local StateViewer = {}
StateViewer.__index = StateViewer

local state = require("tf.state")
local clipboard = require("tf.clipboard")
local util = require("tf.util")
local Config = require("tf.config")

--- Create a new StateViewer instance
--- @return table StateViewer instance
function StateViewer:new()
  local instance = setmetatable({}, StateViewer)
  instance.bufnr = nil
  instance.winid = nil
  instance.resources = {}
  instance.display_resources = {}
  instance.root = nil
  instance.resource_offset = 3
  instance.refresh_token = 0
  instance.source_bufnr = nil
  instance.filter = nil
  return instance
end

--- Get configuration
local function state_config()
  return Config.get().state
end

local function detail_config()
  return state_config().detail or {}
end

local function window_config()
  return state_config().window or {}
end

local function filter_case_sensitive()
  local cfg = state_config()
  local filter = cfg.filter or {}
  return filter.case_sensitive or false
end

--- Update buffer lines
function StateViewer:update_buffer_lines(lines)
  if not self.bufnr or not vim.api.nvim_buf_is_valid(self.bufnr) then
    return
  end

  vim.api.nvim_set_option_value("modifiable", true, { buf = self.bufnr })
  vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = self.bufnr })
end

--- Get or create the state buffer
function StateViewer:get_or_create_buffer()
  if self.bufnr and vim.api.nvim_buf_is_valid(self.bufnr) then
    return self.bufnr
  end

  self.bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = self.bufnr })
  vim.api.nvim_set_option_value("bufhidden", "hide", { buf = self.bufnr })
  vim.api.nvim_set_option_value("swapfile", false, { buf = self.bufnr })
  vim.api.nvim_buf_set_name(self.bufnr, "TerraformState_" .. self.bufnr)
  vim.api.nvim_set_option_value("filetype", "terraform-state", { buf = self.bufnr })
  vim.api.nvim_set_option_value("modifiable", false, { buf = self.bufnr })

  return self.bufnr
end

--- Get resource at cursor position
function StateViewer:get_resource_at_cursor()
  if not self.bufnr or not vim.api.nvim_buf_is_valid(self.bufnr) then
    return nil
  end

  local line = vim.api.nvim_win_get_cursor(0)[1]
  if line <= self.resource_offset then
    return nil
  end

  local index = line - self.resource_offset
  return self.display_resources[index]
end

--- Apply filter to resources
function StateViewer:apply_filter(resources)
  if not self.filter or self.filter == "" then
    return vim.deepcopy(resources)
  end

  local filter = self.filter
  local case_sensitive = filter_case_sensitive()
  if not case_sensitive then
    filter = filter:lower()
  end

  local result = {}
  for _, resource in ipairs(resources) do
    local value = resource
    if not case_sensitive then
      value = resource:lower()
    end
    if value:find(filter, 1, true) then
      result[#result + 1] = resource
    end
  end

  return result
end

--- Set filter value
function StateViewer:set_filter(value)
  if value and value ~= "" then
    self.filter = value
  else
    self.filter = nil
  end
end

--- Render the state buffer
function StateViewer:render()
  if not self.bufnr or not vim.api.nvim_buf_is_valid(self.bufnr) then
    return
  end

  self.display_resources = self:apply_filter(self.resources)

  local header = { "Terraform State Resources" }
  if self.root then
    header[#header + 1] = string.format("Root: %s", self.root)
  end
  if self.filter and self.filter ~= "" then
    header[#header + 1] = string.format("Filter: %s", self.filter)
  end
  header[#header + 1] = string.format("Showing: %d of %d resources", #self.display_resources, #self.resources)

  local lines = vim.deepcopy(header)
  lines[#lines + 1] = ""

  -- Set offset AFTER adding the blank line to account for it
  self.resource_offset = #lines

  if #self.display_resources == 0 then
    if #self.resources == 0 then
      lines[#lines + 1] = "No resources in state"
    else
      lines[#lines + 1] = "No resources matched current filter"
    end
  else
    for _, resource in ipairs(self.display_resources) do
      lines[#lines + 1] = resource
    end
  end

  self:update_buffer_lines(lines)
end

--- Prompt for filter input
function StateViewer:prompt_filter()
  local default = self.filter or ""
  local viewer = self

  local function apply(input)
    if input == nil then
      return
    end
    local cleaned = vim.trim(input)
    viewer:set_filter(cleaned ~= "" and cleaned or nil)
    viewer:render()
  end

  if vim.ui and vim.ui.input then
    vim.schedule(function()
      vim.ui.input({ prompt = "Filter resources", default = default }, apply)
    end)
  else
    local ok, result = pcall(vim.fn.input, "Filter resources: ", default)
    if ok then
      apply(result)
    end
  end
end

--- Clear filter
function StateViewer:clear_filter()
  if not self.filter then
    util.notify("Filter already cleared", "info")
    return
  end
  self:set_filter(nil)
  util.notify("Cleared state filter", "info")
  self:render()
end

--- Copy resource address to clipboard
function StateViewer:yank_resource()
  local resource = self:get_resource_at_cursor()
  if not resource then
    util.notify("No resource under cursor", "warn")
    return
  end

  local ok, method = clipboard.copy(resource)
  if ok then
    local suffix = ""
    if method and method ~= "" then
      suffix = string.format(" (%s)", method)
    end
    util.notify(string.format("Copied state address%s: %s", suffix, resource), "info")
  else
    util.notify("Failed to copy resource address", "error")
  end
end

--- Open state window
function StateViewer:open_window(bufnr)
  local window_cfg = window_config()

  self.winid = util.create_window(bufnr, window_cfg)

  if self.winid and vim.api.nvim_win_is_valid(self.winid) then
    vim.api.nvim_set_option_value("number", true, { win = self.winid })
    vim.api.nvim_set_option_value("relativenumber", false, { win = self.winid })
    vim.api.nvim_set_option_value("cursorline", true, { win = self.winid })
  end
end

--- Show resource detail
function StateViewer:show_resource_detail()
  local resource = self:get_resource_at_cursor()
  if not resource then
    util.notify("No resource under cursor", "warn")
    return
  end

  local job_name = string.format("state_show_%s", self.bufnr or "unknown")

  local viewer = self
  state.show_resource(resource, function(success, output, err)
    if not success then
      util.notify(string.format("Failed to show resource: %s", err or "unknown error"), "error")
      return
    end

    vim.schedule(function()
      vim.cmd("split")
      local detail_bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_win_set_buf(0, detail_bufnr)

      vim.api.nvim_set_option_value("buftype", "nofile", { buf = detail_bufnr })
      vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = detail_bufnr })
      vim.api.nvim_set_option_value("swapfile", false, { buf = detail_bufnr })
      vim.api.nvim_set_option_value("modifiable", true, { buf = detail_bufnr })

      local lines = vim.split(output or "", "\n", { plain = true })
      vim.api.nvim_buf_set_lines(detail_bufnr, 0, -1, false, lines)
      vim.api.nvim_set_option_value("modifiable", false, { buf = detail_bufnr })

      local trimmed = vim.trim(output or "")
      local filetype = (trimmed:match("^%s*[%[{]") and "json") or "terraform"
      vim.api.nvim_set_option_value("filetype", filetype, { buf = detail_bufnr })

      local detail_opts = detail_config()
      if detail_opts.folds then
        local method = detail_opts.foldmethod or "indent"
        vim.api.nvim_set_option_value("foldmethod", method, { win = 0 })
        vim.api.nvim_set_option_value("foldenable", true, { win = 0 })
        vim.api.nvim_set_option_value("foldlevel", 0, { win = 0 })
        vim.cmd("normal! zM")
      else
        vim.api.nvim_set_option_value("foldenable", false, { win = 0 })
      end

      vim.api.nvim_buf_set_keymap(detail_bufnr, "n", "q", ":close<CR>", {
        noremap = true,
        silent = true,
        desc = "Close detail window",
      })
    end)
  end, { start_path = self.root, bufnr = self.source_bufnr, job_name = job_name })
end

--- Delete resource from state
function StateViewer:delete_resource()
  local resource = self:get_resource_at_cursor()
  if not resource then
    util.notify("No resource under cursor", "warn")
    return
  end

  local confirm = vim.fn.confirm(
    string.format("Remove '%s' from terraform state?\n\nWARNING: This will not destroy infrastructure.", resource),
    "&Yes\n&No",
    2
  )

  if confirm ~= 1 then
    util.notify("Cancelled", "info")
    return
  end

  local job_name = string.format("state_rm_%s", self.bufnr or "unknown")

  local viewer = self
  state.remove_resource(resource, function(success, err)
    if not success then
      util.notify(string.format("Failed to remove resource: %s", err or "unknown error"), "error")
      return
    end

    util.notify(string.format("Removed '%s' from state", resource), "info")
    viewer:refresh()
  end, { start_path = self.root, bufnr = self.source_bufnr, job_name = job_name })
end

--- Show help window
function StateViewer:show_help()
  local help_lines = {
    "Terraform State Viewer - Help",
    "",
    "Core:",
    "  <CR>/<Enter>  Show detailed state",
    "  y            Copy resource address",
    "  d            Delete resource",
    "  r            Refresh state",
    "",
    "Filtering:",
    "  f            Prompt for substring filter",
    "  F            Clear filter",
    "  /            Use Vim search",
    "",
    "Misc:",
    "  g?           Show this help",
    "  q            Close viewer",
    "",
    "Press q to close this help",
  }

  vim.cmd("split")
  local help_bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(0, help_bufnr)

  vim.api.nvim_set_option_value("buftype", "nofile", { buf = help_bufnr })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = help_bufnr })
  vim.api.nvim_set_option_value("swapfile", false, { buf = help_bufnr })
  vim.api.nvim_set_option_value("modifiable", true, { buf = help_bufnr })
  vim.api.nvim_buf_set_lines(help_bufnr, 0, -1, false, help_lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = help_bufnr })

  vim.api.nvim_buf_set_keymap(help_bufnr, "n", "q", ":close<CR>", {
    noremap = true,
    silent = true,
    nowait = true,
  })
end

--- Setup keymaps for the state viewer
function StateViewer:setup_keymaps(bufnr)
  local opts = { noremap = true, silent = true, buffer = bufnr, nowait = true }
  local viewer = self

  vim.keymap.set("n", "<CR>", function()
    viewer:show_resource_detail()
  end, vim.tbl_extend("force", opts, { desc = "Show resource detail" }))

  vim.keymap.set("n", "<Enter>", function()
    viewer:show_resource_detail()
  end, vim.tbl_extend("force", opts, { desc = "Show resource detail" }))

  vim.keymap.set("n", "y", function()
    viewer:yank_resource()
  end, vim.tbl_extend("force", opts, { desc = "Copy resource address" }))

  vim.keymap.set("n", "d", function()
    viewer:delete_resource()
  end, vim.tbl_extend("force", opts, { desc = "Delete resource" }))

  vim.keymap.set("n", "r", function()
    viewer:refresh()
  end, vim.tbl_extend("force", opts, { desc = "Refresh state" }))

  vim.keymap.set("n", "f", function()
    viewer:prompt_filter()
  end, vim.tbl_extend("force", opts, { desc = "Filter resources" }))

  vim.keymap.set("n", "F", function()
    viewer:clear_filter()
  end, vim.tbl_extend("force", opts, { desc = "Clear filter" }))

  vim.keymap.set("n", "q", function()
    if viewer.winid and vim.api.nvim_win_is_valid(viewer.winid) then
      vim.api.nvim_win_close(viewer.winid, false)
    end
    viewer:close()
  end, vim.tbl_extend("force", opts, { desc = "Close state viewer" }))

  vim.keymap.set("n", "g?", function()
    viewer:show_help()
  end, vim.tbl_extend("force", opts, { desc = "Show help" }))
end

--- Refresh the state list
function StateViewer:refresh()
  if not self.bufnr or not vim.api.nvim_buf_is_valid(self.bufnr) then
    return
  end

  self.refresh_token = self.refresh_token + 1
  local token = self.refresh_token

  self:update_buffer_lines({
    "Terraform State Resources",
    "Loading terraform state...",
  })

  local job_name = string.format("state_list_%s", self.bufnr or "unknown")

  local viewer = self
  state.list_resources(function(success, resources, err, ctx)
    if token ~= viewer.refresh_token then
      return
    end

    vim.schedule(function()
      if not viewer.bufnr or not vim.api.nvim_buf_is_valid(viewer.bufnr) then
        return
      end

      if not success then
        local summary = util.sanitize_cli_lines(err)[1] or err or "unknown error"
        viewer.root = (ctx and ctx.root) or viewer.root
        util.notify(string.format("Failed to list terraform state: %s", summary), "error")
        return
      end

      viewer.root = (ctx and ctx.root) or viewer.root
      viewer.resources = resources or {}
      viewer:render()
    end)
  end, { start_path = self.root, bufnr = self.source_bufnr, job_name = job_name })
end

--- Close the state viewer and clean up
function StateViewer:close()
  -- Prevent any pending callbacks from updating after close
  self.refresh_token = self.refresh_token + 1

  -- Clean up all references
  self.resources = nil
  self.display_resources = nil
  self.filter = nil
  self.root = nil
  self.source_bufnr = nil
  self.winid = nil
  self.bufnr = nil
end

return StateViewer
