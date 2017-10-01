--[[
	VO PDA Interface
]]

navcomp.pda = {}
local plotButton = nil
local evasionButton, stationAutoReloadButton, shipAutoReloadButton, capshipAutoReloadButton
local sectorPaint = {}

function navcomp.pda:CreateUI (navTab)
	-- Build Button Set for Navigational PDA
	plotButton = iup.stationbutton {title="Plot", font=navcomp.ui.font, action=function () navcomp:PlotPath () end, hotkey=iup.K_p}
	local optionsButton = iup.stationbutton {title="Options", font=navcomp.ui.font, action=navcomp.Options}
	local syncButton = iup.stationbutton {title="Sync", font=navcomp.ui.font, action=function () navcomp.SyncSectorNotes () navcomp:Print ("Synchronization Complete") end}
	local optionsPanel
	if navTab == PDAShipNavigationTab then
		evasionButton = iup.stationbutton {title="Evade", font=navcomp.ui.font, action=navcomp.ToggleEvasionMode}
		shipAutoReloadButton = iup.stationbutton {title="AutoReload", font=navcomp.ui.font, action=navcomp.AutoReloadCurrentPath}
		optionsPanel = iup.hbox {
			evasionButton,
			optionsButton,
			syncButton,
			shipAutoReloadButton;
			expand="HORIZONTAL"
		}
	elseif navTab == StationPDAShipNavigationTab then
		stationAutoReloadButton = iup.stationbutton {title="AutoReload", font=navcomp.ui.font, action=navcomp.AutoReloadCurrentPath}
		optionsPanel = iup.hbox {
			optionsButton,
			syncButton,
			stationAutoReloadButton;
			expand="HORIZONTAL"
		}
	else
		capshipAutoReloadButton = iup.stationbutton {title="AutoReload", font=navcomp.ui.font, action=navcomp.AutoReloadCurrentPath}
		optionsPanel = iup.hbox {
			optionsButton,
			syncButton,
			capshipAutoReloadButton;
			expand="HORIZONTAL"
		}
	end
	local content = iup.vbox {
		iup.label {title="NavComp - v" .. navcomp.version, font=navcomp.ui.font, fgcolor=navcomp.ui.fgcolor, expand="HORIZONTAL"},
		iup.hbox {
			plotButton,
			iup.stationbutton {title="Save", font=navcomp.ui.font, action=navcomp.SavePath, expand="HORIZONTAL"},
			iup.stationbutton {title="Load", font=navcomp.ui.font, action=navcomp.LoadPath, expand="HORIZONTAL"},
			iup.stationbutton {title="Clear Data", font=navcomp.ui.font, action=navcomp.ClearStorms, expand="HORIZONTAL"};
			expand="HORIZONTAL"
		},
		optionsPanel;
	}
	
	iup.Append (navTab [3], content)
	iup.Refresh (navTab)
end

function navcomp.pda:CreateBarUI (barTab)
	-- Build Exchange Buttons
	local content = iup.vbox {
		iup.label {title="NavComp - v" .. navcomp.version, font=navcomp.ui.font, fgcolor=navcomp.ui.fgcolor},
		iup.stationbutton {title="Exchange", font=navcomp.ui.font, action=function () navcomp.com.ui:CreateUI () end};
	}
	
	-- Build Toolbar UI
	local toolbar = iup.hbox {
		toolbar = "YES"
	}

	local child = iup.GetNextChild (barTab [1][1])
	while (child and not child.toolbar) do
		child = iup.GetNextChild (barTab [1][1], child)
	end
	if child and child.toolbar then
		iup.Append (child, content)
		iup.Append (child, iup.fill {})
	else
		iup.Append (barTab [1][1], toolbar)
		iup.Append (toolbar, content)
		iup.Append (toolbar, iup.fill {})
	end
	iup.Refresh (barTab)
end

function navcomp.pda:SetPlotMode (flag)
	if flag then
		plotButton.active = "NO"
	else
		plotButton.active = "YES"
	end
end

function navcomp.pda:SetEvasionMode (flag)
	navcomp.data.isEvading = flag
	if flag then
		evasionButton.title = "Resume"
		evasionButton.image = navcomp.ui.image.button_indicator
		evasionButton.immouseover = navcomp.ui.image.button_indicator_mouseover
		navcomp.ui.evasionIndicator:Activate ()
	else
		evasionButton.title = "Evade"
		evasionButton.image = navcomp.ui.image.button_default
		evasionButton.immouseover = navcomp.ui.image.button_mouseover
		navcomp.ui.evasionIndicator:Deactivate ()
	end
end

function navcomp.pda:SetReloadMode (flag)
	navcomp.data.activePath.autoReload = flag
	if flag then
		stationAutoReloadButton.title = "Will Load"
		shipAutoReloadButton.title = "Will Load"
		capshipAutoReloadButton.title = "Will Load"
		stationAutoReloadButton.image = navcomp.ui.image.button_indicator
		shipAutoReloadButton.image = navcomp.ui.image.button_indicator
		capshipAutoReloadButton.image = navcomp.ui.image.button_indicator
		stationAutoReloadButton.immouseover = navcomp.ui.image.button_indicator_mouseover
		shipAutoReloadButton.immouseover = navcomp.ui.image.button_indicator_mouseover
		capshipAutoReloadButton.immouseover = navcomp.ui.image.button_indicator_mouseover
		navcomp.ui.reloadIndicator:Activate ()
	else
		stationAutoReloadButton.title = "AutoReload"
		shipAutoReloadButton.title = "AutoReload"
		capshipAutoReloadButton.title = "AutoReload"
		stationAutoReloadButton.image = navcomp.ui.image.button_default
		shipAutoReloadButton.image = navcomp.ui.image.button_default
		capshipAutoReloadButton.image = navcomp.ui.image.button_default
		stationAutoReloadButton.immouseover = navcomp.ui.image.button_mouseover
		shipAutoReloadButton.immouseover = navcomp.ui.image.button_mouseover
		capshipAutoReloadButton.immouseover = navcomp.ui.image.button_mouseover
		navcomp.ui.reloadIndicator:Deactivate ()
	end
end

local function setPaint (key, check)
	local p
	for _, p in ipairs (sectorPaint) do
		-- If already defined, replace
		if p.key == key then
			p.check = check
		end
	end
	-- Otherwise add new sector paint
	table.insert (sectorPaint, {
		key = key,
		check = check
	})
end

--[[
	Sets up a paint routine for sectors
	Arguments:
		key (number, string, function) - may be a number (specific sectorId), string (long name of sector), or function which takes a numeric sectorId as an argument
		color (string, function) - the color to paint the sector if: the sectorId matches the passed ID, or a function which determines the color
		
		The key function is used either to identify the sector to be painted (and will be painted as the passed color) or returns a string which must be a defined IUP color string
		Navcomp will store the process against the passed key
]]
function navcomp:AddSectorPaint (key, color)
	-- Check for all paint types
	if type (key) == "number" then
		setPaint (key, function (id)
			if id == key then
				if type (color) == "function" then
					return color (id)
				else
					return color
				end
			end
		end)
	elseif type (key) == "string" then
		local sectorId = navcomp.data:GetSectorIdFromName (key)
		if sectorId then
			setPaint (key, function (id)
				if id == sectorId then
					if type (color) == "string" then
						return color
					elseif type (color) == "function" then
						return color (id)
					end
				end
			end)
		end
	elseif type (key) == "function" then
		setPaint (key, function (id)
			local r = key (id)
			if type (r) == "boolean" and r then
				if type (color) == "string" then
					return color
				elseif type (color) == "function" then
					return color (id)
				end
			elseif type (r) == "string" then
				return r
			elseif type (r) == "function" then
				return r (id)
			end
		end)
	end
end

-- Removes a previously set sector paint routine by its key ID
function navcomp:RemoveSectorPaint (key)
	local index = 0
	local p
	for _, p in ipairs (sectorPaint) do
		index = index + 1
		if p.key == key then
			table.remove (sectorPaint, index)
			break
		end
	end
end

-- Checks if a given key has been added as a Sector Paint
function navcomp:CheckSectorPaint (key)
	local index = 0
	local p
	for _, p in ipairs (sectorPaint) do
		index = index + 1
		if p.key == key then
			return true
		end
	end
	
	return false
end

-- Paint all the storm sectors
local function PaintSectors (navmap, sysId)
	local sectorId, color, colorId, colorIndex, sectorData
	local x, y
	for x = 1, 16 do
		for y = 1, 16 do
			color = nil
			colorIndex = 0
			sectorId = navcomp:BuildSectorId (sysId, x, y)
			colorId = string.format ("COLOR%d", sectorId)
			
			-- Build cumulative color data
			if navcomp:IsEncounteredStormSector (sectorId) then colorIndex = colorIndex + 1 end
			if navcomp:IsEncounteredBotSector (sectorId) then colorIndex = colorIndex + 2 end
			if navcomp:IsAvoidSector (sectorId) then colorIndex = colorIndex + 4 end
			if colorIndex > 0 then
				color = navcomp.ui.hazardColors [colorIndex]
			end
			
			-- Check Sector Paint additions
			if navcomp:IsAnchorSector (sectorId) then color = navcomp.ui.hazardColors [8] end
			local p
			for _, p in ipairs (sectorPaint) do
				color = color or p.check (sectorId)
			end
			
			-- Set the actual color
			if color then
				navmap [colorId] = color
			end
		end
	end
end

-- Custom PDA Navmap
navcomp.pda.lastLoadedSysId = 0
function navcomp.pda:CreateNavmapUI (pdaTab)
	local navmap = pdaTab [1][1][1][1]
	
	local oldLoadMap = navmap.loadmap
	function navmap:loadmap (type, path, id)
		oldLoadMap (self, type, path, id)
		navcomp.pda.lastLoadedSysId = 0
		if type == 2 then
			navcomp.pda.lastLoadedSysId = id + 1
			PaintSectors (navmap, id + 1)
		end
	end
	
	local oldClickMap = navmap.click_cb
	function navmap:click_cb (index, modifiers)
		oldClickMap (self, index, modifiers)
		navcomp:ClearActivePath ()
	end
	
	-- Index is sectorId
	-- str is sector string
	local oldMouseoverMap = navmap.mouseover_cb
	local currentSectorId, startAnchorId
	function navmap:mouseover_cb (index, str)
		currentSectorId = index
		oldMouseoverMap (self, index, str)
	end
	
	local oldKeyHandler = pdaTab.k_any
	local setAnchor = false
	function pdaTab:k_any (key)
		if key == iup.K_v then
			if setAnchor then
				-- Need to check if anchor was placed in requested sector
				navcomp:Print ("Place Anchor in " .. LocationStr (currentSectorId))
				navcomp:WriteNewAnchors ({
					sectorId = currentSectorId,
					anchors = {{
						s = startAnchorId
					}}
				})
				startAnchorId = nil
				setAnchor = false
			else
				navcomp:Print ("Start Anchor in " .. LocationStr (currentSectorId))
				startAnchorId = currentSectorId
				setAnchor = true
			end
			return iup.CONTINUE
		else
			return oldKeyHandler (self, key)
		end
	end
end

function navcomp.pda:OnEvent (event, data)
	if event == "NAVCOMP_REPAINT" then
		--[[
			tab = possible array, if single useritem, process singly, if table, process as array checking for useritem in each element.  If missing, update all 3 PDAs
			sysId = System ID.  If missing use navcomp.pda.lastLoadedSysId
		]]
		data = data or {tab={StationPDAShipNavigationTab, PDAShipNavigationTab, CapShipPDAShipNavigationTab}, sysId=navcomp.pda.lastLoadedSysId}
		if type (data.tab) == "userdata" then
			data.tab = {data.tab}
		elseif type (data.tab) == "function" then
			data.tab = {StationPDAShipNavigationTab, PDAShipNavigationTab, CapShipPDAShipNavigationTab}
		end
		data.tab = data.tab or {StationPDAShipNavigationTab, PDAShipNavigationTab, CapShipPDAShipNavigationTab}
		data.sysId = data.sysId or navcomp.pda.lastLoadedSysId
		local pda
		for _, pda in ipairs (data.tab) do
			PaintSectors (pda [1][1][1][1], data.sysId)
		end
	end
end
