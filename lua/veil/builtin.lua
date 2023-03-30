local Section = require("veil.section")
local utils = require("veil.utils")
local map = require("veil").map

local builtin = {
	sections = {},
	headers = {},
	highlight = {
		normal = function()
			local v = require("veil").api.get_buf()
			local b = vim.api.nvim_get_current_buf()
			if v == b then
				local norm = vim.fn.hlID("Normal")
				return { fg = vim.fn.synIDattr(norm, "fg"), bg = vim.fn.synIDattr(norm, "bg") }
			else
				local nc = vim.fn.hlID("NormalNC")
				return { fg = vim.fn.synIDattr(nc, "fg"), bg = vim.fn.synIDattr(nc, "bg") }
			end
		end,
		visual = function()
			local v = require("veil").api.get_buf()
			local b = vim.api.nvim_get_current_buf()
			local norm = vim.api.nvim_get_hl_by_name("Visual", true)
			local nc = vim.api.nvim_get_hl_by_name("NormalNC", true)
			if v == b then
				return { fg = norm.guifg or norm.fg or norm.foreground, bg = norm.guibg or norm.bg or norm.background }
			else
				return { fg = nc.guifg or nc.fg or nc.foreground, bg = norm.guibg or norm.bg or norm.background }
			end
		end,
	},
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

function builtin.sections.oldfiles(options)
	local opts = options or {}
	local has_icons, icons = pcall(require, "nvim-web-devicons")
	return Section:new({
		header_size = 2,
		state = {
			files = vim.v.oldfiles,
			line_nrs = {},
			max = opts.max or 5,
			home = vim.loop.os_homedir(),
			icons = has_icons and icons or nil,
		},
		contents = function(self)
			local lines = {}
			local align = opts.align or "center"
			self.files = vim.v.oldfiles
			local maxwidth = 0
			for i, file in ipairs(self.files) do
				if string.match(file, self.home) ~= nil then
					local f, e = vim.loop.fs_stat(vim.fn.fnamemodify(file, ":p:s?" .. self.home .. "?"))
					if f ~= nil and e == nil then
						local s = vim.fn.fnamemodify(file, ":~:.")
						if self.icons then
							local icon = self.icons.get_icon(s, vim.fn.fnamemodify(s, ":e"), { default = true })
							s = icon .. " " .. s
						end
						table.insert(lines, s)
						table.insert(self.line_nrs, i)
						maxwidth = math.max(maxwidth, #s)
						if #lines >= self.max then
							break
						end
					end
				end
			end
			table.insert(lines, 1, "Recent files")
			table.insert(lines, 2, "")
			for i, line in ipairs(lines) do
				if align == "center" and line ~= "" then
					lines[i] = string.rep(" ", math.floor((maxwidth - #line) / 2)) .. line
				elseif align == "right" and line ~= "" then
					lines[i] = string.rep(" ", maxwidth - #line) .. line
				end
			end

			return lines
		end,
		hl = builtin.highlight.normal,
		focused_hl = opts.focused_hl or builtin.highlight.visual,
		interactive = true,
		on_interact = function(self, line, _col)
			if line <= 2 then
				return
			end
			-- open the file
			vim.cmd(string.format("edit %s", self.files[self.line_nrs[line - 2]]))
			-- go to last place in file
			vim.api.nvim_feedkeys("'.", "n", false)
		end,
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
			local align = opts.align or "center"
			local maxwidth = 0
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
				maxwidth = math.max(maxwidth, #s)
				table.insert(lines, s)
			end
			for i, line in ipairs(lines) do
				if align == "center" then
					-- lines[i] = string.rep(" ", math.floor((maxwidth - #line) / 2)) .. line
					if #lines[i] < maxwidth then
						lines[i] = lines[i] .. string.rep(" ", maxwidth - #lines[i])
					end
				elseif align == "right" then
					lines[i] = string.rep(" ", maxwidth - #line) .. line
				end
			end
			return lines
		end,
		hl = opts.hl or builtin.highlight.normal,
		focused_hl = opts.focused_hl or builtin.highlight.visual,
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

builtin.headers.frames_days_of_week = {
    Monday = {
    {
        [[   *                        _        *     ]],
        [[                +          | |             ]],
        [[  _ __ ___   ___  _ __   __| | __ _ _   _  ]],
        [[ | '_ ` _ \ / _ \| '_ \ / _` |/ _` | | | | ]],
        [[ | | | | | | (_) | | | | (_| | (_| | |_| | ]],
        [[ |_| |_| |_|\___/|_| |_|\__,_|\__,_|\__, | ]],
        [[                             +       __/ | ]],
        [[     *               *              |___/  ]],
    },
    {
        [[            *               _             +]],
        [[   +             +         | |             ]],
        [[  _ __ ___   ___  _ __   __| | __ _ _ * _  ]],
        [[ | '_ ` _ \ / _ \| '_ \ / _` |/ _` | | | | ]],
        [[ | | | | | | (_) | | | | (_| | (_| | |_| | ]],
        [[ |_| |_| |_|\___/|_| |_|\__,_|\__,_|\__, | ]],
        [[                         *           __/ | ]],
        [[           *                        |___/  ]],
    },
    {
        [[       +                    _              ]],
        [[            *              | |  *          ]],
        [[ *_ __ ___   ___  _ __ + __| | __ _ _   _  ]],
        [[ | '_ ` _ \ / _ \| '_ \ / _` |/ _` | | | | ]],
        [[ | | | | | | (_) | | | | (_| | (_| | |_| | ]],
        [[ |_| |_| |_|\___/|_| |_|\__,_|\__,_|\__, | ]],
        [[     +                *              __/ | ]],
        [[            *                  +    |___/  ]],
    },
    },

    Tuesday = {
    {
        [[  _   *                   _              ]],
        [[ | |                     | |       +     ]],
        [[ | |_ _   _  ___ *___  __| | __ _ _   _  ]],
        [[ | __| | | |/ _ \/ __|/ _` |/ _` | | | | ]],
        [[ | |_| |_| |  __/\__ \ (_| | (_| | |_| | ]],
        [[  \__|\__,_|\___||___/\__,_|\__,_|\__, | ]],
        [[    +                        *     __/ | ]],
        [[              *                   |___/  ]],
    },
    {
        [[  _                       _  *           ]],
        [[ | |              *      | |             ]],
        [[ | |_ _ + _  ___  ___  __| | __ _ _   _ *]],
        [[ | __| | | |/ _ \/ __|/ _` |/ _` | | | | ]],
        [[ | |_| |_| |  __/\__ \ (_| | (_| | |_| | ]],
        [[  \__|\__,_|\___||___/\__,_|\__,_|\__, | ]],
        [[                     +             __/ | ]],
        [[         *                     *  |___/  ]],
    },
    {
        [[  _        *              _              ]],
        [[ | |                     | |      +      ]],
        [[ | |_ _   _  ___  ___ +__| | __ _ _   _  ]],
        [[ | __| | | |/ _ \/ __|/ _` |/ _` | | | | ]],
        [[ | |_| |_| |  __/\__ \ (_| | (_| | |_| | ]],
        [[  \__|\__,_|\___||___/\__,_|\__,_|\__, | ]],
        [[         *                         __/ | ]],
        [[ +                        *       |___/  ]],
    },
    },

    Wednesday = {
    {
        [[                   _    +                _              ]],
        [[    *             | |                   | |         *   ]],
        [[ __      _____  __| |_ __   ___  ___ *__| | __ _ _   _  ]],
        [[ \ \ /\ / / _ \/ _` | '_ \ / _ \/ __|/ _` |/ _` | | | | ]],
        [[  \ V  V /  __/ (_| | | | |  __/\__ \ (_| | (_| | |_| | ]],
        [[   \_/\_/ \___|\__,_|_| |_|\___||___/\__,_|\__,_|\__, | ]],
        [[                           *                      __/ | ]],
        [[          +                                _     |___/  ]],
    },
    {
        [[                   _          *          _              ]],
        [[       +          | |                   | |           * ]],
        [[ __      _____  __| |_ __   ___  ___  __| | __+_ _   _  ]],
        [[ \ \ /\ / / _ \/ _` | '_ \ / _ \/ __|/ _` |/ _` | | | | ]],
        [[  \ V  V /  __/ (_| | | | |  __/\__ \ (_| | (_| | |_| | ]],
        [[   \_/\_/ \___|\__,_|_| |_|\___||___/\__,_|\__,_|\__, | ]],
        [[   *                        *                     __/ | ]],
        [[         *                              +        |___/  ]],
    },
    {
        [[               +   _                 *   _              ]],
        [[                  | |     *             | |      +      ]],
        [[ __ *    _____  __| |_ __   ___  ___  __| | __ _ _   _  ]],
        [[ \ \ /\ / / _ \/ _` | '_ \ / _ \/ __|/ _` |/ _` | | | | ]],
        [[  \ V  V /  __/ (_| | | | |  __/\__ \ (_| | (_| | |_| | ]],
        [[   \_/\_/ \___|\__,_|_| |_|\___||___/\__,_|\__,_|\__, | ]],
        [[     +                            *               __/ | ]],
        [[                 *                          +    |___/  ]],
    },
    },

    Thursday = {
    {
        [[  _   _   *                    _              ]],
        [[ | | | |                      | |        *    ]],
        [[ | |_| |__  _   _ _ __+___  __| | __ _ _   _  ]],
        [[ | __| '_ \| | | | '__/ __|/ _` |/ _` | | | | ]],
        [[ | |_| | | | |_| | |  \__ \ (_| | (_| | |_| | ]],
        [[  \__|_| |_|\__,_|_|  |___/\__,_|\__,_|\__, | ]],
        [[            +                           __/ | ]],
        [[                               *       |___/  ]],
    },
    {
        [[  _   _                   *    _              ]],
        [[ | | | |     +                | |        *    ]],
        [[ | |_| |__  _   _ _ __ ___  __| | __ _ _   _  ]],
        [[ | __| '_ \| | | | '__/ __|/ _` |/ _` | | | | ]],
        [[ | |_| | | | |_| | |  \__ \ (_| | (_| | |_| | ]],
        [[  \__|_| |_|\__,_|_|  |___/\__,_|\__,_|\__, | ]],
        [[                      *                 __/ | ]],
        [[    *                              +   |___/  ]],
    },
    {
        [[  _   _    *                   _              ]],
        [[ | | | |                *     | |             ]],
        [[ | |_| |__  _   _ _ __ ___  __| | __ _ _ + _  ]],
        [[ | __| '_ \| | | | '__/ __|/ _` |/ _` | | | | ]],
        [[ | |_| | | | |_| | |  \__ \ (_| | (_| | |_| | ]],
        [[  \__|_| |_|\__,_|_|  |___/\__,_|\__,_|\__, | ]],
        [[    +                                   __/ | ]],
        [[                *               +      |___/  ]],
    },
    },

    Friday = {
    {
        [[   __   *  _     _           *  ]],
        [[  / _|    (_)   | |             ]],
        [[ | |_ _ __ _  __| | __+_ _   _  ]],
        [[ |  _| '__| |/ _` |/ _` | | | | ]],
        [[ | | | |  | | (_| | (_| | |_| | ]],
        [[ |_| |_|  |_|\__,_|\__,_|\__, | ]],
        [[                  *       __/ | ]],
        [[    +                    |___/  ]],
    },
    {
        [[ + __      _     _    *         ]],
        [[  / _|    (_)   | |             ]],
        [[ | |_ _ __ _ *__| | __ _ _ * _  ]],
        [[ |  _| '__| |/ _` |/ _` | | | | ]],
        [[ | | | |  | | (_| | (_| | |_| | ]],
        [[ |_| |_|  |_|\__,_|\__,_|\__, | ]],
        [[             +            __/ | ]],
        [[   *                   + |___/  ]],
    },
    {
        [[   __   *  _     _              ]],
        [[  / _|    (_)   | |          *  ]],
        [[ | |_ _ __ _  __| | __ _*_   _  ]],
        [[ |  _| '__| |/ _` |/ _` | | | | ]],
        [[ | | | |  | | (_| | (_| | |_| | ]],
        [[ |_| |_|  |_|\__,_|\__,_|\__, | ]],
        [[     *                    __/ | ]],
        [[             +        *  |___/  ]],
    },
    },

    Saturday = {
    {
        [[            _        +        _              ]],
        [[    *      | |               | |             ]],
        [[  ___  __ _| |_ _   _ _ __ __| | __*_ _   _  ]],
        [[ / __|/ _` | __| | | | '__/ _` |/ _` | | | | ]],
        [[ \__ \ (_| | |_| |_| | | | (_| | (_| | |_| | ]],
        [[ |___/\__,_|\__|\__,_|_|  \__,_|\__,_|\__, | ]],
        [[                      *                __/ | ]],
        [[        +                            *|___/  ]],
    },
    {
        [[  +         _                 _       *      ]],
        [[           | |      +        | |             ]],
        [[  ___  __ _| |_ _   _ _ __ __| | __ _ _   _ *]],
        [[ / __|/ _` | __| | | | '__/ _` |/ _` | | | | ]],
        [[ \__ \ (_| | |_| |_| | | | (_| | (_| | |_| | ]],
        [[ |___/\__,_|\__|\__,_|_|  \__,_|\__,_|\__, | ]],
        [[            +                          __/ | ]],
        [[  *                          *        |___/  ]],
    },
    {
        [[            _                 _     *        ]],
        [[           | |       *       | |             ]],
        [[  ___  __*_| |_ _   _ _ __ __| | __ _ _ + _  ]],
        [[ / __|/ _` | __| | | | '__/ _` |/ _` | | | | ]],
        [[ \__ \ (_| | |_| |_| | | | (_| | (_| | |_| | ]],
        [[ |___/\__,_|\__|\__,_|_|  \__,_|\__,_|\__, | ]],
        [[  +                 *                  __/ | ]],
        [[                              +       |___/  ]],
    },
    },

    Sunday = {
    {
        [[  *                   _              ]],
        [[             *       | |      *      ]],
        [[  ___ _ + _ _ __  *__| | __ _ _   _  ]],
        [[ / __| | | | '_ \ / _` |/ _` | | | | ]],
        [[ \__ \ |_| | | | | (_| | (_| | |_| | ]],
        [[ |___/\__,_|_| |_|\__,_|\__,_|\__, | ]],
        [[              *                __/ | ]],
        [[   +                      *   |___/  ]],
    },
    {
        [[                    + _              ]],
        [[  +       *          | |             ]],
        [[  ___ _   _ _ __   __| | __ _ _ + _  ]],
        [[ / __| | | | '_ \ / _` |/ _` | | | | ]],
        [[ \__ \ |_| | | | | (_| | (_| | |_| | ]],
        [[ |___/\__,_|_| |_|\__,_|\__,_|\__, | ]],
        [[                  +           *__/ | ]],
        [[    *                         |___/  ]],
    },
    {
        [[             *        _            * ]],
        [[   +                 | |     *       ]],
        [[  ___ _   _ _ __   __| | __ _ _   _  ]],
        [[ / __| | | | '_ \ / _` |/ _` | | | | ]],
        [[ \__ \ |_| | | | | (_| | (_| | |_| | ]],
        [[ |___/\__,_|_| |_|\__,_|\__,_|\__, | ]],
        [[   +            *              __/ | ]],
        [[        *              +      |___/  ]],
    },
    }
}


return builtin
