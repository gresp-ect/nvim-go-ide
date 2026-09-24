local M = {}

local last_task

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "Task" })
end

local function elapsed_since(started_at)
  return string.format("%.2fs", (vim.uv.hrtime() - started_at) / 1e9)
end

---@param label string
---@return { label: string, started_at: number }
function M.start(label)
  notify(label .. " started…")
  return { label = label, started_at = vim.uv.hrtime() }
end

---@param task { label: string, started_at: number }
---@param succeeded boolean
---@param detail? string
function M.finish(task, succeeded, detail)
  local outcome = succeeded and "succeeded" or "failed"
  local message = task.label .. " " .. outcome .. " · " .. elapsed_since(task.started_at)
  if detail and detail ~= "" then
    message = message .. " · " .. detail
  end
  notify(message, succeeded and vim.log.levels.INFO or vim.log.levels.ERROR)
end

---@param label string
---@param callback function
function M.remember(label, callback)
  last_task = { label = label, callback = callback }
end

function M.rerun()
  if not last_task then
    notify("No task has been run yet.", vim.log.levels.WARN)
    return
  end
  last_task.callback()
end

return M
