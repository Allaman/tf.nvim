local M = {}

local Config = require("tf.config")

--- Check if terraform is available in PATH
--- @return boolean
function M.is_terraform_available()
  return vim.fn.executable(Config.get().terraform.bin) == 1
end

return M
