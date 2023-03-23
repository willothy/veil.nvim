local veil = require("veil")
local utils = require("veil.utils")

local Rendered = {
	text = {},
	nlines = 0,
	longest = 0,
	virt = true,
	hl = "Normal",
}

function Rendered:pad(width)
	local padding
	if self.longest < width then
		padding = (width - (self.longest * 2)) / 2
	end
	for lno, line in ipairs(self.text) do
		self.text[lno] = string.rep(" ", padding) .. line
	end
	return self
end

function Rendered:new(opts)
	local new = vim.tbl_deep_extend("keep", opts or {}, self)
	return new
end

---@alias Highlight { fg: string|nil, bg: string|nil, style:string|nil}
---@class Section
---@field contents fun(self: Section):string[]
---@field state table<string, any>
---@field interactive boolean Whether or not the section is interactive.
---@field hl string | Highlight | fun(self: Section):Highlight Highlight group to use for the section.
local Section = {
	state = {},
	interactive = false,
	hl = "Normal",
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
			-- Reserved names
			if k == "interactive" or k == "contents" then
				error("Section." .. k .. " cannot be updated after initialization", 2)
			else
				rawset(state, k, v)
			end
		end,
	}

	if type(new.hl) == "string" then
		new.hl = vim.api.nvim_get_hl_by_name(new.hl, true)
	end

	-- Generate random id for section hlgroup
	local hl_id = "VeilSection" .. math.floor(math.random() * 100)

	-- Build the section and render function
	mt.__index.interactive = new.interactive
	mt.__index.hl = hl_id
	mt.__index.hl_val = new.hl
	---@type fun(tbl:Section):Rendered
	mt.__index.render = function(tbl)
		-- Create the new hlgroup
		local hl_val
		if type(tbl.hl_val) == "function" then
			hl_val = tbl:hl_val()
		else
			hl_val = tbl.hl_val
		end
		veil.ns = vim.api.nvim_create_namespace("veil")
		vim.api.nvim_set_hl(veil.ns, tbl.hl, hl_val)
		local contents = nil
		if type(new.contents) == "function" then
			contents = new.contents(tbl)
		elseif type(new.contents) == "table" then
			contents = new.contents
		elseif type(new.contents) == "string" then
			contents = { new.contents }
		else
			error("Section.contents must be a function, string[], or string", 2)
		end
		return Rendered:new({
			text = contents,
			nlines = #contents,
			longest = utils.longest_line(contents),
			virt = not tbl.interactive,
			hl = tbl.hl,
		})
	end

	return setmetatable({}, mt)
end

return Section
