local builtin = require("veil.builtin")

local default = {
	---@type Section[]
	sections = {
		builtin.animated({
			{ "-- Veil --", "-- Veil --" },
			{ "+- Veil --", "-- Veil -+" },
			{ "++ Veil --", "-- Veil ++" },
			{ "-+ Veil --", "-- Veil -+" },
			{ "-- Veil ++", "++ Veil --" },
			{ "-- Veil -+", "-+ Veil --" },
			{ "++ Veil --", "-- Veil ++" },
			{ "-+ Veil --", "-- Veil -+" },
		}, {
			hl = { fg = "#5de4c7" },
		}),
	},
	mappings = {},
	startup = true,
}

return default
