--[[
	Metadata Tab for NavComp Control Screen
]]

function navcomp.ui.control:CreateMetadataTab ()
	-- Clone metadata table
	local k, v, v1
	local metadata = {}
	local selectedSysId = nil
	local selectedAlgorithm = nil
	local selectedRow = 0
	for k,v in ipairs (navcomp.plotter.metadata) do
		table.insert (metadata, {})
		for _,v1 in pairs (v.algorithm) do
			table.insert (metadata [k], v1)
		end
	end
	
	local temp = {}
	local systemSelection = navcomp.ui:CreateSystemSelection (" ")
	
	local algorithmSelection = iup.pdasublist {
		font = navcomp.ui.font,
		dropdown = "YES",
		expand = "HORIZONTAL"
	}
	temp = {}
	for k,_ in pairs (navcomp.plotter.algorithm) do
		table.insert (temp, k)
	end
	table.sort (temp, function (a, b) return a:lower () < b:lower () end)
	algorithmSelection [1] = " "
	for k,v in ipairs (temp) do
		algorithmSelection.font = navcomp.ui.font
		algorithmSelection.fgcolor = navcomp.ui.fgcolor
		algorithmSelection [k+1] = v
	end

	local matrix = iup.pdasubmatrix {
		numcol = 1,
		numlin = 1,
		numlin_visible = 10,
		heightdef = 15,
		expand = "YES",
		scrollbar = "YES",
		usetitlewidth = "YES",
		widthdef = 120,
		font = navcomp.ui.font,
		bgcolor = "255 10 10 10 *"
	}
	
	-- Set Headers
	matrix:setcell (0, 1, "Waypoint Selection")
	matrix:setcell (1, 1, string.rep (" ", 40))
	
	function matrix:SetSelectedRow (self, row)
		-- Set all bgcolors
		selectedRow = row
		local l, bgcolor
		for l=1, self.numlin do
			bgcolor = string.format ("bgcolor%d:*", l)
			if l == row then
				self [bgcolor] = "255 150 150 150 *"
			else
				self [bgcolor] = "255 10 10 10 *"
			end
		end
	end
	
	local addButton = iup.stationbutton {title = "Add", expand = "HORIZONTAL", active = "NO"}
	local removeButton = iup.stationbutton {title = "Remove", expand = "HORIZONTAL", active = "NO"}
	local upButton = iup.stationbutton {title = "Up", expand = "HORIZONTAL", active = "NO"}
	local downButton = iup.stationbutton {title = "Down", expand = "HORIZONTAL", active = "NO"}
--	local addButton = iup.button {title = "", image = "plugins/NavComp/images/plus.png", size="32x32", alignment="ACENTER", active = "NO"}
--	local removeButton = iup.button {title = "", image = "plugins/NavComp/images/minus.png", size="32x32", alignment="ACENTER", active = "NO"}
--	local upButton = iup.button {title = "", image = "plugins/NavComp/images/up.png", size="32x32", alignment="ACENTER", active = "NO"}
--	local downButton = iup.button {title = "", image = "plugins/NavComp/images/down.png", size="32x32", alignment="ACENTER", active = "NO"}
	
	local systemMetadata = iup.hbox {
		matrix,
		iup.vbox {
			addButton,
			removeButton,
			upButton,
			downButton;
			expand = "VERTICAL"
		};
		expand = "YES"
	}
	
	function systemMetadata:SetButtonState ()
		addButton.active = "NO"
		removeButton.active = "NO"
		upButton.active = "NO"
		downButton.active = "NO"
		if selectedAlgorithm and selectedSysId  then
			addButton.active = "YES"
		end
		if selectedRow > 0 then
			removeButton.active = "YES"
		end
		if selectedRow > 1 then
			upButton.active = "YES"
		end
		if selectedRow > 0 and selectedRow < #metadata [selectedSysId] then
			downButton.active = "YES"
		end
	end

	function systemMetadata:GetSystemMetadataList (sysId)
		local function getFunction (f)
			local name, method
			for name, method in pairs (navcomp.plotter.algorithm) do
				if f == method then return name end
			end
		end
		
		local list = {}
		local v
		for _,v in ipairs (metadata [sysId]) do
			table.insert (list, getFunction (v))
		end

		return list
	end
	
	local metadataTab = iup.pdasubframe_nomargin {
		iup.hbox {
			iup.fill {size = 5},
			iup.vbox {
				iup.fill {size = 5},
				iup.label {title = "Determine Plotter Logic", expand = "HORIZONTAL"},
				iup.fill {size = 5},
				iup.hbox {
					iup.vbox {
						iup.label {title = "System", fgcolor=navcomp.ui.fgcolor, expand = "HORIZONTAL"},
						systemSelection
					},
					iup.vbox {
						iup.label {title = "Algorithm", fgcolor=navcomp.ui.fgcolor, expand = "HORIZONTAL"},
						algorithmSelection
					};
				},
				systemMetadata;
				expand = "YES"
			};
			expand = "YES"
		};
		tabtitle = "Metadata",
		font = navcomp.ui.font,
		fgcolor = navcomp.ui.fgcolor,
		expand = "YES",
		bgcolor = "255 10 10 10 *"
	}
	
	function metadataTab:Initialize ()
		temp = {}
		for k,_ in pairs (navcomp.plotter.algorithm) do
			table.insert (temp, k)
		end
		table.sort (temp, function (a, b) return a:lower () < b:lower () end)
		algorithmSelection [1] = " "
		for k,v in ipairs (temp) do
			algorithmSelection.font = navcomp.ui.font
			algorithmSelection.fgcolor = navcomp.ui.fgcolor
			algorithmSelection [k+1] = v
		end
	end
	
	matrix.click_cb = function (self, row, col)
		self:SetSelectedRow (self, row)
		return systemMetadata:SetButtonState ()
	end
	
	function addButton:action ()
		if selectedAlgorithm then
			table.insert (metadata [selectedSysId], selectedAlgorithm)
			metadataTab:ReloadData ()
			return systemMetadata:SetButtonState ()
		end
	end
	
	function removeButton:action ()
		if selectedRow > 0 then
			local last = #metadata [selectedSysId]
			local index = selectedRow
			while index < last do
				metadata [selectedSysId][index] = metadata [selectedSysId][index+1]
				index = index + 1
			end
			metadata [selectedSysId][last] = nil
			selectedRow = 0
			metadataTab:ReloadData ()
			return systemMetadata:SetButtonState ()
		end
	end
	
	function upButton:action ()
		if selectedRow > 1 then
			local temp = metadata [selectedSysId][selectedRow-1]
			metadata [selectedSysId][selectedRow-1] = metadata [selectedSysId][selectedRow]
			metadata [selectedSysId][selectedRow] = temp
			metadataTab:ReloadData ()
			matrix:SetSelectedRow (matrix, selectedRow-1)
			return systemMetadata:SetButtonState ()
		end
	end
	
	function downButton:action ()
		if selectedRow < #metadata [selectedSysId] then
			local temp = metadata [selectedSysId][selectedRow+1]
			metadata [selectedSysId][selectedRow+1] = metadata [selectedSysId][selectedRow]
			metadata [selectedSysId][selectedRow] = temp
			metadataTab:ReloadData ()
			matrix:SetSelectedRow (matrix, selectedRow+1)
			return systemMetadata:SetButtonState ()
		end
	end

	function metadataTab:ClearData ()
		local i
		for i=1, tonumber (matrix.numlin) do
			matrix.dellin = 1
		end
	end
	
	function metadataTab:ReloadData ()
		metadataTab:ClearData ()
		if selectedSysId then
			local k, v
			local row = 0
			matrix.expand = "YES"
			matrix.alignment1 = "ALEFT"
			matrix.heightdef = 15
			matrix.widthdef = 120
			for _,v in ipairs (systemMetadata:GetSystemMetadataList (selectedSysId)) do
				matrix.addlin = row
				matrix.font = navcomp.ui.font
				row = row + 1
				matrix:setcell (row, 1, v)
			end
			matrix.numlin = row
			matrix.redraw = "ALL"
		end
		iup.Refresh (matrix)
	end
	
	function metadataTab:GetData ()
		return metadata
	end
	
	function systemSelection:action (text, index, state)
		selectedRow = 0
		if state == 1 and index > 1 then
			if text ~= " " then
				selectedSysId = navcomp.data.systems [text]
			else
				selectedSysId = nil
			end
			metadataTab:ReloadData ()
			return systemMetadata:SetButtonState ()
		elseif index < 2 then
			selectedSysId = nil
			metadataTab:ReloadData ()
			return systemMetadata:SetButtonState ()
		end
	end
	
	function algorithmSelection:action (text, index, state)
		if state == 1 and index > 1 then
			selectedAlgorithm = navcomp.plotter.algorithm [text]
		else
			selectedAlgorithm = nil
		end
		return systemMetadata:SetButtonState ()
	end
	
	return metadataTab
end