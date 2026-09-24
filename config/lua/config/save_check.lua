local M = {}

local running = {}
local pending = {}
local last_output = {}
local invalid_mode

local commands = {
  test = { "go", "test", "." },
  vet = { "go", "vet", "." },
}

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "Go save check" })
end

local function configured_mode()
  local mode = vim.g.nvim_go_save_check
  if mode == nil or mode == false or mode == "" or mode == "off" or mode == "none" then
    return
  end
  if commands[mode] then
    invalid_mode = nil
    return mode
  end
  if invalid_mode ~= mode then
    invalid_mode = mode
    notify(
      "Invalid vim.g.nvim_go_save_check value: " .. vim.inspect(mode) .. '; expected "test", "vet", or nil.',
      vim.log.levels.ERROR
    )
  end
end

local function output_lines(result)
  local lines = {}
  local output = (result.stdout or "") .. (result.stderr or "")
  for line in output:gmatch("[^\r\n]+") do
    table.insert(lines, line)
  end
  return lines
end

local run

run = function(package_dir, mode)
  if running[package_dir] then
    pending[package_dir] = mode
    return
  end

  running[package_dir] = true
  vim.system(commands[mode], { cwd = package_dir, text = true }, function(result)
    vim.schedule(function()
      running[package_dir] = nil
      last_output = output_lines(result)

      if result.code ~= 0 then
        local command = table.concat(commands[mode], " ")
        notify(command .. " failed; use :GoSaveCheckOutput for details.", vim.log.levels.ERROR)
      end

      local next_mode = pending[package_dir]
      pending[package_dir] = nil
      if next_mode then
        run(package_dir, next_mode)
      end
    end)
  end)
end

function M.run(buf)
  local mode = configured_mode()
  if not mode then
    return
  end

  local file = vim.api.nvim_buf_get_name(buf)
  if file == "" then
    return
  end
  run(vim.fs.dirname(vim.fs.normalize(file)), mode)
end

function M.output()
  if #last_output == 0 then
    notify("No save-check output is available yet.")
    return
  end

  vim.cmd("botright new")
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "gotest"
  vim.api.nvim_buf_set_name(buf, "Go save check output")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, last_output)
  vim.bo[buf].modifiable = false
end

return M
