-- A key-hint line under the status bar. Different hints inside the trash.
-- Wraps onto a second line when the window is narrow.

local HINTS = {
	{ "↵", "open" },
	{ "→", "enter" },
	{ "←", "back" },
	{ "␣", "select" },
	{ "y", "copy" },
	{ "x", "cut" },
	{ "p", "paste" },
	{ "r", "rename" },
	{ "a", "new" },
	{ "d", "trash" },
	{ "D", "delete" },
	{ "/", "find" },
	{ ".", "hidden" },
	{ "g", "go to…" },
	{ "~", "all keys" },
	{ "q", "quit" },
}

local TRASH_HINTS = {
	{ "↵", "restore" },
	{ "O", "delete forever / view" },
	{ "←", "back" },
	{ "␣", "select" },
	{ "/", "find" },
	{ "~", "all keys" },
	{ "q", "quit" },
}

local TRASH_NOTE = "items auto-delete after 30 days "

Hints = { _id = "hints", MAX_LINES = 2 }

local function in_trash(tab) return tostring(tab.current.cwd):find("/.local/share/Trash/files", 1, true) ~= nil end

local function hint_width(h) return utf8.len(h[1]) + 2 + utf8.len(h[2]) + 3 end

-- Split the hints into lines that fit `width` (at most MAX_LINES)
function Hints.wrap(width, trash)
	local list = trash and TRASH_HINTS or HINTS
	local lines, cur, used = {}, {}, 1
	for _, h in ipairs(list) do
		local w = hint_width(h)
		local room = width - 1 - ((trash and #lines == 0) and utf8.len(TRASH_NOTE) or 0)
		if used + w > room and #cur > 0 then
			lines[#lines + 1] = cur
			if #lines == Hints.MAX_LINES then
				return lines
			end
			cur, used = {}, 1
		end
		cur[#cur + 1] = h
		used = used + w
	end
	if #cur > 0 then
		lines[#lines + 1] = cur
	end
	return lines
end

function Hints:new(area, tab) return setmetatable({ _area = area, _tab = tab }, { __index = self }) end

function Hints:reflow() return { self } end

function Hints:click() end

function Hints:scroll() end

function Hints:touch() end

function Hints:redraw()
	local trash = in_trash(self._tab)
	local key_style = ui.Style():patch(th.mode.normal_alt):bold()
	local desc_style = th.which.rest

	local elements = {}
	for i, line in ipairs(Hints.wrap(self._area.w, trash)) do
		local spans = { ui.Span(" ") }
		for _, h in ipairs(line) do
			spans[#spans + 1] = ui.Span(" " .. h[1] .. " "):style(key_style)
			spans[#spans + 1] = ui.Span(" " .. h[2] .. "  "):style(desc_style)
		end
		local row = ui.Rect { x = self._area.x, y = self._area.y + i - 1, w = self._area.w, h = 1 }
		elements[#elements + 1] = ui.Line(spans):area(row)
	end

	if trash then
		local row = ui.Rect { x = self._area.x, y = self._area.y, w = self._area.w, h = 1 }
		elements[#elements + 1] = ui.Line(ui.Span(TRASH_NOTE):style(th.which.desc)):area(row):align(ui.Align.RIGHT)
	end
	return elements
end

-- Give the hint line its own row at the bottom
function Root:layout()
	self._chunks = ui.Layout()
		:direction(ui.Layout.VERTICAL)
		:constraints({
			ui.Constraint.Length(1),
			ui.Constraint.Length(Tabs.height()),
			ui.Constraint.Fill(1),
			ui.Constraint.Length(1),
			ui.Constraint.Length(#Hints.wrap(self._area.w, in_trash(cx.active))),
		})
		:split(self._area)
end

local build = Root.build
function Root:build()
	build(self)
	-- before Modal (last), so popups still draw on top
	table.insert(self._children, #self._children, Hints:new(self._chunks[5], cx.active))
end
