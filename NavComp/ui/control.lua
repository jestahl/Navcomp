--[[
	Control UI for Navigational Computer
]]
navcomp.ui.control = {}
dofile ("ui/optionsTab.lua")
dofile ("ui/colorsTab.lua")
dofile ("ui/metadataTab.lua")
dofile ("ui/evasionTab.lua")
dofile ("ui/communicationsTab.lua")

function navcomp.ui.control:CreatePdaUI ()
	-- Build Tabs
	local optionsTab = navcomp.ui.control:CreateOptionsTab ()
	local colorsTab = navcomp.ui.control:CreateColorsTab ()
	local metadataTab = navcomp.ui.control:CreateMetadataTab ()
	local evasionTab = navcomp.ui.control:CreateEvasionTab ()
	local commTab = navcomp.ui.control:CreateCommunicationsTab ()
	
	-- Assemble Tab Frame
	local tabframe = iup.roottabtemplate {
		optionsTab,
		colorsTab,
		evasionTab,
		commTab,
		metadataTab;
		expand = "YES"
	}
	
	-- Assemble PDA Frame
	local saveButton = iup.stationbutton {title="Save"}
	local cancelButton = iup.stationbutton {title="Cancel"}
	
	local pda = iup.vbox {
		iup.label {title = "NavComp Settings v" .. navcomp.version, font=navcomp.ui.font},
		iup.fill {size = 15},
		tabframe,
		iup.hbox {
			iup.fill {},
			saveButton,
			cancelButton;
			expand = "HORIZONTAL"
		};
		expand = "YES"
	}
	
	function pda:DoSave ()
		local k,v
		for k,v in ipairs (metadataTab:GetData ()) do
			navcomp.plotter.metadata [k].algorithm = v
		end
		optionsTab:DoSave ()
		colorsTab:DoSave ()
		evasionTab:DoSave ()
		navcomp.data.confirmBuddyCom = commTab:GetConfirmBuddy ()
		navcomp.data:SaveUserSettings ()
		evasionTab:SaveBinds ()
		
		-- Repaint Navmaps
		if navcomp.pda.lastLoadedSysId > 0 then
			--[[navcomp.pda:PaintSectors (StationPDAShipNavigationTab [1][1][1], navcomp.pda.lastLoadedSysId)
			navcomp.pda:PaintSectors (PDAShipNavigationTab [1][1][1], navcomp.pda.lastLoadedSysId)
			navcomp.pda:PaintSectors (CapShipPDAShipNavigationTab [1][1][1], navcomp.pda.lastLoadedSysId)]]
			ProcessEvent ("NAVCOMP_REPAINT")
		end
	end
	
	function pda:DoCancel ()
		optionsTab:Initialize ()
		metadataTab:Initialize ()
		evasionTab:Initialize ()
		commTab:Initialize ()
		iup.Refresh (pda)
	end
	
	function pda:GetSaveButton ()
		return saveButton
	end
	
	function pda:GetCancelButton ()
		return cancelButton
	end
	
	saveButton.action = function ()
		pda:DoSave ()
	end
	
	cancelButton.action = function ()
		pda:DoCancel ()
	end
	
	return pda
end

function navcomp.ui.control:CreateUI ()
	local pda = navcomp.ui.control:CreatePdaUI ()
	
	local frame = iup.dialog {
		iup.pdarootframe {
			pda;
			expand = "YES"
		},
	    font = navcomp.ui.font,
		border = 'YES',
		topmost = 'YES',
		resize = 'NO',
		maxbox = 'NO',
		minbox = 'NO',
		modal = 'YES',
		fullscreen = 'NO',
		expand = "YES",
		active = 'NO',
		menubox = 'NO',
		bgcolor = "255 10 10 10 *",
		defaultesc = pda:GetCancelButton ()
	}
	
	pda:GetSaveButton ().action = function ()
		pda:DoSave ()
		HideDialog (frame)
		frame.active = "NO"
	end
	
	pda:GetCancelButton ().action = function ()
		pda:DoCancel ()
		HideDialog (frame)
		frame.active = "YES"
	end
	
	pda:GetCancelButton ().focus = "YES"
	
	ShowDialog (frame, iup.CENTER, iup.CENTER)
	frame.active = "YES"
	
	return frame
end