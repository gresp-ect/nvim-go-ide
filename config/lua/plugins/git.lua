return {
  -- LazyVim already provides GitSigns and its Git hunk mappings. Keep those
  -- defaults and enable the IDE-style context that is useful while editing.
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      signcolumn = true,
      attach_to_untracked = true,
      current_line_blame = true,
      current_line_blame_opts = {
        delay = 500,
        ignore_whitespace = true,
        virt_text_pos = "eol",
      },
    },
  },
}
