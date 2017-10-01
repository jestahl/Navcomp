--[[
	Patron list screen for data exchange
]]
local function printtable (t, offset)
	if type (t) == "table" then
		offset = offset or ""
		for k,v in pairs (t) do
			if type (v) == "table" then
				print (string.format ("%s%s", offset, tostring (k)))
				printtable (v, offset .. "-  ")
			else
				print (string.format ("%s%s = %s", offset, tostring (k), tostring (v)))
			end
		end
	else
		print (t)
	end
end

function navcomp.com.ui:CreatePatronList (selection)
	-- Build Path Matrix
	local rowSelected = 0
	local spacer = string.rep (" ", 30)
	local matrix = iup.pdasubmatrix {
		numcol = 1,
		numlin = 1,
		numlin_visible = 10,
		heightdef = 15,
		expand = "YES",
		font = navcomp.ui.font,
		bgcolor = "255 10 10 10 *",
		redraw = "ALL",
		click_cb = function (self, row, col)
			-- Set all bgcolors
			if row > 0 then
				rowSelected = row
				selection.playerSendName = self:getcell (row, 1)
				for l=1,self.numlin do
					if l == row then
						self ["bgcolor"..l..":*"] = "255 150 150 150 *"
					else
						self ["bgcolor"..l..":*"] = "255 10 10 10 *"
					end
				end
				selection:SetState ()
			end
		end
	}
	
	-- Set Headers
	matrix:setcell (0, 1, "Name")
	matrix:setcell (1, 1, spacer)
	
	local function ClearData ()
		local i
		for i=1, tonumber (matrix.numlin) do
			matrix.dellin = 1
		end
		matrix.numlin = 0
	end
	
	local function ReloadData ()
		-- Load Data
		local i, k, v
		local charName = GetPlayerName (GetCharacterID ())
		local list = GetBarPatrons ()
		local patrons = {}
		
		-- Add online guildies as patrons
		for k=1, GetNumGuildMembers () do
			local id, rank, name = GetGuildMemberInfo (k)
			if name ~= charName then
				table.insert (patrons, name)
			end
		end
		
		-- Add bar patrons
		for _, k in ipairs (list) do
			--print (k)
			local name = GetPlayerName (k [1])
			local patronStr = "|" .. table.concat (patrons, "|") .. "|"
			if name ~= charName and not string.find (patronStr, "|" .. name .. "|") then
				table.insert (patrons, name)
			end
		end
		
--		print ("Patrons:")
--		printtable (patrons)
		table.sort (patrons, function (a,b)
			return GetPlayerName (a):lower () < GetPlayerName (b):lower ()
		end)
		
		ClearData ()
		local row = 0
		matrix.alignment1 = "ALEFT"
		matrix.heightdef = 15
		matrix.redraw = "ALL"
		for k, name in ipairs (patrons) do
			matrix.addlin = row
			matrix.font = navcomp.ui.font
			row = row + 1
			matrix:setcell (row, 1, name)
		end
		matrix.numlin = row
	end
	
	local events = {}
	function events:OnEvent (event, data)
		if event == "" then
			ReloadData ()
		end
	end
	
	local patronList = iup.vbox {
		iup.label {title = "", font = navcomp.ui.font},
		iup.label {title = "To Whom", font = navcomp.ui.font, fgcolor = navcomp.ui.fgcolor},
		matrix;
		expand = "VERTICAL"
	}
	
	function patronList:Reset ()
		rowSelected = 0
		selection.playerSendName = nil
	end
	
	function patronList:DoClose ()
--		UnregisterEvent (events, "UPDATE_CHARACTER_LIST")
	end
	ReloadData ()
--	RegisterEvent (events, "UPDATE_CHARACTER_LIST")
	
	return patronList
end