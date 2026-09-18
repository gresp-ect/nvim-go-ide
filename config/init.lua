if vim.fn.has("nvim-0.11.2") == 0 then
  local version = vim.version()
  local version_text = table.concat({ version.major, version.minor, version.patch }, ".")
  vim.api.nvim_echo({
    { "This configuration requires Neovim 0.11.2 or newer; detected " .. version_text .. ".\n", "ErrorMsg" },
    { "Run: hash -r && ~/.local/bin/nvim\n", "WarningMsg" },
  }, true, {})
  return
end

require("config.lazy")

local local_config = vim.fn.expand("~/.config/nvim-go-ide/local.lua")
if vim.fn.filereadable(local_config) == 1 then
  local ok, err = pcall(dofile, local_config)
  if not ok then
    vim.schedule(function()
      vim.notify("Could not load local configuration:\n" .. tostring(err), vim.log.levels.ERROR, {
        title = "nvim-go-ide",
      })
    end)
  end
end
