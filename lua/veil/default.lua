local builtin = require("veil.builtin")

local frames_veil1 = {

	{
		"-- Veil --",
	},
	{
		"+- Veil --",
	},
	{
		"++ Veil --",
	},
	{
		"-+ Veil --",
	},
	{
		"-- Veil ++",
	},
	{
		"-- Veil -+",
	},
	{
		"++ Veil --",
	},
	{
		"-+ Veil --",
	},
}

local frames_veil2 = {
	{ "-- Veil --", "-- Veil --" },
	{ "+- Veil --", "-- Veil -+" },
	{ "++ Veil --", "-- Veil ++" },
	{ "-+ Veil --", "-- Veil -+" },
	{ "-- Veil ++", "++ Veil --" },
	{ "-- Veil -+", "-+ Veil --" },
	{ "++ Veil --", "-- Veil ++" },
	{ "-+ Veil --", "-- Veil -+" },
}

local frames_nvim = {
	{
		[[  *                       _         *    ]],
		[[        +                (_)  +          ]],
		[[    _ __   ___  _____   ___ _ __ ___     ]],
		[[   | '_ \ / _ \/ _ \ \ / / | '_ ` _ \    ]],
		[[   | | | |  __/ (_) \ V /| | | | | | |   ]],
		[[   |_| |_|\___|\___/ \_/ |_|_| |_| |_|   ]],
		[[                              *          ]],
	},
	{
		[[                  +       _              ]],
		[[                         (_)      *      ]],
		[[    _ __*  ___  _____   ___ _ __ ___     ]],
		[[   | '_ \ / _ \/ _ \ \ / / | '_ ` _ \    ]],
		[[   | | | |  __/ (_) \ V /| | | | | | |   ]],
		[[   |_| |_|\___|\___/ \_/ |_|_| |_| |_|   ]],
		[[                    +                    ]],
	},
	{
		[[      *                   _     +        ]],
		[[                         (_)        *    ]],
		[[    _ __   ___  _+___   ___ _ __ ___     ]],
		[[   | '_ \ / _ \/ _ \ \ / / | '_ ` _ \    ]],
		[[   | | | |  __/ (_) \ V /| | | | | | |   ]],
		[[   |_| |_|\___|\___/ \_/ |_|_| |_| |_|   ]],
		[[            *                            ]],
	},
}

local default = {
	---@type Section[]
	sections = {
		builtin.animated(frames_nvim, {
			hl = { fg = "#5de4c7" },
		}),
		builtin.padding(2),
		builtin.buttons({
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
		}),
		builtin.padding(3),
	},
	mappings = {},
	startup = true,
}

return default
