local builtin = require("veil.builtin")

local default = {
	---@type Section[]
	sections = {
		builtin.sections.animated(builtin.headers.frames_nvim, {
			hl = { fg = "#5de4c7" },
		}),
		builtin.sections.padding(2),
		builtin.sections.buttons({
			{
				icon = "",
				text = "Find Files",
				shortcut = "f",
				callback = function()
					require("telescope.builtin").find_files()
				end,
			},
			{
				icon = "",
				text = "Find Word",
				shortcut = "w",
				callback = function()
					require("telescope.builtin").live_grep()
				end,
			},
			{
				icon = "",
				text = "Buffers",
				shortcut = "b",
				callback = function()
					require("telescope.builtin").buffers()
				end,
			},
			{
				icon = "",
				text = "Config",
				shortcut = "c",
				callback = function()
					require("telescope").extensions.file_browser.file_browser({
						path = vim.fn.stdpath("config"),
					})
				end,
			},
		}, { spacing = 6 }),
		builtin.sections.padding(3),
	},
	mappings = {},
	startup = true,
}

return default
