local M = {}

local Object = require("nui.object")
local Layout, Box = require("nui.layout"), require("nui.layout").Box
local Popup = require("nui.popup")

---NOTE: THIS IS SOOOOOO WIP

---@class Veil.Class
---@field name string

---@class Veil.Object: Object
---@field extend fun(self: Veil.Component, classname: string): any
---@field class Veil.Class

---@class Veil.Component: Veil.Object
local Component = Object("Component")

---@param cx Veil.Runtime
---@return NuiLayout.Box
---@diagnostic disable-next-line: unused-local
function Component:build(cx)
	error(("Component:build must be implemented for %s"):format(self.class.name))
end

function Component:update() end

---@return Veil.Component[]
function Component:children()
	return {}
end

---@class Veil.Row: Veil.Component
local Row = Component:extend("Row")

function Row:init(...)
	self._children = { ... }
end

function Row:build(cx)
	cx:create_effect(function()
		self.inner = Box(
			vim.iter(self:children())
				:map(function(c)
					return c:build(cx)
				end)
				:totable(),
			{ dir = "row" }
		)
		cx:update_layout()
	end)
	return self.inner
end

function Row:children()
	if type(self._children[1]) == "function" then
		return self._children[1]()
	end
	return self._children
end

---@class Veil.Col: Veil.Component
local Col = Component:extend("Col")

function Col:init(...)
	self._children = { ... }
end

function Col:build(cx)
	cx:create_effect(function()
		self.inner = Box(
			vim.iter(self:children())
				:map(function(c)
					return c:build(cx)
				end)
				:totable(),
			{ dir = "col" }
		)
		cx:update_layout()
	end)
	return self.inner
end

function Col:children()
	if type(self._children[1]) == "function" then
		return self._children[1]()
	end
	return self._children
end

---@class Veil.Paragraph: Veil.Component
local Paragraph = Component:extend("Paragraph")

---@param lines string | string[] | fun(): (string | string[])
---@param props nui_layout_box_options
function Paragraph:init(lines, props)
	self.props = props or {
		grow = 1,
	}
	self.popup = Popup({})
	self.popup:_buf_create()
	self.lines = lines
end

function Paragraph:build(cx)
	cx:create_effect(function()
		local val = self.lines
		if type(val) == "function" then
			val = val()
		end
		if type(val) == "string" then
			val = { val }
		end
		vim.api.nvim_buf_set_lines(self.popup.bufnr, 0, -1, true, val or {})
	end)
	return Box(self.popup, self.props)
end

---@class Veil.Runtime: Veil.Object
---@field private effects table<integer, fun()>
---@field private running_effect integer?
---@field private next_effect_id integer
---@field private update_callbacks fun()[]
---@field private next_update_cb_id integer
---@overload fun(): Veil.Runtime
local Runtime = Object("Runtime")

function Runtime:update_layout()
	self.block_recursive_effects = true
	for _, update in pairs(self.update_callbacks) do
		update()
	end
	self.block_recursive_effects = false
end

function Runtime:init()
	self.effects = {}
	self.next_effect_id = 1
	self.update_callbacks = {}
	self.next_update_cb_id = 1
	self.block_recursive_effects = false
end

function Runtime:register_update_cb(cb)
	local id = self.next_update_cb_id + 1
	self.next_update_cb_id = id + 1

	self.update_callbacks[id] = cb

	return id
end

function Runtime:run_effect(id)
	if self.block_recursive_effects then
		return
	end
	local cb = self.effects[id]
	if cb then
		local prev = self.running_effect
		self.running_effect = id
		cb()
		self.running_effect = prev
	end
end

function Runtime:create_effect(cb)
	local id = self.next_effect_id
	self.next_effect_id = id + 1

	self.effects[id] = cb

	self:run_effect(id)

	return id
end

function Runtime:remove_effect(id)
	self.effects[id] = nil
end

---@generic T
---@param init T
---@return fun(): T get
---@return fun(value: T | fun(prev: T): T) set
function Runtime:create_signal(init)
	local subscribers = {}

	local function get()
		if not self.running_effect then
			error("attempted to access a signal from outside of a reactive tracking context")
		end
		subscribers[self.running_effect] = true

		return init
	end

	local function set(val)
		if type(val) == "function" then
			init = val(init)
		else
			init = val
		end
		for id in pairs(subscribers) do
			subscribers[id] = nil
			self:run_effect(id)
		end
	end

	return get, set
end

---@class Veil.App: Veil.Object
---@field layout Veil.Component
---@field props nui_layout_options
---@field inner NuiLayout
---@overload fun(layout: Veil.Component | fun(cx: Veil.Runtime): Veil.Component, props: nui_layout_options?): Veil.App
local App = Object("App")

---@param layout Veil.Component | fun(cx: Veil.Runtime): Veil.Component
---@param props nui_layout_options?
function App:init(layout, props)
	assert(layout, "missing required parameter 'layout'")
	self.runtime = Runtime()
	self.props = vim.tbl_deep_extend("force", {
		position = "50%",
		size = {
			width = 0.5,
			height = 0.5,
		},
	}, props or {})

	if type(layout) == "function" then
		self.layout = layout(self.runtime)
	else
		self.layout = layout
	end

	self.inner = Layout(self.props, self.layout:build(self.runtime))
	self.runtime:register_update_cb(function()
		self.inner:update(self.props, self.layout:build(self.runtime))
	end)
end

function App:update(layout)
	self.layout = layout
	self.inner:update(self.props, self.layout:build(self.runtime))
end

function App:mount()
	self.inner:mount()
end

function App:unmount()
	self.inner:unmount()
end

local app = App(function(cx)
	local ltext, set_ltext = cx:create_signal("test")

	local children, set_children = cx:create_signal({
		Paragraph(ltext),
		Paragraph({ "test2" }),
	})

	vim.keymap.set("n", "<leader>1", function()
		set_ltext(function(text)
			return text .. "1"
		end)
	end, {})

	vim.keymap.set("n", "<leader>2", function()
		set_children(function(ch)
			table.insert(ch, Paragraph(ltext))
			return ch
		end)
	end, {})

	vim.keymap.set("n", "<leader>3", function()
		set_children(function(ch)
			table.remove(ch)
			return ch
		end)
	end, {})

	return Row(children)
end)
app:mount()

return M
