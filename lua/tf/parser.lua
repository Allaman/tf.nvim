local M = {}

--- Check if current line contains a resource or data block definition
--- @return string|nil, string|nil -- type (resource/data), resource_type
local function parse_current_line()
  local line = vim.api.nvim_get_current_line()

  -- Ignore lines within heredoc or multi-line strings
  -- This is a basic check - more sophisticated parsing would require treesitter
  if line:match("<<%-?%w+") or line:match("^%s*['\"]") then
    return nil, nil
  end

  -- Match resource "aws_instance" "name" pattern (ignore comments)
  local resource_match = line:match('^%s*resource%s+"([^"]+)"')
  if resource_match then
    return "resource", resource_match
  end

  -- Match data "aws_ami" "name" pattern (ignore comments)
  local data_match = line:match('^%s*data%s+"([^"]+)"')
  if data_match then
    return "data", data_match
  end

  return nil, nil
end

--- Validate that cursor is within block boundaries
--- @param block_start_line number
--- @return boolean
local function is_within_block_boundaries(block_start_line)
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  local total_lines = vim.api.nvim_buf_line_count(0)

  -- Count braces to find block end
  local brace_count = 0
  local in_block = false

  for i = block_start_line, math.min(total_lines, block_start_line + 500) do
    local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]

    -- Skip comments and strings (basic detection)
    local cleaned = line:gsub("#[^\n]*", ""):gsub('"[^"]*"', "")

    for char in cleaned:gmatch(".") do
      if char == "{" then
        brace_count = brace_count + 1
        in_block = true
      elseif char == "}" then
        brace_count = brace_count - 1
        if brace_count == 0 and in_block then
          -- Found the closing brace of the block
          return cursor_line >= block_start_line and cursor_line <= i
        end
      end
    end
  end

  -- If we didn't find closing brace within 500 lines, assume we're in the block
  return cursor_line >= block_start_line
end

--- Search backwards from cursor to find resource or data block declaration
--- @return string|nil, string|nil, number|nil -- type (resource/data), resource_type, line_number
local function find_block_declaration()
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]

  -- Search backwards towards file start
  for i = cursor_line, 1, -1 do
    local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]

    -- Skip lines that look like they're in strings or heredocs
    if line:match("<<%-?%w+") then
      goto continue
    end

    -- Match resource "aws_instance" "name" {
    local resource_match = line:match('^%s*resource%s+"([^"]+)"')
    if resource_match and is_within_block_boundaries(i) then
      return "resource", resource_match, i
    end

    -- Match data "aws_ami" "name" {
    local data_match = line:match('^%s*data%s+"([^"]+)"')
    if data_match and is_within_block_boundaries(i) then
      return "data", data_match, i
    end

    ::continue::
  end

  return nil, nil, nil
end

--- Parse terraform block and extract type and resource
--- This checks if cursor is on a resource/data line or within a block
--- @return table|nil -- { type: "resource"|"data", resource_type: string, provider: string, resource_name: string }
function M.parse_block()
  -- First check current line
  local block_type, resource_type = parse_current_line()

  -- If not found, search backwards for block declaration
  if not block_type then
    block_type, resource_type = find_block_declaration()
  end

  if not block_type or not resource_type then
    return nil
  end

  -- Extract provider prefix (e.g., "aws" from "aws_instance")
  local provider, resource_name = resource_type:match("^([^_]+)_(.*)")

  if not provider or not resource_name then
    -- Handle resources without underscore (rare, but possible)
    provider = resource_type
    resource_name = resource_type
  end

  return {
    type = block_type, -- "resource" or "data"
    resource_type = resource_type, -- "aws_instance"
    provider = provider, -- "aws"
    resource_name = resource_name, -- "instance"
  }
end

return M
