local util = require("tf.util")

local T = MiniTest.new_set()

T["tf.util"] = MiniTest.new_set()
T["tf.util"]["notification"] = MiniTest.new_set()

T["tf.util"]["notification"]["sends info notification"] = function()
  local called = false
  local saved_notify = vim.notify
  vim.notify = function(msg, level, opts)
    called = true
    MiniTest.expect.equality(msg, "test message")
    MiniTest.expect.equality(level, vim.log.levels.INFO)
    MiniTest.expect.equality(opts.title, "tf.nvim")
  end

  util.notify("test message", "info")
  MiniTest.expect.equality(called, true)

  vim.notify = saved_notify
end

T["tf.util"]["notification"]["sends warn notification"] = function()
  local saved_notify = vim.notify
  vim.notify = function(msg, level, opts)
    MiniTest.expect.equality(level, vim.log.levels.WARN)
  end

  util.notify("test warning", "warn")
  vim.notify = saved_notify
end

T["tf.util"]["notification"]["sends error notification"] = function()
  local saved_notify = vim.notify
  vim.notify = function(msg, level, opts)
    MiniTest.expect.equality(level, vim.log.levels.ERROR)
  end

  util.notify("test error", "error")
  vim.notify = saved_notify
end

T["tf.util"]["command_to_string"] = MiniTest.new_set()

T["tf.util"]["command_to_string"]["converts table to string"] = function()
  local cmd = { "terraform", "validate", "-no-color" }
  MiniTest.expect.equality(util.command_to_string(cmd), "terraform validate -no-color")
end

T["tf.util"]["command_to_string"]["returns empty string for nil"] = function()
  MiniTest.expect.equality(util.command_to_string(nil), "")
end

T["tf.util"]["command_to_string"]["returns string as-is"] = function()
  MiniTest.expect.equality(util.command_to_string("terraform validate"), "terraform validate")
end

T["tf.util"]["sanitize_cli_lines"] = MiniTest.new_set()

T["tf.util"]["sanitize_cli_lines"]["removes border characters"] = function()
  local text = "╷\n│ Error: something went wrong\n│ with details\n╵"
  local lines = util.sanitize_cli_lines(text)

  MiniTest.expect.equality(#lines, 2)
  MiniTest.expect.equality(lines[1], "Error: something went wrong")
  MiniTest.expect.equality(lines[2], "with details")
end

T["tf.util"]["sanitize_cli_lines"]["handles empty text"] = function()
  local lines = util.sanitize_cli_lines("")
  MiniTest.expect.equality(#lines, 0)
end

T["tf.util"]["sanitize_cli_lines"]["handles nil text"] = function()
  local lines = util.sanitize_cli_lines(nil)
  MiniTest.expect.equality(#lines, 0)
end

T["tf.util"]["sanitize_cli_lines"]["trims whitespace"] = function()
  local text = "  line with spaces  \n  another line  "
  local lines = util.sanitize_cli_lines(text)

  MiniTest.expect.equality(#lines, 2)
  MiniTest.expect.equality(lines[1], "line with spaces")
  MiniTest.expect.equality(lines[2], "another line")
end

T["tf.util"]["summarize_cli"] = MiniTest.new_set()

T["tf.util"]["summarize_cli"]["returns first line as summary"] = function()
  local text = "Error: init required\nPlease run terraform init"
  local summary, lines = util.summarize_cli(text)

  MiniTest.expect.equality(summary, "Error: init required")
  MiniTest.expect.equality(#lines, 2)
end

T["tf.util"]["summarize_cli"]["handles empty text"] = function()
  local summary, lines = util.summarize_cli("")

  MiniTest.expect.equality(summary, "unknown error")
  MiniTest.expect.equality(#lines, 0)
end

T["tf.util"]["flatten_cli_lines"] = MiniTest.new_set()

T["tf.util"]["flatten_cli_lines"]["joins lines with spaces"] = function()
  local lines = { "Error:", "init", "required" }
  MiniTest.expect.equality(util.flatten_cli_lines(lines), "Error: init required")
end

T["tf.util"]["flatten_cli_lines"]["handles empty array"] = function()
  MiniTest.expect.equality(util.flatten_cli_lines({}), "")
end

T["tf.util"]["flatten_cli_lines"]["handles nil"] = function()
  MiniTest.expect.equality(util.flatten_cli_lines(nil), "")
end

return T
