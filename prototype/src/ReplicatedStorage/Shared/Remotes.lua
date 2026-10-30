-- Shared remotes. The server creates them; the client waits for replication.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local folder
if RunService:IsServer() then
	folder = ReplicatedStorage:FindFirstChild("NightConductorRemotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "NightConductorRemotes"
		folder.Parent = ReplicatedStorage
	end
else
	folder = ReplicatedStorage:WaitForChild("NightConductorRemotes")
end

local function get(className, name)
	local item = folder:FindFirstChild(name)
	if not item then
		item = Instance.new(className)
		item.Name = name
		item.Parent = folder
	end
	return item
end

return {
	Inspect = get("RemoteFunction", "Inspect"),
	Ask = get("RemoteFunction", "Ask"),
	Decide = get("RemoteEvent", "Decide"),
	TunnelChoice = get("RemoteEvent", "TunnelChoice"),
	Restart = get("RemoteEvent", "Restart"),
	GameEvent = get("RemoteEvent", "GameEvent"),
}
