-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- File tree rail (lua/rice/rail.lua)
local rail = require("rice.rail")
vim.keymap.set("n", "<leader>e", rail.toggle, { desc = "File tree: pin open / collapse" })
vim.keymap.set("n", "<C-Left>", rail.left, { desc = "Window left / file tree" })
vim.keymap.set("n", "<C-h>", rail.left, { desc = "Window left / file tree" })
vim.keymap.set("n", "<C-Right>", "<C-w>l", { desc = "Window right" })
-- ← at the start of a line walks into the tree
vim.keymap.set("n", "<Left>", function()
  if vim.fn.col(".") == 1 then
    rail.focus_tree()
  else
    vim.cmd("normal! h")
  end
end, { desc = "Left (into the file tree at the start of a line)" })

-- Tabs
vim.keymap.set("n", "<Tab>", function() rail.cycle(1) end, { desc = "Next tab" })
vim.keymap.set("n", "<S-Tab>", function() rail.cycle(-1) end, { desc = "Previous tab" })
for i = 1, 9 do
  vim.keymap.set("n", "<A-" .. i .. ">", function() rail.goto_tab(i) end, { desc = "Go to tab " .. i })
end
vim.keymap.set("n", "<A-q>", function() Snacks.bufdelete() end, { desc = "Close tab" })
