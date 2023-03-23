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
		}),
	},
	mappings = {},
	startup = true,
}

return default
