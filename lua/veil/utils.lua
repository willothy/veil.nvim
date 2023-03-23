local utils = {}

function utils.longest_line(lines)
	local longest = 0
	for _, line in ipairs(lines) do
		if #line > longest then
			longest = #line
		end
	end
	return longest
end

function utils.empty(lines)
	local empty = {}
	for _ = 1, lines, 1 do
		table.insert(empty, "")
	end
	return empty
end

function utils.split_leading(str)
	local len = #str
	local s = str:gsub("^%s+", "")
	local diff = len - #s - 1
	return string.rep(" ", diff), s
end

return utils
