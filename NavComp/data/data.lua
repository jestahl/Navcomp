--[[
	Data for Navigational Computer
]]
local function printtable (t, offset)
	if type (t) == "table" then
		offset = offset or ""
		for k,v in pairs (t) do
			if type (v) == "table" then
				print (string.format ("%s%s", offset, tostring (k)))
				printtable (v, offset .. "-  ")
			else
				print (string.format ("%s%s = %s", offset, tostring (k), tostring (v)))
			end
		end
	else
		print (t)
	end
end

navcomp.data = {}
navcomp.data.initialize = {}
navcomp.data.logout = {}
navcomp.data.restart = {}
navcomp.data.id = 314159265359
navcomp.data.pathOffset = 1
navcomp.data.sectorLinesOffset = 2
navcomp.data.metadataOffset = 3
navcomp.data.stressMapOffset = 4
navcomp.data.config = "navcomp"
navcomp.data.maxSteps = 32
navcomp.data.maxRecursion = 8
navcomp.data.stepCounter = 0
navcomp.data.images = {}

navcomp.data.activePath = {
	name = nil,
	note = "",
	bind = "",
	autoReload = false,
	autoPlot = false,
	path = {}
}
navcomp.data.navrouteTable = NavRoute.GetCurrentRoute ()
navcomp.data.isEvading = false
navcomp.data.evasionLevel = 3
navcomp.data.pathList = nil
navcomp.data.targetList = {}
navcomp.data.isInitialized = false
navcomp.data.isStormDataSaved = false
navcomp.data.isLineDataSaved = true
navcomp.data.isOptionDataChanged = false
navcomp.data.botStationTypes = {
	"station"
}
navcomp.data.botSafeTypes = {
	"collector",
	"transport",
	"observer"
}
navcomp.data.botAvoidTypes = {
	"assault",
	"guardian",
	"queen",
	"leviathan"
}

-- Navigation Data
--[[
	Structure:

	[sectorId] = {
		storm = {
			time = <time spotted>  (if nil, can never expire)
		},
		bot = {
			time = <time spotted> (if nil, can never expire)
		}
		wormhole = true  (or nil if not a wormhole sector),
		avoid = true (or nil),
		asteroid = true (or nil)
		anchors = {}  (array of items)
	}
	
	IsEncounteredStormSector logic (most of boolean identifiers)
	
	if navcomp.data.navigation [sectorId]
								and navcomp.data.navigation [sectorId].storm
								and not navcomp:IsDataExpired (navcomp.data.navigation [sectorId].storm.time, navcomp.data.stormExpires) then
		return true
	else
		return false
	end
]]
navcomp.data.navigation = {}

navcomp.data.stormExpires = 86400
navcomp.data.botExpires = 86400
navcomp.data.sectorLines = nil
navcomp.data.sectors = {
	A=1, B=2, C=3, D=4, E=5, F=6, G=7, H=8, I=9, J=10, K=11, L=12, M=13, N=14, O=15, P=16
}
navcomp.data.columnNumbers = {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P"}
navcomp.data.systems = {}
navcomp.data.conquerableStations = {
	[5753] = "Latos I-8",
	[4317] = "Bractus M-14",
	[4019] = "Palatus C-12"
}
navcomp.data.racetracks = {
	[4930] = "B5",
	[4932] = "D5",
	[4933] = "E5",
	[4934] = "F5",
	[4935] = "G5",
	[4936] = "H5"
}

-- Cached items
navcomp.data.hive = {}
navcomp.data.hive.isHostile = false
navcomp.data.stressMaps = nil

-- Modifiable Logic
navcomp.data.backgroundPlot = true
navcomp.data.delay = 30
navcomp.data.maxStepLimit = 10
navcomp.data.plotter = nil
navcomp.data.evadePlotter = nil
navcomp.data.avoidStormSectors = false
navcomp.data.avoidManualSectors = false
navcomp.data.useSegmentSmoothing = false
navcomp.data.confirmBuddyCom = true
navcomp.data.anchorOverride = false
navcomp.data.avoidBlockableSectors = false
navcomp.data.autoPlot = false
navcomp.data.plotCapitalSystems = false
navcomp.data.blockStatusMessage = false

dofile ("data/data-saves.lua")
dofile ("data/handlers.lua")

-- Event Handling and Initialization
local loadGuiElements = false
function navcomp.data.initialize:OnEvent (event, id)
	if not navcomp.data.isInitialized then
		UnregisterEvent (navcomp.data.initialize, "PLAYER_ENTERED_GAME")
		
		-- Setting up computational data
		local k
		for k=1, #SystemNames do
			navcomp.data.systems [SystemNames [k]] = k
		end
		navcomp.data:LoadNavigationData ()
		navcomp.data:LoadPathNotes ()
		navcomp.data:LoadSectorLines ()
		navcomp.data:LoadStressMaps ()
		navcomp.data:LoadUserSettings ()
		navcomp.data:LoadBinds ()
		navcomp.data:ExpireData ()
		navcomp:SyncSectorNotes ()
		
		-- Set up randomization for evasion
		math.randomseed (os.time ())
		
		if not loadGuiElements then
			-- HUD and PDA changes
			navcomp.ui.progress = navcomp.ui:CreateProgressBar ()
			iup.Append (HUD.cboxlayer, navcomp.ui.progress)
			
			local indicatorTab
			if pcall (function () return palib and palib.ui and palib.ui.dock end) then
				indicatorTab = palib.ui.dock:AddTab ({title="Navcomp", fgcolor="200 200 200 150", index=4, align="BOTTOM", visible="NO"})
			end
			
			-- Set up Evasion indicator as default element
			navcomp.ui.evasionIndicator = navcomp.ui:CreateEvasionIndicator (indicatorTab)
			
			-- Set up Reload indicator
			navcomp.ui.reloadIndicator = navcomp.ui:CreateReloadIndicator (indicatorTab)
			
			-- Add status to HUD as required
			if indicatorTab then
				indicatorTab:AddStatus ({
					id = "EvasionIndicator",
					obj = navcomp.ui.evasionIndicator,
					visible = "NO"
				})
				indicatorTab:AddStatus ({
					id = "ReloadIndicator",
					obj = navcomp.ui.reloadIndicator,
					visible = "NO"
				})
				--navcomp.ui.evasionIndicator:Deactivate ()
				--navcomp.ui.reloadIndicator:Deactivate ()
			else
				iup.Append (HUD.cboxlayer, navcomp.ui.evasionIndicator)
				iup.Append (HUD.cboxlayer, navcomp.ui.reloadIndicator)
			end
		
			-- Build Navigational Button sets
			navcomp.pda:CreateUI (StationPDAShipNavigationTab)
			navcomp.pda:CreateUI (PDAShipNavigationTab)
			navcomp.pda:CreateUI (CapShipPDAShipNavigationTab)
			
			-- Build Bar Button set
			navcomp.pda:CreateBarUI (StationChatTab)
			
			-- Build Custom Navmap Tabs
			navcomp.pda:CreateNavmapUI (StationPDAShipNavigationTab)
			navcomp.pda:CreateNavmapUI (PDAShipNavigationTab)
			navcomp.pda:CreateNavmapUI (CapShipPDAShipNavigationTab)
			loadGuiElements = true
		end
		
		-- Add Sector Paint for Conquerable Stations and possessed keys
		navcomp:AddSectorPaint (navcomp:IsConquerableStationSector, function (id)
			-- Needs logic to determine if the player owns a cert for the station
			-- Shoud return "255 0 0" (No) or "0 255 0" (Yes)
			return nil
		end)
		
		-- Event Registration
		RegisterEvent (navcomp.data, "SECTOR_CHANGED")
		RegisterEvent (navcomp.data, "ENTERED_STATION")
		RegisterEvent (navcomp.data, "LEAVING_STATION")
		RegisterEvent (navcomp.data, "STORM_STARTED")
		RegisterEvent (navcomp.data, "HUD_SHOW")
		RegisterEvent (navcomp.data, "PLAYER_ENTERED_SECTOR")
		RegisterEvent (navcomp.com, "CHAT_MSG_PRIVATE")
		RegisterEvent (navcomp.data.logout, "PLAYER_LOGGED_OUT")
		RegisterEvent (navcomp.data.restart, "UNLOAD_INTERFACE")
		RegisterEvent (navcomp.data.missions, "PLAYER_DIED")
		RegisterEvent (navcomp.data.missions, "MISSION_ADDED")
		RegisterEvent (navcomp.data.missions, "MISSION_REMOVED")
		RegisterEvent (navcomp.pda, "NAVCOMP_REPAINT")
		navcomp.data.isInitialized = true
		navcomp:Print ("NavComp is initialized")
		ProcessEvent ("NAVCOMP_STARTED")
	end
end

-- Lua ReloadInterface ()
function navcomp.data.restart:OnEvent (event, data)
	navcomp.data.isInitialized = false
	UnregisterEvent (navcomp.data, "SECTOR_CHANGED")
	UnregisterEvent (navcomp.data, "ENTERED_STATION")
	UnregisterEvent (navcomp.data, "LEAVING_STATION")
	UnregisterEvent (navcomp.data, "STORM_STARTED")
	UnregisterEvent (navcomp.data, "HUD_SHOW")
	UnregisterEvent (navcomp.data, "PLAYER_ENTERED_SECTOR")
	UnregisterEvent (navcomp.com, "CHAT_MSG_PRIVATE")
	UnregisterEvent (navcomp.data.logout, "PLAYER_LOGGED_OUT")
	UnregisterEvent (navcomp.data.restart, "UNLOAD_INTERFACE")
	UnregisterEvent (navcomp.data.missions, "PLAYER_DIED")
	UnregisterEvent (navcomp.data.missions, "MISSION_ADDED")
	UnregisterEvent (navcomp.data.missions, "MISSION_REMOVED")
	UnregisterEvent (navcomp.pda, "NAVCOMP_REPAINT")
	
	RegisterEvent (navcomp.data.initialize , "PLAYER_ENTERED_GAME")
	ProcessEvent ("NAVCOMP_RESTARTING")
end

-- Logout procedure
function navcomp.data.logout:OnEvent (event, id)
	navcomp.data:SaveNavigationData ()
	navcomp.data:SaveSectorLines ()
	navcomp.data:SaveStressMaps ()
	navcomp.data:SaveUserSettings ()
	if not pcall (function () return targetless end) or not pcall (function () return bazaar end) or not pcall (function () return gamePlayer end) then ReloadInterface () end
	navcomp.data.restart:OnEvent (event, id)
end

-- Main Event Handler

local leavingStation = false
function navcomp.data:OnEvent (event, data)
	if event == "ENTERED_STATION" then
		navcomp.pda:SetEvasionMode (false)
		navcomp.data:CheckStationMissions ()
		navcomp.data:SaveNavigationData ()
		navcomp.data:SaveSectorLines ()
		navcomp.data:SaveStressMaps ()
		navcomp.data:ExpireData ()
		navcomp:SyncSectorNotes ()
		
	elseif event == "LEAVING_STATION" then
		leavingStation = true
		navcomp.data:SaveSectorLines ()
		navcomp.data:ExpireData ()
		navcomp:SyncSectorNotes ()
		navcomp.data:SaveStressMaps ()
		
	elseif event == "STORM_STARTED" then
		navcomp.data:RecordStorm (GetCurrentSectorid ())
		
	elseif event == "SECTOR_CHANGED" then
		navcomp.data.hive.isHostile = false
		local currentSectorId = GetCurrentSectorid ()
		-- Check for Storm
		if IsStormPresent () then
			navcomp.data.hive.isHostile = navcomp:IsEncounteredBotSector (currentSectorId)
			navcomp.data:RecordStorm (currentSectorId)
		end
		-- Check Evasion mode
		if navcomp.data.isEvading then
			navcomp:PlotEvasionPath ()
			
		-- Is this the last sector in the path?
		elseif currentSectorId == NavRoute.GetNextHop () then
			if navcomp.data.activePath.path and currentSectorId == navcomp.data.activePath.path [#navcomp.data.activePath.path] and navcomp.data.activePath.autoReload then
				navcomp:LoadActivePath (navcomp.data.activePath.name)
			end
		end
		
	elseif event == "HUD_SHOW" then
		local s1 = GetCurrentSectorid ()
		navcomp.data:CheckHostile ()
		if navcomp:IsEncounteredBotSector (s1) and not navcomp.data.hive.isHostile and not IsStormPresent () then
			-- If record shows hostile and scan shows not, then remove
			navcomp.data:RemoveHostileSector (s1)
		end
		
		-- Check if the thread has stopped.  This usually occurs after making a jump, but sometimes after leaving a station
		-- If not leaving a station restart the entire thread process
		-- If leaving a station, attempt to restart the existing thread
		--if navcomp.data.plotter then
		--	print (string.format ("(Before): %s", coroutine.status (navcomp.data.plotter)))
		--end
		if navcomp.data.backgroundPlot and navcomp.data.plotter and coroutine.status (navcomp.data.plotter) == "suspended" then
			-- Try to resume or restart thread
			if not leavingStation then
				navcomp:RunThread ()
			else
				coroutine.resume (navcomp.data.plotter)
			end
			
			--print (string.format ("(After): %s", coroutine.status (navcomp.data.plotter)))
			-- If not restarted, force a restart
			if coroutine.status (navcomp.data.plotter) == "suspended" then
				navcomp:RunThread ()
			end
		end
		navcomp.pda:SetEvasionMode (navcomp.data.isEvading)
		leavingStation = false
		
	elseif event == "PLAYER_ENTERED_SECTOR" then
		-- Identify newly appeared ships
		navcomp.data:CheckHostile ()
	end
end

-- This section is for interacting with missions in the station record
local currentHsSectorId = nil
navcomp.data.missions = {}
function navcomp.data.missions:OnEvent (event, data)
	-- These 2 are for the purpose of handling HS missions
	-- We want to know where the HS is taking place, so we remove that sector only in case the player isn't present when it ends
	if event == "MISSION_ADDED" then
		local name, log, id, obj = GetActiveMissionInfo (1)
		navcomp:ClearActivePath ()
		navcomp:SetActivePath ()
		currentHsSectorId = nil
		if log and log [1] then
			currentHsSectorId = navcomp.data:GetSectorIdFromName (log [1][1], "battle is already underway in (%a+%s?%a*)%s(%a)-(%d%d?)!")
		end
		-- If this code runs, the mission is a Hive Skirmish
		if currentHsSectorId then
			navcomp:AutoReloadCurrentPath ()
			navcomp:CheckAutoPlot (navcomp.data.activePath)
		end
		
	elseif event == "MISSION_REMOVED" then
		-- Logic here for checking if completed an HS
		local missionName, desc, id, finished = GetFinishedMissionInfo (1)
		if missionName == "Hive Skirmish" and finished == "Completed" then
			navcomp.data:RemoveHostileSector (currentHsSectorId)
		end
		currentHsSectorId = nil
		
	elseif event == "PLAYER_DIED" then
		local faction = GetPlayerFaction (data) or 1
		if faction == 0 then
			local name = GetPlayerName (data):lower ()
			if string.find (name, "leviathan") then
				navcomp.data:RemoveHostileSector (GetCurrentSectorid ())
			elseif string.find (name, "queen") then
				if currentHsSectorId then
					navcomp.data:CheckHostile ()
				else
					navcomp.data:RemoveHostileSector (GetCurrentSectorid ())
				end
			end
		end
	end
end
RegisterEvent (navcomp.data.initialize , "PLAYER_ENTERED_GAME")