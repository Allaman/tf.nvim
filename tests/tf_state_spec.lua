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

describe("tf.state_ui helpers", function()
  it("applies filters respecting case sensitivity", function()
    local util = state_ui._test
    local resources = {
      "aws_instance.app",
      "google_compute.instance",
      "azurerm_resource_group.rg",
    }

    local insensitive = util.apply_filter(resources, "AWS", { case_sensitive = false })
    assert.are.same({ "aws_instance.app" }, insensitive)

    local sensitive = util.apply_filter(resources, "AWS", { case_sensitive = true })
    assert.are.same({}, sensitive)
  end)

  it("extracts headline and splits lines", function()
    local util = state_ui._test
    assert.equals("error: boom", util.first_nonempty_line("\n  error: boom\nmore"))
    assert.equals(
      'Error: Backend initialization required, please run "terraform init"',
      util.first_nonempty_line(
        '╷\n│ Error: Backend initialization required, please run "terraform init"\n│ with backend bucket\n╵'
      )
    )
    assert.are.same({ "one", "two" }, util.split_lines("one\ntwo"))
  end)
end)
