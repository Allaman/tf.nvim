local M = {}

local job = require("tf.job")

function M.run(callback, opts)
  opts = opts or {}
  local args = { "validate", "-no-color" }
  local extra_args = {}
  if type(opts.args) == "table" then
    extra_args = opts.args
  elseif type(opts.args) == "string" then
    extra_args = vim.split(opts.args, "%s+", { trimempty = true })
  end

  vim.list_extend(args, extra_args)

  job.execute(args, {
    bufnr = opts.bufnr,
    start_path = opts.start_path,
    job_name = opts.job_name or "validate",
    on_complete = callback,
  })
end

return M
