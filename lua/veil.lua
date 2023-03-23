local veil = {}

local veil_loaded = false

local function configure(opts)
	return vim.tbl_deep_extend("force", require("veil.default"), opts)
end

function veil.display(replace)
	veil.ns = vim.api.nvim_create_namespace("veil")
	if veil.state.open == true then
		return
	end
	if replace then
		veil.buf = vim.api.nvim_get_current_buf()
	else
		veil.buf = vim.api.nvim_create_buf(false, true)
	end
	vim.api.nvim_buf_set_option(veil.buf, "modifiable", false)
	vim.api.nvim_buf_set_option(veil.buf, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(veil.buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(veil.buf, "swapfile", false)
	vim.api.nvim_buf_set_name(veil.buf, "Veil")
	vim.api.nvim_set_current_buf(veil.buf)
	veil.win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_hl_ns(veil.win, veil.ns)
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

function veil.redraw(init)
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
		current_height = (win_height - (veil_height * 2)) / 2
	end
	for id, section in ipairs(rendered) do
		if not section.virt then
			vim.api.nvim_buf_set_lines(veil.buf, current_height, -1, true, section.text)
		else
			local virt = {}
			for _, line in ipairs(section.text) do
				local leading, rest = utils.split_leading(line)
				table.insert(virt, { { leading, "Normal" }, { rest, section.hl } })
			end
			vim.api.nvim_buf_set_extmark(veil.buf, veil.ns, current_height, 0, {
				id = id,
				virt_text_pos = "overlay",
				virt_lines = virt,
			})
		end

		current_height = current_height + section.nlines
	end
	vim.api.nvim_buf_set_option(veil.buf, "modifiable", false)
end

function veil.setup(opts)
	if veil_loaded then
		return
	end
	veil_loaded = true
	veil.settings = configure(opts)
	veil.ns = vim.api.nvim_create_namespace("veil")
	veil.state = {
		open = false,
	}

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
}
