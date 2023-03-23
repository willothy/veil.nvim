local Section = require("veil.section")

local builtin = {}

function builtin.animated(frames)
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
	})
end

return builtin
