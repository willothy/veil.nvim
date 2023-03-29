local compat = {}

function compat.noice(hide)
	if package.loaded["noice"] then
		if hide then
			require("noice.util.hacks")._guicursor = nil
		else
			require("noice.util.hacks").show_cursor()
		end
	end
end

return compat
