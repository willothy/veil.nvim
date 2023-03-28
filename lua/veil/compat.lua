local compat = {}

function compat.noice()
	if package.loaded["noice"] then
		require("noice.util.hacks")._guicursor = nil
	end
end

return compat
