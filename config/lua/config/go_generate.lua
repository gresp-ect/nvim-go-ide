local M = {}

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "Go code generation" })
end

local function current_go_file()
  local buf = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(buf)

  if vim.bo[buf].filetype ~= "go" or file == "" then
    notify("The current buffer is not a saved Go source file.", vim.log.levels.ERROR)
    return
  end

  local ok, err = pcall(vim.api.nvim_buf_call, buf, function()
    vim.cmd("silent update")
  end)
  if not ok then
    notify("Could not save the current buffer:\n" .. tostring(err), vim.log.levels.ERROR)
    return
  end

  return buf, file
end

local function executable(name)
  if vim.fn.executable(name) == 1 then
    return true
  end

  notify(name .. " is not available in PATH; run nvim-go install.", vim.log.levels.ERROR)
  return false
end

local function failure_message(result)
  local message = vim.trim(result.stderr or "")
  if message == "" then
    message = vim.trim(result.stdout or "")
  end
  return message ~= "" and message or "exit " .. result.code
end

local function modify_json_tags(action)
  local buf, file = current_go_file()
  if not buf or not executable("gomodifytags") then
    return
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  local offset = vim.fn.line2byte(cursor[1]) + cursor[2] - 1
  local args = { "gomodifytags", "-file", file, "-offset", tostring(offset), "-w", "-quiet" }
  if action == "add" then
    vim.list_extend(args, { "-add-tags", "json", "-transform", "snakecase", "-skip-unexported" })
  else
    vim.list_extend(args, { "-remove-tags", "json" })
  end

  vim.system(args, { text = true }, vim.schedule_wrap(function(result)
    if result.code ~= 0 then
      notify("gomodifytags failed: " .. failure_message(result), vim.log.levels.ERROR)
      return
    end
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end

    vim.api.nvim_buf_call(buf, function()
      vim.cmd("checktime")
    end)
    notify(action == "add" and "Added JSON tags to the current struct."
      or "Removed JSON tags from the current struct.")
  end))
end

function M.add_json_tags()
  modify_json_tags("add")
end

function M.remove_json_tags()
  modify_json_tags("remove")
end

local function prompt(label, default, callback)
  vim.ui.input({ prompt = label, default = default }, function(value)
    value = value and vim.trim(value) or ""
    if value ~= "" then
      callback(value)
    end
  end)
end

local function append_implementation(buf, output)
  local lines = vim.split(output, "\n", { plain = true })
  while lines[#lines] == "" do
    table.remove(lines)
  end
  if #lines == 0 then
    notify("impl produced no methods.", vim.log.levels.WARN)
    return
  end

  local line_count = vim.api.nvim_buf_line_count(buf)
  local last_line = vim.api.nvim_buf_get_lines(buf, line_count - 1, line_count, false)[1]
  if last_line ~= "" then
    table.insert(lines, 1, "")
  end
  vim.api.nvim_buf_set_lines(buf, line_count, line_count, false, lines)
  notify("Generated interface methods at the end of the file.")
end

local function run_impl(buf, file, receiver, interface)
  if not executable("impl") then
    return
  end

  vim.system({ "impl", receiver, interface }, {
    cwd = vim.fs.dirname(file),
    text = true,
  }, vim.schedule_wrap(function(result)
    if result.code ~= 0 then
      notify("impl failed: " .. failure_message(result), vim.log.levels.ERROR)
      return
    end
    if vim.api.nvim_buf_is_valid(buf) then
      append_implementation(buf, result.stdout or "")
    end
  end))
end

function M.impl(receiver, interface)
  local buf, file = current_go_file()
  if not buf then
    return
  end

  local function with_receiver(value)
    if interface and interface ~= "" then
      run_impl(buf, file, value, interface)
      return
    end
    prompt("Interface (for example io.Reader): ", "", function(iface)
      run_impl(buf, file, value, iface)
    end)
  end

  if receiver and receiver ~= "" then
    with_receiver(receiver)
  else
    prompt("Receiver (for example s *Server): ", "", with_receiver)
  end
end

return M
