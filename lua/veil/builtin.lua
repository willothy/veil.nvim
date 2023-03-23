local Section = require("veil.section")
local utils = require("veil.utils")
local map = require("veil").map

local builtin = {}

function builtin.animated(frames, opts)
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

function builtin.buttons(buttons, options)
	local opts = options or {}
	for _, button in ipairs(buttons) do
		map(button.shortcut, button.callback)
	end
	return Section:new({
		state = {
			buttons = buttons,
		},
		contents = function(self)
			local lines = {}
			for _, button in ipairs(self.buttons) do
				local s = string.format("[%s]  %s  %s", button.shortcut, button.icon, button.text)
				if #s % 2 ~= 0 then
					s = s .. " "
				end
				table.insert(lines, s)
			end
			return lines
		end,
		hl = opts.hl or "Normal",
		interactive = true,
		on_interact = function(_self, button)
			button.callback()
		end,
	})
end

function builtin.padding(size)
	return Section:new({
		contents = function()
			return utils.empty(size)
		end,
		hl = "Normal",
	})
end

return builtin
