--- Shared job execution module for terraform commands
local M = {}

local util = require("tf.util")
local Config = require("tf.config")

local function strip_ansi(text)
  if not text or text == "" then
    return text
  end
  return text:gsub("\27%[[0-9;]*m", "")
end

--- Execute a terraform command asynchronously
--- @param args table Command arguments
--- @param opts table Options including callback, start_path, bufnr, job_name, strip_ansi_codes
--- @return number job_id or -1 on failure
function M.execute(args, opts)
  opts = opts or {}
  local callback = opts.on_complete
  local start_path = opts.start_path

  local root = util.find_root({ start_path = start_path, bufnr = opts.bufnr })

  if not root then
    if callback then
      callback(false, nil, "Terraform root not found", { root = nil })
    end
    return -1
  end

  local command = { Config.get().terraform.bin }
  vim.list_extend(command, args)

  local stdout, stderr = {}, {}

  local job_id = vim.fn.jobstart(command, {
    cwd = root,
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if not data then
        return
      end
      for _, line in ipairs(data) do
        if line ~= "" then
          stdout[#stdout + 1] = line
        end
      end
    end,
    on_stderr = function(_, data)
      if not data then
        return
      end
      for _, line in ipairs(data) do
        if line ~= "" then
          stderr[#stderr + 1] = line
        end
      end
    end,
    on_exit = function(_, code)
      if callback then
        local out = table.concat(stdout, "\n")
        local err = table.concat(stderr, "\n")

        -- Optionally strip ANSI codes (default: true)
        if opts.strip_ansi_codes ~= false then
          out = strip_ansi(out)
          err = strip_ansi(err)
        end

        local success = code == 0
        local ctx = {
          root = root,
          code = code,
          command = command,
          job_name = opts.job_name,
        }

        -- Wrap callback in pcall to prevent uncaught errors from breaking the job system
        local ok, callback_err = pcall(callback, success, out, err, ctx)
        if not ok then
          vim.schedule(function()
            util.notify(string.format("Error in terraform job callback: %s", tostring(callback_err)), "error")
          end)
        end
      end
    end,
  })

  if job_id <= 0 then
    if callback then
      callback(false, nil, "Failed to start terraform job", { root = root })
    end
    return job_id
  end

  return job_id
end

return M
