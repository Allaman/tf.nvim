local helpers = require("tests.helpers")
local parser = require("tf.parser")

local T = MiniTest.new_set()

T["tf.parser.parse_block"] = MiniTest.new_set()

T["tf.parser.parse_block"]["detects resource on declaration line"] = function()
  helpers.with_temp_buffer({
    'resource "aws_instance" "example" {',
    '  ami           = "ami-123"',
    '  instance_type = "t2.micro"',
    "}",
  }, { 1, 0 }, function()
    local block = parser.parse_block()

    MiniTest.expect.no_equality(block, nil)
    MiniTest.expect.equality(block.type, "resource")
    MiniTest.expect.equality(block.resource_type, "aws_instance")
    MiniTest.expect.equality(block.provider, "aws")
    MiniTest.expect.equality(block.resource_name, "instance")
  end)
end

T["tf.parser.parse_block"]["detects resource when cursor is inside block body"] = function()
  helpers.with_temp_buffer({
    'resource "google_compute_instance" "default" {',
    '  name         = "example"',
    '  machine_type = "e2-micro"',
    "}",
  }, { 3, 2 }, function()
    local block = parser.parse_block()

    MiniTest.expect.no_equality(block, nil)
    MiniTest.expect.equality(block.type, "resource")
    MiniTest.expect.equality(block.resource_type, "google_compute_instance")
    MiniTest.expect.equality(block.provider, "google")
    MiniTest.expect.equality(block.resource_name, "compute_instance")
  end)
end

T["tf.parser.parse_block"]["detects data block"] = function()
  helpers.with_temp_buffer({
    'data "azurerm_virtual_network" "vnet" {',
    '  name                = "production"',
    '  resource_group_name = "networking"',
    "}",
  }, { 2, 4 }, function()
    local block = parser.parse_block()

    MiniTest.expect.no_equality(block, nil)
    MiniTest.expect.equality(block.type, "data")
    MiniTest.expect.equality(block.resource_type, "azurerm_virtual_network")
    MiniTest.expect.equality(block.provider, "azurerm")
    MiniTest.expect.equality(block.resource_name, "virtual_network")
  end)
end

T["tf.parser.parse_block"]["returns nil when no block is found"] = function()
  helpers.with_temp_buffer({
    'variable "region" {',
    "  type    = string",
    '  default = "us-east-1"',
    "}",
  }, { 1, 0 }, function()
    local block = parser.parse_block()
    MiniTest.expect.equality(block, nil)
  end)
end

return T
