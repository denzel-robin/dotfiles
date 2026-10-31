-- File tree "rail": a narrow strip left of the editor with a little info about the
-- project and a hint to expand it; expands into the full neo-tree.
--
--   collapsed: 4 columns — folder/file counts, git changes, "» ␣e" hint at the bottom
--   expanded:  neo-tree. Entering it with ← / Ctrl+← expands it until you leave again;
--              Space+e pins it open (or collapses it).
local M = {
  collapsed_width = 4,
  expanded_width = 32,
  pinned = false, -- expanded with Space+e: stays open when you leave it
}

local api = vim.api
local rail_buf
local suppress = false -- true while we open/close windows ourselves
local ns = api.nvim_create_namespace("rice-rail")

local function filetype(win)
  return vim.bo[api.nvim_win_get_buf(win)].filetype
end

local function is_tree(win)
  return filetype(win) == "neo-tree"
end

local function is_rail(win)
  return filetype(win) == "rice-rail"
end

local function is_special(win)
  return is_tree(win) or is_rail(win)
end

local function normal_wins()
  return vim.tbl_filter(function(w)
    return api.nvim_win_get_config(w).relative == ""
  end, api.nvim_tabpage_list_wins(0))
end

local function find(pred)
  for _, w in ipairs(normal_wins()) do
    if pred(w) then
      return w
    end
  end
end

function M.tree_win()
  return find(is_tree)
end

function M.rail_win()
  return find(is_rail)
end

-- The editor window to return to: the previous window if it's an editor, else any editor
function M.editor_win()
  local prev = vim.fn.win_getid(vim.fn.winnr("#"))
  if prev ~= 0 and api.nvim_win_is_valid(prev) and api.nvim_win_get_config(prev).relative == "" and not is_special(prev) then
    return prev
  end
  return find(function(w)
    return not is_special(w)
  end)
end

-- ── Rail contents ─────────────────────────────────────────────────────────────

M.git_changes = nil

local function count_entries(dir)
  local dirs, files = 0, 0
  for _, name in ipairs(vim.fn.readdir(dir) or {}) do
    if name:sub(1, 1) ~= "." then
      if vim.fn.isdirectory(dir .. "/" .. name) == 1 then
        dirs = dirs + 1
      else
        files = files + 1
      end
    end
  end
  return dirs, files
end

function M.refresh_git()
  vim.system({ "git", "-C", vim.fn.getcwd(), "status", "--porcelain" }, { text = true }, function(res)
    local n = nil
    if res.code == 0 then
      n = #vim.split(vim.trim(res.stdout), "\n", { trimempty = true })
    end
    vim.schedule(function()
      M.git_changes = n
      M.render()
    end)
  end)
end

local function num(n)
  return n > 999 and " 1k+" or string.format(" %d", n)
end

function M.render()
  local win = M.rail_win()
  if not win or not rail_buf or not api.nvim_buf_is_valid(rail_buf) then
    return
  end
  local height = api.nvim_win_get_height(win)
  local dirs, files = count_entries(vim.fn.getcwd())

  local lines, hls = {}, {}
  local function add(text, group)
    table.insert(lines, text)
    hls[#lines] = group
  end
  add(" 󰉋", "Directory")
  add(num(dirs), "RiceRailText")
  add("")
  add(" 󰈔", "RiceRailIcon")
  add(num(files), "RiceRailText")
  if M.git_changes and M.git_changes > 0 then
    add("")
    add(" ", "RiceRailGit")
    add(num(M.git_changes), "RiceRailGit")
  end
  while #lines < height - 2 do
    add("")
  end
  add(" »", "RiceRailHint")
  add(" ␣e", "RiceRailDim")

  vim.bo[rail_buf].modifiable = true
  api.nvim_buf_set_lines(rail_buf, 0, -1, false, lines)
  vim.bo[rail_buf].modifiable = false
  api.nvim_buf_clear_namespace(rail_buf, ns, 0, -1)
  for i, group in pairs(hls) do
    if group then
      api.nvim_buf_set_extmark(rail_buf, ns, i - 1, 0, { end_row = i - 1, end_col = #lines[i], hl_group = group })
    end
  end
end

-- ── Opening / closing ────────────────────────────────────────────────────────

local function rail_buffer()
  if rail_buf and api.nvim_buf_is_valid(rail_buf) then
    return rail_buf
  end
  rail_buf = api.nvim_create_buf(false, true)
  vim.bo[rail_buf].filetype = "rice-rail"
  vim.bo[rail_buf].bufhidden = "hide"
  vim.bo[rail_buf].swapfile = false
  -- Clicking or pressing a key in the rail just opens the tree
  for _, key in ipairs({ "<CR>", "<Right>", "<LeftMouse>", "l" }) do
    vim.keymap.set("n", key, function()
      M.focus_tree()
    end, { buffer = rail_buf, nowait = true })
  end
  return rail_buf
end

function M.open_rail()
  if M.rail_win() or M.tree_win() then
    return
  end
  local cur = api.nvim_get_current_win()
  suppress = true
  local win = api.nvim_open_win(rail_buffer(), false, { split = "left", win = -1, width = M.collapsed_width })
  suppress = false
  local opts = {
    number = false, relativenumber = false, signcolumn = "no", foldcolumn = "0", statuscolumn = "",
    cursorline = false, wrap = false, list = false, spell = false, winfixwidth = true, winbar = "",
  }
  for k, v in pairs(opts) do
    vim.wo[win][k] = v
  end
  if api.nvim_win_is_valid(cur) then
    api.nvim_set_current_win(cur)
  end
  M.refresh_git()
  M.render()
end

function M.expand(focus)
  suppress = true
  local rail = M.rail_win()
  if rail then
    api.nvim_win_close(rail, true)
  end
  require("neo-tree.command").execute({
    action = focus and "focus" or "show",
    source = "filesystem",
    position = "left",
    reveal = true,
  })
  suppress = false
end

function M.collapse()
  if M.tree_win() then
    suppress = true
    require("neo-tree.command").execute({ action = "close" })
    suppress = false
  end
  M.open_rail()
end

-- ── Actions (used by keymaps) ────────────────────────────────────────────────

-- Space+e: pin the tree open, or collapse it
function M.toggle()
  if M.tree_win() then
    M.pinned = false
    M.collapse()
  else
    M.pinned = true
    M.expand(true)
  end
end

-- ← / Ctrl+←: go into the tree (expanding the rail)
function M.focus_tree()
  local tree = M.tree_win()
  if tree then
    api.nvim_set_current_win(tree)
  else
    M.expand(true)
  end
end

-- → / Ctrl+→ from the tree: back to the editor (collapsing unless pinned)
function M.focus_editor()
  local ed = M.editor_win()
  if ed then
    api.nvim_set_current_win(ed)
  end
  if not M.pinned and M.tree_win() then
    M.collapse()
  end
end

-- Ctrl+← in the editor: a split to the left first, otherwise the tree
function M.left()
  local cur = api.nvim_get_current_win()
  vim.cmd("wincmd h")
  local now = api.nvim_get_current_win()
  if now == cur or is_special(now) then
    M.focus_tree()
  end
end

-- Tab keys always act on the editor's tabs, even from inside the tree
local function in_editor()
  if is_special(api.nvim_get_current_win()) then
    local ed = M.editor_win()
    if ed then
      api.nvim_set_current_win(ed)
    end
  end
end

function M.cycle(dir)
  in_editor()
  vim.cmd(dir > 0 and "BufferLineCycleNext" or "BufferLineCyclePrev")
end

function M.goto_tab(n)
  in_editor()
  vim.cmd("BufferLineGoToBuffer " .. n)
end

-- ── Neo-tree hooks (wired in lua/plugins/tree.lua) ──────────────────────────

-- → in the tree: open a closed folder, otherwise go back to the editor
function M.tree_right(state)
  local node = state.tree:get_node()
  if node.type == "directory" and not node:is_expanded() then
    state.commands["toggle_node"](state)
  else
    M.focus_editor()
  end
end

-- ← in the tree: close an open folder, otherwise go up to the parent
function M.tree_left(state)
  local node = state.tree:get_node()
  if node.type == "directory" and node:is_expanded() then
    state.commands["toggle_node"](state)
  else
    require("neo-tree.ui.renderer").focus_node(state, node:get_parent_id())
  end
end

function M.on_file_opened()
  if not M.pinned then
    vim.schedule(M.collapse)
  end
end

function M.on_tree_closed()
  if not suppress then
    M.pinned = false
    vim.schedule(M.open_rail)
  end
end

-- ── Autocommands ─────────────────────────────────────────────────────────────

local function wants_rail(buf)
  local ft = vim.bo[buf].filetype
  return vim.bo[buf].buftype == "" and ft ~= "" and ft ~= "snacks_dashboard" and ft ~= "rice-rail" and ft ~= "neo-tree"
    and api.nvim_buf_get_name(buf) ~= ""
end

function M.setup()
  local group = api.nvim_create_augroup("rice-rail", { clear = true })

  vim.api.nvim_set_hl(0, "RiceRailText", { link = "Comment", default = true })
  vim.api.nvim_set_hl(0, "RiceRailIcon", { link = "Special", default = true })
  vim.api.nvim_set_hl(0, "RiceRailGit", { link = "DiagnosticWarn", default = true })
  vim.api.nvim_set_hl(0, "RiceRailHint", { link = "Function", default = true })
  vim.api.nvim_set_hl(0, "RiceRailDim", { link = "Comment", default = true })

  -- Show the rail whenever a real file is open
  api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function(ev)
      if wants_rail(ev.buf) and not is_special(api.nvim_get_current_win()) then
        vim.schedule(M.open_rail)
      end
    end,
  })

  -- Clicking into the rail opens the tree
  api.nvim_create_autocmd("WinEnter", {
    group = group,
    callback = function()
      if not suppress and is_rail(api.nvim_get_current_win()) then
        vim.schedule(M.focus_tree)
      end
    end,
  })

  -- Leaving the tree any other way (e.g. clicking the editor) collapses it too
  api.nvim_create_autocmd("WinLeave", {
    group = group,
    callback = function()
      if suppress or M.pinned or not is_tree(api.nvim_get_current_win()) then
        return
      end
      vim.schedule(function()
        local now = api.nvim_get_current_win()
        if api.nvim_win_get_config(now).relative == "" and not is_special(now) and M.tree_win() and not M.pinned then
          M.collapse()
        end
      end)
    end,
  })

  -- Only the rail/tree left (last file closed): quit instead of being stuck in it
  api.nvim_create_autocmd("WinClosed", {
    group = group,
    callback = function()
      vim.schedule(function()
        local wins = normal_wins()
        if #wins > 0 and vim.iter(wins):all(is_special) then
          vim.cmd("quitall")
        end
      end)
    end,
  })

  api.nvim_create_autocmd({ "VimResized", "WinResized" }, { group = group, callback = M.render })
  api.nvim_create_autocmd({ "DirChanged", "BufWritePost", "FocusGained" }, { group = group, callback = M.refresh_git })

  -- A file may already be open by the time this runs
  if wants_rail(api.nvim_get_current_buf()) then
    vim.schedule(M.open_rail)
  end
end

return M
