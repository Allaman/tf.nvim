local util = require("tf.util")

describe("tf.util", function()
  describe("notification", function()
    it("sends info notification", function()
      local called = false
      local saved_notify = vim.notify
      vim.notify = function(msg, level, opts)
        called = true
        assert.equals("test message", msg)
        assert.equals(vim.log.levels.INFO, level)
        assert.equals("tf.nvim", opts.title)
      end

      util.notify("test message", "info")
      assert.is_true(called)

      vim.notify = saved_notify
    end)

    it("sends warn notification", function()
      local saved_notify = vim.notify
      vim.notify = function(msg, level, opts)
        assert.equals(vim.log.levels.WARN, level)
      end

      util.notify("test warning", "warn")
      vim.notify = saved_notify
    end)

    it("sends error notification", function()
      local saved_notify = vim.notify
      vim.notify = function(msg, level, opts)
        assert.equals(vim.log.levels.ERROR, level)
      end

      util.notify("test error", "error")
      vim.notify = saved_notify
    end)
  end)

  describe("command_to_string", function()
    it("converts table to string", function()
      local cmd = { "terraform", "validate", "-no-color" }
      assert.equals("terraform validate -no-color", util.command_to_string(cmd))
    end)

    it("returns empty string for nil", function()
      assert.equals("", util.command_to_string(nil))
    end)

    it("returns string as-is", function()
      assert.equals("terraform validate", util.command_to_string("terraform validate"))
    end)
  end)

  describe("sanitize_cli_lines", function()
    it("removes border characters", function()
      local text = "╷\n│ Error: something went wrong\n│ with details\n╵"
      local lines = util.sanitize_cli_lines(text)

      assert.equals(2, #lines)
      assert.equals("Error: something went wrong", lines[1])
      assert.equals("with details", lines[2])
    end)

    it("handles empty text", function()
      local lines = util.sanitize_cli_lines("")
      assert.equals(0, #lines)
    end)

    it("handles nil text", function()
      local lines = util.sanitize_cli_lines(nil)
      assert.equals(0, #lines)
    end)

    it("trims whitespace", function()
      local text = "  line with spaces  \n  another line  "
      local lines = util.sanitize_cli_lines(text)

      assert.equals(2, #lines)
      assert.equals("line with spaces", lines[1])
      assert.equals("another line", lines[2])
    end)
  end)

  describe("summarize_cli", function()
    it("returns first line as summary", function()
      local text = "Error: init required\nPlease run terraform init"
      local summary, lines = util.summarize_cli(text)

      assert.equals("Error: init required", summary)
      assert.equals(2, #lines)
    end)

    it("handles empty text", function()
      local summary, lines = util.summarize_cli("")

      assert.equals("unknown error", summary)
      assert.equals(0, #lines)
    end)
  end)

  describe("flatten_cli_lines", function()
    it("joins lines with spaces", function()
      local lines = { "Error:", "init", "required" }
      assert.equals("Error: init required", util.flatten_cli_lines(lines))
    end)

    it("handles empty array", function()
      assert.equals("", util.flatten_cli_lines({}))
    end)

    it("handles nil", function()
      assert.equals("", util.flatten_cli_lines(nil))
    end)
  end)
end)
