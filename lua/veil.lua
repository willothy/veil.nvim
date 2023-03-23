local veil = {}

local veil_loaded = false

local function configure(opts)
	return vim.tbl_deep_extend("force", require("veil.default"), opts)
end

function veil.display(replace)
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

local function longest_line(lines)
	local longest = 0
	for _, line in ipairs(lines) do
		if #line > longest then
			longest = #line
		end
	end
	return longest
end

function veil.redraw()
	local lines = {}
	local width = vim.api.nvim_win_get_width(veil.win)
	local height = vim.api.nvim_win_get_height(veil.win)
	for _, section in ipairs(veil.settings.sections) do
		local rendered = section:render()
		local longest = longest_line(rendered)
		local padding = 0
		if longest < width then
			padding = (width - (longest * 2)) / 2
		end
		for _, line in ipairs(rendered) do
			table.insert(lines, string.rep(" ", padding) .. line)
		end
	end

	if #lines < height then
		local height_padding = (height - #lines) / 2
		for i = 1, height_padding, 1 do
			if i <= height_padding then
				table.insert(lines, 1, "")
			end
		end
	end

	local virt = {}
	for _, line in ipairs(lines) do
		table.insert(virt, { { line, "Normal" } })
	end

	vim.api.nvim_buf_set_extmark(veil.buf, veil.ns, 0, 0, {
		id = 1,
		virt_text_pos = "overlay",
		virt_lines = virt,
	})
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
