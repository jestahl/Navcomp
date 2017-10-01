--[[
	Tab for Anchor data
]]

function navcomp.com.ui:CreateAnchorTab (selected)
	local function BuildList ()
		local list = {}
		local sectorId, data
		for sectorId, data in pairs (navcomp.data.navigation) do
			if data.anchors then
				list [LocationStr (tonumber (sectorId))] = {sectorId=sectorId, anchors=data.anchors}
			end
		end
		
		return list
	end
	
	local anchorTab = iup.vbox {
		navcomp.com.ui:CreateList ("Sector", "anchors", selected, BuildList);
		font = navcomp.ui.font,
		tabtitle = "Anchors",
		size = "1000x400"
	}
	
	function anchorTab:Reset ()
		selected.anchors = nil
	end
	
	function anchorTab:DoClose ()
	end
	
	return anchorTab
end