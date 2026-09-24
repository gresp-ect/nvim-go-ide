return {
  -- Keep golangci-lint available through :GoLint, but do not run it on every
  -- write. Full-project linting is too expensive for the save path.
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.go = nil
    end,
  },

  -- Make the save-time Go pipeline explicit: goimports organizes imports and
  -- both tools leave the buffer in canonical gofumpt form before it is written.
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        go = { "goimports", "gofumpt" },
      },
    },
  },

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
    opts = function(_, opts)
      opts.delve = {
        path = vim.fn.expand("~/.local/bin/dlv"),
        detached = vim.fn.has("win32") == 0,
      }
      opts.dap_configurations = require("config.debug").configurations()
    end,
  },

  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>r", group = "Run / Go tools" },
        { "<leader>t", group = "Test" },
        { "<leader>dd", group = "Debug Go" },
      },
    },
  },
}
