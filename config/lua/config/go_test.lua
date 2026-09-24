local M = {}
local task_status = require("config.task_status")

local namespace = vim.api.nvim_create_namespace("nvim-go-coverage")
local coverage = {}
local last_output = {}

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "Go test" })
end

local function save_all()
  local ok, err = pcall(vim.cmd, "wall")
  if not ok then
    notify("Could not save all modified buffers:\n" .. tostring(err), vim.log.levels.ERROR)
  end
  return ok
end

local function current_go_file()
  local buf = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(buf)
  if vim.bo[buf].filetype ~= "go" or file == "" then
    notify("The current buffer is not a saved Go source file.", vim.log.levels.ERROR)
    return
  end
  return buf, vim.fs.normalize(file)
end

local function current_test_name(buf)
  local ok, node = pcall(vim.treesitter.get_node, { bufnr = buf })
  if ok then
    while node do
      if node:type() == "function_declaration" then
        local name_node = node:field("name")[1]
        local name = name_node and vim.treesitter.get_node_text(name_node, buf) or nil
        if name and name:match("^Test[%w_]+$") then
          return name
        end
        break
      end
      node = node:parent()
    end
  end

  for line = vim.api.nvim_win_get_cursor(0)[1], 1, -1 do
    local text = vim.api.nvim_buf_get_lines(buf, line - 1, line, false)[1] or ""
    local name = text:match("^func%s+(Test[%w_]+)%s*%(")
    if name then
      return name
    end
    if text:match("^func%s+") then
      break
    end
  end
end

local function source_path(package_dir, source)
  source = source:gsub("^%./", "")
  if source:sub(1, 1) == "/" then
    return vim.fs.normalize(source)
  end

  local direct = vim.fs.normalize(package_dir .. "/" .. source)
  if vim.fn.filereadable(direct) == 1 then
    return direct
  end
  return vim.fs.normalize(package_dir .. "/" .. vim.fs.basename(source))
end

local function apply_coverage(buf)
  vim.api.nvim_buf_clear_namespace(buf, namespace, 0, -1)
  local file = vim.fs.normalize(vim.api.nvim_buf_get_name(buf))
  local lines = coverage[file]
  if not lines then
    return
  end

  local line_count = vim.api.nvim_buf_line_count(buf)
  for line, covered in pairs(lines) do
    if not covered and line <= line_count then
      vim.api.nvim_buf_set_extmark(buf, namespace, line - 1, 0, {
        sign_text = "│",
        sign_hl_group = "GoCoverageUncoveredSign",
        line_hl_group = "GoCoverageUncovered",
        priority = 20,
      })
    end
  end
end

local function read_coverage(profile, package_dir)
  coverage = {}
  local covered_statements = 0
  local total_statements = 0

  for _, line in ipairs(vim.fn.readfile(profile)) do
    local source, start_line, end_line, statements, count = line:match(
      "^(.+):(%d+)%.%d+,(%d+)%.%d+%s+(%d+)%s+(%d+)$"
    )
    if source then
      local file = source_path(package_dir, source)
      coverage[file] = coverage[file] or {}
      statements = tonumber(statements)
      count = tonumber(count)
      total_statements = total_statements + statements
      if count > 0 then
        covered_statements = covered_statements + statements
      end
      for number = tonumber(start_line), tonumber(end_line) do
        coverage[file][number] = coverage[file][number] or count > 0
      end
    end
  end

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      apply_coverage(buf)
    end
  end

  if total_statements == 0 then
    return "no statements"
  end
  return string.format("%.1f%%", covered_statements * 100 / total_statements)
end

local function failure_items(output, package_dir)
  local items = {}
  local local_items = {}
  local seen = {}
  for line in output:gmatch("[^\r\n]+") do
    local ok, decoded = pcall(vim.json.decode, line)
    decoded = ok and decoded or nil
    local text = type(decoded) == "table" and decoded.Output or line
    if text then
      local source, number, message = text:match("%s*([%w%._/%-]+%.go):(%d+):?%s*(.*)")
      if source and number then
        local file = source_path(package_dir, source)
        local key = file .. ":" .. number .. ":" .. message
        if not seen[key] then
          seen[key] = true
          local item = {
            filename = file,
            lnum = tonumber(number),
            col = 1,
            text = message ~= "" and message or "Go test failure",
            type = "E",
          }
          table.insert(items, item)
          if vim.startswith(file, package_dir .. "/") then
            table.insert(local_items, item)
          end
        end
      end
    end
  end
  return #local_items > 0 and local_items or items
end

local function output_lines(stdout, stderr)
  local lines = {}
  local raw_output = (stdout or "") .. (stderr or "")
  for line in raw_output:gmatch("[^\r\n]+") do
    local ok, decoded = pcall(vim.json.decode, line)
    local text = ok and type(decoded) == "table" and decoded.Output or line
    if text then
      text = text:gsub("[\r\n]+$", "")
      if text ~= "" then
        table.insert(lines, text)
      end
    end
  end
  return lines
end

local function execute_test(name, package_dir)
  local profile = vim.fn.tempname() .. ".cover"
  local command = { "go", "test", "-json", "-coverprofile=" .. profile }
  if name then
    vim.list_extend(command, { "-run", "^" .. name .. "$" })
  end
  table.insert(command, ".")

  local label = name and ("Test " .. name) or "Test current package"
  task_status.remember(label, function()
    if save_all() then
      execute_test(name, package_dir)
    end
  end)
  local task = task_status.start(label)
  vim.system(command, { cwd = package_dir, text = true }, function(result)
    vim.schedule(function()
      last_output = output_lines(result.stdout, result.stderr)
      local percentage
      if vim.fn.filereadable(profile) == 1 then
        percentage = read_coverage(profile, package_dir)
        vim.uv.fs_unlink(profile)
      end

      if result.code == 0 then
        vim.fn.setqflist({}, "r", { title = "Go test", items = {} })
        task_status.finish(task, true, percentage and ("coverage " .. percentage) or nil)
        return
      end

      local items = failure_items(table.concat(last_output, "\n"), package_dir)
      vim.fn.setqflist({}, "r", { title = "Go test failures", items = items })
      if #items > 0 then
        vim.cmd("cfirst")
        local detail = "jumped to first failure"
        if percentage then
          detail = detail .. " · coverage " .. percentage
        end
        task_status.finish(task, false, detail)
      else
        task_status.finish(task, false, "use :GoTestOutput for details")
      end
    end)
  end)
end

local function run_test(name)
  local _, file = current_go_file()
  if not file or not save_all() then
    return
  end
  execute_test(name, vim.fs.dirname(file))
end

function M.nearest()
  local buf = current_go_file()
  if not buf then
    return
  end
  local name = current_test_name(buf)
  if not name then
    notify("Place the cursor inside a Go test function.", vim.log.levels.ERROR)
    return
  end
  run_test(name)
end

function M.package()
  run_test()
end

function M.output()
  if #last_output == 0 then
    notify("No Go test output is available yet.")
    return
  end
  vim.cmd("botright new")
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "gotest"
  vim.api.nvim_buf_set_name(buf, "Go test output")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, last_output)
  vim.bo[buf].modifiable = false
end

function M.clear_coverage()
  coverage = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      vim.api.nvim_buf_clear_namespace(buf, namespace, 0, -1)
    end
  end
  notify("Coverage markers cleared.")
end

vim.api.nvim_set_hl(0, "GoCoverageUncovered", { link = "DiffDelete", default = true })
vim.api.nvim_set_hl(0, "GoCoverageUncoveredSign", { link = "DiagnosticError", default = true })

vim.api.nvim_create_autocmd("BufEnter", {
  group = vim.api.nvim_create_augroup("nvim-go-coverage", { clear = true }),
  pattern = "*.go",
  callback = function(args)
    apply_coverage(args.buf)
  end,
})

return M
