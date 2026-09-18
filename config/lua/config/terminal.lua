local M = {}

local session_cwd

local function terminal_options()
  session_cwd = session_cwd or LazyVim.root.get()

  return {
    cwd = session_cwd,
    interactive = true,
    auto_close = true,
    win = {
      position = "bottom",
      height = 0.35,
    },
  }
end

function M.toggle()
  Snacks.terminal.toggle(nil, terminal_options())
end

---@param command string
function M.execute(command)
  if command == "" then
    M.toggle()
    return
  end

  require("config.runner").run(command)
end

return M
