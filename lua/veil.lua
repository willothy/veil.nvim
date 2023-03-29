local veil = {
	loclist = {},
	settings = {
		mappings = {},
	},
	state = {
		open = false,
		loaded = false,
		resized = false,
		vcursor = 0,
		height = 0,
	},
}

function veil:configure(opt)
	local opts = vim.tbl_deep_extend("force", require("veil.default"), opt or {})
	self.settings.sections = opts.sections or {}
	self.settings.mappings = vim.tbl_deep_extend("keep", self.settings.mappings, opts.mappings or {})
	self.settings.listed = opts.listed
	self.settings.startup = opts.startup
	self.settings.selection = opts.selection
end

function veil:reset()
	self.state.open = false
	self.state.resized = false
	self.state.vcursor = 0
	self.state.height = 0
end

function veil:section_at_cursor()
	return self.loclist:find(self.state.vcursor)
end

function veil:section_offset(section)
	if not section then
		return nil
	end
	local start = section.startl
	return math.max(self.state.vcursor - start, 1)
end

function veil:move(dir)
	local count = math.max(vim.v.count, 1)
	if dir == "up" then
		local loc, idx = self.loclist:find(self.state.vcursor - count)
		if not idx then
			return
		end
		while idx >= 1 and loc ~= nil and not loc.interactive do
			count = count + loc.nlines
			idx = idx - 1
			loc = self.loclist[idx]
		end
		if loc ~= nil and loc.interactive then
			self.state.vcursor = self.state.vcursor - count
			return true
		end
	else
		local loc, idx = self.loclist:find(self.state.vcursor + count)
		if not idx then
			return
		end
		while idx < #self.loclist and loc ~= nil and not loc.interactive do
			count = count + loc.nlines
			idx = idx + 1
			loc = self.loclist[idx]
		end
		if loc ~= nil and loc.interactive then
			self.state.vcursor = self.state.vcursor + count
			return true
		end
	end
	return false
end

local function up()
	if veil:move("up") then
		veil:redraw()
	end
end

local function down()
	if veil:move("down") then
		veil:redraw()
	end
end

function veil.loclist:clear()
	for i, _ in ipairs(self) do
		table.remove(self, i)
	end
end

function veil.loclist:find(line)
	for idx, loc in ipairs(self) do
		if line > loc.startl and line <= loc.endl then
			return loc, idx
		end
	end
	return nil
end

function veil:setup_buffer(replace)
	if replace then
		self.buf = vim.api.nvim_get_current_buf()
	else
		self.buf = vim.api.nvim_create_buf(self.settings.listed, false)
	end
	vim.api.nvim_buf_set_option(self.buf, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(self.buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(self.buf, "swapfile", false)
	vim.api.nvim_buf_set_option(self.buf, "filetype", "veil")
	vim.api.nvim_buf_set_name(self.buf, "Veil")
	vim.api.nvim_set_hl_ns(self.ns)
	vim.api.nvim_set_current_buf(self.buf)

	local hl = vim.api.nvim_get_hl_by_name("Cursor", true)
	hl.blend = 100
	vim.api.nvim_set_hl(veil.ns, "VeilCursor", hl)
	vim.api.nvim_set_hl(veil.ns, "Cursor", hl)

	local group = vim.api.nvim_create_augroup("VeilCursorGroup", { clear = true })
	vim.cmd("setlocal guicursor=a:VeilCursor")

	vim.api.nvim_create_autocmd({ "WinEnter" }, {
		group = group,
		pattern = "*",
		-- buffer = self.buf,
		-- once = true,
		callback = function(v)
			if v.buf ~= self.buf then
				vim.cmd("setlocal guicursor=" .. self.state.guicursor)
				require("veil.compat").noice(false)
			else
				vim.cmd("setlocal guicursor=a:VeilCursor")
				require("veil.compat").noice(true)
			end
		end,
	})

	vim.api.nvim_create_autocmd({ "BufWinLeave", "WinLeave", "WinNew" }, {
		group = group,
		-- pattern = "*",
		buffer = self.buf,
		-- once = true,
		callback = function()
			-- veil:reset()
			vim.cmd("setlocal guicursor=" .. self.state.guicursor)
			require("veil.compat").noice(false)
		end,
	})

	vim.api.nvim_set_current_buf(self.buf)
end

function veil:setup_window()
	self.win = vim.api.nvim_get_current_win()
	self.state.height = vim.api.nvim_win_get_height(self.win)
	vim.api.nvim_buf_set_lines(self.buf, 0, -1, true, require("veil.utils").empty(self.state.height))
	vim.api.nvim_buf_set_option(self.buf, "modifiable", false)

	vim.api.nvim_win_set_hl_ns(self.win, self.ns)

	vim.wo[self.win].wrap = false
end

function veil:setup_mappings()
	vim.keymap.set("n", "<CR>", self.interact, { buffer = self.buf, noremap = true })
	vim.keymap.set("n", "j", down, { buffer = self.buf, noremap = true })
	vim.keymap.set("n", "<Down>", down, { buffer = self.buf, noremap = true })
	vim.keymap.set("n", "k", up, { buffer = self.buf, noremap = true })
	vim.keymap.set("n", "<Up>", up, { buffer = self.buf, noremap = true })

	for map, cmd in pairs(self.settings.mappings) do
		vim.keymap.set("n", map, cmd, {
			silent = true,
			buffer = self.buf,
		})
	end
end

function veil:display(replace)
	if self.state.open == true then
		return
	else
		veil:reset()
	end

	self:setup_buffer(replace)
	veil:setup_window()
	self:setup_mappings()

	-- Required to hide the cursor when folke/noice.nvim is installed
	require("veil.compat").noice(true)

	vim.cmd("setlocal nonu nornu")

	local group = vim.api.nvim_create_augroup("veilgroup", { clear = true })

	vim.api.nvim_create_autocmd({ "BufUnload", "BufDelete", "BufWipeout" }, {
		group = group,
		buffer = self.buf,
		callback = function()
			self.state.open = false
			-- Required to hide the cursor when folke/noice.nvim is installed
			require("veil.compat").noice(true)

			return true
		end,
	})

	self.state.open = true
	local timer = vim.loop.new_timer()
	self:redraw(true)

	timer:start(
		200,
		200,
		vim.schedule_wrap(function()
			if self.state.open == false then
				timer:stop()
			else
				self:redraw()
			end
		end)
	)
end

function veil.interact()
	local section = veil:section_at_cursor()
	if not section then
		return
	end
	local handle = section.handle
	local offset = veil:section_offset(section)
	if handle.on_interact then
		handle.on_interact(offset, 1)
	end
end

function veil:redraw(init)
	self.ns = vim.api.nvim_create_namespace("veil")
	local utils = require("veil.utils")
	local win_width = vim.api.nvim_win_get_width(self.win)
	local win_height = vim.api.nvim_win_get_height(self.win)

	local rendered = {}
	local veil_height = 0
	for _, s in ipairs(self.settings.sections) do
		local section = s:render():pad(win_width)
		veil_height = veil_height + section.nlines
		table.insert(rendered, section)
	end

	vim.api.nvim_buf_set_option(self.buf, "modifiable", true)
	if init or self.state.resized then
		self.loclist:clear()
		self.state.resized = false
	end

	local current_height = 0
	if veil_height < win_height then
		current_height = math.floor((self.state.height - veil_height) / 4)
	end
	for id, section in ipairs(rendered) do
		if self.state.vcursor == 0 and not section.virt then
			self.state.vcursor = current_height + 1
		end
		local virt = {}
		local max_width = 0
		for i, line in ipairs(section.text) do
			local leading, rest = utils.split_leading(line)
			max_width = math.max(max_width, #rest)
			local focused = (not section.virt) and (self.state.vcursor == current_height + i)
			local sep = self.settings.selection.separators
			if focused then
				local fhl = vim.fn.hlID(section.focused_hl)
				local inv_hl = {
					fg = vim.fn.synIDattr(fhl, "bg"),
					bg = "none",
				}
				vim.api.nvim_set_hl(0, section.focused_hl .. "Inv", inv_hl)
			end
			table.insert(virt, {
				{ leading, "Normal" },
				{ focused and sep.left or " ", focused and section.focused_hl .. "Inv" or "Normal" },
				{ rest, focused and section.focused_hl or section.hl },
				{ focused and sep.right or " ", focused and section.focused_hl .. "Inv" or "Normal" },
			})
		end
		for i, line in ipairs(virt) do
			if #line ~= 2 then
				virt[i][3][1] = line[3][1] .. string.rep(" ", math.max(max_width - #line[3][1], 0))
			else
				virt[i][2][1] = line[2][1] .. string.rep(" ", math.max(max_width - #line[2][1], 0))
			end
		end

		vim.api.nvim_buf_set_extmark(self.buf, veil.ns, current_height, 0, {
			id = id,
			virt_text_pos = "eol",
			virt_lines = virt,
		})

		self.loclist[id] = {
			startl = current_height,
			endl = current_height + section.nlines,
			nlines = section.nlines,
			handle = section,
			interactive = not section.virt,
		}

		current_height = current_height + section.nlines
	end
	if self.state.vcursor == 0 then
		self.state.vcursor = 1
	end
	vim.api.nvim_buf_set_option(self.buf, "modifiable", false)
end

function veil:map(lhs, rhs)
	if not self.buf then
		self.settings.mappings[lhs] = rhs
	else
		vim.api.nvim_buf_set_keymap(self.buf, "n", lhs, rhs, {})
	end
end

function veil.setup(opts)
	if veil.state.loaded then
		return
	end
	veil.state.loaded = true
	veil.state.guicursor = vim.api.nvim_get_option("guicursor")
	veil:configure(opts)
	veil.ns = vim.api.nvim_create_namespace("veil")

	if veil.settings.startup then
		vim.api.nvim_create_autocmd("BufEnter", {
			once = true,
			callback = function()
				if vim.fn.argc() == 0 then
					veil:display(true)
				end
				return true
			end,
		})
	end

	vim.api.nvim_create_user_command("Veil", function()
		veil:display()
	end, {})
end

return {
	setup = veil.setup,
	display = function(replace)
		veil:display(replace or false)
	end,
	map = function(...)
		veil:map(...)
	end,
	move = {
		up = up,
		down = down,
	},
}
