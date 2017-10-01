--[[
	Option Data Modifiers
	
	Defines performance options selectable for individual systems
	]]
	
function navcomp.plotter:SetSegmentSmoothingOn ()
	navcomp.data.useSegmentSmoothing = true
	navcomp.data.isOptionDataChanged = true
end

function navcomp.plotter:SetSegmentSmoothingOff ()
	navcomp.data.useSegmentSmoothing = false
	navcomp.data.isOptionDataChanged = true
end

function navcomp.plotter:SetStormAvoidanceOn ()
	navcomp.data.avoidStormSectors = true
	navcomp.data.isOptionDataChanged = true
end

function navcomp.plotter:SetStormAvoidanceOff ()
	navcomp.data.avoidStormSectors = false
	navcomp.data.isOptionDataChanged = true
end

function navcomp.plotter:SetManualAvoidanceOn ()
	navcomp.data.avoidManualSectors = true
	navcomp.data.isOptionDataChanged = true
end

function navcomp.plotter:SetManualAvoidanceOff ()
	navcomp.data.avoidManualSectors = false
	navcomp.data.isOptionDataChanged = true
end

function navcomp.plotter:SetBlockableAvoidanceOn ()
	navcomp.data.avoidBlockableSectors = true
	navcomp.data.isOptionDataChanged = true
end

function navcomp.plotter:SetBlockableAvoidanceOff ()
	navcomp.data.avoidBlockableSectors = false
	navcomp.data.isOptionDataChanged = true
end
