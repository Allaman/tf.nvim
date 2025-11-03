local defaults = {
  filetypes = { "terraform", "tf", "terraform-vars", "tfvars", "hcl" },
  terraform = {
    bin = "terraform",
  },
  doc = {
    browser_command = nil,
    default_action = "copy",
    providers = {},
  },
  state = {
    filter = {
      case_sensitive = false,
    },
    detail = {
      folds = true,
      foldmethod = "indent",
    },
    window = {
      mode = "vsplit",
      split = {
        position = "botright",
        size = 80,
      },
      float = {
        width = 0.6,
        height = 0.8,
      },
      focus = true,
    },
  },
}

local config = vim.deepcopy(defaults)

local M = {}

--- Validate configuration options
--- @param opts table
--- @return boolean, string|nil
local function validate_config(opts)
  if not opts then
    return true
  end

  -- Validate window modes
  local valid_modes = { "split", "vsplit", "float" }

  if opts.state and opts.state.window and opts.state.window.mode then
    if not vim.tbl_contains(valid_modes, opts.state.window.mode) then
      return false, string.format("Invalid state.window.mode: '%s'. Must be one of: %s",
        opts.state.window.mode, table.concat(valid_modes, ", "))
    end
  end

  -- Validate default action
  if opts.doc and opts.doc.default_action then
    local valid_actions = { "copy", "open" }
    if not vim.tbl_contains(valid_actions, opts.doc.default_action) then
      return false, string.format("Invalid doc.default_action: '%s'. Must be one of: %s",
        opts.doc.default_action, table.concat(valid_actions, ", "))
    end
  end

  -- Validate float dimensions
  if opts.state and opts.state.window and opts.state.window.float then
    local float = opts.state.window.float
    if float.width and (type(float.width) ~= "number" or float.width <= 0 or float.width > 1) then
      return false, "Invalid state.window.float.width: Must be a number between 0 and 1"
    end
    if float.height and (type(float.height) ~= "number" or float.height <= 0 or float.height > 1) then
      return false, "Invalid state.window.float.height: Must be a number between 0 and 1"
    end
  end

  -- Validate terraform bin is a string
  if opts.terraform and opts.terraform.bin and type(opts.terraform.bin) ~= "string" then
    return false, "Invalid terraform.bin: Must be a string"
  end

  return true
end

--- Get the current configuration table.
--- @return table
function M.get()
  return config
end

--- Reset configuration to defaults.
function M.reset()
  for k in pairs(config) do
    config[k] = nil
  end
  local restored = vim.deepcopy(defaults)
  for k, v in pairs(restored) do
    config[k] = v
  end
  return config
end

--- Merge user options into the configuration.
--- @param opts table|nil
function M.extend(opts)
  if not opts then
    return config
  end

  local valid, err = validate_config(opts)
  if not valid then
    error(string.format("[tf.nvim] Configuration error: %s", err))
  end

  config = vim.tbl_deep_extend("force", config, opts)
  return config
end

--- Access the default configuration table.
--- @return table
function M.defaults()
  return vim.deepcopy(defaults)
end

return M
