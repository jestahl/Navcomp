--[[
	Algorithmic functions for NavComp
	
	All functions take the same arguments:
	
	n1 = the waypoint head under consideration
	n2 = the current waypoint head
	s2 = the final target of the navroute within a given system
	stats = contains system stress map and stress statistics
	area = contains list of considered waypoints and local stress data for jump calculation
	
	A waypoint has the following structure:
	
	s = the sector ID of the waypoint 
	d1 = the real distance from the starting point to the waypoint
	d2 = the real distance from the waypoint to the target
	str1 = the total sector stress between the starting point and the waypoint
	line1 = the line length (in sectors) between the starting point and the waypoint
	str2 = the total sector stress between the waypoint and the target
	line2 = the line length (in sectors) between the waypoint and the target
	blocked = is the path between the waypoint and the target blocked by a prohibited sector?
	
	A Comparator should return n1 or n2 if one of those fits exactly the selection conditions for the test.
	The Comparator should return nil if unable to choose definitively between the waypoints.
]]

navcomp.plotter = {}
dofile ("plotter/options.lua")
dofile ("plotter/line-ratio.lua")
dofile ("plotter/edge.lua")

function navcomp.plotter:Stress (n1, n2, s2, stats, area)
	if stats.map [n1.s] < stats.map [n2.s] - 3 then
		return n1
	end
end

function navcomp.plotter:LineStress (n1, n2, s2, stats, area)
	local stress1 = n1.str1 + n1.str2
	local stress2 = n2.str1 + n2.str2
	if stress1 < stress2 - 5 then
		return n1
	end
end

function navcomp.plotter:FinalLineStress (n1, n2, s2, stats, area)
	if n1.str2 < n2.str2 then
		return n1
	end
end

function navcomp.plotter:Distance (n1, n2, s2, stats, area)
	if n1.d2 < n2.d2 then
		return n1
	end
end

function navcomp.plotter:EllipticDistance (n1, n2, s2, stats, area)
	if (n1.d1 + n1.d2) < (n2.d1 + n2.d2 - 3) then
		return n1
	end
end

function navcomp.plotter:HyperbolicDistance (n1, n2, s2, stats, area)
	if math.abs (n1.d1 - n1.d2) < math.abs (n2.d1 - n2.d2) - 3 then
		return n1
	end
end

function navcomp.plotter:EllipticLineDistance (n1, n2, s2, stats, area)
	if (n1.line1 + n1.line2) < (n2.line1 + n2.line2) then
		return n1
	end
end

function navcomp.plotter:HyperbolicLineDistance (n1, n2, s2, stats, area)
	if math.abs (n1.line1 - n1.line2) < math.abs (n2.line1 - n2.line2) then
		return n1
	end
end

function navcomp.plotter:FinalLineDistance (n1, n2, s2, stats, area)
	if n1.line2 < n2.line2 then
		return n1
	end
end
