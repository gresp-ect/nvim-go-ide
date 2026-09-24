-- Register common Go template names so gopls can attach without an unknown
-- filetype warning in :checkhealth vim.lsp.
vim.filetype.add({
  extension = { gotmpl = "gotmpl" },
  pattern = { [".*%.go%.tmpl"] = "gotmpl" },
})

vim.api.nvim_create_autocmd("BufWritePost", {
  group = vim.api.nvim_create_augroup("nvim-go-save-check", { clear = true }),
  pattern = "*.go",
  callback = function(args)
    require("config.save_check").run(args.buf)
  end,
  desc = "Optionally test or vet the current Go package after saving",
})
