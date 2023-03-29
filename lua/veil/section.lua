local fn = vim.fn
local hl_id = fn.hlID
local hl_attr = fn.synIDattr

local noop = function() end

local Highlight = {
	---@type string Hex color
	fg = hl_attr(hl_id("Normal"), "fg", "gui"),
	---@type string Hex color
	bg = hl_attr(hl_id("Normal"), "bg", "gui"),
	bold = false,
	italic = false,
	underline = false,
}

---@class Chunk
local Chunk = {
	---@type string
	text = "",
	---@type string|Highlight Highlight group or highlight table
	hl = "Normal",
}

---@class Section
---@field title? Chunk | fun(self: Section): Chunk
---Content provider, can be a function, Line, or list of lines
---This should be used to generate content, not to update state
---@field content Line | Line[] | fun(self: Section): Line | Line[]
---Called once, when the section is first created
---@field init? fun(self: Section)
---Whether or not the section should update
---If false, the section will only be updated on init, or when the user interacts with it
---Will always be false when content is not a function
---@field should_update boolean | fun(self: Section): boolean
---Called when the section should update
---This should be used to update state
---@field update fun(self: Section)
---Persistent state table, the only part of the section that can be mutated at runtime
---Will be created regardless of whether it is initialized in `init` or `Section:new()`
---@field state? table
---Whether or not the section is interactive
---@field interactive? boolean
---Called when the user interacts with the section with <CR>
---@field interact? fun(self: Section, offset: integer)
---@field index? integer The index of the section in the stack
---The cursor relative to the focused section (interactive only)
---Whether the section is focused
---@field focused? boolean
---Will be -1 if the section is not focused
---@field focus_offset integer
local Section = {}
Section.content = { text = "Override this", hl = "Normal" }
Section.interact = noop
Section.init = noop
Section.update = noop
Section.should_update = false
Section.interactive = false
Section.focused = false
Section.focus_offset = -1

local mutable = {
	state = true,
	focused = true,
	focused_offset = true,
}
local only_allow_state_change = function(tbl, k, v)
	if mutable[k] then
		rawset(tbl, k, v)
	else
		vim.api.nvim_err_writeln("Can only mutate `section.state` after initialization, attempted to mutate " .. k)
	end
end

---@param init boolean Whether to call the init function
function Section:render(init)
	if init then
		self:init()
		if self.title ~= nil and type(self.title) == "function" then
			rawset(self, "title", self:title())
		end
	end
	local should_update = self.should_update
	if type(self.should_update) == "function" then
		should_update = self:should_update()
	else
		should_update = self.should_update
	end
	if init or self.focused or should_update then
		self:update()
	end
	local title = self.title
	---@type Line | Line[]
	local content
	if type(self.content) == "function" then
		content = self:content()
	else
		content = self.content
	end
	local nlines = 1
	if vim.tbl_islist(content) then
		nlines = #content
	else
		content = { { content } }
	end
	rawset(self, "nlines", nlines)
	return {
		-- nil title will be handled in Veil:redraw()
		title = title,
		content = content,
		nlines = nlines,
		interactive = self.interactive,
		interact = function(...)
			self:interact(...)
		end,
	}
end

---@param self Section Base class
---@param proto Section|table Section prototype / config
---@return Section instance The new instance
function Section:new(proto, idx)
	local instance = {}
	if proto ~= nil then
		instance.state = proto.state or {}
		instance.title = proto.title
		instance.content = proto.content
		instance.update = proto.update
		instance.should_update = proto.should_update
		instance.interact = proto.interact
		instance.interactive = proto.interactive
		instance.init = proto.init
	else
		-- New state should always be created
		-- Never mutate the original state
		instance.state = {}
	end
	instance.index = idx
	return setmetatable(instance, {
		__index = self,
		__newindex = only_allow_state_change,
	})
end

return Section
