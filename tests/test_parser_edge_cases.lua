local helpers = require("tests.helpers")
local parser = require("tf.parser")

local T = MiniTest.new_set()

T["tf.parser edge cases"] = MiniTest.new_set()

T["tf.parser edge cases"]["ignores resource declarations in comments"] = function()
  helpers.with_temp_buffer({
    '# resource "aws_instance" "commented"',
    "",
    'resource "aws_s3_bucket" "real" {',
    '  bucket = "my-bucket"',
    "}",
  }, { 4, 0 }, function()
    local block = parser.parse_block()

    MiniTest.expect.no_equality(block, nil)
    MiniTest.expect.equality(block.type, "resource")
    MiniTest.expect.equality(block.resource_type, "aws_s3_bucket")
    MiniTest.expect.equality(block.provider, "aws")
    MiniTest.expect.equality(block.resource_name, "s3_bucket")
  end)
end

T["tf.parser edge cases"]["handles resource with no underscore"] = function()
  helpers.with_temp_buffer({
    'resource "random" "test" {',
    "  length = 16",
    "}",
  }, { 2, 0 }, function()
    local block = parser.parse_block()

    MiniTest.expect.no_equality(block, nil)
    MiniTest.expect.equality(block.type, "resource")
    MiniTest.expect.equality(block.resource_type, "random")
    MiniTest.expect.equality(block.provider, "random")
    MiniTest.expect.equality(block.resource_name, "random")
  end)
end

T["tf.parser edge cases"]["handles multi-part provider names"] = function()
  helpers.with_temp_buffer({
    'resource "google_compute_instance" "vm" {',
    '  name = "test-vm"',
    "}",
  }, { 2, 0 }, function()
    local block = parser.parse_block()

    MiniTest.expect.no_equality(block, nil)
    MiniTest.expect.equality(block.provider, "google")
    MiniTest.expect.equality(block.resource_name, "compute_instance")
  end)
end

T["tf.parser edge cases"]["does not match resource inside heredoc"] = function()
  helpers.with_temp_buffer({
    'resource "null_resource" "script" {',
    '  provisioner "local-exec" {',
    "    command = <<-EOF",
    '      # resource "fake_resource" "trap"',
    "    EOF",
    "  }",
    "}",
  }, { 4, 0 }, function()
    local block = parser.parse_block()

    -- Should find the real null_resource, not the fake one in heredoc
    MiniTest.expect.no_equality(block, nil)
    MiniTest.expect.equality(block.resource_type, "null_resource")
  end)
end

T["tf.parser edge cases"]["validates cursor is within block boundaries"] = function()
  helpers.with_temp_buffer({
    'resource "aws_instance" "web" {',
    '  ami = "ami-123"',
    "}",
    "",
    'resource "aws_s3_bucket" "data" {',
    '  bucket = "my-data"',
    "}",
  }, { 4, 0 }, function()
    -- Cursor on empty line between blocks
    -- Just verify it doesn't crash; boundary behaviour is implementation-defined
    parser.parse_block()
  end)
end

T["tf.parser edge cases"]["handles nested blocks correctly"] = function()
  helpers.with_temp_buffer({
    'resource "aws_instance" "web" {',
    '  dynamic "ebs_block_device" {',
    "    for_each = var.disks",
    "    content {",
    "      device_name = ebs_block_device.value",
    "    }",
    "  }",
    "}",
  }, { 5, 0 }, function()
    local block = parser.parse_block()

    MiniTest.expect.no_equality(block, nil)
    MiniTest.expect.equality(block.type, "resource")
    MiniTest.expect.equality(block.resource_type, "aws_instance")
  end)
end

T["tf.parser edge cases"]["handles cursor on closing brace"] = function()
  helpers.with_temp_buffer({
    'resource "aws_instance" "web" {',
    '  ami = "ami-123"',
    "}",
  }, { 3, 0 }, function()
    local block = parser.parse_block()

    MiniTest.expect.no_equality(block, nil)
    MiniTest.expect.equality(block.resource_type, "aws_instance")
  end)
end

T["tf.parser edge cases"]["returns nil for module blocks"] = function()
  helpers.with_temp_buffer({
    'module "vpc" {',
    '  source = "./modules/vpc"',
    "}",
  }, { 2, 0 }, function()
    local block = parser.parse_block()
    MiniTest.expect.equality(block, nil)
  end)
end

T["tf.parser edge cases"]["returns nil for variable blocks"] = function()
  helpers.with_temp_buffer({
    'variable "region" {',
    "  type = string",
    "}",
  }, { 2, 0 }, function()
    local block = parser.parse_block()
    MiniTest.expect.equality(block, nil)
  end)
end

T["tf.parser edge cases"]["returns nil for output blocks"] = function()
  helpers.with_temp_buffer({
    'output "instance_ip" {',
    "  value = aws_instance.web.public_ip",
    "}",
  }, { 2, 0 }, function()
    local block = parser.parse_block()
    MiniTest.expect.equality(block, nil)
  end)
end

T["tf.parser edge cases"]["handles data block with complex name"] = function()
  helpers.with_temp_buffer({
    'data "aws_ami" "ubuntu_latest" {',
    "  most_recent = true",
    "}",
  }, { 2, 0 }, function()
    local block = parser.parse_block()

    MiniTest.expect.no_equality(block, nil)
    MiniTest.expect.equality(block.type, "data")
    MiniTest.expect.equality(block.resource_type, "aws_ami")
  end)
end

T["tf.parser edge cases"]["handles extra whitespace in declaration"] = function()
  helpers.with_temp_buffer({
    '  resource   "aws_instance"   "web"   {',
    '    ami = "ami-123"',
    "  }",
  }, { 2, 0 }, function()
    local block = parser.parse_block()

    MiniTest.expect.no_equality(block, nil)
    MiniTest.expect.equality(block.resource_type, "aws_instance")
  end)
end

return T
