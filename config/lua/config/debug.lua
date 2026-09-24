local M = {}

local config_name = ".nvim-go-debug.json"

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "Go debug" })
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

local function project_root(file)
  local go_mod = vim.fs.find("go.mod", { path = vim.fs.dirname(file), upward = true })[1]
  if not go_mod then
    notify("Could not find go.mod for the current file.", vim.log.levels.ERROR)
    return
  end
  return vim.fs.dirname(go_mod)
end

local function validate_args(value, location)
  if value == nil then
    return {}
  end
  if not vim.islist(value) then
    return nil, location .. ".args must be an array of strings"
  end
  for _, argument in ipairs(value) do
    if type(argument) ~= "string" then
      return nil, location .. ".args must contain only strings"
    end
  end
  return value
end

local function validate_env(value, location)
  if value == nil then
    return {}
  end
  if type(value) ~= "table" or vim.islist(value) then
    return nil, location .. ".env must be an object with string values"
  end
  for name, content in pairs(value) do
    if type(name) ~= "string" or type(content) ~= "string" then
      return nil, location .. ".env must contain only string keys and values"
    end
  end
  return value
end

local function project_settings(root, kind)
  local path = root .. "/" .. config_name
  if vim.fn.filereadable(path) == 0 then
    return { args = {}, env = {} }
  end

  local read_ok, lines = pcall(vim.fn.readfile, path)
  local decode_ok, decoded = false, nil
  if read_ok then
    decode_ok, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
  end
  if not decode_ok or type(decoded) ~= "table" or vim.islist(decoded) then
    return nil, config_name .. " must contain a JSON object"
  end

  local args, args_error = validate_args(decoded.args, config_name)
  local env, env_error = validate_env(decoded.env, config_name)
  if args_error or env_error then
    return nil, args_error or env_error
  end

  local override = decoded[kind]
  if override ~= nil then
    if type(override) ~= "table" or vim.islist(override) then
      return nil, config_name .. "." .. kind .. " must be an object"
    end
    local override_args, override_args_error = validate_args(override.args, config_name .. "." .. kind)
    local override_env, override_env_error = validate_env(override.env, config_name .. "." .. kind)
    if override_args_error or override_env_error then
      return nil, override_args_error or override_env_error
    end
    vim.list_extend(args, override_args)
    env = vim.tbl_extend("force", env, override_env)
  end

  return { args = args, env = env }
end

local function configuration(kind)
  local buf, file = current_go_file()
  if not file then
    return
  end
  local root = project_root(file)
  if not root then
    return
  end
  local settings, err = project_settings(root, kind)
  if not settings then
    notify(err, vim.log.levels.ERROR)
    return
  end

  local names = {
    current_file = "Go: Current file",
    current_package = "Go: Current package",
    current_test = "Go: Current test",
  }
  local config = {
    type = "go",
    request = "launch",
    name = names[kind],
    cwd = root,
    program = kind == "current_file" and file or vim.fs.dirname(file),
    args = vim.deepcopy(settings.args),
    env = settings.env,
  }

  if kind == "current_test" then
    local test_name = require("config.go_test").current_test_name(buf)
    if not test_name then
      notify("Place the cursor inside a Go test function.", vim.log.levels.ERROR)
      return
    end
    config.mode = "test"
    config.args = vim.list_extend({ "-test.run", "^" .. test_name .. "$" }, config.args)
  else
    config.mode = "debug"
  end

  return config
end

local function start(kind)
  local config = configuration(kind)
  if config then
    require("dap").run(config)
  end
end

function M.file()
  start("current_file")
end

function M.package()
  start("current_package")
end

function M.test()
  start("current_test")
end

-- nvim-dap also exposes these templates through its configuration picker.
function M.configurations()
  local configurations = {}
  for _, kind in ipairs({ "current_file", "current_package", "current_test" }) do
    local template = {
      type = "go",
      request = "launch",
      name = ({
        current_file = "Go: Current file",
        current_package = "Go: Current package",
        current_test = "Go: Current test",
      })[kind],
    }
    setmetatable(template, {
      __call = function()
        return configuration(kind) or require("dap").ABORT
      end,
    })
    table.insert(configurations, template)
  end
  return configurations
end

return M
