local veil = {}

local veil_loaded = false

-- local Section = require('veil').section
-- local s = Section:new()
-- print(s)

---@class Section
---@field contents fun():string[]
---@field state table
---@field interactive boolean
local Section = {
	contents = function(_self)
		return { "configure your veil!" }
	end,
	state = {},
	interactive = false,
	__index = {
		new = function(self, opts)
			local new = vim.tbl_deep_extend("keep", opts or {}, self)
			-- setmetatable(new, {
			-- 	render = new.contents,
			-- 	interactive = function()
			-- 		return new.interactive
			-- 	end,
			-- })
			new.__index = new.state
			-- new.__newindex = function(_t, _k, _v)
			-- 	error("attempt to update a read-only table", 2)
			-- end
			new.state = nil
			new.contents = nil
			new.interactive = nil
			return new
		end,
	},
}
setmetatable(Section, Section)

local defaults = {
	---@type Section[]
	sections = {
		Section:new(),
	},
	mappings = {},
	startup = true,
}

local function configure(opts)
	return vim.tbl_deep_extend("force", defaults, opts)
end

veil.section = Section

function veil.display(replace)
	if replace then
		veil.buf = vim.api.nvim_get_current_buf()
	else
		veil.buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_set_current_buf(veil.buf)
	end
	vim.api.nvim_buf_set_name(veil.buf, "Veil")
	vim.api.nvim_buf_set_option(veil.buf, "modifiable", false)
	vim.api.nvim_buf_set_option(veil.buf, "filetype", "veil")
	vim.api.nvim_buf_set_option(veil.buf, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(veil.buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(veil.buf, "swapfile", false)
	vim.cmd("setlocal nonu nornu nolist")

	for map, cmd in pairs(veil.settings.mappings) do
		vim.keymap.set("n", map, cmd, {
			silent = true,
			buffer = veil.buf,
		})
	end

	vim.api.nvim_create_autocmd("WinResized", {
		buffer = veil.buf,
		callback = function()
			veil.redraw()
		end,
	})
	veil.redraw()
end

function veil.redraw()
	local lines = {}
	local width = vim.api.nvim_win_get_width(0)
	local height = vim.api.nvim_win_get_height(0)
	for _, section in ipairs(veil.settings.sections) do
		for _, line in ipairs(section.contents()) do
			if #line < width then
				local padding = (width - #line) / 2
				line = string.rep(" ", padding) .. line
			end
			table.insert(lines, line)
		end
	end

	if #lines < height then
		local padding = (height - #lines) / 2
		for _ = 1, padding, 1 do
			table.insert(lines, 1, "")
			table.insert(lines, "")
		end
	end

	vim.api.nvim_buf_set_option(veil.buf, "modifiable", true)
	vim.api.nvim_buf_set_lines(veil.buf, 0, -1, true, lines)
	vim.api.nvim_buf_set_option(veil.buf, "modifiable", false)
end

function veil.setup(opts)
	if veil_loaded then
		return
	end
	veil_loaded = true
	veil.settings = configure(opts)
	veil.state = {
		open = false,
	}

	if veil.settings.startup then
		vim.api.nvim_create_autocmd("VimEnter", {
			callback = function()
				if vim.fn.argc() == 0 then
					veil.display(true)
				end
				return true
			end,
		})
	end

	vim.api.nvim_create_user_command("Veil", function()
		veil.display()
	end, {})
end

return veil
