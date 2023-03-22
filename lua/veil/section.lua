---@class Section
---@field contents fun(self: Section):string[]
---@field state table<string, any>
---@field interactive boolean Whether or not the section is interactive.
local Section = {
	state = {},
	interactive = false,
}

function Section:contents()
	return { "configure your veil!" }
end

---@alias SectionOpts Section
---@type fun(opts: table):Section
function Section:new(opts)
	local new = vim.tbl_deep_extend("keep", opts or {}, self)

	local mt = {
		__index = new.state,
		__newindex = function(state, k, v)
			if k == "interactive" or k == "contents" then
				error("Section." .. k .. " cannot be updated after initialization", 2)
			else
				rawset(state, k, v)
			end
		end,
	}
	mt.__index.interactive = new.interactive
	mt.__index.render = function()
		return new.contents(mt)
	end

	return setmetatable({}, mt)
end

return Section
