local M = {}

local function notify_error(message)
  vim.notify(message, vim.log.levels.ERROR, { title = "Runner" })
end

local function save_all()
  local ok, err = pcall(vim.cmd, "wall")
  if ok then
    return true
  end

  notify_error("Could not save all modified buffers:\n" .. tostring(err))
  return false
end

local function wait_script(command)
  return command
    .. [[; status=$?; printf '\n\nExit status: %s\nPress any key to close...' "$status"; IFS= read -r -s -n 1; exit 0]]
end

---@param command string
---@param opts? { buf?: number, cwd?: string, save?: boolean, wait?: boolean }
function M.run(command, opts)
  opts = opts or {}
  local buf = opts.buf or vim.api.nvim_get_current_buf()

  if opts.save ~= false and not save_all() then
    return
  end

  local cwd = opts.cwd or LazyVim.root.get({ buf = buf })
  local script = opts.wait == false and command or wait_script(command)

  Snacks.terminal.open({ "bash", "-lc", script }, {
    cwd = cwd,
    interactive = true,
    auto_close = true,
    win = {
      position = "bottom",
      height = 0.35,
    },
  })
end

local function current_go_file()
  local buf = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(buf)

  if vim.bo[buf].filetype ~= "go" or file == "" then
    notify_error("The current buffer is not a saved Go source file.")
    return
  end

  return buf, file
end

function M.go_file()
  local buf, file = current_go_file()
  if not buf then
    return
  end

  M.run("go run " .. vim.fn.shellescape(file), {
    buf = buf,
    cwd = vim.fs.dirname(file),
  })
end

function M.go_package()
  local buf, file = current_go_file()
  if not buf then
    return
  end

  local root = LazyVim.root.get({ buf = buf })
  local directory = vim.fs.dirname(file)
  local relative = vim.fs.relpath(root, directory)
  local cwd = relative and root or directory
  local package = relative == "." and "." or relative and "./" .. relative or "."

  M.run("go run " .. vim.fn.shellescape(package), {
    buf = buf,
    cwd = cwd,
  })
end

return M
