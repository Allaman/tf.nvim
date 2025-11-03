local M = {}

local job = require("tf.job")
local util = require("tf.util")

M.find_root = util.find_root

--- Determine if the current context is inside a Terraform project
--- @param start_path string|nil
--- @return boolean
function M.is_terraform_directory(start_path)
  return M.find_root(start_path) ~= nil
end

--- List all resources in terraform state asynchronously
--- @param callback fun(success:boolean, resources:table|nil, err:string|nil, ctx:table)
--- @param opts table|nil
function M.list_resources(callback, opts)
  opts = opts or {}
  job.execute({ "state", "list" }, {
    start_path = opts.start_path,
    bufnr = opts.bufnr,
    job_name = opts.job_name or "state_list",
    on_complete = function(success, out, err, ctx)
      if not callback then
        return
      end

      if not success then
        callback(false, nil, err ~= "" and err or (out ~= "" and out or "unknown error"), ctx)
        return
      end

      local resources = {}

      if out ~= "" then
        for line in out:gmatch("[^\r\n]+") do
          if line:match("%S") then
            resources[#resources + 1] = line
          end
        end
      end

      callback(true, resources, nil, ctx)
    end,
  })
end

--- Show detailed state for a specific resource asynchronously
--- @param resource string
--- @param callback fun(success:boolean, output:string|nil, err:string|nil, ctx:table)
--- @param opts table|nil
function M.show_resource(resource, callback, opts)
  if not resource or resource == "" then
    if callback then
      callback(false, nil, "No resource specified", { root = nil })
    end
    return
  end

  opts = opts or {}
  job.execute({ "state", "show", resource }, {
    start_path = opts.start_path,
    bufnr = opts.bufnr,
    job_name = opts.job_name or "state_show",
    on_complete = function(success, out, err, ctx)
      if not callback then
        return
      end

      if success then
        callback(true, out, nil, ctx)
      else
        callback(false, nil, err ~= "" and err or (out ~= "" and out or "unknown error"), ctx)
      end
    end,
  })
end

--- Remove a resource from terraform state asynchronously
--- @param resource string
--- @param callback fun(success:boolean, err:string|nil, ctx:table)
--- @param opts table|nil
function M.remove_resource(resource, callback, opts)
  if not resource or resource == "" then
    if callback then
      callback(false, "No resource specified", { root = nil })
    end
    return
  end

  opts = opts or {}
  job.execute({ "state", "rm", resource }, {
    start_path = opts.start_path,
    bufnr = opts.bufnr,
    job_name = opts.job_name or "state_rm",
    on_complete = function(success, _, err, ctx)
      if callback then
        if success then
          callback(true, nil, ctx)
        else
          callback(false, err ~= "" and err or "unknown error", ctx)
        end
      end
    end,
  })
end

--- Pull current terraform state asynchronously
--- @param callback fun(success:boolean, err:string|nil, ctx:table)
--- @param opts table|nil
function M.pull_state(callback, opts)
  opts = opts or {}
  job.execute({ "state", "pull" }, {
    start_path = opts.start_path,
    bufnr = opts.bufnr,
    job_name = opts.job_name or "state_pull",
    on_complete = function(success, _, err, ctx)
      if callback then
        if success then
          callback(true, nil, ctx)
        else
          callback(false, err ~= "" and err or "unknown error", ctx)
        end
      end
    end,
  })
end

return M
