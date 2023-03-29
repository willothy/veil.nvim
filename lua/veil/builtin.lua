local Section = require("veil.section")
local utils = require("veil.utils")
local map = require("veil").map

local builtin = {
	sections = {},
	headers = {},
}

function builtin.sections.animated(frames, opts)
	return Section:new({
		state = {
			frames = frames,
			frame = 1,
		},
		contents = function(self)
			local frame = self.frames[self.frame]
			if self.frame < #self.frames then
				self.frame = self.frame + 1
			else
				self.frame = 1
			end
			if type(frame) == "string" then
				return { frame }
			else
				return frame
			end
		end,
		hl = opts.hl or "Normal",
	})
end

function builtin.sections.buttons(buttons, options)
	local opts = options or {}
	for _, button in ipairs(buttons) do
		if button.shortcut then
			map(button.shortcut, button.callback)
		end
	end
	return Section:new({
		state = {
			buttons = buttons,
		},
		on_interact = function(self, line, _col)
			self.buttons[line].callback()
		end,
		contents = function(self)
			local lines = {}
			for _, button in ipairs(self.buttons) do
				local s = string.format(
					"%s%s  %s",
					button.shortcut and ("[ " .. button.shortcut .. " ]" .. string.rep(" ", opts.spacing or 2)) or "",
					button.icon,
					button.text
				)
				if #s % 2 ~= 0 then
					s = s .. " "
				end
				table.insert(lines, s)
			end
			return lines
		end,
		hl = opts.hl or "Normal",
		focused_hl = opts.focused_hl or "Visual",
		interactive = true,
	})
end

function builtin.sections.padding(size)
	return Section:new({
		contents = function()
			return utils.empty(size)
		end,
		hl = "Normal",
	})
end

builtin.headers.frames_veil1 = {
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

builtin.headers.frames_veil2 = {
	{ "-- Veil --", "-- Veil --" },
	{ "+- Veil --", "-- Veil -+" },
	{ "++ Veil --", "-- Veil ++" },
	{ "-+ Veil --", "-- Veil -+" },
	{ "-- Veil ++", "++ Veil --" },
	{ "-- Veil -+", "-+ Veil --" },
	{ "++ Veil --", "-- Veil ++" },
	{ "-+ Veil --", "-- Veil -+" },
}

builtin.headers.frames_nvim = {
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

return builtin
