--[[
	Tools for managing calculation elements in NavComp
]]

function navcomp:SetPath (path, clearPath)
	local v
	if path and #path > 0 then
		if clearPath == nil then clearPath = true end
		if GetCurrentSectorid () == path [1] then
			table.remove (path, 1)
		end
		if clearPath then NavRoute.clear () end
		for _,v in ipairs (path) do
			NavRoute.addbyid (v)
			navcomp:Yield ()
		end
	end
end

function navcomp:ComparePaths (path1, path2)
	if type (path1) ~= "table" or type (path2) ~= "table" then return false
	elseif #path1 ~= #path2 then return false
	else
		-- Compare sectorIds in each path.  If any differ, return false
		local k
		for k=1, #path1 do
			if path1 [k] ~= path2 [k] then return false end
		end
		
		return true
	end
end

function navcomp:ClearActivePath ()
	navcomp.data.activePath.name = nil
	navcomp.data.activePath.note = ""
	navcomp.data.activePath.autoPlot = false
	navcomp.pda:SetReloadMode (false)
end

function navcomp:CheckAutoPlot (navpath)
	if navpath.autoPlot or navcomp.data.autoPlot then
		navcomp:PlotPath ()
	end
end

function navcomp:SetActivePath ()
	navcomp.data.activePath.path = NavRoute.GetCurrentRoute ()
end

function navcomp:SaveActivePath (data)
	local navpath = navcomp.data:CreatePath (data)
	if navpath then
		navcomp.data:SavePathNote (navpath)
		navcomp.data:SavePathNotes ()
		navcomp:CheckAutoPlot (navpath)
		return true
	else
		return false
	end
end

function navcomp:LoadActivePath (pathName)
	local navpath = navcomp.data:LoadPathNote (pathName) or navcomp.data.activePath
	if navpath and #navpath.path > 0 then
		navcomp.data.activePath = navpath
		navcomp:SetPath (navpath.path)
		navcomp:CheckAutoPlot (navpath)
		return true
	else
		return false
	end
end

function navcomp:BuildLocationId (x, y)
	return 16 * (x - 1) + y
end

function navcomp:BuildSectorId (sysId, x, y)
	return 256 * (sysId-1) + navcomp:BuildLocationId (x, y)
end

function navcomp:Distance (s1, s2)
	local _, y1, x1 = SplitSectorID (s1)
	local _, y2, x2 = SplitSectorID (s2)
	return (x2 - x1)*(x2 - x1) + (y2 - y1)*(y2 - y1)
end

function navcomp:Lower (n, r)
	if n < r + 1 then
		return n - 1
	else
		return r
	end
end

function navcomp:Upper (n, r)
	if n > 16 - r then
		return 16 - n
	else
		return r
	end
end

function navcomp:GetSectorNote (s1)
	if s1 then
		local sysId = GetSystemID (s1)
		if not SystemNotes [sysId] then
			return ""
		end
		return SystemNotes [sysId][s1] or ""
	else
		return ""
	end
end

function navcomp:SetSectorNote (s1, note)
	if s1 then
		note = note or ""
		local sysId = GetSystemID (s1)
		SystemNotes [sysId][s1] = note
	end
end

function navcomp:SyncSectorNotes ()
	local sysId, targetId, sectorId, notes, note, nav
	
	-- Create clone of navigation object
	local tempNav = navcomp.data:Clone (navcomp.data.navigation)
	
	-- Loop through Notes and make any noted changes
	-- Remove each discovered sector note from the clone
	for sysId, notes in pairs (SystemNotes) do
		for targetId, note in pairs (notes) do
			-- Check for manual avoids
			if string.find (note:lower (), "#avoid:") then
				-- Found avoid, checking if already recorded
				tempNav [targetId] = nil
				navcomp.data.navigation [targetId] = navcomp.data.navigation [targetId] or {}
				if not navcomp.data.navigation [targetId].avoid then
					-- New avoid, clear system from map cache
					navcomp.data.stressMaps [GetSystemID (targetId)] = nil
				end
				navcomp.data.navigation [targetId].avoid = true
			end
			
			-- Check for Anchors
			-- Anchor syntax
			-- #anchors ([*]<sectorId>, [*]<sectorId>, ...):
			local sectors = string.match (note, "#anchors%s*%(([%*?%a%-?%d%d?%s*,?]+)%):")
			if sectors then
				local v, h, override
				tempNav [targetId] = nil
				navcomp.data.navigation [targetId] = navcomp.data.navigation [targetId] or {}
				navcomp.data.navigation [targetId].anchors = {}
				for override, v, h in string.gmatch (sectors, "(%*?)(%a)%-?(%d%d?)") do
					override = override == "*"
					sectorId = navcomp:BuildSectorId (sysId, h, navcomp.data.sectors [v:upper ()])
					table.insert (navcomp.data.navigation [targetId].anchors, {s=sectorId, override=override})
				end
			end
		end
	end
	
	-- Loop through any remaining temp navigation objects and clear their stress maps
	-- since no navigational tags were found in the sector notes
	for targetId, nav in pairs (tempNav) do
		if nav.avoid then
			navcomp.data.stressMaps [GetSystemID (targetId)] = nil
		end
		navcomp.data.navigation [targetId].avoid = nil
		navcomp.data.navigation [targetId].anchors = nil
	end
	
	ProcessEvent ("NAVCOMP_REPAINT")
end

if not string.Split then
	function string.Split (s, d, trim)
		s = s or ""
		d = d or " "
		trim = trim or false
		local words = {}
		s = s .. d
		local pattern = "[^" .. d .. "]+"
		
		local elem
		for elem in string.gmatch (s, pattern) do
			if trim then
				local k
				for k=1, elem:len () do
					if elem:sub (k, k) ~= " " then
						elem = elem:sub (k)
						break
					end
				end
				for k=elem:len (), 1, -1 do
					if elem:sub (k, k) ~= " " then
						elem = elem:sub (1, k)
						break
					end
				end
			end
			table.insert (words, elem)
		end
		
		return words
	end
end

function navcomp:GetAnchorDefinition (sectorId)
	-- Get any anchor information (if present)
	local before, after, oldAnchors
	local note = navcomp:GetSectorNote (sectorId)
	local i1, i2 = string.find (note, "#anchors%s*%([%*?%a%-?%d%d?%s*,?]+%):")
	if i1 and i2 then
		before = string.sub (note, 1, i1-1)
		after = string.sub (note, i2+1)
		oldAnchors = string.match (string.sub (note, i1, i2), "#anchors%s*%(([%*?%a%-?%d%d?%s*,?]+)%):")
	else
		if note:len () > 0 then
			before = note .. "\n"
		else
			before = ""
		end
		after = ""
		oldAnchors = ""
	end
	return before, after, oldAnchors
end

function navcomp:WeaveAnchors (anchorStr, sortCb)
	local item
	local data = {}
	for _, item in ipairs (string.Split (anchors, ",", true)) do
		local lock, column, row = string.match (item, "(%*?)([ABCDEFGHIJKLMNOP])(%d%d?)")
		table.insert (data, {lock=lock or "", col=column, row=row})
	end
	sortCb = sortCb or function (a, b)
		if a.col < b.col then
			return true
		elseif a.col == b.col then
			return tonumber (a.row) < tonumber (b.row)
		else
			return false
		end
	end
	table.sort (data, sortCb)
	local temp = {}
	for _, item in ipairs (data) do
		table.insert (temp, string.format ("%s%s%s", item.lock, item.col, item.row))
	end
	
	return table.concat (temp, ",")
end

function navcomp:IsAnchorDefinedForSector (sectorId, anchorId)
end

function navcomp:WriteNewAnchors (target)
	-- Rewrite the sector note for the given sector
	local anchor, sysId, note, x, y, newAnchors, lock
	local before, after, oldAnchors = navcomp:GetAnchorDefinition (target.sectorId)
	
	--Build anchor string
	newAnchors = {}
	for _, anchor in ipairs (target.anchors) do
		sysId, y, x = SplitSectorID (anchor.s)
		lock = ""
		if anchor.override then
			lock = "*"
		end
		table.insert (newAnchors, string.format ("%s%s", lock, navcomp.data.columnNumbers [y] .. tostring (x)))
	end
	newAnchors = table.concat (newAnchors, ",")
	
	-- Rebuild sector note
	if oldAnchors:len () > 0 then
		note = before .. string.format ("#anchors (%s,%s):", oldAnchors, newAnchors) .. after
	else
		note = before .. string.format ("#anchors (%s):", newAnchors) .. after
	end
	navcomp:SetSectorNote (target.sectorId, note)
end

function navcomp:GetSectorLine (s1, s2)
	local s
	local sysId, y1, x1 = SplitSectorID (s1)
	local _, y2, x2 = SplitSectorID (s2)
	local sysTag = 256 * (sysId - 1)
	local loc1 = navcomp:BuildLocationId (x1, y1)
	local loc2 = navcomp:BuildLocationId (x2, y2)
	local lineId
	if loc1 <= loc2 then
		lineId = string.format ("%d:%d", loc1, loc2)
	else
		lineId = string.format ("%d:%d", loc2, loc1)
	end
	local sectors = {}
	
	if navcomp.data.sectorLines [lineId] then
		for _,s in ipairs (navcomp.data.sectorLines [lineId]) do
			--sectors [#sectors + 1] = sysTag + s
			table.insert (sectors, sysTag + s)
		end
	else
		navcomp:Yield ()
		local diffx = x2 - x1
		local diffy = y2 - y1
		local ang = math.atan2 (diffx, diffy)
		local dist = math.sqrt (diffx * diffx + diffy * diffy)
		
		local newX, newY
		local sine = math.sin (ang)
		local cosine = math.cos (ang)
		local sectorId, k
		local lineStr
		for k=0, math.floor (dist + 0.5), 0.25 do
			newX = math.floor (k * sine + x1 + 0.5)
			newY = math.floor (k * cosine + y1 + 0.5)
			sectorId = navcomp:BuildSectorId (sysId, newX, newY)
			lineStr = "|" .. table.concat (sectors, "|") .. "|"
			if not string.find (lineStr, "|" .. sectorId .. "|") then
				table.insert (sectors, sectorId)
			end
			navcomp:Yield ()
		end
		
		navcomp.data.sectorLines [lineId] = {}
		for _,s in ipairs (sectors) do
			table.insert (navcomp.data.sectorLines [lineId], (s - sysTag))
		end
		navcomp.data.isLineDataSaved = false
	end
	
	return sectors
end

function navcomp:CheckBotTypes (s1, types)
	local bots
	if type (s1) == "number" then
		bots = GetBotSightedInfoForSector (s1):lower ()
	else
		bots = s1:lower ()
	end
	local v
	for _,v in ipairs (types) do
		if string.find (bots, v) then return true end
	end
	
	return false
end

function navcomp:IsDataExpired (data, expires)
	expires = expires or 0
	return expires > 0 and data and tonumber (data) and os.difftime (os.time (), data) > expires
end

function navcomp:IsEncounteredStormSector (s1)
	if not navcomp.data.navigation [s1] then
		return false
	end
	if navcomp.data.navigation [s1].storm and not navcomp:IsDataExpired (navcomp.data.navigation [s1].storm.time, navcomp.data.stormExpires) then
		return true
	else
		-- Kill any record of a storm in that sector
		navcomp.data.navigation [s1].storm = nil
		return false
	end
end

-- Check record for hostile bots
function navcomp:IsEncounteredBotSector (s1)
	if not navcomp.data.navigation [s1] then
		return false
	end
	if navcomp.data.navigation [s1].bot and not navcomp:IsDataExpired (navcomp.data.navigation [s1].bot.time, navcomp.data.botExpires) then
		return true
	else
		-- Kill any record of bots in that sector
		navcomp.data.navigation [s1].bot = nil
		return false
	end
end

function navcomp:IsAvoidSector (s1)
	return navcomp.data.navigation [s1] and navcomp.data.navigation [s1].avoid
end

function navcomp:IsAnchorSector (s1)
	return navcomp.data.navigation [s1] and navcomp.data.navigation [s1].anchors
end

-- Hostiles listed in nav screen
function navcomp:IsHostileBotSector (s1)
	return navcomp:CheckBotTypes (s1, navcomp.data.botAvoidTypes)
end

-- Benign bots only.  Check listed and recorded
function navcomp:IsBotSector (s1)
	return navcomp:CheckBotTypes (s1, navcomp.data.botSafeTypes) and 
				not navcomp:CheckBotTypes (s1, navcomp.data.botAvoidTypes) and 
				not navcomp:IsEncounteredBotSector (s1)
end

-- Special Stations
function navcomp:IsStationSector (s1)
	return navcomp:IsConquerableStationSector (s1) or navcomp:CheckBotTypes (s1, navcomp.data.botStationTypes)
end

function navcomp:IsConquerableStationSector (s1)
	if navcomp.data.conquerableStations [s1] then return true
	else return false
	end
end

function navcomp:IsRacetrackSector (s1)
	if navcomp.data.racetracks [s1] then return true
	else return false
	end
end

-- Special Sectors
function navcomp:IsStarSector (s1)
	local sysName = SystemNames [GetSystemID (s1)]:lower ()
	return string.find (navcomp.data.starSectors [sysName], "|" .. tostring (s1) .. "|")
end

function navcomp:IsTrainingSector (s1)
	return string.find (navcomp.data.training, "|" .. tostring (s1) .. "|")
end

function navcomp:IsWormholeSector (s1)
	if not navcomp.data.navigation [s1] then
		return false
	end
	return navcomp.data.navigation [s1].wormhole ~= nil
end

function navcomp:IsSectorProhibited (s1, useLogic)
	useLogic = useLogic or false
	local result = navcomp:IsEncounteredBotSector (s1) or navcomp:IsHostileBotSector (s1)
	if useLogic then
		result = result or (navcomp.data.avoidStormSectors and navcomp:IsEncounteredStormSector (s1))
		result = result or (navcomp.data.avoidManualSectors and navcomp:IsAvoidSector (s1))
	end
	
	return result
end

function navcomp:IsBlockableSector (s1, useLogic)
	useLogic = useLogic or false
	if useLogic and navcomp.data.avoidBlockableSectors then
		return navcomp:IsStationSector (s1) or navcomp:IsWormholeSector (s1)
	end
	
	return false
end

function navcomp:IsPathProhibited (s1, s2, useLogic)
	local path = navcomp:GetSectorLine (s1, s2)
	if #path == 2 then return false end
	local k, v
	for k,v in ipairs (path) do
		if v ~= s1 and v ~= s2 and navcomp:IsSectorProhibited (v, useLogic) then return true end
	end
	
	return false
end

function navcomp:IsCapitalSystem (sysId)
	if string.find (navcomp.data.capitalSystems, "|" .. tostring (sysId) .. "|") then
		return true
	else
		return false
	end
end

function navcomp:GetSectorStress (s1)
	local sysId, y, x = SplitSectorID (s1)
	local stress = 0
	local s2, i, j
	for i=x-1, x+1, 1 do
		for j=y-1, y+1, 1 do
			navcomp:Yield ()
			if i > 0 and j > 0 and i < 17 and j < 17 then
				s2 = navcomp:BuildSectorId (sysId, i, j)
				if navcomp:IsSectorProhibited (s2) or navcomp:IsAvoidSector (s2) then
					stress = stress + 1
				elseif navcomp:IsEncounteredStormSector (s2) then
					stress = stress + 1
				end
			elseif not navcomp:IsSectorProhibited (s1) then
				stress = stress - 1
			end
		end
	end

	if stress < 0 then stress = 0 end
	if navcomp:IsEncounteredStormSector (s1) then
		stress = stress + 1
	end
	if navcomp:IsSectorProhibited (s1) then
		stress = stress + 2
	end
	if navcomp:IsAvoidSector (s1) then
		stress = stress + 2
	end
	if navcomp:IsStarSector (s1) then
		stress = stress + 10
	end
	
	return stress
end

function navcomp:GetLineStress (s1, s2, map)
	local sectors = navcomp:GetSectorLine (s1, s2)
	local s
	local stress = 0
	for _, s in ipairs (sectors) do
		stress = stress + map [s]
	end
	
	return stress, #sectors
end

function navcomp:AnalyzeSystem (s1)
	local sysId = GetSystemID (s1)
	if not navcomp.data.stressMaps [sysId] then
		local s, o, i, j
		local stressMap = {}
		local systemStress = 0
		local step = 0
		for i=1, 16, 1 do
			for j=1, 16, 1 do
				step = step + 1
				s = navcomp:BuildSectorId (sysId, i, j)
				stressMap [s] = navcomp:GetSectorStress (s)
				systemStress = systemStress + stressMap [s]
				navcomp.ui.progress:Update (step)
				navcomp:Yield ()
			end
		end
		
		navcomp.data.stressMaps [sysId] =  {map = stressMap, stress = systemStress}
	end
	
	return navcomp.data.stressMaps [sysId]
end

function navcomp:Print (msg, color)
	if not navcomp.data.blockStatusMessage then
		color = color or "00ff00"
		local m = string.format ("\127%s%s\127o", color, msg)
		if navcomp.ui.progress then
			navcomp.ui.progress:SetTitle (m)
		end
		if PlayerInStation () or PDADialog.visible == "YES" then
			if not navcomp.data.blockStatusMessage then
				print (m)
			end
		else
			HUD:PrintSecondaryMsg (m)
		end
	end
end

function navcomp:PrintStats (sysId, stats)
	local s, s1, i, j
	for i=1, 16 do
		s = ""
		for j=1, 16 do
			s = s .. stats.map [navcomp:BuildSectorId (sysId, i, j)] .. "   "
		end
		print (s)
	end
end

function navcomp:Compare (n1, n2, s2, stats, area, proc)
	-- Check for Final Target
	local f, result
	if n1.s == s2 then
		return n1
	elseif n2.s == s2 then
		return n2
	end
	
	-- Check if path is clear to Target
	if not n1.blocked and (n2.blocked or n1.d2 < n2.d2) then
		return n1
	elseif not n2.blocked and (n1.blocked or n2.d2 < n1.d2) then
		return n2
	end

	-- Performing Waypoint Checks
	local node = n2
	for _,f in ipairs (proc) do
		navcomp:Yield ()
		result = f (navcomp, n1, n2, s2, stats, area)
		if result then
			node = result
		end
	end
	
	return node
end

-- Don't use.  Not ready for prime time
function navcomp:SortJumps (s1, s2, stats, area)
	local sysId = GetSystemID (s1.s)
	local s = s1
	for _,v in ipairs (area.sectors) do
		s = navcomp:Compare (v, s, s2, stats, area, navcomp.plotter:GetAlgorithm (sysId, stats, area))
	end
	return s
end

function navcomp:GetJumps (s1, s2, navrouteString, map)
	local sysId, x, y, x1, y1, ts, str1, str2, line1, line2
	local sectors = {}
	local areaStress = 0
	sysId, y1, x1 = SplitSectorID (s1)
	local areaSize = navcomp.plotter.metadata [sysId].areaSize
	for x=x1-navcomp:Lower (x1, areaSize), x1+navcomp:Upper (x1, areaSize) do
		for y=y1-navcomp:Lower (y1, areaSize), y1+navcomp:Upper (y1, areaSize) do
			ts = navcomp:BuildSectorId (sysId, x, y)
			if (ts == s2 or
						(not string.find (navrouteString, "|" .. ts .. "|") and 
						not navcomp:IsSectorProhibited (ts, true) and
						not navcomp:IsStarSector (ts) and
						not navcomp:IsConquerableStationSector (ts) and
						not navcomp:IsRacetrackSector (ts) and
						not navcomp:IsTrainingSector (ts) and
						not navcomp:IsBlockableSector (ts, true))) and
						not navcomp:IsPathProhibited (s1, ts, true) then
				str1, line1 = navcomp:GetLineStress (s1, ts, map)
				str2, line2 = navcomp:GetLineStress (ts, s2, map)
				areaStress = areaStress + map [ts]
				sectors [#sectors + 1] = {
					s = ts,
					d1 = navcomp:Distance (s1, ts),
					d2 = navcomp:Distance (ts, s2),
					str1 = str1,
					line1 = line1,
					str2 = str2,
					line2 = line2,
					blocked = navcomp:IsPathProhibited (ts, s2, true)
				}
			end
			navcomp:Yield ()
		end
	end
	
	return {sectors = sectors, stress = areaStress}
end