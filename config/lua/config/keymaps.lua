local runner = require("config.runner")
local terminal = require("config.terminal")
local go_test = require("config.go_test")

local function shell_command(name, command, description)
  vim.api.nvim_create_user_command(name, function()
    runner.run(command)
  end, { desc = description })
end

vim.api.nvim_create_user_command("Run", function(opts)
  runner.run(opts.args)
end, {
  nargs = "+",
  complete = "shellcmd",
  desc = "Run a shell command in the bottom terminal",
})

vim.api.nvim_create_user_command("Terminal", function(opts)
  terminal.execute(opts.args)
end, {
  nargs = "*",
  complete = "shellcmd",
  desc = "Toggle the persistent bottom terminal or run a command",
})

-- Preserve the familiar built-in spelling while routing exact :terminal and
-- :term commands through the persistent bottom terminal.
vim.cmd([[cnoreabbrev <expr> terminal getcmdtype() ==# ':' && getcmdline() ==# 'terminal' ? 'Terminal' : 'terminal']])
vim.cmd([[cnoreabbrev <expr> term getcmdtype() ==# ':' && getcmdline() ==# 'term' ? 'Terminal' : 'term']])

vim.api.nvim_create_user_command("GoRunFile", runner.go_file, {
  desc = "Run the current Go file",
})
vim.api.nvim_create_user_command("GoRunPackage", runner.go_package, {
  desc = "Run the Go package containing the current file",
})
vim.api.nvim_create_user_command("GoTestNearest", go_test.nearest, {
  desc = "Test the Go test function under the cursor",
})
vim.api.nvim_create_user_command("GoTestPackage", go_test.package, {
  desc = "Test the package containing the current Go file",
})
vim.api.nvim_create_user_command("GoTestOutput", go_test.output, {
  desc = "Show the latest Go test output",
})
vim.api.nvim_create_user_command("GoCoverageClear", go_test.clear_coverage, {
  desc = "Clear Go coverage markers",
})
vim.api.nvim_create_user_command("GoSaveCheckOutput", require("config.save_check").output, {
  desc = "Show the latest Go save-check output",
})

shell_command("GoRun", "go run .", "Run the root Go package")
shell_command("GoBuild", "go build ./...", "Build all Go packages")
shell_command("GoTest", "go test ./...", "Test all Go packages")
shell_command("GoTestVerbose", "go test -v ./...", "Test all Go packages verbosely")
shell_command("GoVet", "go vet ./...", "Vet all Go packages")
shell_command("GoLint", "golangci-lint run ./...", "Lint all Go packages")
shell_command("GoTidy", "go mod tidy", "Tidy the Go module")
shell_command("GoGenerate", "go generate ./...", "Run go generate for all packages")

vim.keymap.set("n", "<F5>", runner.go_package, { desc = "Go: Run current package" })
vim.keymap.set({ "n", "t" }, "<C-/>", terminal.toggle, { desc = "Toggle persistent terminal" })
vim.keymap.set({ "n", "t" }, "<C-_>", terminal.toggle, { desc = "Toggle persistent terminal" })
vim.keymap.set("n", "<leader>rb", "<cmd>GoBuild<cr>", { desc = "Go: Build all packages" })
vim.keymap.set("n", "<leader>rf", "<cmd>GoRunFile<cr>", { desc = "Go: Run current file" })
vim.keymap.set("n", "<leader>rg", "<cmd>GoGenerate<cr>", { desc = "Go: Generate" })
vim.keymap.set("n", "<leader>ri", "<cmd>GoTidy<cr>", { desc = "Go: Tidy module" })
vim.keymap.set("n", "<leader>rl", "<cmd>GoLint<cr>", { desc = "Go: Lint all packages" })
vim.keymap.set("n", "<leader>rp", "<cmd>GoRunPackage<cr>", { desc = "Go: Run current package" })
vim.keymap.set("n", "<leader>rr", "<cmd>GoRun<cr>", { desc = "Go: Run root package" })
vim.keymap.set("n", "<leader>tn", "<cmd>GoTestNearest<cr>", { desc = "Go: Test function" })
vim.keymap.set("n", "<leader>tp", "<cmd>GoTestPackage<cr>", { desc = "Go: Test current package" })
vim.keymap.set("n", "<leader>to", "<cmd>GoTestOutput<cr>", { desc = "Go: Show test output" })
vim.keymap.set("n", "<leader>tc", "<cmd>GoCoverageClear<cr>", { desc = "Go: Clear coverage" })
vim.keymap.set("n", "<leader>rt", "<cmd>GoTest<cr>", { desc = "Go: Test all packages" })
vim.keymap.set("n", "<leader>rv", "<cmd>GoTestVerbose<cr>", { desc = "Go: Test all packages (verbose)" })
vim.keymap.set("n", "<leader>rV", "<cmd>GoVet<cr>", { desc = "Go: Vet all packages" })
