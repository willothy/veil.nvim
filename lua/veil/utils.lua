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

function utils.split_leading(string)
	local leading_ws = string:match("^%s*")
	local rest = string:match("^%s*(.*)")
	return leading_ws, rest
end

return utils
