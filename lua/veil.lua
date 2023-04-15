local api = vim.api
local Section = require("veil.section")

local autocmd = vim.api.nvim_create_autocmd

---@class Veil Veil state singleton
local Veil = {}

---@class Config
---@field sections Section[]
---@field mappings table<Keymap, fun()>
---@field startup boolean Whether to open Veil on startup (only applies if argc == 0)
---@field center { horizontal: boolean, vertical: boolean } Whether to center the window vertically/horizontally
Veil.config = require("veil.default")

---@class State
Veil.state = {
	---@type Section[] The list of generated sections
	stack = {},
	current = {
		---@type integer cursor location (y-axis)
		cursor = 1,
	},
	---@type boolean Whether the Veil window is open
	open = false,
	---@type boolean Whether Veil has been loaded
	loaded = false,
	height = 0,
	window = {
		---@type window Window id
		id = nil,
		---@type integer Width of the Veil window
		width = 0,
		---@type integer Height of the Veil window
		height = 0,
	},
	---@type buffer? Buffer number
	buffer = nil,
	ns = api.nvim_create_namespace("veil"),
	---@type timer UV Timer for updates
	timer = nil,
}

function Veil:init_buf(replace)
	local buf
	if replace then
		buf = api.nvim_get_current_buf()
	else
		buf = api.nvim_create_buf(false, false)
	end
	local win = vim.api.nvim_get_current_win()
	local opt = function(option, val)
		api.nvim_buf_set_option(buf, option, val)
	end

	opt("buftype", "nofile")
	opt("filetype", "veil")
	opt("swapfile", false)
	opt("bufhidden", "wipe")
	opt("buflisted", false)

	self.state.buffer = buf
	self.state.window.id = win
	self.state.window.width = api.nvim_win_get_width(win)
	self.state.window.height = api.nvim_win_get_height(win)
	if not self.state.ns then
		self.state.ns = api.nvim_create_namespace("veil")
	end
	api.nvim_win_set_hl_ns(win, self.state.ns)

	autocmd("WinResized", {
		buffer = buf,
		callback = function()
			self.state.window.width = api.nvim_win_get_width(win)
			self.state.window.height = api.nvim_win_get_height(win)
			self:kill_loop()
			self:init_loop()
		end,
	})

	-- vim.wo[win].number = false
	-- vim.wo[win].relativenumber = false
	-- vim.wo[win].signcolumn = "no"
	-- vim.wo[win].cursorline = false
	-- vim.wo[win].cursorcolumn = false
	-- vim.wo[win].colorcolumn = ""
	--  vim.bo[buf].
	api.nvim_set_current_buf(buf)
	vim.cmd("setlocal nonu nornu")
	vim.cmd('setlocal statuscolumn=""')
	local empty = {}
	for i = 1, self.state.window.height do
		empty[i] = ""
	end
	api.nvim_buf_set_lines(buf, 0, -1, true, empty)
	opt("modifiable", false)
	self.state.open = true

	autocmd({ "BufUnload", "BufWipeout" }, {
		buffer = buf,
		callback = function()
			self.state.open = false
		end,
	})
end

---@param replace boolean Whether to replace the current buffer
function Veil:display(replace)
	self:init_buf(replace)
	self.state.stack = self:mkstack()
	self:redraw()
	self:init_loop()
end

function Veil:init_loop()
	local timer = vim.loop.new_timer()

	timer:start(
		250,
		250,
		vim.schedule_wrap(function()
			if self.state.open == false then
				timer:stop()
			else
				self:redraw()
			end
		end)
	)
	self.state.timer = timer
end

function Veil:kill_loop()
	if self.state.timer ~= nil then
		self.state.timer:stop()
		self.state.timer = nil
	end
end

---@param init boolean Whether this is the first time the window is being drawn
function Veil:redraw()
	if not self.state.open then
		return
	end
	api.nvim_buf_clear_namespace(self.state.buffer, self.state.ns, 1, -1)
	local current_line = 1
	if self.state.height < self.state.window.height then
		current_line = math.floor(self.state.window.height / 2) - math.floor(self.state.height / 2)
	end
	for snr, section in ipairs(self.state.stack) do
		local section_start = current_line
		if self.state.current.cursor > section_start and self.state.current.cursor < section.nlines then
			section.focused = true
			section.focus_offset = self.state.current.cursor - section_start
		else
			section.focused = false
		end
		section = section:render()
		local rendered = {}
		for lnr, line in ipairs(section.content) do
			local line_len = 0
			for cnr, chunk in ipairs(line) do
				if cnr == 1 then
					table.insert(rendered, {})
				end
				local hl = chunk.hl
				local text = chunk.text
				if not hl then
					hl = "Normal"
				end
				if type(hl) == "table" then
					vim.api.nvim_set_hl(self.state.ns, "VeilSection" .. snr .. "_L" .. lnr .. "_C" .. cnr, hl)
					hl = "VeilSection" .. snr .. "_L" .. lnr .. "_C" .. cnr
				end
				line_len = line_len + string.len(text)
				-- convert to extmark format
				table.insert(rendered[#rendered], { text, hl })
			end
			current_line = current_line + 1
		end
		local max_width = 0
		for _, r in ipairs(rendered) do
			local line_len = 0
			for _, chunk in ipairs(r) do
				line_len = line_len + string.len(chunk[1])
			end
			if line_len > max_width then
				max_width = line_len
			end
		end
		if self.config.center.horizontal and max_width < self.state.window.width then
			for i, _ in ipairs(rendered) do
				table.insert(rendered[i], 1, {
					string.rep(" ", math.floor(self.state.window.width / 2) - math.floor(max_width / 2)),
					"Normal",
				})
			end
		end
		api.nvim_buf_set_extmark(self.state.buffer, self.state.ns, section_start, 0, {
			virt_text_pos = "eol",
			virt_lines = rendered,
		})
	end
end

---@return Section[] stack
function Veil:mkstack()
	---@type Section[]
	local stack = {}
	for idx, section in ipairs(self.config.sections) do
		table.insert(stack, Section:new(section, idx))
		-- Initialize the sections
		self.state.height = self.state.height + #stack[#stack]:render(true)
	end
	return stack
end

function Veil.setup(config)
	Veil.config = vim.tbl_deep_extend("force", Veil.config, config)
	if not Veil.state.loaded then
		-- TODO: create mappings here
		for _keymap, _fn in pairs(Veil.config.mappings) do
		end
	end
	Veil.state.loaded = true

	if Veil.config.startup then
		autocmd("BufEnter", {
			once = true,
			callback = function()
				if vim.fn.argc() == 0 then
					Veil:display(true)
				end
			end,
		})
	end

	vim.api.nvim_create_user_command("Veil", function()
		Veil:display()
	end, {})
end

return {
	setup = function(config)
		Veil:setup(config)
	end,
}
