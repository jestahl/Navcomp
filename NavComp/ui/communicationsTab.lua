--[[
	Communications Options Tab for NavComp control screen
]]

function navcomp.ui.control:CreateCommunicationsTab ()
	local confirmBuddyToggle = iup.stationtoggle {title="  Confirm Buddy/Guild Member before receiving data", fgcolor=navcomp.ui.fgcolor}
	
	local commTab = iup.pdasubframe_nomargin {
		iup.hbox {
			iup.fill {size = 5},
			iup.vbox {
				iup.fill {size = 15},
				iup.label {title="Communications Options", font=navcomp.ui.font, expand = "HORIZONTAL"},
				iup.hbox {
					confirmBuddyToggle;
				},
				iup.fill {};
				expand = "YES"
			},
			iup.fill {size = 5};
			expand = "YES"
		};
		tabtitle="Communications",
		font=navcomp.ui.font,
		expand = "YES"
	}
	
	function commTab:Initialize ()
		confirmBuddyToggle.value = navcomp.ui:GetOnOffSetting (navcomp.data.confirmBuddyCom)
	end
	commTab:Initialize ()

	function commTab:GetConfirmBuddy ()
		return confirmBuddyToggle.value == "ON"
	end
	
	return commTab
end