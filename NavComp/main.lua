--[[
	Navigational Computer
	
	Author: Keller
]]
declare ("navcomp", {})
navcomp.version = "2.1.1"
dofile ("data/data.lua")
dofile ("data/data-star.lua")
dofile ("plotter/comparators.lua")
dofile ("data/data-plotter.lua")
dofile ("util.lua")
dofile ("ui/ui.lua")
dofile ("com/com.lua")
dofile ("debug.lua")

function navcomp:None () end

function navcomp:Help ()
	navcomp:Print ("NavComp Commands")
	navcomp:Print ("-  help - Prints this list")
	navcomp:Print ("-  options - Displays Control screen")
	navcomp:Print ("-  plot - Determines reasonable safe path between 2 sectors")
	navcomp:Print ("-  save - Saves current navpath")
	navcomp:Print ("-  load - Loads previously saved navpath")
	navcomp:Print ("-  clear - Clears previously recorded storm data or hostile bot data")
	navcomp:Print ("-  reset - Resets NavComp")
	navcomp:Print ("-  evade - Toggles Evasion")
	navcomp:Print ("-  autoreload - Activates autoreload for the current navpath")
end

function navcomp:Options ()
	navcomp.ui.control:CreateUI ()
end

-- Intended as a shortcut for external plugins to set paths without worrying about particulars
function navcomp:PlotPathToSector (sector)
	navcomp:ClearActivePath ()
	navcomp:PlotPath (sector)
end

function navcomp:PlotPath (sector)
	if sector then
		if type (sector) == "string" then
			sector = navcomp.data:GetSectorIdFromName (sector)
		end
		if type (sector) == "number" then
			NavRoute.SetFinalDestination (sector)
		end
	end
	navcomp.pda:SetEvasionMode (false)
	navcomp.data:ExpireData ()
	if navcomp.data.backgroundPlot then
		if not navcomp.data.plotter or coroutine.status (navcomp.data.plotter) == "dead" then
			-- Create plotter thread
			navcomp.data.plotter = coroutine.create (navcomp.DoPlot)
		end
		
		-- Start plotter thread
		if coroutine.status (navcomp.data.plotter) == "suspended" then
			navcomp:Print ("Plotting...")
			navcomp.ui.progress.visible = "YES"
			iup.Refresh (HUD.cboxlayer)
			navcomp:RunThread ()
		end
	else
		navcomp:DoPlot ()
		navcomp:Print ("Plot Complete")
	end
end

function navcomp:SavePath (args)
	navcomp.pda:SetEvasionMode (false)
	if args and args [2] then
		navcomp.data.activePath.name = args [2]
		navcomp.data.activePath.note = args [3] or ""
		navcomp.data.activePath.autoPlot = false
		if args [4] then
			navcomp.data.activePath.autoPlot = args [4]:lower () == "true"
		end
		navcomp.pda:SetReloadMode (false)
		if args [5] then
			navcomp.pda:SetReloadMode (args [5]:lower () == "true")
		end
		navcomp:SetActivePath ()
		navcomp:SaveActivePath (navcomp.data.activePath)
		navcomp:CheckAutoPlot (navcomp.data.activePath)
	else
		local path1 = navcomp.data:Clone (navcomp.data.activePath.path)
		local path2 = GetFullPath (GetCurrentSectorid (), NavRoute.GetCurrentRoute ())
		if path2 and #path2 > 0 then
			if path1 [1] == GetCurrentSectorid () then table.remove (path1, 1) end
			table.remove (path2, 1)
		
			if not navcomp:ComparePaths (path1, path2) then
				navcomp:ClearActivePath ()
			end
			if not navcomp.data.activePath.name then
				local first = GetCurrentSectorid ()
				if first then first = AbbrLocationStr (first)
				else first = "No Sector" end
				local last = NavRoute.GetFinalDestination ()
				if last then last = AbbrLocationStr (last)
				else last = "No Sector" end
				navcomp.data.activePath.name = first .. ":" .. last
			end
			navcomp.ui:CreateUI (false)
		else
			navcomp.ui:CreateAlertUI ("No Path to Save")
		end
	end
end

function navcomp:LoadPath (args)
	if args and args [2] then
		navcomp:LoadActivePath (args [2])
	else
		navcomp.pda:SetEvasionMode (false)
		navcomp.ui:CreateUI (true)
	end
end

function navcomp:Exchange ()
	navcomp.com.ui:CreateUI ()
end

function navcomp:ClearStorms ()
	navcomp.ui:CreateClearDataUI ()
end

function navcomp:ToggleEvasionMode ()
	if not PlayerInStation () then
		navcomp.data.isEvading = not (navcomp.data.isEvading and true)
		if navcomp.data.isEvading then
			-- Determine where we are in the existing path (if any)
			navcomp:SetActivePath ()
			
			-- Start new evasion path
			NavRoute.clear ()
			navcomp:PlotEvasionPath ()
		else
			-- Reset path back to its original course
			navcomp:SetPath (navcomp.data.activePath.path)
		end
		navcomp.pda:SetEvasionMode (navcomp.data.isEvading)
	end
end

function navcomp:Reset ()
	-- Disables the current path if it's set to autoreload
	if navcomp.data.activePath.autoReload then
		navcomp:ClearActivePath ()
	end
end

function navcomp:AutoReloadCurrentPath ()
	if navcomp.data.activePath.autoReload then
		navcomp.pda:SetReloadMode (false)
	else
		navcomp.data.activePath.path = GetFullPath (GetCurrentSectorid (), NavRoute.GetCurrentRoute ())
		navcomp.pda:SetReloadMode (true)
	end
end

local commands = {
	analyze = navcomp.Analyze,
	find = navcomp.FindPath,
	line = navcomp.Line,
	jumps = navcomp.Jumps,
	metadata = navcomp.MetaData,
	segment = navcomp.Segment,
	help = navcomp.Help,
	options = navcomp.Options,
	plot = navcomp.PlotPath,
	load = navcomp.LoadPath,
	save = navcomp.SavePath,
	reset = navcomp.Reset,
	clear = navcomp.ClearStorms,
	exchange = navcomp.Exchange,
	evade = navcomp.ToggleEvasionMode,
	autoreload = navcomp.AutoReloadCurrentPath
}
function navcomp.Start (obj, args)
	if args then
		local f = commands [args [1]:lower ()] or navcomp.Help
		f (navcomp, args)
	else
		navcomp:Help ()
	end
end
RegisterUserCommand ("navcomp", navcomp.Start)
RegisterUserCommand ("nc", navcomp.Start)
RegisterUserCommand ("evade", navcomp.ToggleEvasionMode)

return navcomp