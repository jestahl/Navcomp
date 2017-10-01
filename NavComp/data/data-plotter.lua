--[[
	Algorithmic data for Navigational Computer
]]

-- Canned Algorithms
navcomp.plotter.DEFAULT = {
	navcomp.plotter.FinalLineStress,
	navcomp.plotter.EllipticDistance,
	navcomp.plotter.HyperbolicDistance
}

navcomp.plotter.CLUSTER = {
	navcomp.plotter.HyperbolicDistance,
	navcomp.plotter.Distance
}

navcomp.plotter.CHANNELED = {
	navcomp.plotter.FinalLineStress,
	navcomp.plotter.EllipticDistance
}

navcomp.plotter.LOOSE = {
	navcomp.plotter.Stress,
	navcomp.plotter.Distance
}

navcomp.plotter.EDGE = {
	navcomp.plotter.LineRatio,
	navcomp.plotter.EllipticDistance,
	navcomp.plotter.Stress
}

-- Star Navigation Data
navcomp.plotter.metadata = {
	{algorithm=navcomp.plotter.CHANNELED, baseStress=120, areaSize=3}, 		-- Sol II
	{algorithm=navcomp.plotter.CLUSTER,	baseStress=114, areaSize=3},			-- Betheshee
	{algorithm=navcomp.plotter.DEFAULT,	baseStress=342, areaSize=3},			-- Geira Rutilus
	{algorithm=navcomp.plotter.CLUSTER,	baseStress=676, areaSize=3},			-- Deneb
	{algorithm=navcomp.plotter.DEFAULT,	baseStress=103, areaSize=3},			-- Eo
	{algorithm=navcomp.plotter.DEFAULT,	baseStress=0, areaSize=3},				-- Cantus
	{algorithm=navcomp.plotter.DEFAULT,	baseStress=0, areaSize=3},				-- Metana
	{algorithm=navcomp.plotter.DEFAULT,	baseStress=0, areaSize=3},				-- Setalli Shinas
	{algorithm=navcomp.plotter.DEFAULT,	baseStress=155, areaSize=3},			-- Itan
	{algorithm=navcomp.plotter.DEFAULT,	baseStress=278, areaSize=3},			-- Pherona
	{algorithm=navcomp.plotter.DEFAULT,	baseStress=350, areaSize=3},			-- Artana Aquilus
	{algorithm=navcomp.plotter.DEFAULT,	baseStress=33, areaSize=3},				-- Divinia
	{algorithm=navcomp.plotter.CLUSTER,	baseStress=293, areaSize=3},			-- Jallik
	{algorithm=navcomp.plotter.DEFAULT,	baseStress=20, areaSize=3},				-- Edras
	{algorithm=navcomp.plotter.CHANNELED, baseStress=348, areaSize=3}, 		-- Verasi
	{algorithm=navcomp.plotter.DEFAULT,	baseStress=0, areaSize=3},	 			-- Pelatus
	{algorithm=navcomp.plotter.DEFAULT,	baseStress=0, areaSize=3},				-- Bractus
	{algorithm=navcomp.plotter.DEFAULT,	baseStress=514, areaSize=3},			-- Nyrius
	{algorithm=navcomp.plotter.DEFAULT,	baseStress=111, areaSize=3},			-- Dau
	{algorithm=navcomp.plotter.DEFAULT,	baseStress=0, areaSize=3},				-- Sedina
	{algorithm=navcomp.plotter.CHANNELED, baseStress=480, areaSize=3},		-- Azek
	{algorithm=navcomp.plotter.EDGE,	baseStress=0, areaSize=3},					-- Odia
	{algorithm=navcomp.plotter.DEFAULT,	baseStress=0, areaSize=3},				-- Latos
	{algorithm=navcomp.plotter.DEFAULT,	baseStress=118, areaSize=3},			-- Arta Caelestis
	{algorithm=navcomp.plotter.DEFAULT,	baseStress=0, areaSize=3},				-- Ukari
	{algorithm=navcomp.plotter.DEFAULT,	baseStress=160, areaSize=3},			-- Helios
	{algorithm=navcomp.plotter.DEFAULT,	baseStress=0, areaSize=3},				-- Initros
	{algorithm=navcomp.plotter.DEFAULT,	baseStress=93, areaSize=3},				-- Pyronis
	{algorithm=navcomp.plotter.DEFAULT,	baseStress=0, areaSize=3},				-- Rhamus
	{algorithm=navcomp.plotter.DEFAULT,	baseStress=40, areaSize=3},				-- Dantia
	{algorithm=navcomp.plotter.DEFAULT,	baseStress=0, areaSize=3}				-- Devlopia
}

-- Table for determining the algorithm list
navcomp.plotter.algorithm = {
	["+ Skip System Plot"] = function () return "skip" end,
	["+ Storm Avoidance On"] = navcomp.plotter.SetStormAvoidanceOn,
	["- Storm Avoidance Off"] = navcomp.plotter.SetStormAvoidanceOff,
	["+ Manual Avoidance On"] = navcomp.plotter.SetManualAvoidanceOn,
	["- Manual Avoidance Off"] = navcomp.plotter.SetManualAvoidanceOff,
	["+ Blockable Avoidance On"] = navcomp.plotter.SetBlockableAvoidanceOn,
	["- Blockable Avoidance Off"] = navcomp.plotter.SetBlockableAvoidanceOff,
	["+ Segment Smoothing On"] = navcomp.plotter.SetSegmentSmoothingOn,
	["- Segment Smoothing Off"] = navcomp.plotter.SetSegmentSmoothingOff,
	["Stress"] = navcomp.plotter.Stress,
	["Line Stress"] = navcomp.plotter.LineStress,
	["Final Line Stress"] = navcomp.plotter.FinalLineStress,
	["Distance"] = navcomp.plotter.Distance,
	["Hyperbolic Distance"] = navcomp.plotter.HyperbolicDistance,
	["Hyperbolic Line Distance"] = navcomp.plotter.HyperbolicLineDistance,
	["Elliptic Distance"] = navcomp.plotter.EllipticDistance,
	["Elliptic Line Distance"] = navcomp.plotter.EllipticLineDistance,
	["Final Line Distance"] = navcomp.plotter.FinalLineDistance,
	["Line Ratio"] = navcomp.plotter.LineRatio,
	["Edge"] = navcomp.plotter.Edge
}

function navcomp.plotter:GetSystemMetadataList (sysId)
	local function getFunction (f)
		local name, method
		for name, method in pairs (navcomp.plotter.algorithm) do
			if f == method then return name end
		end
	end
	
	local list = {}
	local v
	for _,v in ipairs (navcomp.plotter.metadata [sysId].algorithm) do
		table.insert (list, getFunction (v))
	end
	
	return list
end

function navcomp.plotter:GetAlgorithm (sysId, stats, area)
	return navcomp.plotter.metadata [sysId].algorithm
end