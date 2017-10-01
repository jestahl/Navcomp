--[[
	UI Definition
]]
navcomp.ui = {}
navcomp.ui.hsize = gkinterface.GetXResolution () / 900
navcomp.ui.vsize = gkinterface.GetYResolution () / 600
navcomp.ui.font = 12 * navcomp.ui.vsize
navcomp.ui.fontSmall = 8 * navcomp.ui.vsize
navcomp.ui.fgcolor = "200 200 50"
navcomp.ui.progress = nil
navcomp.ui.evasionIndicator = nil
navcomp.ui.reloadIndicator = nil
navcomp.ui.indicatorTab = nil
navcomp.ui.hazardColors = {
	"150 150 150",			-- Storm
	"255 255 0",				-- Bot
	"255 0 255",				-- Both
	"255 255 255",			-- Manual
	"255 255 255",			-- Manual + Storm
	"255 255 255",			-- Manual + Bot
	"255 255 255",			-- Manual + Both
	"0 0 255"					-- Anchors placed
}
navcomp.ui.bgcolor_indicator_off = "128 128 128 128"
navcomp.ui.bgcolor_indicator_on = "0 255 0 128"
navcomp.ui.image = {
	button_default = IMAGE_DIR .. "button.png",
	button_mouseover = IMAGE_DIR .. "button_tab.png",
	button_indicator = "plugins/Navcomp/images/toggle_button.png",
	button_indicator_mouseover = "plugins/Navcomp/images/toggle_over_button.png"
}
local createdIndicator = false

function navcomp.ui:GetOnOffSetting (flag)
	if (flag) then
		return "ON"
	else
		return "OFF"
	end
end

function navcomp.ui:GetMapForSystem (sysId)
	local mapName
	if sysId < 10 then
		mapName = string.format ("lua/maps/system0%dmap.lua", sysId)
	else
		mapName = string.format ("lua/maps/system%dmap.lua", sysId)
	end
	local map = dofile (mapName)
	
	return mapName, map
end

function navcomp.ui:CreateMapUI (sysId)
	local navmap = iup.navmap {}
	local mapName = navcomp.ui:GetMapForSystem (sysId)
	navmap:loadmap (2, mapName, sysId-1)
	
	return navmap
end

function navcomp.ui:CreateSystemSelection (defaultValue)
	local systemSelection = iup.pdasublist  {
		font = navcomp.ui.font,
		dropdown = "YES",
		visible_items = 10,
		expand = "HORIZONTAL"
	}
	systemSelection [1] = defaultValue
	local temp = {}
	for k,v in ipairs (SystemNames) do
		table.insert (temp, v)
	end
	table.sort (temp, function (a, b) return a:lower () < b:lower () end)
	for k,v in ipairs (temp) do
		systemSelection.font = navcomp.ui.font
		systemSelection.fgcolor = navcomp.ui.fgcolor
		systemSelection [k+1] = v
	end
	
	return systemSelection
end

dofile ("ui/pda.lua")
dofile ("ui/control.lua")
dofile ("ui/editor.lua")

navcomp.ui.sortColumn = 1
function navcomp.ui:CreateUI (isLoad)
	local selectedName, selectedNote, selectedPath
	local maxNoteWidth = 75
	local saveButton = iup.stationbutton {title="Save" }
	local saveAsButton = iup.stationbutton {title="Save As", active="NO"}
	local loadButton = iup.stationbutton {title="Load", active="NO"}
	local deleteButton = iup.stationbutton {title="Delete", active="NO"}
	local closeButton = iup.stationbutton {title="Close", focus="YES"}
	
	-- Build Save component
	local text = iup.text {value="", font=navcomp.ui.font, expand="HORIZONTAL"}
	local note = iup.text {value="", font=navcomp.ui.font, expand="HORIZONTAL"}
	local bind = iup.text {value="", font=navcomp.ui.font, size=string.format ("%dx", math.floor (25*navcomp.ui.hsize+0.5))}
	local autoPlot = iup.stationtoggle {title="  Autoplot Path?", fgcolor=navcomp.ui.fgcolor}
	local autoReload = iup.stationtoggle {title="  Auto Reload Path?", fgcolor=navcomp.ui.fgcolor}
	if isLoad then
		saveButton.active = "NO"
		autoPlot.active = "NO"
		autoReload.active = "NO"
	end
	
	local savePda = iup.hbox {
		iup.vbox {
			iup.label {title=" "},
			iup.label {title=" "},
			iup.label {title="Name: ", font=navcomp.ui.font, fgcolor=navcomp.ui.fgcolor},
			iup.label {title="Note: ", font=navcomp.ui.font, fgcolor=navcomp.ui.fgcolor};
		},
		iup.vbox {
			iup.label {title="Current NavPath", expand="HORIZONTAL"},
			iup.hbox {
				autoPlot,
				iup.fill {size=25},
				autoReload,
				iup.fill {size=35},
				iup.label {title="Bind: ", font=navcomp.ui.font, fgcolor=navcomp.ui.fgcolor},
				bind;
				expand="HORIZONTAL"
			},
			text,
			note;
		};
		expand = "HORIZONTAL"
	}
	
	-- Build Path Matrix
	local l
	local matrix = iup.pdasubmatrix {
		numcol = 4,
		numlin = 1,
		numlin_visible = 10,
		heightdef = 15,
		width4 = 120,
		expand = "YES",
		font = navcomp.ui.font,
		bgcolor = "255 10 10 10 *"
	}
	
	-- Set Headers
	matrix:setcell (0, 1, "Name")
	matrix:setcell (0, 2, "From Sector")
	matrix:setcell (0, 3, "To Sector")
	matrix:setcell (0, 4, "Note")
	matrix:setcell (1, 4, string.rep (" ", maxNoteWidth))
	
	local pda = iup.pdarootframe {
		iup.vbox {
			iup.label {title = "Manage Navpaths", font = navcomp.ui.font, fgcolor=navcomp.ui.fgcolor, expand="HORIZONTAL"},
			matrix,
			iup.fill {},
			savePda,
			iup.hbox {
				iup.fill {},
				saveButton,
				saveAsButton,
				loadButton,
				deleteButton,
				closeButton; };
		};
	}
	local frame = iup.dialog {
		pda,
	    font = navcomp.ui.font,
		border = 'YES',
		topmost = 'YES',
		resize = 'NO',
		maxbox = 'NO',
		minbox = 'NO',
		modal = 'YES',
		fullscreen = 'NO',
		expand = 'YES',
		active = 'NO',
		menubox = 'NO',
		size = "x%50",
		bgcolor = "255 10 10 10 *",
		defaultesc = closeButton
	}
	
	matrix.click_cb = function (self, row, col)
		-- Set all bgcolors
		for l=1,self.numlin do
			if l == row then
				self ["bgcolor"..l..":*"] = "255 150 150 150 *"
			else
				self ["bgcolor"..l..":*"] = "255 10 10 10 *"
			end
		end
		
		if row == 0 then
			selectedName = nil
			selectedNote = ""
			selectedPath = {autoPlot=false, autoReload=false}
			navcomp.ui.sortColumn = col
			frame:ReloadData ()
			saveAsButton.active = "NO"
			if isLoad then
				saveButton.active = "NO"
			else
				saveButton.active = "YES"
			end
			loadButton.active = "NO"
			deleteButton.active = "NO"
		else
			selectedName = self:getcell (row, 1)
			selectedNote = navcomp.data.pathList [selectedName].note
			selectedPath = navcomp.data.pathList [selectedName] or {autoPlot=false, autoReload=false}
			if selectedPath.name then
				saveAsButton.active = "YES"
			end
			if isLoad then
				loadButton.active = "YES"
				saveButton.active = "NO"
			else
				loadButton.active = "NO"
				saveButton.active = "YES"
			end
			deleteButton.active = "YES"
		end
		frame:SetPathName (selectedName)
		frame:SetNote (selectedNote)
		autoPlot.value = navcomp.ui:GetOnOffSetting (selectedPath.autoPlot)
		autoReload.value = navcomp.ui:GetOnOffSetting (selectedPath.autoReload)
		bind.title = selectedPath.bind or ""
	end
	
	saveButton.action = function ()
		HideDialog (frame)
		frame.active = "NO"
		navcomp.data.activePath = navcomp.data:CreatePath ({
			name = text.value,
			note = note.value,
			autoPlot = autoPlot.value == "ON",
			autoReload = autoReload.value == "ON"
		})
		navcomp:SaveActivePath (navcomp.data.activePath)
		navcomp:CheckAutoPlot (navcomp.data.activePath)
	end
	
	saveAsButton.action = function ()
		navcomp.data.activePath = navcomp.data:CreatePath (selectedPath)
		navcomp.data.activePath.name = text.value
		navcomp.data.activePath.note = note.value
		navcomp:SaveActivePath (navcomp.data.activePath)
		frame:ReloadData ()
	end
	
	loadButton.action = function ()
		HideDialog (frame)
		frame.active = "NO"
		navcomp:LoadActivePath (selectedName)
	end
	
	deleteButton.action = function ()
		local name = selectedName
		navcomp.data.pathList [name] = nil
		frame:SetPathName ("")
		frame:SetNote ("")
		bind.title = ""
		loadButton.active = "NO"
		navcomp.data:SavePathNotes ()
		frame:ReloadData ()
	end

	closeButton.action = function ()
		HideDialog (frame)
		frame.active = "NO"
	end
	
	function frame:SetPathName (s)
		text.value = s
	end
	
	function frame:SetNote (s)
		note.value = s
	end

	function frame:ClearData ()
		local i
		for i=1, tonumber (matrix.numlin) do
			matrix.dellin = 1
		end
	end
	
	function frame:ReloadData ()
		local list = navcomp.data.pathList
		local keys = {}
		local k, v
		if list then
			for k,v in pairs (list) do
				table.insert (keys, k)
			end
			table.sort (keys, function (a,b)
				if navcomp.ui.sortColumn == 1 then
					return a:lower () < b:lower ()
				elseif navcomp.ui.sortColumn == 2 then
					return AbbrLocationStr (list [a].path [1]):lower () < AbbrLocationStr (list [b].path [1]):lower ()
				elseif navcomp.ui.sortColumn == 3 then
					local patha = list [a].path
					local pathb = list [b].path
					return AbbrLocationStr (patha [#patha]):lower () < AbbrLocationStr (pathb [#pathb]):lower ()
				elseif navcomp.ui.sortColumn == 4 then
					return list [a].note:lower () < list [b].note:lower ()
				end
			end)
		end
		
		frame:ClearData ()
		local row = 0
		local path, note
		matrix.alignment1 = "ALEFT"
		matrix.alignment2 = "ALEFT"
		matrix.alignment3 = "ALEFT"
		matrix.alignment4 = "ALEFT"
		matrix.width4 = 120
		matrix.heightdef = 15
		for k,v in ipairs (keys) do
			path = list [v].path
			note = list [v].note
			if note:len () > maxNoteWidth then
				note = note:sub (1, maxNoteWidth-4) .. " ..."
			end
			matrix.addlin = row
			matrix.font = navcomp.ui.font
			row = row + 1
			matrix:setcell (row, 1, v)
			matrix:setcell (row, 2, AbbrLocationStr (path [1]))
			matrix:setcell (row, 3, AbbrLocationStr (path [#path]))
			matrix:setcell (row, 4, note)
		end
		matrix.numlin = row
		matrix.redraw = "ALL"
		iup.Refresh (frame)
	end
	
	if not isLoad then
		frame:SetPathName (navcomp.data.activePath.name)
		frame:SetNote (navcomp.data.activePath.note)
		autoPlot.value = navcomp.ui:GetOnOffSetting (navcomp.data.activePath.autoPlot)
		autoReload.value = navcomp.ui:GetOnOffSetting (navcomp.data.activePath.autoReload)
		bind.title = navcomp.data.activePath.bind or ""
	end
	ShowDialog (frame, iup.CENTER, iup.CENTER)
	frame:ReloadData ()
	frame.active = "YES"
	
	return frame
end

function navcomp.ui:CreateProgressBar ()
	local x = gkinterface.GetXResolution () / 2 - 100
	local y = gkinterface.GetYResolution () / 4
	local label = iup.label {
		title = "",
		size = "195x20",
		font = navcomp.ui.font
	}
	local pbar = iup.stationprogressbar {
		title = "",
		size = "195x10",
		minvalue = 0,
		maxvalue = 500,
        uppercolor = "0 0 0 0 *",
        lowercolor = "64 255 64 155 *"
	}

	local frame = iup.pdarootframe {
		iup.vbox {
			label,
			pbar;
		},
		visible="NO",
		size="200x35",
		cx=x,
		cy=y
	}
	
	function frame:SetTitle (str)
		label.title = str
		iup.Refresh (frame)
	end
	
	function frame:Update (index)
		pbar.value = index
	end
	
	return frame
end

function navcomp.ui:CreateEvasionIndicator (tab)
	local frame
	if tab then
		frame = iup.label {
			title = "Evasion Active",
			bgcolor = "255 0 0 128",
			font = navcomp.ui.fontSmall,
			fgcolor = "255 255 255",
			alignment = "ACENTER",
			visible = "NO",
			size = palib.ui:GetHSize (10),
			Start = function ()
				--frame:Start ()
			end,
			Stop = function ()
				--frame:Stop ()
			end
		}
	else
		frame = iup.pdarootframe {
			iup.label {
				title = "Evasion Active",
				bgcolor = "255 0 0 155",
				font = navcomp.ui.font,
				fgcolor = "255 255 255",
				size = "150x20",
				alignment = "ACENTER"
			},
			visible = "NO",
			size = "152x22",
			cx = gkinterface.GetXResolution () / 2 - 75,
			cy = gkinterface.GetYResolution () / 4 - 35,
			Start = function ()
				--frame:Start ()
			end,
			Stop = function ()
				--frame:Stop ()
			end
		}
	
		function frame:Activate ()
			frame.visible = "YES"
		end
		
		function frame:Deactivate ()
			frame.visible = "NO"
		end
	end
	
	return frame
end

function navcomp.ui:CreateReloadIndicator (tab)
	local frame
	if tab then
		frame = iup.label {
			title = "Reload Active",
			bgcolor = "0 255 0 128",
			font = navcomp.ui.fontSmall,
			fgcolor = "255 255 255",
			alignment = "ACENTER",
			visible = "NO",
			size = palib.ui:GetHSize (10),
			Start = function ()
				--frame:Start ()
			end,
			Stop = function ()
				--frame:Stop ()
			end
		}
	else
		frame = iup.pdarootframe {
			iup.label {
				title = "Reload Active",
				bgcolor = "0 255 0 155",
				font = navcomp.ui.font,
				fgcolor = "255 255 255",
				size = "150x20",
				alignment = "ACENTER"
			},
			visible = "NO",
			size = "150x20",
			cx = gkinterface.GetXResolution () - 151,
			cy = 5,
			Start = function ()
				--frame:Start ()
			end,
			Stop = function ()
				--frame:Stop ()
			end
		}
	
		function frame:Activate ()
			frame.visible = "YES"
		end
		
		function frame:Deactivate ()
			frame.visible = "NO"
		end
	end
	
	return frame
end

function navcomp.ui:CreateAlertUI (msg, buttonNames, buttonCbs, pos, focus, size, isMultiline)
	size = size or "500x300"
	if not pos or type (pos) ~= "table" then pos = {x=iup.CENTER, y=iup.CENTER} end
	pos.x = pos.x or iup.CENTER
	pos.y = pos.y or iup.CENTER
	local msglabel
	local okButton = iup.stationbutton {title="Ok", focus="YES"}
	if type (msg) == "string" then
		msglabel = iup.label {title=msg, fgcolor=gamePlayer.ui.fgcolor, alignment="ACENTER", expand="HORIZONTAL"}
		if isMultiline then
			msglabel = iup.pdasubmultiline {value = msg, scrollbar = "YES", size = "400x200", expand = "YES"}
		end
	elseif type (msg) == "userdata" then
		msglabel = msg
	else
		msglabel = iup.fill {}
	end
	
	local buttonBar = iup.hbox {iup.fill {};}
	
	local pda = iup.stationsubframe {
		iup.hbox {
			iup.fill {size=10},
			iup.vbox {
				iup.fill {size=5},
				msglabel,
				iup.fill {size=15},
				buttonBar,
				iup.fill {size=5};
			},
			iup.fill {size=10};
		};
		expand="YES"
	}
	
	local frame = iup.dialog {
		pda,
	    font = gamePlayer.ui.font,
		border = 'YES',
		topmost = 'YES',
		resize = 'NO',
		maxbox = 'NO',
		minbox = 'NO',
		modal = 'YES',
		fullscreen = 'NO',
		expand = "YES",
		menubox = 'NO',
		bgcolor = gamePlayer.ui.bgcolor,
		defaultesc = okButton
	}
	
	function okButton:action ()
		HideDialog (frame)
		frame.active = "NO"
	end
	
	if buttonNames and #buttonNames > 0 then
		local k, name, cb
		for k, name in ipairs (buttonNames) do
			local button = iup.stationbutton {title=name}
			--frame [string.format ("button%s", name)] = button
			if focus ~= nil and k == focus then
				button.focus = "YES"
				frame.defaultesc = button
			end
			if buttonCbs [k] then
				button.action = function ()
					buttonCbs [k] ()
					HideDialog (frame)
					frame.active = "NO"
				end
			else
				button.action = function ()
					HideDialog (frame)
					frame.active = "NO"
				end
			end
			iup.Append (buttonBar, button)
		end
	else
		iup.Append (buttonBar, okButton)
	end
	
	-- Display
	ShowDialog (frame, pos.x, pos.y)
	frame.active = "YES"
	
	return frame
end