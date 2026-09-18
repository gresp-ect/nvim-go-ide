local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local uv = vim.uv or vim.loop

if not uv.fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local output = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    lazyrepo,
    lazypath,
  })

  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to install lazy.nvim:\n", "ErrorMsg" },
      { output, "WarningMsg" },
    }, true, {})
    os.exit(1)
  end
end

vim.opt.rtp:prepend(lazypath)

local spec = {
  { "LazyVim/LazyVim", import = "lazyvim.plugins" },
  { import = "lazyvim.plugins.extras.lang.go" },
  { import = "lazyvim.plugins.extras.dap.core" },
  { import = "lazyvim.plugins.extras.test.core" },
  { import = "plugins" },
}

local local_plugins = vim.fn.expand("~/.config/nvim-go-ide/plugins.lua")
if vim.fn.filereadable(local_plugins) == 1 then
  local ok, plugins = pcall(dofile, local_plugins)
  if ok and type(plugins) == "table" then
    vim.list_extend(spec, plugins)
  elseif not ok then
    vim.schedule(function()
      vim.notify("Could not load local plugins:\n" .. tostring(plugins), vim.log.levels.ERROR, {
        title = "nvim-go-ide",
      })
    end)
  end
end

require("lazy").setup({
  spec = spec,
  defaults = {
    lazy = false,
    version = false,
  },
  install = { colorscheme = { "tokyonight", "habamax" } },
  -- None of the selected plugins needs LuaRocks; disabling it keeps the
  -- health report focused and avoids installing an unused Lua runtime.
  rocks = { enabled = false, hererocks = false },
  checker = {
    enabled = true,
    notify = false,
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
