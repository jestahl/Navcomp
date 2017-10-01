--[[
	This comparator chooses jump sectors based on the ratio = sum line stress / sum line distance
	and making the lowest ratio the most desirable
]]

function navcomp.plotter:LineRatio (n1, n2, s2, stats, area)
	local n1ratio = (n1.str1+n1.str2)/(n1.line1+n1.line2)
	local n2ratio = (n2.str1+n2.str2)/(n2.line1+n2.line2)
	if n1ratio < n2ratio then
		return n1
	end
end