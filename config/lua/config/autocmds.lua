-- Register common Go template names so gopls can attach without an unknown
-- filetype warning in :checkhealth vim.lsp.
vim.filetype.add({
  extension = { gotmpl = "gotmpl" },
  pattern = { [".*%.go%.tmpl"] = "gotmpl" },
})
