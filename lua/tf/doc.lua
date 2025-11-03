local M = {}

local parser = require("tf.parser")
local providers = require("tf.providers")
local clipboard = require("tf.clipboard")
local util = require("tf.util")
local Config = require("tf.config")

local function detect_browser_command()
  local os_name = vim.loop.os_uname().sysname

  if os_name == "Darwin" then
    return "open"
  elseif os_name == "Linux" then
    return "xdg-open"
  elseif os_name:match("Windows") then
    return "start"
  end

  return nil
end

local function open_in_browser(url)
  local cfg = Config.get()
  local browser_cmd = cfg.doc.browser_command or detect_browser_command()

  if not browser_cmd then
    util.notify("Could not detect browser command. Please configure browser_command in setup()", "error")
    return false
  end

  local cmd

  if type(browser_cmd) == "table" then
    cmd = vim.deepcopy(browser_cmd)
    table.insert(cmd, url)
  else
    if browser_cmd == "start" then
      cmd = { "cmd.exe", "/c", "start", "", url }
    else
      cmd = { browser_cmd, url }
    end
  end

  local job = vim.fn.jobstart(cmd, { detach = true })

  if job <= 0 then
    util.notify("Failed to launch browser command", "error")
    return false
  end

  return true
end

local function is_supported_filetype()
  local filetype = vim.bo.filetype
  return vim.tbl_contains(Config.get().filetypes, filetype)
end

function M.open(action)
  local cfg = Config.get()

  action = action or cfg.doc.default_action

  if not is_supported_filetype() then
    util.notify("Not in a Terraform file", "warn")
    return
  end

  local block = parser.parse_block()

  if not block then
    util.notify("No Terraform resource or data block found under cursor", "warn")
    return
  end

  local url = providers.construct_url(block)

  if not url then
    util.notify("Could not construct documentation URL", "error")
    return
  end

  if action == "open" then
    local success = open_in_browser(url)
    if success then
      util.notify(string.format("Opening in browser: %s", url), "info")
    end
    return
  end

  local success, method = clipboard.copy(url)
  if success then
    local method_suffix = ""
    if method == "osc52" then
      method_suffix = " (OSC52)"
    elseif method == "unnamed" then
      method_suffix = " (unnamed register)"
    end
    util.notify(string.format("Copied%s: %s", method_suffix, url), "info")
  else
    util.notify("Failed to copy URL to clipboard", "error")
  end
end

return M
