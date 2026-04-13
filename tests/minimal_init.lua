local uv = vim.loop
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")

vim.opt.runtimepath:append(root)

local function path_exists(path)
  return path and uv.fs_stat(path) ~= nil
end

local function ensure_dir(dir)
  if path_exists(dir) then
    return
  end
  vim.fn.mkdir(dir, "p")
end

local testing_root = vim.env.FYLER_TESTING_DIR or vim.fs.joinpath(root, ".test-deps")

local function ensure_install(repo)
  local name = repo:match("/([%w%._-]+)$")
  if not name then
    return
  end

  ensure_dir(testing_root)

  local install_path = vim.fs.joinpath(testing_root, name)

  if not path_exists(install_path) then
    local args = { "git", "clone", "--depth=1", "https://github.com/" .. repo .. ".git", install_path }

    if vim.system then
      local result = vim.system(args):wait()
      if not result or result.code ~= 0 then
        print(string.format("[tf.nvim tests] failed to clone %s", repo))
        return
      end
    else
      vim.fn.system(args)
      if vim.v.shell_error > 0 then
        print(string.format("[tf.nvim tests] failed to clone %s", repo))
        return
      end
    end
  end

  if not path_exists(install_path) then
    return
  end

  vim.opt.runtimepath:prepend(install_path)
end

local mini_path = os.getenv("MINI_PATH")

if mini_path and mini_path ~= "" then
  vim.opt.runtimepath:append(mini_path)
else
  local ok = pcall(vim.cmd, "packadd mini.nvim")
  if not ok then
    ensure_install("echasnovski/mini.nvim")
  end
end

vim.opt.swapfile = false
vim.opt.shadafile = "NONE"

require("mini.test").setup()
