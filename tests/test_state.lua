local state = require("tf.state")
local state_ui = require("tf.state_ui")
local util = require("tf.util")
local Config = require("tf.config")

local saved = {}

local function reset_stubs()
  Config.reset()
  vim.fn.jobstart = saved.jobstart
  vim.fn.jobstop = saved.jobstop
  vim.fn.executable = saved.executable
  util.find_root = saved.util_find_root
  state.find_root = saved.state_find_root
  state.is_terraform_available = saved.is_available
  if saved.buf and vim.api.nvim_buf_is_valid(saved.buf) then
    vim.api.nvim_buf_delete(saved.buf, { force = true })
  end
end

local T = MiniTest.new_set()

T["tf.state_ui helpers"] = MiniTest.new_set()

T["tf.state_ui helpers"]["applies filters respecting case sensitivity"] = function()
  local helpers = state_ui._test
  local resources = {
    "aws_instance.app",
    "google_compute.instance",
    "azurerm_resource_group.rg",
  }

  local insensitive = helpers.apply_filter(resources, "AWS", { case_sensitive = false })
  MiniTest.expect.equality(insensitive, { "aws_instance.app" })

  local sensitive = helpers.apply_filter(resources, "AWS", { case_sensitive = true })
  MiniTest.expect.equality(sensitive, {})
end

T["tf.state_ui helpers"]["extracts headline and splits lines"] = function()
  local helpers = state_ui._test
  MiniTest.expect.equality(helpers.first_nonempty_line("\n  error: boom\nmore"), "error: boom")
  MiniTest.expect.equality(
    helpers.first_nonempty_line(
      '╷\n│ Error: Backend initialization required, please run "terraform init"\n│ with backend bucket\n╵'
    ),
    'Error: Backend initialization required, please run "terraform init"'
  )
  MiniTest.expect.equality(helpers.split_lines("one\ntwo"), { "one", "two" })
end

return T
