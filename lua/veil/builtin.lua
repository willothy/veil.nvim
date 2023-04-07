local builtin = {
	sections = {},
	frames = {},
}
local veil = { text = "Veil", hl = { fg = "#00cfcf" } }
local space = { text = " " }
builtin.frames.veil = {
	{ { veil, space, { text = "⠋", hl = { fg = "#00cfcf" } } } },
	{ { veil, space, { text = "⠙", hl = { fg = "#00cfcf" } } } },
	{ { veil, space, { text = "⠹", hl = { fg = "#00cfcf" } } } },
	{ { veil, space, { text = "⠸", hl = { fg = "#00cfcf" } } } },
	{ { veil, space, { text = "⠼", hl = { fg = "#00cfcf" } } } },
	{ { veil, space, { text = "⠴", hl = { fg = "#00cfcf" } } } },
	{ { veil, space, { text = "⠦", hl = { fg = "#00cfcf" } } } },
	{ { veil, space, { text = "⠧", hl = { fg = "#00cfcf" } } } },
	{ { veil, space, { text = "⠇", hl = { fg = "#00cfcf" } } } },
	{ { veil, space, { text = "⠏", hl = { fg = "#00cfcf" } } } },
}

function builtin.frames.new(frames, hl)
	local new = {}
	for _, frame in ipairs(frames) do
		table.insert(new, {})
		for j, line in ipairs(frame) do
			table.insert(new[#new], {})
			table.insert(new[#new][j], { text = line, hl = hl })
		end
	end
	return new
end

function builtin.sections.animated(frames)
	return {
		state = {
			animation = {
				current = 1,
				frames = frames,
			},
		},
		should_update = true,
		update = function(self)
			local current = self.state.animation.current
			self.state.animation.current = current + 1
			if current >= #self.state.animation.frames then
				self.state.animation.current = 1
			end
		end,
		content = function(self)
			return self.state.animation.frames[self.state.animation.current]
		end,
	}
end

return builtin
