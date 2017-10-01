--[[
	Debugging functions and code
]]

function navcomp:Line ()
	navcomp:SetPath (navcomp:GetSectorLine (GetCurrentSectorid (), NavRoute.GetFinalDestination ()), true)
end

function navcomp:Jumps ()
	local navpath = NavRoute.GetCurrentRoute ()
	local s1, s2, sectors, area
	if #navpath > 1 then
		s1 = navpath [#navpath - 1]
		s2 = navpath [#navpath]
	else
		s1 = GetCurrentSectorid ()
		s2 = NavRoute.GetFinalDestination ()
	end
	local sysId = GetSystemID (GetCurrentSectorid ())
	local stats = navcomp:AnalyzeSystem (s1)
	local navrouteString = "|" .. tostring (s1) .. "|" .. table.concat (navpath, "|") .. "|"
	area = navcomp:GetJumps (s1, s2, navrouteString, stats.map)
	local s = {
			s = s1,
			d1 = 0,
			d2 = navcomp:Distance (s1, s2) + 5,
			str1 = stats.map [s1] + 3,
			line1 = 1,
			str2 = navcomp:GetLineStress (s1, s2, stats.map),
			line2 = #navcomp:GetSectorLine (s1, s2),
			blocked = navcomp:IsPathProhibited (s1, s2, true)
		}
	local initialBlocked = s.blocked
	print ("index: Sector Name [d1, d2] = [stress1/line1, stress2/line2] (sum line stress / sum line distance) Blocked")
	print (string.format ("%d: %s [%d, %d] = [%d/%d, %d/%d] (%f) %s", 0, AbbrLocationStr (s.s), s.d1, s.d2, s.str1, s.line1, s.str2, s.line2, ((s.str1+s.str2)/(s.line1+s.line2)), tostring (s.blocked)))
	for k,v in ipairs (area.sectors) do
		print (string.format ("%d: %s [%d, %d] = [%d/%d, %d/%d] (%f) %s", k, AbbrLocationStr (v.s), v.d1, v.d2, v.str1, v.line1, v.str2, v.line2, ((v.str1+v.str2)/(v.line1+v.line2)), tostring (v.blocked)))
		s = navcomp:Compare (v, s, s2, stats, area, navcomp.plotter:GetAlgorithm (sysId, stats, area))
	end
	if not initialBlocked then
		s.s = s2
	end
	print (string.format ("System Stress Total/Average: %d/%f", stats.stress, stats.stress/256))
	print (string.format ("Area Stress Total/Average: %d/%f", area.stress, area.stress/#area.sectors))
	print (string.format ("Prohibited Sectors: %d", (24-#area.sectors)))
	print (string.format ("Prohibited Stress: %f", area.stress/(24-#area.sectors)))
	print (string.format ("Area Percent of Stress: %f", area.stress/stats.stress * 100))
	print (string.format ("Area Percent of System: %f", #area.sectors/256 * 100))
	print (string.format ("S/A Rating: %f", area.stress/stats.stress * 256/#area.sectors))
	print (string.format ("Suggested Jump: %s", AbbrLocationStr (s.s)))
end

function navcomp:FindPath ()
	navcomp.data:LoadNavigationData ()
	navcomp.data:LoadPathNotes ()
	local s1 = GetCurrentSectorid ()
	local s2 = NavRoute.GetFinalDestination ()
	local stats = navcomp:AnalyzeSystem (s1)
	navcomp.data.targetList = {}
	navcomp:SetPath (navcomp:FindSystemPath (s1, s2, stats))
end

function navcomp:Analyze ()
	local sysId = GetSystemID (GetCurrentSectorid ())
	navcomp:PrintStats (sysId, navcomp:AnalyzeSystem (GetCurrentSectorid ()))
end

function navcomp:MetaData ()
	local v
	for _,v in ipairs (navcomp.plotter:GetSystemMetadataList (GetSystemID (GetCurrentSectorid ()))) do
		print (string.format ("Logic: %s", v))
	end
end

function navcomp:Segment ()
	local sysId
	local n1 = {x=0, y=0}
	local n2 = {x=0, y=0}
	local n3 = {x=0, y=0}
	local n4 = {x=0, y=0}
	local k = 1
	local path = {GetCurrentSectorid ()}
	local s
	for _,s in ipairs (NavRoute.GetCurrentRoute ()) do
		table.insert (path, s)
	end
	
	print (string.format ("path length: %d", #path))
		
	-- Set up first and 3rd line segments
	sysId, n1.y, n1.x = SplitSectorID (path [k])
	sysId, n2.y, n2.x = SplitSectorID (path [k+1])
	sysId, n3.y, n3.x = SplitSectorID (path [k+2])
	sysId, n4.y, n4.x = SplitSectorID (path [k+3])
	print (string.format ("n1 x=%d\ty=%d", n1.x, n1.y))
	print (string.format ("n2 x=%d\ty=%d", n2.x, n2.y))
	print (string.format ("n3 x=%d\ty=%d", n3.x, n3.y))
	print (string.format ("n4 x=%d\ty=%d", n4.x, n4.y))
	
	-- Find intersection
	local a0 = n1.y - n2.y
	local a1 = n2.x - n1.x
	local b0 = n3.y - n4.y
	local b1 = n4.x - n3.x
	local a2 = a0*n2.x + a1*n2.y
	local b2 = b0*n4.x + b1*n4.y
	local w = a0*b1 - a1*b0
	print (string.format ("a0, a1, a2 = %d\t%d\t%d", a0, a1, a2))
	print (string.format ("b0, b1, b2 = %d\t%d\t%d", b0, b1, b2))
	
	local xInt = math.floor (-1 * (a1*b2 - a2*b1)/w + 0.5)
	local yInt = math.floor ((a0*b2 - a2*b0)/w + 0.5)
	local c1 = navcomp:BuildSectorId (sysId, xInt, yInt)
	print (string.format ("Data: %s (%d, %d)", SystemNames [sysId], xInt, yInt))
	print (string.format ("Intersection point: %s", AbbrLocationStr (c1)))
	path [k+1] = c1
	table.remove (path, k+2)
	navcomp:SetPath (path, true)
end