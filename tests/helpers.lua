local M = {}

local function cleanup_buffer(bufnr)
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end
end

--- Execute callback with a temporary buffer populated with provided lines.
--- The buffer is always cleaned up after the callback (even on error).
--- @param lines string[]
--- @param cursor { [1]: integer, [2]: integer }|nil
--- @param callback fun(bufnr: integer)
function M.with_temp_buffer(lines, cursor, callback)
  vim.cmd("enew")
  local bufnr = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()

  vim.api.nvim_set_option_value("buftype", "nofile", { buf = bufnr })
  vim.api.nvim_set_option_value("swapfile", false, { buf = bufnr })

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })

  if cursor then
    vim.api.nvim_win_set_cursor(win, cursor)
  end

  local ok, err = pcall(callback, bufnr)

  cleanup_buffer(bufnr)

  if not ok then
    error(err)
  end
end

return M
