--[[
	Communications Dialog Definitions
]]
navcomp.com.ui = {}
dofile ("com/ui/anchorTab.lua")
dofile ("com/ui/dataTab.lua")
dofile ("com/ui/navpathTab.lua")
dofile ("com/ui/patronList.lua")

-- Undo Function Set
function navcomp.com.ui:CreateUndo (matrix, selected, tabkey)
	local selectAllButton = iup.stationbutton {title="Select All", font=navcomp.ui.font, active="YES"}
	local undoButton = iup.stationbutton {title="Undo", font=navcomp.ui.font, active="NO"}
	local undoAllButton = iup.stationbutton {title="Undo All", font=navcomp.ui.font, active="NO"}
	local undoRows = {}
	
	local undoTools = iup. hbox {
		selectAllButton,
		undoButton,
		undoAllButton,
		iup.fill {};
		expand = "YES"
	}
	
	local function CheckButtonState ()
		if #undoRows > 0 then
			undoButton.active = "YES"
			undoAllButton.active = "YES"
		else
			undoButton.active = "NO"
			undoAllButton.active = "NO"
		end
	end
	
	function undoTools:AddUndo (row)
		if not string.find (table.concat (undoRows, "|"), tostring (row)) then
			table.insert (undoRows, row)
		end
		CheckButtonState ()
	end
	
	function undoTools:RemoveUndo (row)
		-- Find row to remove
		local k
		for k=1, #undoRows do
			if undoRows [k] == row then
				table.remove (undoRows, k)
			end
		end
		CheckButtonState ()
	end
	
	function selectAllButton.action ()
		local row, key
		-- Simulate clicks of each row
		for row=1, matrix.numlin do
			matrix:click_cb (row, 1)
		end
		matrix:PaintSelectedRows ()
		CheckButtonState ()
	end
	
	function undoButton.action ()
		if #undoRows > 0 then
			local key = matrix:getcell (table.remove (undoRows, #undoRows), 1)
			selected [tabkey][key] = nil
			matrix:PaintSelectedRows ()
			CheckButtonState ()
		end
	end
	
	function undoAllButton.action ()
		selected [tabkey] = nil
		undoRows = {}
		matrix:PaintSelectedRows ()
		CheckButtonState ()
	end
	
	return undoTools
end

-- Matrix List for Displaying Data
function navcomp.com.ui:CreateList (headerName, tabkey, selected, BuildListCB)
	-- Build Path Matrix
	local spacer = string.rep (" ", 50)
	local matrix = iup.pdasubmatrix {
		numcol = 1,
		numlin = 1,
		numlin_visible = 10,
		heightdef = 15,
		expand = "YES",
		font = navcomp.ui.font,
		bgcolor = "255 10 10 10 *",
		redraw = "ALL"
	}
	
	-- Set Headers
	matrix:setcell (0, 1, headerName)
	matrix:setcell (1, 1, spacer)
	
	local undo = navcomp.com.ui:CreateUndo (matrix, selected, tabkey)
	
	local function ClearData ()
		local i
		for i=1, tonumber (matrix.numlin) do
			matrix.dellin = 1
		end
		matrix.numlin = 0
	end
	
	local list = BuildListCB ()
	local function ReloadData ()
		-- Build viewable list
		local keys = {}
		for k,v in pairs (list) do
			table.insert (keys, k)
		end
		table.sort (keys, function (a,b)
			return a:lower () < b:lower ()
		end)
		
		-- Load matrix
		ClearData ()
		local row = 0
		local path
		matrix.alignment1 = "ALEFT"
		matrix.heightdef = 15
		matrix.redraw = "ALL"
		for k,v in ipairs (keys) do
			matrix.addlin = row
			matrix.font = navcomp.ui.font
			row = row + 1
			matrix:setcell (row, 1, v)
		end
		matrix.numlin = row
	end
	
	function matrix.PaintSelectedRows (self)
		local row, key
		for row=1, self.numlin do
			key = self:getcell (row, 1)
			if key and selected [tabkey] and selected [tabkey][key] then
				self [string.format ("bgcolor%d:*", row)] = "255 150 150 150 *"
			else
				self [string.format ("bgcolor%d:*", row)] = "255 10 10 10 *"
			end
		end
	end
	
	function matrix.click_cb (self, row, col)
		-- Set all bgcolors
		selected.activeTab = tabkey
		if row > 0 then
			local key = self:getcell (row, 1)
			local item = list [key]
			if item then
				if not selected [tabkey] then selected [tabkey] = {} end
				if not selected [tabkey][key] then
					undo:AddUndo (row)
					selected [tabkey][key] = item
				else
					undo:RemoveUndo (row)
					selected [tabkey][key] = nil
				end
				self:PaintSelectedRows ()
				selected:SetState ()
			end
		end
	end
	
	local list = iup.vbox {
		matrix,
		undo;
		expand="YES"
	}
	ReloadData ()
	
	return list
end

function navcomp.com.ui:CreateUI ()
	local selected = {
		activeTab = nil,
		playerSendName = nil,
		data = nil,
		path = nil,
		anchors = nil
	}
    local sendButton = iup.stationbutton {title = "Send", font = navcomp.ui.font, active = "NO"}
    local cancelButton = iup.stationbutton {title = "Cancel", font = navcomp.ui.font}
	local resetButton = iup.stationbutton {title="Reset", font=navcomp.ui.font}

    local patronList = navcomp.com.ui:CreatePatronList (selected)
    local dataTab = navcomp.com.ui:CreateDataTab (selected)
    local navpathTab = navcomp.com.ui:CreateNavpathTab (selected)
    local anchorTab = navcomp.com.ui:CreateAnchorTab (selected)
	
	function resetButton.action ()
		navcomp.com:Close ("Communications Reset")
		patronList:Reset ()
		anchorTab:Reset ()
		dataTab:Reset ()
		navpathTab:Reset ()
	end
	
	function selected.SetState (self)
		if self.playerSendName and (self.anchors or self.data or self.path) then
			sendButton.active = "YES"
		end
	end

    local tabFrame = iup.pda_root_tabs {
        dataTab,
        navpathTab,
        anchorTab;
		font = navcomp.ui.font,
		expand = "YES"
    }

	-- Layout Content
    local pda = iup.vbox {
        iup.label {title = "Navcomp Exchange", font = navcomp.ui.font,  expand = "HORIZONTAL"},

        -- List Containers
        iup.hbox {
			iup.fill {size = 5},
            patronList,
            iup.fill {size = 10},
            tabFrame,
			iup.fill {size = 5};
            expand = "YES"
        },

        -- Button bar
        iup.hbox {
            iup.fill {},
            sendButton,
			resetButton,
            cancelButton;
            expand = "YES"
        }
    }

	-- Dialog
    local frame = iup.dialog {
	    iup.pdarootframe {
	        pda,
			expand = "YES"
		},
        font = navcomp.ui.font,
        border = 'YES',
        topmost = 'YES',
        resize = 'NO',
        maxbox = 'NO',
        minbox = 'NO',
        modal = 'NO',
        fullscreen = 'NO',
        expand = "NO",
        active = 'NO',
        menubox = 'NO',
        bgcolor = "255 10 10 10 *",
        defaultesc = cancelButton
	}
	
	local function DoClose ()
		patronList:DoClose ()
		dataTab:DoClose ()
		navpathTab:DoClose ()
		anchorTab:DoClose ()
		HideDialog (frame)
		frame.active = "NO"
	end
	
	function sendButton.action ()
		DoClose ()
		local data = {
			name = selected.playerSendName,
			type = selected.activeTab
		}
		if selected.activeTab == "data" then
			local item, v
			data.payload = {storms={}, hive={}}
			for _, item in pairs (selected.data) do
				for _, v in ipairs (item.storms) do
					table.insert (data.payload.storms, v)
				end
				for _, v in ipairs (item.hive) do
					table.insert (data.payload.hive, v)
				end
			end
		elseif selected.activeTab == "path" then
			local path
			data.payload = {}
			for _, path in pairs (selected.path) do
				table.insert (data.payload, path)
			end
		elseif selected.activeTab == "anchors" then
			local v
			data.payload = {}
			for _, v in pairs (selected.anchors) do
				table.insert (data.payload, v)
			end
		end
		navcomp.com:RequestConnection (data)
	end

	function cancelButton.action ()
		DoClose ()
	end

	local x = gkinterface.GetXResolution () / 3
	local y = gkinterface.GetYResolution () / 4
	ShowDialog (frame, x, y)
    frame.active = "YES"

    return frame
end

function navcomp.com.ui:CreateComApproveUI (sender)
	local acceptButton = iup.stationbutton {title="Accept"}
	local refuseButton = iup.stationbutton {title="Refuse"}
	local str = string.format ("Data Exchange Request from %s", sender)
	
	local pda = iup.pdarootframe {
		iup.vbox {
			iup.label {title=str, expand="HORIZONTAL"},
			iup.label {title="Accept?", alignment="ACENTER", expand="HORIZONTAL"},
			iup.hbox {
				iup.fill {},
				acceptButton,
				refuseButton;
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
		defaultesc = refuseButton
	}
	
	acceptButton.action = function ()
		HideDialog (frame)
		frame.active = "NO"
		navcomp.com:SendAcknowledge (sender, true)
	end
	
	refuseButton.action = function ()
		HideDialog (frame)
		frame.active = "NO"
		navcomp.com:SendAcknowledge (sender, false)
	end
	
	-- Display Dialog
	ShowDialog (frame, iup.CENTER, iup.CENTER)
	frame.active = "YES"
	
	return frame
end