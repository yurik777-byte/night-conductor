-- Builds the prototype station, train, booth and passenger models from primitives.
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local WorldBuilder = {}

local WORLD_NAME = "NightConductorWorld"
local PASSENGER_FOLDER = "NightConductorPassengers"

WorldBuilder.spawnCFrame = CFrame.lookAt(Vector3.new(-8, 3, -18), Vector3.new(-8, 3, -12))
WorldBuilder.boothCFrame = CFrame.lookAt(Vector3.new(-8, 4, -12), Vector3.new(-8, 4, -18))
WorldBuilder.trainDoorCFrame = CFrame.lookAt(Vector3.new(-8, 4, -4.8), Vector3.new(-8, 4, 0))
WorldBuilder.exitCFrame = CFrame.lookAt(Vector3.new(20, 4, -18), Vector3.new(30, 4, -18))
WorldBuilder.startCFrame = CFrame.lookAt(Vector3.new(20, 4, -12), Vector3.new(-8, 4, -12))

local function part(parent, name, size, cframe, color, material, transparency, canCollide)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Anchored = true
	p.CanCollide = canCollide ~= false
	p.Color = color or Color3.fromRGB(180, 180, 180)
	p.Material = material or Enum.Material.SmoothPlastic
	p.Transparency = transparency or 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function cylinder(parent, name, size, cframe, color, material)
	local p = part(parent, name, size, cframe, color, material or Enum.Material.Metal, 0, false)
	p.Shape = Enum.PartType.Cylinder
	return p
end

local function addPointLight(parent, color, brightness, range)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = brightness
	light.Range = range
	light.Shadows = false
	light.Parent = parent
	return light
end

local function billboard(parent, text, offset, size)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = size or UDim2.fromOffset(360, 100)
	gui.StudsOffset = offset or Vector3.new(0, 2.5, 0)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(255, 220, 150)
	label.TextStrokeTransparency = 0.6
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui
	return gui
end

local function buildLighting()
	Lighting.ClockTime = 0
	Lighting.Brightness = 1.4
	Lighting.Ambient = Color3.fromRGB(18, 22, 34)
	Lighting.OutdoorAmbient = Color3.fromRGB(25, 32, 50)
	Lighting.FogEnd = 220
	Lighting.FogColor = Color3.fromRGB(10, 12, 22)
	Lighting.EnvironmentDiffuseScale = 0.45
	Lighting.EnvironmentSpecularScale = 0.2

	for _, child in ipairs(Lighting:GetChildren()) do
		if child.Name == "PrototypeAtmosphere" or child.Name == "PrototypeBloom" or child.Name == "PrototypeColor" then
			child:Destroy()
		end
	end

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "PrototypeAtmosphere"
	atmosphere.Density = 0.38
	atmosphere.Haze = 2
	atmosphere.Glare = 0.15
	atmosphere.Color = Color3.fromRGB(120, 145, 190)
	atmosphere.Decay = Color3.fromRGB(70, 80, 120)
	atmosphere.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Name = "PrototypeBloom"
	bloom.Intensity = 0.45
	bloom.Size = 24
	bloom.Threshold = 0.9
	bloom.Parent = Lighting

	local color = Instance.new("ColorCorrectionEffect")
	color.Name = "PrototypeColor"
	color.TintColor = Color3.fromRGB(230, 238, 255)
	color.Contrast = 0.05
	color.Saturation = -0.08
	color.Parent = Lighting
end

local function buildTrain(world)
	local body = part(world, "TrainFloor", Vector3.new(60, 0.5, 14), CFrame.new(0, 1.25, 4), Color3.fromRGB(70, 45, 30), Enum.Material.WoodPlanks)
	body.CanCollide = true

	part(world, "TrainLeftWallA", Vector3.new(18, 6, 0.4), CFrame.new(-21, 4, -3), Color3.fromRGB(25, 70, 52), Enum.Material.Wood)
	part(world, "TrainLeftWallB", Vector3.new(34, 6, 0.4), CFrame.new(13, 4, -3), Color3.fromRGB(25, 70, 52), Enum.Material.Wood)
	part(world, "TrainRightWall", Vector3.new(60, 6, 0.4), CFrame.new(0, 4, 11), Color3.fromRGB(25, 70, 52), Enum.Material.Wood)
	part(world, "TrainEndA", Vector3.new(0.4, 6, 14), CFrame.new(-30, 4, 4), Color3.fromRGB(25, 70, 52), Enum.Material.Wood)
	part(world, "TrainEndB", Vector3.new(0.4, 6, 14), CFrame.new(30, 4, 4), Color3.fromRGB(25, 70, 52), Enum.Material.Wood)
	part(world, "TrainRoof", Vector3.new(60, 0.5, 14), CFrame.new(0, 7.25, 4), Color3.fromRGB(18, 48, 38), Enum.Material.Wood)

	for index = 1, 5 do
		local x = -24 + (index - 1) * 12
		part(world, "Window" .. index, Vector3.new(7, 3, 0.2), CFrame.new(x, 4.4, -3.24), Color3.fromRGB(130, 180, 210), Enum.Material.Glass, 0.55, false)
	end

	for _, x in ipairs({ -24, -12, 0, 12, 24 }) do
		for _, z in ipairs({ -2.8, 10.8 }) do
			cylinder(world, "Wheel", Vector3.new(0.8, 2.2, 2.2), CFrame.new(x, 1, z) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(30, 30, 30))
		end
	end

	part(world, "BrassTrimTop", Vector3.new(60, 0.2, 0.25), CFrame.new(0, 6.8, -3.2), Color3.fromRGB(190, 150, 70), Enum.Material.Metal)
	part(world, "BrassTrimBottom", Vector3.new(60, 0.2, 0.25), CFrame.new(0, 1.2, -3.2), Color3.fromRGB(190, 150, 70), Enum.Material.Metal)

	local door = part(world, "TrainDoor", Vector3.new(8, 5.5, 0.3), CFrame.new(-8, 3.75, -3.2), Color3.fromRGB(190, 150, 70), Enum.Material.Metal)
	door.Transparency = 0.35
	part(world, "TrainStep", Vector3.new(8, 0.5, 3), CFrame.new(-8, 0.55, -4.8), Color3.fromRGB(80, 60, 40), Enum.Material.Wood)

	local chimney = cylinder(world, "Chimney", Vector3.new(1.4, 2.8, 1.4), CFrame.new(-26, 9, 4) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(40, 40, 45))
	chimney.CanCollide = false

	local headlight = part(world, "Headlight", Vector3.new(1.2, 1.2, 0.4), CFrame.new(-31, 5, 4), Color3.fromRGB(255, 220, 140), Enum.Material.Neon)
	addPointLight(headlight, Color3.fromRGB(255, 210, 130), 2, 30)

	for index = 1, 5 do
		local x = -22 + (index - 1) * 10
		part(world, "Seat" .. index, Vector3.new(7, 0.5, 2.5), CFrame.new(x, 2.1, 9.5), Color3.fromRGB(110, 35, 45), Enum.Material.Fabric)
		part(world, "SeatBack" .. index, Vector3.new(7, 3, 0.4), CFrame.new(x, 3.5, 10.7), Color3.fromRGB(90, 25, 35), Enum.Material.Fabric)
	end

	for _, x in ipairs({ -20, 0, 20 }) do
		local lamp = part(world, "TrainLamp", Vector3.new(1, 0.25, 1), CFrame.new(x, 6.95, 4), Color3.fromRGB(255, 210, 140), Enum.Material.Neon)
		addPointLight(lamp, Color3.fromRGB(255, 190, 110), 1.2, 18)
	end
end

local function buildStation(world)
	part(world, "Platform", Vector3.new(90, 1, 26), CFrame.new(0, 0.5, -14), Color3.fromRGB(90, 85, 80), Enum.Material.Concrete)
	part(world, "SafetyLine", Vector3.new(90, 0.08, 0.5), CFrame.new(0, 1.05, -1.6), Color3.fromRGB(230, 190, 70), Enum.Material.Neon, 0, false)

	for _, x in ipairs({ -30, 30 }) do
		local pole = part(world, "LampPole", Vector3.new(0.5, 7, 0.5), CFrame.new(x, 4, -12), Color3.fromRGB(35, 35, 40), Enum.Material.Metal)
		pole.CanCollide = false
		local lamp = part(world, "PlatformLamp", Vector3.new(1.4, 1.4, 1.4), CFrame.new(x, 7.6, -12), Color3.fromRGB(255, 210, 140), Enum.Material.Neon)
		lamp.CanCollide = false
		addPointLight(lamp, Color3.fromRGB(255, 190, 110), 2.2, 26)
	end

	local canopy = part(world, "Canopy", Vector3.new(44, 0.5, 16), CFrame.new(-4, 10, -18), Color3.fromRGB(30, 45, 40), Enum.Material.Metal)
	canopy.CanCollide = false
	for _, x in ipairs({ -24, 16 }) do
		for _, z in ipairs({ -24, -10.5 }) do
			part(world, "CanopyPillar", Vector3.new(0.5, 9, 0.5), CFrame.new(x, 5.2, z), Color3.fromRGB(40, 40, 45), Enum.Material.Metal)
		end
	end

	local signPart = part(world, "StationSign", Vector3.new(14, 3, 0.5), CFrame.new(0, 8, -24), Color3.fromRGB(30, 40, 35), Enum.Material.Wood)
	signPart.CanCollide = false
	billboard(signPart, "STATION 0\nLAST LIGHT", Vector3.new(0, 0, 0), UDim2.fromOffset(520, 130))

	local boothSign = part(world, "BoothSign", Vector3.new(5, 1.2, 0.3), CFrame.new(-8, 5.9, -15), Color3.fromRGB(30, 40, 35), Enum.Material.Wood)
	boothSign.CanCollide = false
	billboard(boothSign, "CONDUCTOR", Vector3.new(0, 0, 0), UDim2.fromOffset(300, 70))

	local desk = part(world, "Desk", Vector3.new(7, 1.3, 2.6), CFrame.new(-8, 1.15, -15), Color3.fromRGB(80, 52, 32), Enum.Material.Wood)
	desk.CanCollide = true
	part(world, "DeskTop", Vector3.new(7.2, 0.2, 2.8), CFrame.new(-8, 1.9, -15), Color3.fromRGB(110, 75, 45), Enum.Material.Wood)
	part(world, "TicketTray", Vector3.new(2.2, 0.15, 1.2), CFrame.new(-8.8, 2.05, -14.9), Color3.fromRGB(180, 140, 60), Enum.Material.Metal)
	part(world, "Stamp", Vector3.new(0.6, 1, 0.6), CFrame.new(-6.4, 2.3, -14.9), Color3.fromRGB(120, 30, 30), Enum.Material.Metal)

	local mirrorFrame = part(world, "MirrorFrame", Vector3.new(2.2, 2.8, 0.2), CFrame.new(-10.6, 3.3, -15), Color3.fromRGB(160, 120, 55), Enum.Material.Metal)
	mirrorFrame.CanCollide = false
	local mirrorGlass = part(world, "MirrorGlass", Vector3.new(1.8, 2.4, 0.06), CFrame.new(-10.6, 3.3, -15.1), Color3.fromRGB(180, 210, 230), Enum.Material.Glass, 0.25, false)
	mirrorGlass.CanCollide = false

	local lamp = part(world, "DeskLamp", Vector3.new(0.5, 0.9, 0.5), CFrame.new(-5.6, 2.9, -15), Color3.fromRGB(255, 210, 140), Enum.Material.Neon)
	lamp.CanCollide = false
	addPointLight(lamp, Color3.fromRGB(255, 190, 110), 1.6, 16)

	local moon = part(world, "Moon", Vector3.new(34, 34, 34), CFrame.new(130, 95, -180), Color3.fromRGB(230, 235, 255), Enum.Material.Neon, 0, false)
	moon.Shape = Enum.PartType.Ball
	moon.CanCollide = false

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "ConductorSpawn"
	spawn.Size = Vector3.new(7, 1, 7)
	spawn.CFrame = CFrame.lookAt(Vector3.new(-8, 1.5, -18), Vector3.new(-8, 1.5, -12))
	spawn.Anchored = true
	spawn.CanCollide = true
	spawn.Transparency = 1
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = world
end

function WorldBuilder.build()
	local legacyBaseplate = Workspace:FindFirstChild("Baseplate")
	if legacyBaseplate and legacyBaseplate:IsA("BasePart") then
		legacyBaseplate:Destroy()
	end

	local old = Workspace:FindFirstChild(WORLD_NAME)
	if old then
		old:Destroy()
	end

	local oldPassengers = Workspace:FindFirstChild(PASSENGER_FOLDER)
	if oldPassengers then
		oldPassengers:Destroy()
	end

	local world = Instance.new("Folder")
	world.Name = WORLD_NAME

	part(world, "Baseplate", Vector3.new(260, 2, 260), CFrame.new(0, -1, 0), Color3.fromRGB(45, 48, 52), Enum.Material.Slate)
	buildStation(world)
	buildTrain(world)

	world.Parent = Workspace
	buildLighting()

	local passengers = Instance.new("Folder")
	passengers.Name = PASSENGER_FOLDER
	passengers.Parent = Workspace
end

function WorldBuilder.clearPassengers()
	local folder = Workspace:FindFirstChild(PASSENGER_FOLDER)
	if folder then
		folder:Destroy()
	end
end

local function createPassengerModel(data)
	local model = Instance.new("Model")
	model.Name = "Passenger_" .. data.id

	local skin = data.appearance.skinColor
	local shirt = data.appearance.shirtColor
	local pants = data.appearance.pantsColor
	local hat = data.appearance.hatColor

	local torso = part(model, "Torso", Vector3.new(2, 2, 1), CFrame.new(0, 3, 0), shirt, Enum.Material.Fabric, 0, false)
	model.PrimaryPart = torso
	part(model, "Head", Vector3.new(1.5, 1.5, 1.5), CFrame.new(0, 4.6, 0), skin, Enum.Material.SmoothPlastic, 0, false)
	part(model, "Hat", Vector3.new(1.7, 0.4, 1.7), CFrame.new(0, 5.5, 0), hat, Enum.Material.Fabric, 0, false)
	part(model, "LeftArm", Vector3.new(0.7, 2, 0.7), CFrame.new(-1.4, 3.1, 0), shirt, Enum.Material.Fabric, 0, false)
	part(model, "RightArm", Vector3.new(0.7, 2, 0.7), CFrame.new(1.4, 3.1, 0), shirt, Enum.Material.Fabric, 0, false)
	part(model, "LeftLeg", Vector3.new(0.8, 2, 0.8), CFrame.new(-0.5, 1.2, 0), pants, Enum.Material.Fabric, 0, false)
	part(model, "RightLeg", Vector3.new(0.8, 2, 0.8), CFrame.new(0.5, 1.2, 0), pants, Enum.Material.Fabric, 0, false)
	part(model, "LeftShoe", Vector3.new(0.9, 0.35, 1.1), CFrame.new(-0.5, 0.2, -0.15), Color3.fromRGB(35, 30, 30), Enum.Material.SmoothPlastic, 0, false)
	part(model, "RightShoe", Vector3.new(0.9, 0.35, 1.1), CFrame.new(0.5, 0.2, -0.15), Color3.fromRGB(35, 30, 30), Enum.Material.SmoothPlastic, 0, false)

	local shadowX = data.shadowWrong and 1.8 or 0
	local shadowZ = data.shadowWrong and 0.8 or 0
	local shadow = part(model, "Shadow", Vector3.new(2.4, 0.04, 1.4), CFrame.new(shadowX, -2.97, shadowZ), Color3.fromRGB(5, 5, 8), Enum.Material.SmoothPlastic, 0.55, false)
	shadow.CanCollide = false

	part(model, "LeftEye", Vector3.new(0.18, 0.18, 0.08), CFrame.new(-0.3, 4.78, -0.77), Color3.fromRGB(20, 20, 20), Enum.Material.SmoothPlastic, 0, false)
	part(model, "RightEye", Vector3.new(0.18, 0.18, 0.08), CFrame.new(0.3, 4.78, -0.77), Color3.fromRGB(20, 20, 20), Enum.Material.SmoothPlastic, 0, false)
	part(model, "Mouth", Vector3.new(0.5, 0.08, 0.08), CFrame.new(0, 4.35, -0.77), Color3.fromRGB(80, 30, 40), Enum.Material.SmoothPlastic, 0, false)

	if data.extraFinger then
		part(model, "ExtraFinger", Vector3.new(0.14, 0.45, 0.14), CFrame.new(1.72, 2.45, -0.15), skin, Enum.Material.SmoothPlastic, 0, false)
	end

	billboard(model.PrimaryPart, data.name, Vector3.new(0, 2.6, 0), UDim2.fromOffset(220, 44))

	return model
end

function WorldBuilder.spawnPassenger(data)
	local folder = Workspace:FindFirstChild(PASSENGER_FOLDER)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = PASSENGER_FOLDER
		folder.Parent = Workspace
	end

	local model = createPassengerModel(data)
	model:PivotTo(WorldBuilder.startCFrame)
	model.Parent = folder
	return model
end

function WorldBuilder.movePassenger(model, targetCFrame, duration)
	if not model or not model.PrimaryPart then
		return
	end

	local value = Instance.new("CFrameValue")
	value.Value = model:GetPivot()

	local tween = TweenService:Create(
		value,
		TweenInfo.new(duration or 1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Value = targetCFrame }
	)

	local connection = value.Changed:Connect(function()
		if model.Parent then
			model:PivotTo(value.Value)
		end
	end)

	tween:Play()
	tween.Completed:Wait()
	connection:Disconnect()
	value:Destroy()
end

function WorldBuilder.removePassenger(model)
	if model then
		model:Destroy()
	end
end

return WorldBuilder
