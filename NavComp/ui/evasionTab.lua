--[[
	Evasion Tab for NavComp control screen
]]

function navcomp.ui.control:CreateEvasionTab ()
	local toggleBind = iup.text {value = "", size = "100x"}
	local levelSelection = iup.pdasublist  {
		font = navcomp.ui.font,
		dropdown = "YES",
		visible_items = 10,
		expand = "HORIZONTAL"
	}
	levelSelection [1] = "3"
	levelSelection [2] = "5"
	levelSelection [3] = "10"
	
	local evasionTab = iup.pdasubframe_nomargin {
		iup.hbox {
			iup.fill {size = 5},
			iup.vbox {
				iup.fill {size = 15},
				iup.label {title = "Data", font = navcomp.ui.font},
				iup.hbox {
					iup.label {title = "Evasion Level:", font = navcomp.ui.font, fgcolor = navcomp.ui.fgcolor},
					iup.fill {size = 10},
					levelSelection
				},
				iup.fill {size = 25},
				iup.label {title = "Binds", font = navcomp.ui.font},
				iup.hbox {
					iup.label {title = "Toggle Evasion Mode:", font = navcomp.ui.font, fgcolor = navcomp.ui.fgcolor},
					iup.fill {size = 10},
					toggleBind;
				},
				iup.fill {};
			},
			iup.fill {size = 5};
			expand = "YES"
		};
		tabtitle = "Evasion",
		font = navcomp.ui.font,
		expand = "YES"
	}
	
	function evasionTab:GetToggleBind ()
		return toggleBind.value
	end
	
	function evasionTab:SetEvasionLevel (level)
		local k
		for k=1, 3, 1 do
			if levelSelection [k] == tostring (level) then
				levelSelection.value = k
			end
		end
	end
	
	function evasionTab:Initialize ()
		evasionTab:SetEvasionLevel (navcomp.data.evasionLevel)
		toggleBind.value = gkini.ReadString (navcomp.data.config, "evadeBind", "")
	end
	
	-- Initialize on load
	evasionTab:Initialize ()
	
	function evasionTab:DoSave ()
		navcomp.data.evasionLevel = tonumber (levelSelection [levelSelection.value])
	end
	
	function evasionTab:SaveBinds ()
		navcomp.data:SaveBinds ({toggleBind.value})
	end
	
	return evasionTab
end