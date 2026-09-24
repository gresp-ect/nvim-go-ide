local M = {}
local task_status = require("config.task_status")

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

---@param command string
---@param opts? { buf?: number, cwd?: string, label?: string, save?: boolean }
function M.run(command, opts)
  opts = opts or {}
  local buf = opts.buf or vim.api.nvim_get_current_buf()

  if opts.save ~= false and not save_all() then
    return
  end

  local cwd = opts.cwd or LazyVim.root.get({ buf = buf })
  local label = opts.label or command
  local repeat_opts = vim.tbl_extend("force", {}, opts, { buf = buf, cwd = cwd })
  task_status.remember(label, function()
    M.run(command, repeat_opts)
  end)
  local task = task_status.start(label)

  Snacks.terminal.open({ "bash", "-lc", command }, {
    cwd = cwd,
    interactive = true,
    auto_close = false,
    win = {
      position = "bottom",
      height = 0.35,
      on_buf = function(terminal)
        vim.api.nvim_create_autocmd("TermClose", {
          buffer = terminal.buf,
          once = true,
          callback = function()
            local status = vim.v.event.status
            task_status.finish(task, status == 0, status == 0 and nil or "exit " .. status)
          end,
        })
      end,
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
    label = "Run current file",
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
    label = "Run current package",
  })
end

return M
