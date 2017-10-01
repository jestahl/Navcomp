--------------------------------------------------------------
--
--	Data Handling Functions
--
--------------------------------------------------------------

local reservedKeywords = "|storm|bot|wormhole|avoid|asteroid|"

function navcomp.data:Clone (t)
	if not t then return nil end
	local temp = {}
	local prop, value
	for prop, value in pairs (t) do
		if type (value) == "table" then
			temp [prop] = navcomp.data:Clone (value)
		else
			temp [prop] = value
		end
	end
	
	return temp
end

function navcomp.data:SetPathDefaults (path)
	path.note = path.note or ""
	path.autoReload = path.autoReload or false
	path.autoPlot = path.autoPlot or false
	path.path = path.path or GetFullPath (GetCurrentSectorid (), NavRoute.GetCurrentRoute ())
	
	return path
end

function navcomp.data:CreatePath (data)
	if data and data.name then
		-- Create basic path with standard properties
		return navcomp.data:SetPathDefaults (navcomp.data:Clone (data))
	end
end

function navcomp.data:BuildWormholeList ()
	local sysId,sectorId
	local sysMapName, sysData
	local x, y
	local id
	for sysId,_ in ipairs (SystemNames) do
		id = ""
		if sysId < 10 then id = "0" end
		id = id .. tostring (sysId)
		sysMapName = string.format ("lua/maps/system%smap.lua", id)
		sysData = dofile (sysMapName)
		for _,v in ipairs (sysData [1]) do
			if string.find (v.desc:lower (), "wormhole") then
				sectorId = 256 * (sysId-1) + v.id
				navcomp.data.navigation [sectorId].wormhole = true
			end
		end
	end
	navcomp.data.isStormDataSaved = false
	navcomp.data:SaveNavigationData ()
end

local function CheckDataExpiration (prop, k, v, now, t)
	if t > 0 and k == prop and os.difftime (now, v.time) > t then
		v = nil
		return true
	end
end

local expirationProc = {
	storm = navcomp.data.stormExpires,
	bot = navcomp.data.botExpires
}
function navcomp.data:ExpireData ()
	local s, d, k, v, numProps
	local repaint = false
	local now = os.time ()
	for s, d in pairs (navcomp.data.navigation) do
		-- Loop through all the navigation objects
		numProps = 0
		for k, v in pairs (d) do
			-- Loop through all the attributes of a found navigation object
			-- Check the data time against the current time
			local attr, expireTime
			for attr, expireTime in pairs (expirationProc) do
				expireTime = tonumber (expireTime) or 0
				if expireTime > 0 and k == attr and os.difftime (now, v.time) > expireTime then
					-- Clear Checked Data
					v = nil
					repaint = true
				end
			end
			if not repaint then
				numProps = numProps + 1
			end
		end
		if numProps == 0 then
			-- No properties were counted, remove the entire navigation object
			navcomp.data.navigation [s] = nil
			repaint = true
		end
		if repaint then
			ProcessEvent ("NAVCOMP_REPAINT")
		end
	end
end

function navcomp:AddDataExpiration (list)
	-- Pass a hashed list of values to check and expire
	local k, v
	for k, v in pairs (list) do
		if type (k) == "string" and k ~= "storm" and k ~= "bot" and type (v) == "number" and v >= 0 then
			expirationProc [k] = v
		end
	end
end

function navcomp:RemoveDataExpiration (list)
	-- Pass a hashed list of attributes to expire (can be the same list as AddDataExpiration)
	local k, v
	for k, v in pairs (list) do
		if type (k) == "string" and k ~= "storm" and k ~= "bot" then
			expirationProc [k] = nil
		end
	end
end

function navcomp:GetSectorData (sectorId)
	-- Need to make a clone of existing record so as not to expose the underlying database
	if navcomp.data.navigation [sectorId] then
		local result = {}
		local k, v
		for k, v in pairs (navcomp.data.navigation [sectorId]) do
			result [k] = v
		end
		return result
	end
end

function navcomp:SetSectorData (sectorId, data)
	-- Check for all reserved keywords in inbound data object
	if sectorId and tonumber (sectorId) then
		navcomp.data.navigation [sectorId] = navcomp.data.navigation [sectorId] or {}
		data = data or {}
		local k, v
		for k, v in pairs (data) do
			if not string.find (reservedKeywords, "|" .. tostring (k) .. "|") then
				navcomp.data.navigation [sectorId][k] = v
			end
		end
	end
end

-- Data Processing Functions
function navcomp.data:RecordStorm (s1, inStation)
	navcomp.data.navigation [s1] = navcomp.data.navigation [s1] or {}
	if not navcomp.data.navigation [s1].storm then
		local str = "Recording Storm in "
		if inStation then
			str = "Storm reported in "
		end
		navcomp:Print (str .. AbbrLocationStr (s1))
		navcomp.data.stressMaps [GetSystemID (s1)] = nil
	end
	navcomp.data.navigation [s1].storm = {
		time = os.time ()
	}
	navcomp.data.isStormDataSaved = false
	ProcessEvent ("NAVCOMP_REPAINT")
end

function navcomp.data:RecordBots (s1, inStation)
	navcomp.data.navigation [s1] = navcomp.data.navigation [s1] or {}
	if not navcomp.data.navigation [s1].bot then
		local str = "Recording Hostile Bots in "
		if inStation then
			str = "Hive activity reported in "
		end
		navcomp:Print (str .. AbbrLocationStr (s1))
		navcomp.data.stressMaps [GetSystemID (s1)] = nil
	end
	navcomp.data.navigation [s1].bot = {
		time = os.time ()
	}
	navcomp.data.isStormDataSaved = false
	ProcessEvent ("NAVCOMP_REPAINT")
end

function navcomp.data:GetSectorIdFromName (sectorName, pattern)
	if not sectorName then return nil end
	
	-- Determine Sector ID
	pattern = pattern or "(%a+%s?%a*)%s(%a)%-?(%d%d?)"
	local sysName, h, v = string.match (sectorName, pattern)
	if sysName then
		return 256 * (navcomp.data.systems [sysName]-1) + 16 * (v-1) + navcomp.data.sectors [h]
	else
		return nil
	end
end

-- Check Station Missions for Storm Info
function navcomp.data:CheckStationMissions ()
	local info, a, b, sysName, temp, h, v, sectorId, stormPresent
	for k=1, GetNumAvailableMissions () do
		info = GetAvailableMissionInfo (k)
		
		--Hive presence in sysName H-V (Ion Storm in progress)
		if string.find (info.desc, "Hive presence in") then
			-- Found Hive Skirmish
			local check
			if string.find (info.desc, "Ion Storm in progress") then
				check = "Hive presence in (.+) (%(Ion Storm in progress%))$"
			else
				check = "Hive presence in (.+)$"
			end
			temp, stormPresent = string.match (info.desc, check)
			
			-- Determine Sector ID
			sectorId = navcomp.data:GetSectorIdFromName (temp)
			
			-- Add sector to Hive data
			navcomp.data:RecordBots (sectorId, true)
			if stormPresent then
				navcomp.data:RecordStorm (sectorId, true)
			end
			
		end
	end
	if not navcomp.data.isStormDataSaved then
		navcomp.data:SaveNavigationData ()
	end
end

function navcomp.data:CheckHostile ()
	if not navcomp.data.hive.isHostile then
		local sectorId = GetCurrentSectorid ()
		ForEachPlayer (function (id)
			local faction = GetPlayerFaction (id) or 1
			if faction == 0 then
				if navcomp:IsHostileBotSector (GetPlayerName (id)) and 
						not navcomp:IsStationSector (sectorId) and not navcomp:IsWormholeSector (sectorId) then
					navcomp.data.hive.isHostile = true
					navcomp.data:RecordBots (sectorId)
				end
			end
		end)
	end
end

function navcomp.data:RemoveHostileSector (sectorId)
	-- Remove sector ID from hostile list
	if navcomp.data.navigation [sectorId] then
		navcomp.data.navigation [sectorId].bot = nil
		navcomp.data.stressMaps [GetSystemID (sectorId)] = nil
		navcomp:Print ("Removing Hostile Bot record in " .. AbbrLocationStr (sectorId))
		ProcessEvent ("NAVCOMP_REPAINT")
	end
end

function navcomp.data:ClearData (sysId, type)
	--[[
		Data Clear Types:
			0 = Storm
			1 = Hive
			2 = Manual
			3 = All
	]]
	if sysId then
		-- Loop through data and remove requested data type from any sectorId which matches the sysId
		navcomp.data.stressMaps [sysId] = nil
		local s, d, sys
		for s, d in pairs (navcomp.data.navigation) do
			sys= SplitSectorID (s)
			if type == 3 or type == 0 and sys == sysId then
				-- Clear storm data
				d.storm = nil
			end
			if type == 3 or type == 1 and sys == sysId then
				-- Clear bot data
				d.bot = nil
			end
			if type == 3 or type == 2 and sys == sysId then
				d.avoid = nil
			end
		end
		if type == 0 then
			navcomp:Print (string.format ("Storm Data Cleared for %s", SystemNames [sysId]))
		elseif type == 1 then
			navcomp:Print (string.format ("Hive Data Cleared for %s", SystemNames [sysId]))
		elseif type == 2 then
			navcomp:Print (string.format ("Avoid Data Cleared for %s", SystemNames [sysId]))
			navcomp:SyncSectorNotes ()
		elseif type == 3 then
			navcomp:Print (string.format ("All Data Cleared for %s", SystemNames [sysId]))
			navcomp:SyncSectorNotes ()
		end
	else
		-- Clear all systems of requested data
		local s, d, sys
		for s, d in pairs (navcomp.data.navigation) do
			if type == 3 or type == 0 then
				-- Clear storm data
				d.storm = nil
			end
			if type == 3 or type == 1 then
				-- Clear bot data
				d.bot = nil
			end
			if type == 3 or type == 2 then
				d.avoid = nil
			end
		end
		if type == 0 then
			navcomp:Print ("All Storm Data Cleared")
		elseif type == 1 then
			navcomp:Print ("All Hive Data Cleared")
		elseif type == 2 then
			navcomp:Print ("All Avoid Data Cleared")
			navcomp:SyncSectorNotes ()
		elseif type == 3 then
			navcomp:Print ("All Data Cleared")
			navcomp:SyncSectorNotes ()
		end
	end
	navcomp.data:ExpireData ()
	navcomp.data.isStormDataSaved = false
	navcomp.data:SaveNavigationData ()
end
