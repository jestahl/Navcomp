--[[
	Tab for managing encounter data of bots and storms
]]

function navcomp.com.ui:CreateDataTab (selected)
	local function BuildList ()
		-- Load Data
		local list = {}
		local k, v, sysId, x, y, name
		navcomp.data:ExpireData ()
		for k, v in pairs (navcomp.data.navigation) do
			sysId = SplitSectorID (k)
			name = SystemNames [sysId]
			if v.storm then
				list [name] = list [name] or {storms = {}, hive = {}}
				table.insert (list [name].storms, k)
			end
			if v.bot then
				list [name] = list [name] or {storms = {}, hive = {}}
				table.insert (list [name].hive, k)
			end
		end
		
		return list
	end
	
	local dataTab = iup.vbox {
		navcomp.com.ui:CreateList ("System", "data", selected, BuildList);
		font = navcomp.ui.font,
		tabtitle = "Data",
		size = "1000x400"
	}
	
	function dataTab:Reset ()
		selected.data = nil
	end
	
	function dataTab:DoClose ()
	end
	
	return dataTab
end