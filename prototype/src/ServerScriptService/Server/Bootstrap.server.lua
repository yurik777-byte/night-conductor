local physicalService = script.Parent:FindFirstChild("PhysicalService")

if physicalService then
	print("[NightConductor] Bootstrap physical v8 loaded")
	require(physicalService).init()
else
	local GameService = require(script.Parent:WaitForChild("GameService"))
	print("[NightConductor] Bootstrap v7 loaded")
	GameService.init()
end
