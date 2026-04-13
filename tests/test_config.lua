local Config = require("tf.config")

local T = MiniTest.new_set()

T["tf.config"] = MiniTest.new_set({
  hooks = {
    pre_case = function()
      Config.reset()
    end,
  },
})

T["tf.config"]["returns default configuration"] = function()
  local config = Config.get()
  MiniTest.expect.equality(type(config), "table")
  MiniTest.expect.equality(type(config.terraform), "table")
  MiniTest.expect.equality(config.terraform.bin, "terraform")
  MiniTest.expect.equality(type(config.doc), "table")
  MiniTest.expect.equality(config.doc.default_action, "copy")
end

T["tf.config"]["extends configuration with user options"] = function()
  Config.extend({
    terraform = { bin = "/custom/terraform" },
    doc = { default_action = "open" },
  })

  local config = Config.get()
  MiniTest.expect.equality(config.terraform.bin, "/custom/terraform")
  MiniTest.expect.equality(config.doc.default_action, "open")
end

T["tf.config"]["deep merges nested configuration"] = function()
  Config.extend({
    state = {
      window = { mode = "float" },
    },
  })

  local config = Config.get()
  MiniTest.expect.equality(config.state.window.mode, "float")
  -- Should preserve other defaults
  MiniTest.expect.equality(type(config.state.window.split), "table")
  MiniTest.expect.equality(type(config.state.window.float), "table")
end

T["tf.config"]["resets to defaults"] = function()
  Config.extend({ terraform = { bin = "/custom/terraform" } })
  MiniTest.expect.equality(Config.get().terraform.bin, "/custom/terraform")

  Config.reset()
  MiniTest.expect.equality(Config.get().terraform.bin, "terraform")
end

T["tf.config"]["validates window mode"] = function()
  MiniTest.expect.error(function()
    Config.extend({
      state = { window = { mode = "invalid_mode" } },
    })
  end, "Invalid state.window.mode")
end

T["tf.config"]["validates default_action"] = function()
  MiniTest.expect.error(function()
    Config.extend({
      doc = { default_action = "invalid" },
    })
  end, "Invalid doc.default_action")
end

T["tf.config"]["validates float dimensions"] = function()
  MiniTest.expect.error(function()
    Config.extend({
      state = { window = { float = { width = 1.5 } } },
    })
  end, "Invalid state.window.float.width")
end

T["tf.config"]["accepts valid float dimensions"] = function()
  MiniTest.expect.no_error(function()
    Config.extend({
      state = { window = { float = { width = 0.7, height = 0.8 } } },
    })
  end)

  local config = Config.get()
  MiniTest.expect.equality(config.state.window.float.width, 0.7)
  MiniTest.expect.equality(config.state.window.float.height, 0.8)
end

T["tf.config"]["returns copy of defaults"] = function()
  local defaults1 = Config.defaults()
  local defaults2 = Config.defaults()

  -- Different table objects
  MiniTest.expect.equality(defaults1 ~= defaults2, true)
  -- Same content
  MiniTest.expect.equality(defaults1, defaults2)
end

T["tf.config"]["preserves unmodified config sections"] = function()
  local original_filetypes = vim.deepcopy(Config.get().filetypes)

  Config.extend({
    terraform = { bin = "/custom/terraform" },
  })

  MiniTest.expect.equality(Config.get().filetypes, original_filetypes)
end

return T
