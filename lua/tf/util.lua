local M = {}

local uv = vim.loop
local path_sep = vim.loop.os_uname().sysname == "Windows" and "\\" or "/"

local active_progress = {}

--- Notification helper that routes to vim.notify with plugin title.
--- @param message string
--- @param level '"info"'|'"warn"'|'"error"'|nil
function M.notify(message, level)
  local log_level = vim.log.levels.INFO
  if level == "warn" then
    log_level = vim.log.levels.WARN
  elseif level == "error" then
    log_level = vim.log.levels.ERROR
  end
  vim.notify(message, log_level, { title = "tf.nvim" })
end

--- Start a progress indicator for a long-running operation
--- @param operation_name string
--- @param message string
--- @return number progress_id
function M.start_progress(operation_name, message)
  local progress_id = #active_progress + 1
  local initial_message = message or operation_name

  -- Show notification immediately
  M.notify(initial_message, "info")

  -- Store minimal progress info
  active_progress[progress_id] = {
    operation = operation_name,
    message = initial_message,
  }

  return progress_id
end

--- Stop a progress indicator
--- @param progress_id number
function M.stop_progress(progress_id)
  active_progress[progress_id] = nil
end

local function join_path(dir, fragment)
  if dir:sub(-1) == path_sep then
    return dir .. fragment
  end
  return dir .. path_sep .. fragment
end

local function normalize_dir(path)
  if not path or path == "" then
    return nil
  end

  local ok, real = pcall(uv.fs_realpath, path)
  if ok and real and type(real) == "string" and real ~= "" then
    return real
  end

  return vim.fn.fnamemodify(path, ":p")
end

local function has_tf_files(dir)
  local ok, files = pcall(vim.fn.glob, join_path(dir, "*.tf"), 0, 1)
  if ok and type(files) == "table" and #files > 0 then
    return true
  end

  ok, files = pcall(vim.fn.glob, join_path(dir, "*.tfvars"), 0, 1)
  if ok and type(files) == "table" and #files > 0 then
    return true
  end

  return false
end

local function has_state_markers(dir)
  if vim.fn.filereadable(join_path(dir, "terraform.tfstate")) == 1 then
    return true
  end

  if vim.fn.isdirectory(join_path(dir, ".terraform")) == 1 then
    return true
  end

  return false
end

local function get_lsp_root(bufnr)
  if not vim.lsp or not vim.lsp.get_clients then
    return nil
  end

  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = bufnr, name = "terraformls" })

  for _, client in ipairs(clients) do
    local root_dir = client.config and client.config.root_dir
    if root_dir and root_dir ~= "" then
      return normalize_dir(root_dir)
    end
  end

  return nil
end

local function find_filesystem_root(path)
  local dir = normalize_dir(path)

  if not dir then
    return nil
  end

  if vim.fn.isdirectory(dir) == 0 then
    dir = normalize_dir(vim.fn.fnamemodify(dir, ":h"))
  end

  while dir and dir ~= "" do
    if has_tf_files(dir) or has_state_markers(dir) then
      return dir
    end

    local parent = vim.fn.fnamemodify(dir, ":h")
    if not parent or parent == "" or parent == dir then
      break
    end

    dir = parent
  end

  return nil
end

--- Locate the nearest Terraform project root.
--- Prefers the terraformls LSP root and falls back to filesystem detection.
--- @param opts table|string|nil
--- @return string|nil
function M.find_root(opts)
  local options = opts

  if type(options) ~= "table" then
    options = { start_path = opts }
  end

  local bufnr = options.bufnr or vim.api.nvim_get_current_buf()

  local lsp_root = get_lsp_root(bufnr)
  if lsp_root then
    return lsp_root
  end

  local path = options.start_path

  if not path or path == "" then
    path = vim.api.nvim_buf_get_name(bufnr)
  end

  if not path or path == "" then
    path = uv.cwd()
  end

  return find_filesystem_root(path)
end

local border_chars = "╷╵│║╔╗╚╝╠╣╦╩═╬─└┌┘┐├┤┬┴┼╭╮╰╯"

--- Create a window (float, split, or vsplit) for a buffer
--- @param bufnr number Buffer to display
--- @param window_cfg table Window configuration with mode, split, float, focus
--- @return number winid Window ID
function M.create_window(bufnr, window_cfg)
  window_cfg = window_cfg or {}
  local mode = window_cfg.mode or "vsplit"
  local winid

  if mode == "float" then
    local columns = vim.o.columns
    local rows = vim.o.lines
    local float_cfg = window_cfg.float or {}
    local width_ratio = math.max(0.1, math.min(1.0, float_cfg.width or 0.6))
    local height_ratio = math.max(0.1, math.min(1.0, float_cfg.height or 0.8))

    local width = math.max(20, math.min(columns - 4, math.floor(columns * width_ratio)))
    local height = math.max(5, math.min(rows - 2, math.floor(rows * height_ratio)))
    local row = math.max(0, math.floor((rows - height) / 2))
    local col = math.max(0, math.floor((columns - width) / 2))

    winid = vim.api.nvim_open_win(bufnr, true, {
      relative = "editor",
      style = "minimal",
      border = "rounded",
      width = width,
      height = height,
      row = row,
      col = col,
    })
  else
    local split_cfg = window_cfg.split or {}
    local position = split_cfg.position or "botright"
    local size = split_cfg.size or (mode == "vsplit" and 80 or 15)

    if mode == "vsplit" then
      size = math.max(1, math.min(vim.o.columns - 5, size))
      vim.cmd(string.format("%s %svsplit", position, size > 0 and size or ""))
    else
      size = math.max(1, math.min(vim.o.lines - 3, size))
      vim.cmd(string.format("%s %ssplit", position, size > 0 and size or ""))
    end

    winid = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(winid, bufnr)
  end

  if window_cfg.focus == false then
    vim.cmd("wincmd p")
  end

  return winid
end

local function safe_json_decode(str)
  local ok, decoded = pcall(vim.json.decode, str)
  if ok then
    return decoded
  end
  return nil
end

--- Convert a command table to a human-readable string.
--- @param cmd table|string|nil
--- @return string
function M.command_to_string(cmd)
  if type(cmd) == "table" then
    return table.concat(cmd, " ")
  end
  if cmd == nil then
    return ""
  end
  return tostring(cmd)
end

--- Sanitize CLI output by stripping Terraform border characters and trimming whitespace.
--- @param text string|nil
--- @return string[]
function M.sanitize_cli_lines(text)
  if not text or text == "" then
    return {}
  end

  local lines = {}

  for raw_line in text:gmatch("([^\r\n]+)") do
    local line = raw_line:gsub("\194\160", " ")

    line = line:gsub("^%s*[" .. border_chars .. "|│]+%s*", "")
    line = line:gsub("[%s" .. border_chars .. "|│]+$", "")
    line = line:gsub("^%s+", "")
    line = line:gsub("%s+$", "")

    if line ~= "" then
      table.insert(lines, line)
    end
  end

  return lines
end

--- Summarize CLI output by returning the first non-empty sanitized line and the full set.
--- @param text string|nil
--- @return string summary, string[] lines
function M.summarize_cli(text)
  local lines = M.sanitize_cli_lines(text)
  if #lines == 0 then
    return "unknown error", lines
  end
  return lines[1], lines
end

--- Flatten sanitized CLI lines into a single sentence.
--- @param lines string[]
--- @return string
function M.flatten_cli_lines(lines)
  if not lines or #lines == 0 then
    return ""
  end
  return table.concat(lines, " ")
end

return M
