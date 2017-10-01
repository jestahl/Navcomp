--[[
	This comparator attempts to choose edge sectors
	to move around a system
	
	Note: this is comparable to the rookMove file, except
	it's trying to find paths based on locus definitions and
	not by expert determinative systems.
	
	Note to self: this algorithm could be sped up if all open ranks/files were located at start and cached.
]]

local function Check2Jump (n1, n2, s2)
	-- Check for row/col jump point for 2 jump scenario
	local sysId
	local w1 = {x=0, y=0, c1={s=0, d=0}, c2={s=0, d=0}, ok1=true, ok2=true}
	local w2 = {x=0, y=0, c1={s=0, d=0}, c2={s=0, d=0}, ok1=true, ok2=true}
	local w3 = {x=0, y=0, c1={s=0, d=0}, c2={s=0, d=0}, ok1=true, ok2=true}
	local w4 = {x=0, y=0, c1={s=0, d=0}, c2={s=0, d=0}, ok1=true, ok2=true}
	local s = {x=0, y=0}
	
	-- Get coordinates of the considered waypoint and the target
	navcomp:Yield ()
	sysId, w1.y, w1.x = SplitSectorID (n1.s)
	sysId, w2.y, w2.x = SplitSectorID (n2.s)
	sysId, s.y, s.x = SplitSectorID (s2)
	
	-- 2 Jump Scenarios
	-- Find the common point c1.
	-- Check if the path is clear from n1 to c1 and c1 to s2
	w1.c1.s = navcomp:BuildSectorId (sysId, w1.x, s.y)
	w1.c1.d = (w1.x - s.x)*(w1.x - s.x)
	w1.c2.s = navcomp:BuildSectorId (sysId, s.x, w1.y)
	w1.c2.d = (w1.y - s.y)*(w1.y - s.y)
	w2.c1.s = navcomp:BuildSectorId (sysId, w2.x, s.y)
	w2.c1.d = (w2.x - s.x)*(w2.x - s.x)
	w2.c2.s = navcomp:BuildSectorId (sysId, s.x, w2.y)
	w2.c2.d = (w2.y - s.y)*(w2.y - s.y)
	
	navcomp:Yield ()
	w1.ok1 = not (navcomp:IsPathProhibited (n1.s, w1.c1.s, true) or navcomp:IsPathProhibited (w1.c1.s, s2, true))
	w1.ok2 = not (navcomp:IsPathProhibited (n1.s, w1.c2.s, true) or navcomp:IsPathProhibited (w1.c2.s, s2, true))
	local ok1 = w1.ok1 or w1.ok2
	w2.ok1 = not (navcomp:IsPathProhibited (n1.s, w2.c1.s, true) or navcomp:IsPathProhibited (w2.c1.s, s2, true))
	w2.ok2 = not (navcomp:IsPathProhibited (n1.s, w2.c2.s, true) or navcomp:IsPathProhibited (w2.c2.s, s2, true))
	local ok2 = w2.ok1 or w2.ok2
	--print (string.format ("W1: C1 s= %s, d=%d\tC2 s=%s, d=%d\t%s", AbbrLocationStr (w1.c1.s), w1.c1.d, AbbrLocationStr (w1.c2.s), w1.c2.d, tostring (ok1)))
	--print (string.format ("W2: C1 s= %s, d=%d\tC2 s=%s, d=%d\t%s", AbbrLocationStr (w2.c1.s), w2.c1.d, AbbrLocationStr (w2.c2.s), w2.c2.d, tostring (ok2)))
	
	-- If valid, return n1
	if ok1 and (not ok2 or 
				w1.c1.d < w2.c1.d or
				w1.c1.d < w2.c2.d or
				w1.c2.d < w2.c1.d or
				w1.c2.d < w2.c2.d) then
		return n1
	end
end

local function GetNearsFars (n1)
	local sysId, x, y, nx, ny, fx, fy
	sysId, y, x = SplitSectorID (n1.s)
	nx = 1
	fx = 16
	if x > 8 then
		nx = 16
		fx = 1
	end
	ny = 1
	fy = 16
	if y > 8 then
		ny = 16
		fy = 1
	end
	
	return x, y, nx, ny, fx, fy
end

local function CheckCorridor (n)
	--[[
		Edges are defined as x=1 or 16 or y=1 or 16
		if x=1 or 16, look for a sector with the same x but with y set to 1 or 16
		that sector's edge should be free of prohibitions
	]]
	local sysId, y, x = SplitSectorID (n.s)
	local t1, t2, result
	-- Check for X Corridor
	t1 = navcomp:BuildSectorId (sysId, x, 1)
	t2 = navcomp:BuildSectorId (sysId, x, 16)
	result = not navcomp:IsPathProhibited (t1, t2, true)
	
	-- Check for Y Corridor
	t1 = navcomp:BuildSectorId (sysId, 1, y)
	t2 = navcomp:BuildSectorId (sysId, 16, y)
	return result or (not navcomp:IsPathProhibited (t1, t2, true))
end

function navcomp.plotter:Edge (n1, n2, s2, stats, area)
	local result = Check2Jump (n1, n2, s2)
	if result then return result end
	
	-- 2 Jump did not produce a choice.  See if we're on an edge
	-- then jump to it provided the edge is clear and has the lowest stress
	-- along that edge.  If 2 edges are clear with the same stress, pick
	-- the one which would provide a jump closest to the target
	
	-- Check for not edge
	-- Pick n1 if an edge, not blocked, and n2 is either: A) an edge and blocked, B) has an intersection
	-- not closer than the intersection for n1 and s2, or C) n2 is not an edge
	-- if n1 is not an edge or is an edge and blocked, reject
	if CheckCorridor (n1) then
		if not CheckCorridor (n2) then
			return n1
		end
		
		-- 2 possible intersection points
		local c1, c2
		local nx1, nx2, ny1, ny2, sx, sy, sysId
		sysId, sy, sx = SplitSectorID (s2)
		sysId, ny1, nx1 = SplitSectorID (n1.s)
		sysId, ny2, nx2 = SplitSectorID (n2.s)
		if (nx1-sx) < (ny1-sy) then
			c1 = nx1-sx
		else
			c1 = ny1-sy
		end
		if (nx2-sx) < (ny2-sy) then
			c2 = nx2-sx
		else
			c2 = ny2-sy
		end
		if c1 < c2 then
			return n1
		end
	end
end