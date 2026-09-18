return {
  -- Activates the golangci-lint integration declared by LazyVim's Go extra.
  { "mfussenegger/nvim-lint" },

  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      -- These tools are installed and versioned in ~/.local/bin. Keeping them
      -- out of Mason avoids duplicate downloads and PATH ambiguity.
      local external = {
        delve = true,
        gofumpt = true,
        goimports = true,
        golangci_lint = true,
        ["golangci-lint"] = true,
        gomodifytags = true,
        impl = true,
        ["tree-sitter-cli"] = true,
      }
      opts.ensure_installed = vim.tbl_filter(function(tool)
        return not external[tool]
      end, opts.ensure_installed or {})
    end,
  },

  -- Show gopls parameter and inferred-type hints directly in Go buffers.
  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hints = { enabled = true },
      servers = {
        -- Core Go tools live in ~/.local/bin, so use the verified system binary
        -- instead of waiting for a duplicate Mason installation.
        gopls = {
          mason = false,
          settings = {
            gopls = {
              completeFunctionCalls = true,
            },
          },
        },
      },
    },
  },

  -- Load completion on demand and show function signatures while typing.
  {
    "saghen/blink.cmp",
    opts = {
      signature = { enabled = true },
    },
  },

  -- Reuse the verified Delve installation from ~/.local/bin.
  {
    "leoluz/nvim-dap-go",
    lazy = true,
    opts = {
      delve = {
        path = vim.fn.expand("~/.local/bin/dlv"),
        detached = vim.fn.has("win32") == 0,
      },
    },
  },

  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>r", group = "Run / Go" },
      },
    },
  },
}
