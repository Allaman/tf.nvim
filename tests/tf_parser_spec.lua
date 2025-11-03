local helpers = require("tests.helpers")
local parser = require("tf.parser")

describe("tf.parser.parse_block", function()
  it("detects resource on declaration line", function()
    helpers.with_temp_buffer({
      'resource "aws_instance" "example" {',
      "  ami           = \"ami-123\"",
      "  instance_type = \"t2.micro\"",
      "}",
    }, { 1, 0 }, function()
      local block = parser.parse_block()

      assert.is_not_nil(block)
      assert.equals("resource", block.type)
      assert.equals("aws_instance", block.resource_type)
      assert.equals("aws", block.provider)
      assert.equals("instance", block.resource_name)
    end)
  end)

  it("detects resource when cursor is inside block body", function()
    helpers.with_temp_buffer({
      'resource "google_compute_instance" "default" {',
      "  name         = \"example\"",
      "  machine_type = \"e2-micro\"",
      "}",
    }, { 3, 2 }, function()
      local block = parser.parse_block()

      assert.is_not_nil(block)
      assert.equals("resource", block.type)
      assert.equals("google_compute_instance", block.resource_type)
      assert.equals("google", block.provider)
      assert.equals("compute_instance", block.resource_name)
    end)
  end)

  it("detects data block", function()
    helpers.with_temp_buffer({
      'data "azurerm_virtual_network" "vnet" {',
      "  name                = \"production\"",
      "  resource_group_name = \"networking\"",
      "}",
    }, { 2, 4 }, function()
      local block = parser.parse_block()

      assert.is_not_nil(block)
      assert.equals("data", block.type)
      assert.equals("azurerm_virtual_network", block.resource_type)
      assert.equals("azurerm", block.provider)
      assert.equals("virtual_network", block.resource_name)
    end)
  end)

  it("returns nil when no block is found", function()
    helpers.with_temp_buffer({
      "variable \"region\" {",
      "  type    = string",
      "  default = \"us-east-1\"",
      "}",
    }, { 1, 0 }, function()
      local block = parser.parse_block()
      assert.is_nil(block)
    end)
  end)
end)
