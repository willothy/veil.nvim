---@class Veil.Rect
---@field x number
---@field y number
---@field width number
---@field height number
local Rect = {}

---@return Veil.Rect
function Rect:new(x, y, width, height)
	local o = {
		x = x,
		y = y,
		width = width,
		height = height,
	}
	setmetatable(o, self)
	self.__index = self
	return o
end

---@class Veil.Highlight
---@field fg string
---@field bg string
---@field style string
---@field sp string
---@field bold boolean
---@field italic boolean
---@field underline boolean

---@class Veil.Chunk
---@field str string
---@field hl string | Veil.Highlight
local Chunk = {}

---@return Veil.Chunk
function Chunk:new(str, hl)
	local o = {
		str = str,
		hl = hl,
	}
	setmetatable(o, self)
	self.__index = self
	return o
end

---@class Line
---@field chunks Veil.Chunk[]
local Line = {}

function Line:new(chunks, action)
	local o = {
		chunks = chunks,
		action = action,
	}
	setmetatable(o, self)
	self.__index = self
	return o
end

function Line:from_str(str, hl)
	return Line:new({ Chunk:new(str, hl) })
end

function Line:width()
	return vim.iter(self.chunks):fold(0, function(acc, cnk)
		return acc + #cnk.str
	end)
end

function Line:lpad(padding)
	table.insert(self.chunks, 1, { str = string.rep(" ", padding), hl = "Normal" })
end

function Line:rpad(padding)
	table.insert(self.chunks, { str = string.rep(" ", padding), hl = "Normal" })
end

function Line:pad_to(width)
	local padding = math.floor((width - self:width()) / 2)
	self:lpad(padding)
	self:rpad(padding)
end

---@class Veil.Render
---@field content Veil.Line[]
---@field geometry Veil.Rect
local Render = {}

function Render:new(content, geometry)
	local o = {
		content = content,
		geometry = geometry,
	}
	setmetatable(o, self)
	self.__index = self
	return o
end

---@enum Veil.EventType
---@field AUTOCMD string
---@field TICK string
local EventType = {
	AUTOCMD = "autocmd",
	TICK = "tick",
}

---@class Veil.Event
---@field type Veil.EventType
---@field autocmd? string
local Event = {
	TICK = { type = EventType.TICK },
}

---@param type Veil.EventType
---@param autocmd? string
function Event:new(type, autocmd)
	local o = {
		type = type,
		autocmd = autocmd,
	}
	setmetatable(o, self)
	self.__index = self
	return o
end

function Event:autocmd(autocmd)
	return Event:new(EventType.AUTOCMD, autocmd)
end

---@alias Veil.Section.State table<string, any>
---@alias Veil.Section.Id integer
---@class Veil.Section
---@field title string
---@field provider fun(state: Veil.Section.State): Veil.Line[]
---@field init fun(state: Veil.Section.State)
---@field update fun(state: Veil.Section.State)
---@field on_key fun(state: Veil.Section.State, key: string)
---@field events Veil.Event[]
---@field state Veil.Section.State
---@field id Veil.Section.Id
local Section = {}

---@param opts Veil.Section
---@return Veil.Section
function Section:new(opts, id)
	local provider = opts.provider
	if not provider then
		vim.api.nvim_err_writeln(
			string.format("Section %s does not have a provider function", opts.title or "<unknown>")
		)
	end
	local o = {
		title = opts.title or "",
		provider = provider,
		events = opts.events or {},
		update = opts.update,
		state = {},
		id = id,
	}
	if opts.init then
		opts.init(o.state)
	end
	setmetatable(o, self)
	self.__index = self
	return o
end

---@return Veil.Render
function Section:render(width, start_line)
	local content = self:provider(self.state)
	local geometry = Rect:new(0, start_line, width, #content)
	return Render:new(content, geometry)
end

---@class Veil.Veil
local Veil = {}

---@class Veil.State
---@field rendered Veil.Render[]
---@field sections Veil.Section[]
---@field timer uv_timer_t
---@field interval number
---@field tick_handlers table<Veil.Section.Id, fun(state: Veil.Section.State)[]>
---@field autocmd_handlers table<string, { id : Veil.Section.Id, cb : fun(state: Veil.Section.State) }>
Veil.state = {}

---@class Veil.Config
---@field sections Veil.Section[]
Veil.config = {
	sections = {
		{
			title = "",
			provider = function(state)
				return { Line:new({ Chunk:new(string.format("%s", state.count), "Normal") }) }
			end,
			init = function(state)
				state.count = 0
			end,
			update = function(state)
				state.count = state.count + 1
			end,
			events = {
				Event.TICK,
			},
		},
		{
			title = "",
			provider = function(state)
				return { Line:from_str("Hello, world #" .. state.count .. "!", "Normal") }
			end,
			init = function(state)
				state.count = 0
			end,
			update = function(state)
				state.count = state.count + 1
			end,
			events = { Event:autocmd("LspAttach") },
		},
	},
}

function Veil.setup(opts)
	opts = opts or {}
	if opts.sections then
		Veil.config.sections = opts.sections
	end
	if opts.tick_interval then
		Veil.state.interval = opts.tick_interval
	else
		Veil.state.interval = 250
	end

	Veil.state.sections = {}
	Veil.state.tick_handlers = {}
	Veil.state.autocmd_handlers = {}

	-- setup sections
	for id, section in vim.iter(Veil.config.sections):enumerate() do
		local s = Section:new(section, id)
		if s.update then
			for event in vim.iter(s.events) do
				if event.type == EventType.TICK then
					Veil.state.tick_handlers[id] = s.update
				elseif event.type == EventType.AUTOCMD then
					if not Veil.state.autocmd_handlers[event.autocmd] then
						Veil.state.autocmd_handlers[event.autocmd] = {}
					end
					table.insert(Veil.state.autocmd_handlers[event.autocmd], { id = id, cb = s.update })
				end
			end
		end
		Veil.state.sections[id] = s
	end

	-- setup autocmds
	local augroup = vim.api.nvim_create_augroup("veil", { clear = true })
	for autocmd, handlers in pairs(Veil.state.autocmd_handlers) do
		vim.api.nvim_create_autocmd(autocmd, {
			group = augroup,
			callback = function()
				for handler in vim.iter(handlers) do
					handler.cb(Veil.state.sections[handler.id].state)
				end
				Veil:render()
			end,
		})
	end

	-- setup timer
	if Veil.state.timer then
		if Veil.state.timer:is_active() then
			Veil.state.timer:stop()
		end
		Veil.state.timer:close()
	end
	Veil.state.timer = vim.loop.new_timer()
	Veil.state.timer:start(Veil.state.interval, Veil.state.interval, function()
		for id, handler in pairs(Veil.state.tick_handlers) do
			handler(Veil.state.sections[id].state)
		end
		Veil:render()
	end)

	-- setup buffer
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_set_current_buf(buf)
	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(buf, "swapfile", false)
	vim.api.nvim_buf_set_option(buf, "filetype", "veil")
	vim.api.nvim_buf_set_option(buf, "modifiable", false)

	Veil.state.buf = buf

	vim.api.nvim_create_autocmd("WinResized", {
		buffer = buf,
		callback = function()
			vim.api.nvim_buf_set_option(buf, "modifiable", true)
			vim.api.nvim_buf_set_lines(
				Veil.state.buf,
				0,
				-1,
				false,
				(function()
					local w = vim.api.nvim_win_get_width(0)
					local h = vim.api.nvim_win_get_height(0)
					local lines = {}
					for _ = 1, h do
						table.insert(lines, string.rep(" ", w))
					end
					return lines
				end)()
			)
			vim.api.nvim_buf_set_option(buf, "modifiable", false)
			Veil:render()
		end,
	})

	vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout", "BufLeave" }, {
		buffer = buf,
		once = true,
		callback = function()
			if Veil.state.timer then
				Veil.state.timer:stop()
				if not Veil.state.timer:is_closing() then
					Veil.state.timer:close()
				end
			end
			vim.api.nvim_clear_autocmds({ group = augroup })
		end,
	})

	Veil:render()
end

function Veil:render()
	local rendered = {}
	vim.iter(Veil.state.sections):each(function(section)
		section = section:render()
		Veil.state.rendered[section.id] = section
		vim.iter(section.content):each(function(line)
			table.insert(section, line)
		end)
	end)
	local buf = Veil.state.buf
	vim.schedule(function()
		vim.api.nvim_buf_set_option(buf, "modifiable", true)
		vim.api.nvim_buf_set_extmark(buf, vim.api.nvim_create_namespace("veil_ns"), 0, 0, {
			id = 1,
			virt_lines = rendered,
			virt_text_pos = "overlay",
		})
		vim.api.nvim_buf_set_option(buf, "modifiable", false)
	end)
end

return Veil
