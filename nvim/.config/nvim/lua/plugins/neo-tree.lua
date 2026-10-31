-- File tree: collapsed to a narrow "rail" by default, expands into neo-tree
-- (see lua/rice/rail.lua for the behaviour).
return {
  "nvim-neo-tree/neo-tree.nvim",
  keys = {
    { "<leader>e", false }, -- replaced by the rail toggle (lua/config/keymaps.lua)
    { "<leader>E", false },
  },
  opts = function(_, opts)
    local rail = require("rice.rail")
    opts.close_if_last_window = false -- the rail handles quitting
    opts.window = opts.window or {}
    opts.window.width = rail.expanded_width
    opts.window.mappings = vim.tbl_extend("force", opts.window.mappings or {}, {
      ["<Right>"] = rail.tree_right,   -- open folder / back to the editor
      ["<Left>"] = rail.tree_left,     -- close folder / up to the parent
      ["<C-Right>"] = function() rail.focus_editor() end,
      ["<C-l>"] = function() rail.focus_editor() end,
      ["<Tab>"] = function() rail.cycle(1) end,
      ["<S-Tab>"] = function() rail.cycle(-1) end,
    })
    opts.event_handlers = opts.event_handlers or {}
    table.insert(opts.event_handlers, { event = "file_opened", handler = rail.on_file_opened })
    table.insert(opts.event_handlers, { event = "neo_tree_window_after_close", handler = rail.on_tree_closed })
  end,
}
