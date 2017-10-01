--[[
	Creates the tab for managing exchanges of navigation paths
]]

function navcomp.com.ui:CreateNavpathTab (selected)
	local function BuildList ()
		return navcomp.data.pathList
	end
	
	local navpathTab = iup.vbox {
		navcomp.com.ui:CreateList ("Path", "path", selected, BuildList);
		font = navcomp.ui.font,
		tabtitle = "Nav Paths",
		size = "1000x400"
	}
	
	function navpathTab:Reset ()
		selected.navpath = nil
	end
	
	function navpathTab:DoClose ()
	end
	
	return navpathTab
end