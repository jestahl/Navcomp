--[[
	Utility Functions for Navigation Computer Plugin
]]

dofile ("data/tools.lua")

function navcomp:FindSystemPath (s1, s2, stats, recursionLevel)
	recursionLevel = recursionLevel or 0
	local first = s1
	navcomp.data.targetList = navcomp.data.targetList or {}
	table.insert (navcomp.data.targetList, s2)
	local targetListString = "|" .. table.concat (navcomp.data.targetList, "|") .. "|"
	local sysId, y1, x1 = SplitSectorID (s1)
	local _, y2, x2 = SplitSectorID (s2)
	local targetDist = navcomp:Distance (s1, s2)
	local s, x, y, x1, y1, ts, k, v, proc
	local stress, dist, str
	local navroute = {s1}
	local area = {}
	local navrouteString
	local steps = 0
	
	while s1 ~= s2 and steps < navcomp.data.maxSteps do
		navcomp:Yield ()
		navcomp.ui.progress:Update (256 + math.floor (244 * (1 - navcomp:Distance (s1, s2) / targetDist)))
		steps = steps + 1
		navrouteString = "|" .. table.concat (navroute, "|") .. "|"
		s = {
			s = s1,
			d1 = 0,
			d2 = navcomp:Distance (s1, s2) + 5,
			str1 = stats.map [s1] + 3,
			line1 = 1,
			str2 = navcomp:GetLineStress (s1, s2, stats.map),
			line2 = #navcomp:GetSectorLine (s1, s2),
			blocked = navcomp:IsPathProhibited (s1, s2, true)
		}
		if s.blocked then
			area = navcomp:GetJumps (s1, s2, navrouteString, stats.map)
			proc = navcomp.plotter:GetAlgorithm (sysId, stats, area)
			
			-- Check if skipping this system
			if proc [1] (navcomp, area.sectors [1], area.sectors [1], s2, stats, area) == "skip" then
				s = {
					s = s2,
					d1 = 0,
					d2 = 0,
					str1 = 0,
					line1 = 0,
					str2 = 0,
					line2 = 0,
					blocked = false
				}
			else
				for _,v in ipairs (area.sectors) do
					s = navcomp:Compare (v, s, s2, stats, area, proc)
				end
			end
			if s.s ~= s1 then
				table.insert (navroute, s.s)
				s1 = s.s
			end
		else
			table.insert (navroute, s2)
			s1 = s2
		end
	end
	
	-- Check if complete path.  If not, recurse outward until successful
	if navroute [#navroute] ~= s2 then
		if recursionLevel <= navcomp.data.maxRecursion then
			area = navcomp:GetJumps (s2, first, targetListString, stats.map)
			for _,v in ipairs (area.sectors) do
				s = navcomp:Compare (v, s, first, stats, area, navcomp.plotter:GetAlgorithm (sysId, stats, area))
			end
			local foundPath = false
			for _,v in ipairs (area.sectors) do
				s1 = v.s
				navroute = navcomp:FindSystemPath (first, s1, stats, recursionLevel+1)
				if navroute [#navroute] == s1 then
					foundPath = true
					break
				end
				navcomp:Yield ()
			end
			if not foundPath then
				s1 = navroute [#navroute]
			end
			local finalroute = navcomp:FindSystemPath (s1, s2, stats, recursionLevel+1)
			for _,v in ipairs (finalroute) do
				table.insert (navroute, v)
			end
		else
			-- All recursive attempts to find a clear path exhausted.  Just draw a line
			-- from where we got lost to end.
			table.insert (navroute, s2)
		end
	end
	
	return navroute
end

function navcomp:SmoothSystemPath (path, stats)
	local result = {path [1]}
	if #path > 2 then
		local first = 1
		local last = 3
		local totalStress, smoothStress
		for k=2, #path-1 do
			if navcomp:IsSectorProhibited (path [k], true) or navcomp:IsAvoidSector (path [k]) or navcomp:IsConquerableStationSector (path [k]) then
				-- Do Nothing, we're dropping this jump
			elseif navcomp:IsPathProhibited (path [first], path [last], true) then
				table.insert (result, path [k])
				first = k
			elseif navcomp:IsBotSector (path [k]) or navcomp:IsStationSector (path [k]) then
				-- Do Nothing, we're dropping this jump
			end
			last = last + 1
			navcomp:Yield ()
		end
	end
	table.insert (result, path [#path])

	return result
end

function navcomp:SmoothLineSegments (path, stats)
	local sysId
	local n1 = {x=0, y=0}
	local n2 = {x=0, y=0}
	local n3 = {x=0, y=0}
	local n4 = {x=0, y=0}
	local k = 1
	while k+3 <= #path do
			
		-- Set up first and 3rd line segments
		sysId, n1.y, n1.x = SplitSectorID (path [k])
		sysId, n2.y, n2.x = SplitSectorID (path [k+1])
		sysId, n3.y, n3.x = SplitSectorID (path [k+2])
		sysId, n4.y, n4.x = SplitSectorID (path [k+3])
		
		-- Find intersection
		navcomp:Yield ()
		local a0 = n1.y - n2.y
		local a1 = n2.x - n1.x
		local b0 = n3.y - n4.y
		local b1 = n4.x - n3.x
		local a2 = a0*n2.x + a1*n2.y
		local b2 = b0*n4.x + b1*n4.y
		local w = a0*b1 - a1*b0
		
		local xInt = math.floor (-1 * (a1*b2 - a2*b1)/w + 0.5)
		local yInt = math.floor ((a0*b2 - a2*b0)/w + 0.5)
		if xInt >=1 and xInt <= 16 and yInt >= 1 and yInt <= 16 then
			local c1 = navcomp:BuildSectorId (sysId, xInt, yInt)
			
			-- Check if prohibited
			-- Check intersection point
			-- If both new segments are not prohibited, add new node to path in n2 and remove n3
			navcomp:Yield ()
			if not navcomp:IsSectorProhibited (c1, true) and
								not navcomp:IsStarSector (c1) and
								not navcomp:IsAvoidSector (c1) and 
								not navcomp:IsConquerableStationSector (c1) and
								not navcomp:IsTrainingSector (c1) and
								not navcomp:IsBlockableSector (c1, true) and 
								not navcomp:IsPathProhibited (path [k], c1, true) and 
								not navcomp:IsPathProhibited (c1, path [k+3], true) then
				path [k+1] = c1
				table.remove (path, k+2)
			else
				k = k + 1
			end
		else
			k = k + 1
		end
	end
	
	return path
end

function navcomp:PlotSystemPath (s1, s2, stats)
	-- Check for possible anchors for the target
	local anchorpath = {}
	if s1 ~= s2 and navcomp.data.navigation [s2] then
		local anchors = navcomp.data.navigation [s2].anchors
		while anchors do
			local ank, anchor, override
			for _, ank in ipairs (anchors) do
				override = navcomp.data.anchorOverride or ank.override
				if ank.s == s1 and (override or not navcomp:IsPathProhibited (ank.s, s2, true)) then
					table.insert (anchorpath, 1, s2)
					table.insert (anchorpath, 1, s1)
					return anchorpath
				
				elseif not anchor and (override or not navcomp:IsPathProhibited (ank.s, s2, true)) then
					anchor = ank.s
				end
			end
			if anchor then
				table.insert (anchorpath, 1, s2)
				s2 = anchor
				anchors =  nil
				if navcomp.data.navigation [s2] then
					anchors = navcomp.data.navigation [s2].anchors
				end
			else
				anchors = nil
			end
		end
	end

	-- Calculate navpath normally
	navcomp.data.targetList = {}
	local navpath = navcomp:FindSystemPath (s1, s2, stats)
	local numSteps
	repeat
		numSteps = #navpath
		navpath = navcomp:SmoothSystemPath (navpath, stats)
		navcomp:Yield ()
	until numSteps == #navpath
	if navcomp.data.useSegmentSmoothing then
		navcomp:SmoothLineSegments (navpath, stats)
	end
	
	-- If anchors were used, append them to the path
	local s
	for _, s in ipairs (anchorpath) do
		table.insert (navpath, s)
	end
	
	return navpath
end

function navcomp:PlotFullPath (path)
	if not path then return end
	local s1 = path [1]
	local currentSysId = GetSystemID (s1)
	if navcomp.data.backgroundPlot then
		navcomp:Print ("Plotting " .. SystemNames [currentSysId])
	end
	local sysId, systempath, k, stats
	local navpath = {}
	sysId = GetSystemID (s1)
	if navcomp.data.plotCapitalSystems or not navcomp:IsCapitalSystem (sysId) then
		stats = navcomp:AnalyzeSystem (s1)
	end
	
	-- Build paths through each system along the route
	for k=2, #path do
		sysId = GetSystemID (path [k])
		systempath = {}
		if sysId ~= currentSysId then
			if navcomp.data.backgroundPlot then
				navcomp:Print ("Plotting " .. SystemNames [sysId])
			end
			if navcomp.data.isOptionDataChanged then
				navcomp.data:LoadPerformanceOptions ()
			end
			systempath = {path [k]}
			s1 = path [k]
			if navcomp.data.plotCapitalSystems or not navcomp:IsCapitalSystem (sysId) then
				stats = navcomp:AnalyzeSystem (s1)
			end
			currentSysId = sysId
		else
			if not navcomp.data.plotCapitalSystems and navcomp:IsCapitalSystem (sysId) then
				systempath = {s1, path [k]}
			else
				systempath = navcomp:PlotSystemPath (s1, path [k], stats)
			end
			s1 = path [k]
		end
		for _,v in ipairs (systempath) do
			table.insert (navpath, v)
		end
		if not navcomp.data.isEvading then
			navcomp:SetPath (systempath, false)
		end
		navcomp:Yield ()
	end
	
	return navpath
end

function navcomp:PlotEvasionPath ()
	local x, y, x1, y1, sectors
	local path = {}
	local evadePath = NavRoute.GetCurrentRoute ()
	local steps = #evadePath
	local s1 = evadePath [steps] or GetCurrentSectorid ()
	if steps < math.ceil (navcomp.data.evasionLevel/2) then
		local evasionLevel = navcomp.data.evasionLevel
		while steps < evasionLevel do
			local sysId, x, y, x1, y1, ts, str1, str2, line1, line2
			sysId, y1, x1 = SplitSectorID (s1)
			sectors = {}
			for x=x1-navcomp:Lower (x1, 1), x1+navcomp:Upper (x1, 1) do
				for y=y1-navcomp:Lower (y1, 1), y1+navcomp:Upper (y1, 1) do
					ts = navcomp:BuildSectorId (sysId, x, y)
					if ts ~= s1 and
							not navcomp:IsSectorProhibited (ts, true) and
							not navcomp:IsStarSector (ts) and
							not navcomp:IsConquerableStationSector (ts) and
							not navcomp:IsRacetrackSector (ts) and
							not navcomp:IsStationSector (ts) and
							not navcomp:IsWormholeSector (ts) and
							not navcomp:IsTrainingSector (ts) then
						sectors [#sectors + 1] = ts
					end
				end
			end
			
			s1 = sectors [math.random (#sectors)]
			path [#path + 1] = s1
			steps = steps + 1
		end
		
		navcomp:SetPath (path, false)
	end
end

-- Thread Management
function navcomp:DoPlot ()
	navcomp.pda:SetPlotMode (true)
	if navcomp.data.isOptionDataChanged then
		navcomp.data:LoadPerformanceOptions ()
	end
	navcomp.data.stepCounter = 0
	local navpath = NavRoute.GetCurrentRoute ()
	NavRoute.clear ()
	navcomp:PlotFullPath (GetFullPath (GetCurrentSectorid (), navpath))
	if navcomp.data.isOptionDataChanged then
		navcomp.data:LoadPerformanceOptions ()
	end
	navcomp.data.activePath.path = navpath
	navcomp.pda:SetPlotMode (false)
	
	return #navpath
end

local thread = Timer ()
function navcomp:RunThread ()
	if not navcomp.data.isEvading then
		thread:SetTimeout (navcomp.data.delay, function ()
			coroutine.resume (navcomp.data.plotter)
			if coroutine.status (navcomp.data.plotter):lower () ~= "dead" then
				return navcomp:RunThread ()
			else
				navcomp.ui.progress.visible = "NO"
				iup.Refresh (HUD.cboxlayer)
				navcomp:Print ("Plot Complete")
			end
		end)
	else
		navcomp.data.plotter = nil
		navcomp.ui.progress.visible = "NO"
		navcomp:Print ("Plot Interrupted")
		iup.Refresh (HUD.cboxlayer)
	end
end

function navcomp:Yield ()
	if navcomp.data.backgroundPlot and navcomp.data.plotter then
		navcomp.data.stepCounter = navcomp.data.stepCounter + 1
		if navcomp.data.stepCounter == navcomp.data.maxStepLimit and coroutine.status (navcomp.data.plotter) == "running" then
			navcomp.data.stepCounter = 0
			coroutine.yield ()
		end
	end
end