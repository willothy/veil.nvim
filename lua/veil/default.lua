local builtin = require("veil.builtin")

return {
	sections = {
		-- {
		-- 	content = {
		-- 		hl = "Visual",
		-- 		text = "Hello, World!",
		-- 	},
		-- },
		builtin.sections.animated,
	},
	mappings = {},
	startup = true,
	center = {
		horizontal = true,
		vertical = true,
	},
}
