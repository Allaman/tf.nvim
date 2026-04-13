local clipboard = require("tf.clipboard")

local T = MiniTest.new_set()

local saved_setreg

T["tf.clipboard"] = MiniTest.new_set({
  hooks = {
    pre_case = function()
      saved_setreg = vim.fn.setreg
    end,
    post_case = function()
      vim.fn.setreg = saved_setreg
    end,
  },
})

T["tf.clipboard"]["copies to + register successfully"] = function()
  local calls = {}
  vim.fn.setreg = function(reg, text)
    table.insert(calls, { reg = reg, text = text })
    return 1
  end

  local ok, method = clipboard.copy("test text")
  MiniTest.expect.equality(ok, true)
  MiniTest.expect.equality(method, "+")
  MiniTest.expect.equality(#calls, 1)
  MiniTest.expect.equality(calls[1].reg, "+")
  MiniTest.expect.equality(calls[1].text, "test text")
end

T["tf.clipboard"]["falls back to * register if + fails"] = function()
  local calls = {}
  vim.fn.setreg = function(reg, text)
    table.insert(calls, { reg = reg, text = text })
    if reg == "+" then
      error("+ register not available")
    end
    return 1
  end

  local ok, method = clipboard.copy("test text")
  MiniTest.expect.equality(ok, true)
  MiniTest.expect.equality(method, "*")
  MiniTest.expect.equality(#calls, 2)
  MiniTest.expect.equality(calls[1].reg, "+")
  MiniTest.expect.equality(calls[2].reg, "*")
end

T["tf.clipboard"]["handles empty text"] = function()
  local ok, method = clipboard.copy("")
  -- Empty text should return false as it's not valid content to copy
  MiniTest.expect.equality(ok, false)
  MiniTest.expect.equality(method, nil)
end

T["tf.clipboard"]["handles nil text gracefully"] = function()
  local ok, method = clipboard.copy(nil)
  MiniTest.expect.equality(ok, false)
  MiniTest.expect.equality(method, nil)
end

return T
