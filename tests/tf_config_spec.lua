local Config = require("tf.config")

describe("tf.config", function()
  before_each(function()
    Config.reset()
  end)

  it("returns default configuration", function()
    local config = Config.get()
    assert.is_table(config)
    assert.is_table(config.terraform)
    assert.equals("terraform", config.terraform.bin)
    assert.is_table(config.doc)
    assert.equals("copy", config.doc.default_action)
  end)

  it("extends configuration with user options", function()
    Config.extend({
      terraform = { bin = "/custom/terraform" },
      doc = { default_action = "open" },
    })

    local config = Config.get()
    assert.equals("/custom/terraform", config.terraform.bin)
    assert.equals("open", config.doc.default_action)
  end)

  it("deep merges nested configuration", function()
    Config.extend({
      state = {
        window = { mode = "float" },
      },
    })

    local config = Config.get()
    assert.equals("float", config.state.window.mode)
    -- Should preserve other defaults
    assert.is_table(config.state.window.split)
    assert.is_table(config.state.window.float)
  end)

  it("resets to defaults", function()
    Config.extend({ terraform = { bin = "/custom/terraform" } })
    assert.equals("/custom/terraform", Config.get().terraform.bin)

    Config.reset()
    assert.equals("terraform", Config.get().terraform.bin)
  end)

  it("validates window mode", function()
    local ok, err = pcall(function()
      Config.extend({
        state = { window = { mode = "invalid_mode" } },
      })
    end)

    assert.is_false(ok)
    assert.is_truthy(err:match("Invalid state.window.mode"))
  end)

  it("validates default_action", function()
    local ok, err = pcall(function()
      Config.extend({
        doc = { default_action = "invalid" },
      })
    end)

    assert.is_false(ok)
    assert.is_truthy(err:match("Invalid doc.default_action"))
  end)

  it("validates float dimensions", function()
    local ok, err = pcall(function()
      Config.extend({
        state = { window = { float = { width = 1.5 } } },
      })
    end)

    assert.is_false(ok)
    assert.is_truthy(err:match("Invalid state.window.float.width"))
  end)

  it("accepts valid float dimensions", function()
    local ok = pcall(function()
      Config.extend({
        state = { window = { float = { width = 0.7, height = 0.8 } } },
      })
    end)

    assert.is_true(ok)
    local config = Config.get()
    assert.equals(0.7, config.state.window.float.width)
    assert.equals(0.8, config.state.window.float.height)
  end)

  it("returns copy of defaults", function()
    local defaults1 = Config.defaults()
    local defaults2 = Config.defaults()

    assert.are_not.equal(defaults1, defaults2) -- Different tables
    assert.same(defaults1, defaults2) -- Same content
  end)

  it("preserves unmodified config sections", function()
    local original_filetypes = vim.deepcopy(Config.get().filetypes)

    Config.extend({
      terraform = { bin = "/custom/terraform" },
    })

    assert.same(original_filetypes, Config.get().filetypes)
  end)
end)
