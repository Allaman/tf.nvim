local clipboard = require("tf.clipboard")

describe("tf.clipboard", function()
  local saved_setreg

  before_each(function()
    saved_setreg = vim.fn.setreg
  end)

  after_each(function()
    vim.fn.setreg = saved_setreg
  end)

  it("copies to + register successfully", function()
    local calls = {}
    vim.fn.setreg = function(reg, text)
      table.insert(calls, { reg = reg, text = text })
      return 1
    end

    local ok, method = clipboard.copy("test text")
    assert.is_true(ok)
    assert.equals("+", method)
    assert.equals(1, #calls)
    assert.equals("+", calls[1].reg)
    assert.equals("test text", calls[1].text)
  end)

  it("falls back to * register if + fails", function()
    local calls = {}
    vim.fn.setreg = function(reg, text)
      table.insert(calls, { reg = reg, text = text })
      if reg == "+" then
        error("+ register not available")
      end
      return 1
    end

    local ok, method = clipboard.copy("test text")
    assert.is_true(ok)
    assert.equals("*", method)
    assert.equals(2, #calls)
    assert.equals("+", calls[1].reg)
    assert.equals("*", calls[2].reg)
  end)

  it("handles empty text", function()
    local ok, method = clipboard.copy("")
    -- Empty text should return false as it's not valid content to copy
    assert.is_false(ok)
    assert.is_nil(method)
  end)

  it("handles nil text gracefully", function()
    local ok, method = clipboard.copy(nil)
    assert.is_false(ok)
    assert.is_nil(method)
  end)
end)
