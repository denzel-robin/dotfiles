-- Claude Code inside Neovim (LazyVim extra "ai.claudecode", plugin coder/claudecode.nvim).
-- Claude opens on the right; the file tree rail stays on the left.
return {
  "coder/claudecode.nvim",
  opts = {
    terminal = {
      split_side = "right",
      split_width_percentage = 0.35,
    },
  },
  init = function()
    -- Ctrl+←/→ leave the Claude panel like any other window (terminals capture keys otherwise)
    vim.api.nvim_create_autocmd("TermOpen", {
      callback = function(ev)
        vim.keymap.set("t", "<C-Left>", [[<C-\><C-n><Cmd>lua require("rice.rail").left()<CR>]], { buffer = ev.buf, desc = "Window left" })
        vim.keymap.set("t", "<C-Right>", [[<C-\><C-n><C-w>l]], { buffer = ev.buf, desc = "Window right" })
      end,
    })
  end,
}
