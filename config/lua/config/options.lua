-- Use Space for project and workflow commands.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Neovim uses UTF-8 internally; only detect and write UTF-8 text files.
vim.opt.encoding = "utf-8"
vim.opt.fileencodings = { "utf-8" }

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.signcolumn = "yes"
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"
vim.opt.confirm = true
vim.opt.autowrite = true
vim.opt.autowriteall = true
vim.opt.wrap = false
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.undofile = true
vim.opt.inccommand = "split"
vim.opt.pumheight = 12
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
