--[[
	Hazard Editor
]]

function navcomp.ui:CreateClearDataUI ()
	local stormButton = iup.stationbutton {title="Storm"}
	local hiveButton = iup.stationbutton {title="Hive"}
	local manualButton = iup.stationbutton {title="Manual"}
	local allButton = iup.stationbutton {title="All"}
	local cancelButton = iup.stationbutton {title="Cancel", focus="YES"}
	local systemSelection = navcomp.ui:CreateSystemSelection ("All Systems")
	local selectedSysId = nil
	
	local pda = iup.pdarootframe {
		iup.vbox {
			iup.label {title="Clear Which Data?", fgcolor=navcomp.ui.fgcolor, alignment="ACENTER", expand="HORIZONTAL"},
			iup.hbox {
				iup.label {title="System: ", fgcolor=navcomp.ui.fgcolor},
				systemSelection;
			},
			iup.hbox {
				iup.fill {},
				stormButton,
				hiveButton,
				manualButton,
				allButton,
				cancelButton;
				expand="HORIZONTAL"
			};
			expand="YES"
		};
		expand="YES"
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
		expand = "YES",
		active = 'NO',
		menubox = 'NO',
		bgcolor = "255 10 10 10 *",
		defaultesc = cancelButton
	}
	
	function systemSelection:action (text, index, state)
		selectedSysId = nil
		if state == 1 and index > 1 then
			selectedSysId = navcomp.data.systems [text]
		end
	end
	
	stormButton.action = function ()
		HideDialog (frame)
		frame.active = "NO"
		navcomp.data:ClearData (selectedSysId, 0)
	end
	
	hiveButton.action = function ()
		HideDialog (frame)
		frame.active = "NO"
		navcomp.data:ClearData (selectedSysId, 1)
	end
	
	manualButton.action = function ()
		HideDialog (frame)
		frame.active = "NO"
		navcomp.data:ClearData (selectedSysId, 2)
	end
	
	allButton.action = function ()
		HideDialog (frame)
		frame.active = "NO"
		navcomp.data:ClearData (selectedSysId, 3)
	end
	
	cancelButton.action = function ()
		HideDialog (frame)
		frame.active = "NO"
	end
	
	-- Display Dialog
	ShowDialog (frame, iup.CENTER, iup.CENTER)
	frame.active = "YES"
	
	return frame
end