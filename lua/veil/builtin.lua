local builtin = {
	sections = {},
}

builtin.sections.animated = {
	state = {
		animation = {
			current = 1,
			frames = {
				-- { { { text = "⠋", hl = "Normal" } } },
				-- { { { text = "⠙", hl = "Normal" } } },
				-- { { { text = "⠹", hl = "Normal" } } },
				-- { { { text = "⠸", hl = "Normal" } } },
				-- { { { text = "⠼", hl = "Normal" } } },
				-- { { { text = "⠴", hl = "Normal" } } },
				-- { { { text = "⠦", hl = "Normal" } } },
				-- { { { text = "⠧", hl = "Normal" } } },
				-- { { { text = "⠇", hl = "Normal" } } },
				-- { { { text = "⠏", hl = "Normal" } } },
				{ { { text = "⠋", hl = { fg = "#ff0000" } } } },
				{ { { text = "⠙", hl = { fg = "#00ff00" } } } },
				{ { { text = "⠹", hl = { fg = "#0000ff" } } } },
				{ { { text = "⠸", hl = { fg = "#ff0000" } } } },
				{ { { text = "⠼", hl = { fg = "#00ff00" } } } },
				{ { { text = "⠴", hl = { fg = "#0000ff" } } } },
				{ { { text = "⠦", hl = { fg = "#ff0000" } } } },
				{ { { text = "⠧", hl = { fg = "#00ff00" } } } },
				{ { { text = "⠇", hl = { fg = "#0000ff" } } } },
				{ { { text = "⠏", hl = { fg = "#ff0000" } } } },
			},
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
		local frames = self.state.animation.frames
		return frames[self.state.animation.current]
	end,
}

return builtin
