local veil = {}

veil.settings = {
	mappings = {},
}

function veil.settings.configure(opts)
	return vim.tbl_deep_extend("force", require("veil.default"), veil.settings, opts)
end

function veil.display(replace)
	veil.ns = vim.api.nvim_create_namespace("veil")
	if veil.state.open == true then
		return
	end
	if replace then
		veil.buf = vim.api.nvim_get_current_buf()
	else
		veil.buf = vim.api.nvim_create_buf(false, false)
	end
	vim.api.nvim_buf_set_option(veil.buf, "modifiable", false)
	vim.api.nvim_buf_set_option(veil.buf, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(veil.buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(veil.buf, "swapfile", false)
	vim.api.nvim_buf_set_option(veil.buf, "filetype", "veil")
	vim.api.nvim_buf_set_option(veil.buf, "buflisted", false)
	vim.api.nvim_buf_set_name(veil.buf, "Veil")
	vim.api.nvim_set_current_buf(veil.buf)
	veil.win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_hl_ns(veil.win, veil.ns)
	vim.cmd("setlocal nonu nornu nolist")

	vim.keymap.set("n", "<CR>", veil.interact, { buffer = veil.buf, noremap = true })

	for map, cmd in pairs(veil.settings.mappings) do
		vim.keymap.set("n", map, cmd, {
			silent = true,
			buffer = veil.buf,
		})
	end

	vim.api.nvim_create_autocmd({ "BufUnload", "BufDelete", "BufWipeout" }, {
		buffer = veil.buf,
		callback = function()
			veil.state.open = false
			return true
		end,
	})
	veil.state.open = true
	local timer = vim.loop.new_timer()
	veil.redraw(true)

	timer:start(
		200,
		200,
		vim.schedule_wrap(function()
			if veil.state.open == false then
				timer:stop()
			else
				veil.redraw()
			end
		end)
	)
end

veil.loclist = {}

local locations = {}
function locations.clear()
	for i, _ in ipairs(veil.loclist) do
		veil.loclist[i] = nil
	end
end

function locations.find(line)
	for _, loc in ipairs(veil.loclist) do
		if line > loc.startl and line <= loc.endl then
			return loc
		end
	end
	return nil
end

function veil.interact()
	local cursor = vim.api.nvim_win_get_cursor(veil.win)
	local line = cursor[1]
	local col = cursor[2]
	local res = locations.find(line)
	if not res then
		return
	end
	local handle = res.handle
	local startl = res.startl
	local relno = line - startl
	if handle.on_interact then
		handle.on_interact(relno, col)
	end
end

function veil.redraw(init)
	local cursor = vim.api.nvim_win_get_cursor(veil.win)
	-- locations.clear()
	veil.ns = vim.api.nvim_create_namespace("veil")
	local utils = require("veil.utils")
	local win_width = vim.api.nvim_win_get_width(veil.win)
	local win_height = vim.api.nvim_win_get_height(veil.win)

	local rendered = {}
	local veil_height = 0
	for _, s in ipairs(veil.settings.sections) do
		local section = s:render():pad(win_width)
		veil_height = veil_height + section.nlines
		table.insert(rendered, section)
	end

	vim.api.nvim_buf_set_option(veil.buf, "modifiable", true)
	if init then
		vim.api.nvim_buf_set_lines(veil.buf, 0, -1, true, utils.empty(win_height - veil_height))
	end

	local current_height = 0
	if veil_height < win_height then
		current_height = math.floor((win_height - (veil_height * 2)) / 2)
	end
	for id, section in ipairs(rendered) do
		if not section.virt then
			if
				veil.loclist[id] ~= nil
				and (
					veil.loclist[id].startl ~= current_height
					or veil.loclist[id].endl ~= current_height + section.nlines
				)
			then
				vim.api.nvim_buf_set_lines(
					veil.buf,
					veil.loclist[id].startl,
					veil.loclist[id].endl,
					true,
					utils.empty(veil.loclist[id].endl - veil.loclist[id].startl)
				)
				current_height = veil.loclist[id].startl
			end
			vim.api.nvim_buf_set_lines(veil.buf, current_height, -1, true, section.text)
		else
			local virt = {}
			for _, line in ipairs(section.text) do
				local leading, rest = utils.split_leading(line)
				table.insert(virt, { { leading, "Normal" }, { rest, section.hl } })
			end
			vim.api.nvim_buf_set_extmark(veil.buf, veil.ns, current_height, 0, {
				id = id,
				virt_text_pos = "eol",
				virt_lines = virt,
			})
		end

		veil.loclist[#veil.loclist + 1] =
			{ startl = current_height, endl = current_height + section.nlines, handle = section }

		current_height = current_height + section.nlines
	end
	vim.api.nvim_buf_set_option(veil.buf, "modifiable", false)
	vim.api.nvim_win_set_cursor(veil.win, cursor)
end

veil.state = {
	open = false,
	loaded = false,
}

function veil.map(lhs, rhs)
	if not veil.buf then
		veil.settings.mappings[lhs] = rhs
	else
		vim.api.nvim_buf_set_keymap(veil.buf, "n", lhs, rhs, {})
	end
end

function veil.setup(opts)
	if veil.state.loaded then
		return
	end
	veil.state.loaded = true
	veil.settings = veil.settings.configure(opts)
	veil.ns = vim.api.nvim_create_namespace("veil")

	-- TODO: Do I really need this?
	math.randomseed(os.time())

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

return {
	setup = veil.setup,
	display = veil.display,
	map = veil.map,
}
