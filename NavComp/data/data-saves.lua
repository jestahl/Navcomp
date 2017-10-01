--------------------------------------------------------------
--
--	Load/Save Data Functions
--
--------------------------------------------------------------

function navcomp.data:SavePathNote (data)
	if data.name and data.path then
		navcomp.data.pathList [data.name] = data
		navcomp:Print (string.format ("%s path saved", data.name))
	end
end

function navcomp.data:LoadPathNote (name)
	local path = navcomp.data:Clone (navcomp.data.pathList [name])
	if path then
		navcomp.data.activePath = path
		navcomp:Print (string.format ("%s path loaded", name))
		
		return navcomp.data.activePath
	else
		if name then
			navcomp:Print (string.format ("%s path not found", name))
		else
			navcomp:Print ("Path not Specified")
		end
	end
end

function navcomp.data:SavePathNotes ()
	if pairs (navcomp.data.pathList) then
		local charId = navcomp.data.id + navcomp.data.pathOffset
		SaveSystemNotes (spickle (navcomp.data.pathList), charId)
	end
end

function navcomp.data:LoadPathNotes ()
	if not navcomp.data.pathList then
		navcomp.data.pathList = {}
		local charId = navcomp.data.id + navcomp.data.pathOffset
		navcomp.data.pathList = unspickle (LoadSystemNotes (charId)) or {}
	end
	local path
	for _,path in pairs (navcomp.data.pathList) do
		path.autoReload = path.autoReload or false
		path.autoPlot = path.autoPlot or false
	end
end

-- Save Storm Sector data to notes
function navcomp.data:SaveNavigationData ()
	if navcomp.data.navigation and not navcomp.data.isStormDataSaved then
		local charId = navcomp.data.id
		SaveSystemNotes (spickle (navcomp.data.navigation), charId)
		navcomp.data.isStormDataSaved = true
		navcomp:Print ("Data Uploaded")
	end
end

-- When starting up, load previously stored navigation data
function navcomp.data:LoadNavigationData ()
	if not navcomp.data.isInitialized then
		local charId = navcomp.data.id
		local data = unspickle (LoadSystemNotes (charId)) or {}
		if data.storms or data.hive or data.wormholes then
			-- Older version of data store needs updating
			-- Storm Sectors
			local sectorId
			data.storm = data.storm or {}
			for _, sectorId in ipairs (data.storm) do
				navcomp.data.navigation [sectorId] = navcomp.data.navigation [sectorId] or {}
				navcomp.data.navigation [sectorId].storm = {time=os.time ()}
			end
			
			-- Bot Sectors
			data.hive = data.hive or {}
			for _, sectorId in ipairs (data.hive) do
				navcomp.data.navigation [sectorId] = navcomp.data.navigation [sectorId] or {}
				navcomp.data.navigation [sectorId].bot = {time=os.time ()}
			end
			
			-- Wormhole Sectors
			data.wormholes = data.wormholes or {}
			for _, sectorId in ipairs (data.wormholes) do
				navcomp.data.navigation [sectorId] = navcomp.data.navigation [sectorId] or {}
				navcomp.data.navigation [sectorId].wormhole = true
			end
		else
			navcomp.data.navigation = data
		end
		navcomp.data.isStormDataSaved = true
	end
end

-- Save all previously calculated sector lines
function navcomp.data:SaveSectorLines ()
	local charId = navcomp.data.id + navcomp.data.sectorLinesOffset 
	SaveSystemNotes (spickle (navcomp.data.sectorLines), charId)
	navcomp.data.isLineDataSaved = true
end

-- Load previously calculated sector line data
function navcomp.data:LoadSectorLines ()
	if not navcomp.data.sectorLines then
		local charId = navcomp.data.id + navcomp.data.sectorLinesOffset 
		navcomp.data.sectorLines = unspickle (LoadSystemNotes (charId)) or {}
	end
end

-- Save cached stress maps
function navcomp.data:SaveStressMaps ()
	local charId = navcomp.data.id + navcomp.data.stressMapOffset
	SaveSystemNotes (spickle (navcomp.data.stressMaps), charId)
end

-- Load cached stress maps
function navcomp.data:LoadStressMaps ()
	if not navcomp.data.stressMaps then
		local charId = navcomp.data.id + navcomp.data.stressMapOffset
		navcomp.data.stressMaps = unspickle (LoadSystemNotes (charId)) or {}
	end
end

-- Save NavComp user settings
function navcomp.data:SaveUserSettings ()
	-- Options
	gkini.WriteString (navcomp.data.config, "backgroundPlot", tostring (navcomp.data.backgroundPlot))
	gkini.WriteInt (navcomp.data.config, "delay", navcomp.data.delay)
	gkini.WriteInt (navcomp.data.config, "chunk", navcomp.data.maxStepLimit)
	gkini.WriteString (navcomp.data.config, "avoidStormSectors", tostring (navcomp.data.avoidStormSectors))
	gkini.WriteString (navcomp.data.config, "avoidManualSectors", tostring (navcomp.data.avoidManualSectors))
	gkini.WriteString (navcomp.data.config, "avoidBlockableSectors", tostring (navcomp.data.avoidBlockableSectors))
	gkini.WriteString (navcomp.data.config, "useSegmentSmoothing", tostring (navcomp.data.useSegmentSmoothing))
	gkini.WriteString (navcomp.data.config, "confirmBuddyCom", tostring (navcomp.data.confirmBuddyCom))
	gkini.WriteString (navcomp.data.config, "anchorOverride", tostring (navcomp.data.anchorOverride))
	gkini.WriteString (navcomp.data.config, "autoPlot", tostring (navcomp.data.autoPlot))
	gkini.WriteString (navcomp.data.config, "plotCapitalSystems", tostring (navcomp.data.plotCapitalSystems))
	gkini.WriteString (navcomp.data.config, "blockStatusMessage", tostring (navcomp.data.blockStatusMessage))
	gkini.WriteString (navcomp.data.config, "stormColor", navcomp.ui.hazardColors [1])
	gkini.WriteString (navcomp.data.config, "hostileBotColor", navcomp.ui.hazardColors [2])
	gkini.WriteString (navcomp.data.config, "bothColor", navcomp.ui.hazardColors [3])
	gkini.WriteString (navcomp.data.config, "manualColor", navcomp.ui.hazardColors [4])
	gkini.WriteString (navcomp.data.config, "manualStormColor", navcomp.ui.hazardColors [5])
	gkini.WriteString (navcomp.data.config, "manualHostileBotColor", navcomp.ui.hazardColors [6])
	gkini.WriteString (navcomp.data.config, "manualBothColor", navcomp.ui.hazardColors [7])
	gkini.WriteString (navcomp.data.config, "anchorColor", navcomp.ui.hazardColors [8])
	gkini.WriteString (navcomp.data.config, "evasionLevel", navcomp.data.evasionLevel)
	gkini.WriteString (navcomp.data.config, "stormExpires", navcomp.data.stormExpires)
	gkini.WriteString (navcomp.data.config, "botExpires", navcomp.data.botExpires)
	
	-- Metadata
	local charId = navcomp.data.id + navcomp.data.metadataOffset
	local sysId, v
	local metadata = {}
	for sysId,_ in ipairs (navcomp.plotter.metadata) do
		table.insert (metadata, {})
		for _,v in pairs (navcomp.plotter:GetSystemMetadataList (sysId)) do
			table.insert (metadata [sysId], v)
		end
	end
	SaveSystemNotes (spickle (metadata), charId)
	
	-- Evasion
	gkini.WriteInt (navcomp.data.config, "evasionLevel", navcomp.data.evasionLevel)
	
	-- Communication
	gkini.WriteString (navcomp.data.config, "confirmBuddyCom", navcomp.data.confirmBuddyCom)
end

-- Load Performance Options
function navcomp.data:LoadPerformanceOptions ()
	navcomp.data.avoidStormSectors = (gkini.ReadString (navcomp.data.config, "avoidStormSectors", "false") == "true")
	navcomp.data.avoidManualSectors = (gkini.ReadString (navcomp.data.config, "avoidManualSectors", "false") == "true")
	navcomp.data.avoidBlockableSectors = (gkini.ReadString (navcomp.data.config, "avoidBlockableSectors", "false") == "true")
	navcomp.data.useSegmentSmoothing = (gkini.ReadString (navcomp.data.config, "useSegmentSmoothing", "false") == "true")
	navcomp.data.isOptionDataChanged = false
end

-- Load NavComp user settings
function navcomp.data:LoadUserSettings ()
	-- Options
	navcomp.data.backgroundPlot = (gkini.ReadString (navcomp.data.config, "backgroundPlot", "true") == "true")
	navcomp.data.confirmBuddyCom = (gkini.ReadString (navcomp.data.config, "confirmBuddyCom", "true") == "true")
	navcomp.data.anchorOverride = (gkini.ReadString (navcomp.data.config, "anchorOverride", "false") == "true")
	navcomp.data.autoPlot = (gkini.ReadString (navcomp.data.config, "autoPlot", "true") == "true")
	navcomp.data.plotCapitalSystems = (gkini.ReadString (navcomp.data.config, "plotCapitalSystems", "false") == "true")
	navcomp.data.blockStatusMessage = (gkini.ReadString (navcomp.data.config, "blockStatusMessage", "false") == "true")
	navcomp.data.delay = gkini.ReadInt (navcomp.data.config, "delay", 25)
	navcomp.data.maxStepLimit = gkini.ReadInt (navcomp.data.config, "chunk", 10)
	navcomp.data.stormExpires = gkini.ReadInt (navcomp.data.config, "stormExpires", 86400)
	navcomp.data.botExpires = gkini.ReadInt (navcomp.data.config, "botExpires", 86400)
	navcomp.data:LoadPerformanceOptions ()
	navcomp.ui.hazardColors = {
		gkini.ReadString (navcomp.data.config, "stormColor", "150 150 150"),
		gkini.ReadString (navcomp.data.config, "hostileBotColor", "255 255 0"),
		gkini.ReadString (navcomp.data.config, "bothColor", "255 0 255"),
		gkini.ReadString (navcomp.data.config, "manualColor", "255 255 255"),
		gkini.ReadString (navcomp.data.config, "manualStormColor", "150 150 150"),	
		gkini.ReadString (navcomp.data.config, "manualHostileBotColor", "255 255 0"),
		gkini.ReadString (navcomp.data.config, "manualBothColor", "255 0 255"),
		gkini.ReadString (navcomp.data.config, "anchorColor", "0 0 255")
	}
	
	-- Metadata
	local k, v, k1, v1
	local charId = navcomp.data.id + navcomp.data.metadataOffset
	local metadata = unspickle (LoadSystemNotes (charId)) or {}
	if #metadata > 0 then
		for k, v in ipairs (metadata) do
			navcomp.plotter.metadata [k].algorithm = {}
			for k1, v1 in ipairs (v) do
				table.insert (navcomp.plotter.metadata [k].algorithm, navcomp.plotter.algorithm [v1])
			end
		end
	end
	
	-- Evasion
	navcomp.data.evasionLevel = gkini.ReadInt (navcomp.data.config, "evasionLevel", 3)
	
	-- Communication
	navcomp.data.confirmBuddyCom = (gkini.ReadString (navcomp.data.config, "confirmBuddyCom", "false") == "true")
end

function navcomp.data:SaveBinds (binds)
	local evadeBind = binds [1] or ""
	gkinterface.UnbindCommand ("evade")
	if evadeBind:len () > 0 then
		gkini.WriteString (navcomp.data.config, "evadeBind", evadeBind)
		gkinterface.GKProcessCommand (string.format ("bind %s evade", evadeBind))
	end
end

function navcomp.data:LoadBinds ()
	local evadeBind = gkini.ReadString (navcomp.data.config, "evadeBind", "")
	gkinterface.UnbindCommand ("evade")
	if evadeBind:len () > 0 then
		gkinterface.GKProcessCommand (string.format ("bind %s evade", evadeBind))
	end
end