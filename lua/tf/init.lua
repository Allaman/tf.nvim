local M = {}

local providers = require("tf.providers")
local state_ui = require("tf.state_ui")
local state = require("tf.state")
local validate_runner = require("tf.validate")
local doc_runner = require("tf.doc")
local util = require("tf.util")
local Config = require("tf.config")

--- Check if terraform is available in PATH
--- @return boolean
local function is_terraform_available()
  return vim.fn.executable(Config.get().terraform.bin) == 1
end

M.config = Config.get()

--- Setup function for plugin configuration
--- @param opts table|nil
M.setup = function(opts)
  opts = opts or {}

  -- Merge user configuration
  local cfg = Config.extend(opts)
  M.config = cfg

  -- Merge custom providers
  if cfg.doc.providers then
    providers.merge_providers(cfg.doc.providers)
  end

  -- Register user commands
  vim.api.nvim_create_user_command("TerraformDoc", function()
    M.open_doc()
  end, {
    desc = "Open Terraform documentation for resource/data under cursor",
  })

  vim.api.nvim_create_user_command("TerraformDocCopy", function()
    M.open_doc("copy")
  end, {
    desc = "Copy Terraform documentation URL to clipboard",
  })

  vim.api.nvim_create_user_command("TerraformDocOpen", function()
    M.open_doc("open")
  end, {
    desc = "Open Terraform documentation in browser",
  })

  vim.api.nvim_create_user_command("TerraformState", function()
    M.open_state()
  end, {
    desc = "Open Terraform state viewer",
  })

  vim.api.nvim_create_user_command("TerraformValidate", function()
    M.validate()
  end, {
    desc = "Run terraform validate in the current project root",
  })
end

--- Main function to parse block and handle documentation URL
--- @param action string|nil -- "copy" or "open" or nil
function M.open_doc(action)
  doc_runner.open(action)
end

--- Open terraform state viewer
function M.open_state()
  state_ui.open()
end

--- Run terraform validate in detected project root
function M.validate()
  if not is_terraform_available() then
    util.notify("terraform command not found in PATH", "error")
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local root = util.find_root({ bufnr = bufnr })

  if not root then
    util.notify("Not in a terraform directory", "warn")
    return
  end

  local progress_id = util.start_progress("validate", string.format("Running terraform validate (%s)", root))

  validate_runner.run(function(success, out, err, ctx)
    -- Ensure progress is always stopped, even if callback throws error
    local cleanup_ok, _ = pcall(util.stop_progress, progress_id)
    if not cleanup_ok then
      -- Fallback: try to stop it anyway
      pcall(function()
        util.stop_progress(progress_id)
      end)
    end

    local project_root = (ctx and ctx.root) or root
    local cleaned_out = vim.trim(out or "")
    local cleaned_err = vim.trim(err or "")

    if success then
      local message = string.format("Terraform validate passed (%s)", project_root)
      if cleaned_out ~= "" then
        message = string.format("%s\n%s", message, cleaned_out)
      end
      util.notify(message, "info")
      return
    end

    local combined = cleaned_err
    if cleaned_out ~= "" then
      combined = combined ~= "" and (combined .. "\n\n" .. cleaned_out) or cleaned_out
    end

    if combined == "" then
      combined = "terraform validate failed with no output"
    end

    util.notify(string.format("Terraform validate failed (%s)\n%s", project_root, combined), "error")
  end, {
    bufnr = bufnr,
    start_path = root,
    job_name = "validate",
  })
end

return M
