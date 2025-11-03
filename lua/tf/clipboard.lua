local M = {}
local osc52_max_length = 65535

local function base64_encode(data)
  -- Use built-in base64 encoding if available (Neovim 0.10+)
  if vim.base64 and vim.base64.encode then
    return vim.base64.encode(data)
  end

  -- Fallback to base64 command for older Neovim versions
  local handle = io.popen("base64", "w")
  if handle then
    handle:write(data)
    handle:close()
  end

  local result = vim.fn.system("printf '%s' " .. vim.fn.shellescape(data) .. " | base64")
  return vim.trim(result)
end

local function build_osc52_sequence(text)
  if #text > osc52_max_length then
    return nil
  end

  local encoded = base64_encode(text)
  local osc = string.format("\027]52;c;%s\007", encoded)

  if vim.env.TMUX then
    return string.format("\027Ptmux;\027%s\027\\", osc)
  elseif vim.env.SCREEN then
    return string.format("\027P\027%s\027\\", osc)
  end

  return osc
end

local function try_osc52(text)
  local sequence = build_osc52_sequence(text)

  if not sequence then
    return false
  end

  local ok = false

  if type(vim.v.stderr) == "number" and vim.v.stderr > 0 then
    ok = pcall(vim.api.nvim_chan_send, vim.v.stderr, sequence)
  end

  return ok
end

--- Copy text to system clipboard
--- Uses various clipboard methods depending on availability
--- @param text string
--- @return boolean success
--- @return string|nil method one of "+", "*", "osc52", "unnamed"
function M.copy(text)
  if not text or text == "" then
    return false, nil
  end

  -- Try vim.fn.setreg with + register (X11/clipboard)
  local ok, _ = pcall(vim.fn.setreg, "+", text)
  if ok then
    return true, "+"
  end

  -- Try vim.fn.setreg with * register (primary selection)
  ok, _ = pcall(vim.fn.setreg, "*", text)
  if ok then
    return true, "*"
  end

  -- OSC52 fallback for terminals that support it
  if try_osc52(text) then
    return true, "osc52"
  end

  -- Final fallback to unnamed register
  ok, _ = pcall(vim.fn.setreg, "", text)
  if ok then
    return true, "unnamed"
  end

  return false, nil
end

--- Display notification message
--- @param message string
--- @param level string|nil -- "info", "warn", "error"
function M.notify(message, level)
  local log_level = vim.log.levels.INFO

  if level == "warn" then
    log_level = vim.log.levels.WARN
  elseif level == "error" then
    log_level = vim.log.levels.ERROR
  end

  vim.notify(message, log_level, { title = "tf.nvim" })
end

return M
