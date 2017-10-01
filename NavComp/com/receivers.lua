--[[
	Receiver functions for handling data communications
]]

-- Processes receipt of data
-- Enter all storm data into records
function navcomp.com:DataReceived (sender, data)
	local receivedSystems = {}
	navcomp.data.isStormDataSaved = false
	local v, sysId
	if data.storms then
		for _,v in ipairs (data.storms) do
			if not navcomp.data.navigation [v] or not navcomp.data.navigation [v].storm then
				navcomp.data.navigation [v]	= navcomp.data.navigation [v] or {}
				navcomp.data.navigation [v].storm = {
					time = os.time ()
				}
				sysId = GetSystemID (v)
				receivedSystems [sysId] = "YES"
			end
		end
	end
	if data.hive then
		for _,v in ipairs (data.hive) do
			if not navcomp.data.navigation [v] or not navcomp.data.navigation [v].bot then
				navcomp.data.navigation [v]	= navcomp.data.navigation [v] or {}
				navcomp.data.navigation [v].bot = {
					time = os.time ()
				}
				sysId = GetSystemID (v)
				receivedSystems [sysId] = "YES"
			end
		end
	end
	navcomp.data:SaveNavigationData ()
	
	-- Remove all new encounter systems from map cache
	for sysId, _ in pairs (receivedSystems) do
		navcomp.data.stressMaps [sysId] = nil
	end
	
	-- Inform user of list of received Systems
	navcomp:Print (string.format ("Received Encounter Data from %s", sender))
	if #data == 0 then
		navcomp:Print ("None")
	end
	for sysId, _ in pairs (receivedSystems) do
		navcomp:Print (SystemNames [sysId])
	end
	ProcessEvent ("NAVCOMP_REPAINT")
end

-- Processes receipt of navpath
-- Save path sectors to storage
function navcomp.com:PathReceived (sender, data)
	local receivedRoutes = {}
	if #data > 0 then
		local route
		for _, route in ipairs (data) do
			navcomp.data:SavePathNote (navcomp.data:SetPathDefaults (route))
			receivedRoutes [route.name] = "YES"
		end
		navcomp.data:SavePathNotes ()
		
		-- Inform user of list of new routes received
		navcomp:Print (string.format ("Received Navroutes from %s", sender))
		for route, _ in pairs (receivedRoutes) do
			navcomp:Print (route)
		end
	end
end

function navcomp.com:AnchorsReceived (sender, data)
	-- for all sectors in received data, overwrite existing sector anchors
	local target, anchor, sysId, note, x, y, before, after, oldAnchors, newAnchors, lock
	if #data > 0 then
		navcomp:Print (string.format ("Received Anchors from %s", sender))
	end
	for _, target in ipairs (data) do
		-- Add newly received anchors to sector anchor definition
		navcomp:WriteNewAnchors (target)
		
		--[[-- Rewrite the sector note for the given sector
		note = navcomp:GetSectorNote (target.sectorId)
		local i1, i2 = string.find (note, "#anchors%s*%([%*?%a%-?%d%d?%s*,?]+%):")
		before = string.sub (note, 1, i1-1)
		after = string.sub (note, i2+1)
		oldAnchors = string.sub (note, i1, i2)
		
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
		note = before .. string.format ("#anchors (%s,%s):", oldAnchors, newAnchors) .. after
		navcomp:SetSectorNote (target.sectorId, note)]]
		
		-- Inform user of new anchor received
		navcomp:Print (LocationStr (target.sectorId))
		
		-- Resync data
		navcomp.data:ExpireData ()
		navcomp:SyncSectorNotes ()
		navcomp:Print ("Synchronization Complete")
	end
	ProcessEvent ("NAVCOMP_REPAINT")
end