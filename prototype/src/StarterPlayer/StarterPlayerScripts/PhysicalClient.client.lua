-- v8 physical slice client: first-person vestibule, props, documents, mirror, magnifier, stamps.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local function new(className, props, children)
	local instance = Instance.new(className)
	for key, value in pairs(props or {}) do
		instance[key] = value
	end
	for _, child in ipairs(children or {}) do
		child.Parent = instance
	end
	return instance
end

local function corner(instance, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = instance
	return c
end

local function stroke(instance, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.fromRGB(180, 150, 90)
	s.Thickness = thickness or 1.5
	s.Transparency = transparency or 0.2
	s.Parent = instance
	return s
end

local gui = new("ScreenGui", {
	Name = "NightConductorPhysicalUI",
	ResetOnSpawn = false,
	IgnoreGuiInset = false,
	DisplayOrder = 50,
})
gui.Parent = playerGui

local taskFrame = new("Frame", {
	Name = "TaskBar",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 12),
	Size = UDim2.fromOffset(680, 54),
	BackgroundColor3 = Color3.fromRGB(14, 22, 20),
	BackgroundTransparency = 0.08,
	BorderSizePixel = 0,
})
corner(taskFrame, 8)
stroke(taskFrame, Color3.fromRGB(150, 120, 60), 1.2, 0.3)
taskFrame.Parent = gui

local taskLabel = new("TextLabel", {
	Size = UDim2.new(1, -20, 1, 0),
	Position = UDim2.fromOffset(10, 0),
	BackgroundTransparency = 1,
	Text = "ОЖИДАНИЕ ПАССАЖИРА",
	TextColor3 = Color3.fromRGB(255, 232, 180),
	Font = Enum.Font.GothamBold,
	TextSize = 16,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Center,
	TextYAlignment = Enum.TextYAlignment.Center,
})
taskLabel.Parent = taskFrame

local nameLabel = new("TextLabel", {
	Position = UDim2.fromOffset(22, 18),
	Size = UDim2.fromOffset(420, 26),
	BackgroundTransparency = 1,
	Text = "",
	TextColor3 = Color3.fromRGB(255, 225, 165),
	Font = Enum.Font.GothamBlack,
	TextSize = 22,
	TextXAlignment = Enum.TextXAlignment.Left,
})
nameLabel.Parent = gui

local metaLabel = new("TextLabel", {
	Position = UDim2.fromOffset(22, 44),
	Size = UDim2.fromOffset(520, 18),
	BackgroundTransparency = 1,
	Text = "",
	TextColor3 = Color3.fromRGB(165, 190, 180),
	Font = Enum.Font.Gotham,
	TextSize = 13,
	TextXAlignment = Enum.TextXAlignment.Left,
})
metaLabel.Parent = gui

local progressLabel = new("TextLabel", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -22, 0, 22),
	Size = UDim2.fromOffset(120, 22),
	BackgroundTransparency = 1,
	Text = "",
	TextColor3 = Color3.fromRGB(255, 220, 150),
	Font = Enum.Font.GothamBold,
	TextSize = 15,
	TextXAlignment = Enum.TextXAlignment.Right,
})
progressLabel.Parent = gui

local crosshair = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(4, 4),
	BackgroundColor3 = Color3.fromRGB(255, 245, 220),
	BorderSizePixel = 0,
	BackgroundTransparency = 0.25,
})
corner(crosshair, 2)
crosshair.Parent = gui

local hintBar = new("TextLabel", {
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 22, 1, -10),
	Size = UDim2.fromOffset(620, 20),
	BackgroundTransparency = 1,
	Text = "E — взаимодействие   ·   1–5 — инструменты",
	TextColor3 = Color3.fromRGB(180, 200, 190),
	Font = Enum.Font.Gotham,
	TextSize = 13,
	TextXAlignment = Enum.TextXAlignment.Left,
})
hintBar.Parent = gui

local contextFrame = new("Frame", {
	Name = "Context",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -42),
	Size = UDim2.fromOffset(430, 38),
	BackgroundColor3 = Color3.fromRGB(12, 18, 16),
	BackgroundTransparency = 0.05,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 25,
})
corner(contextFrame, 8)
stroke(contextFrame, Color3.fromRGB(255, 205, 90), 1.5, 0.25)
contextFrame.Parent = gui

local contextLabel = new("TextLabel", {
	Size = UDim2.new(1, -16, 1, 0),
	Position = UDim2.fromOffset(8, 0),
	BackgroundTransparency = 1,
	Text = "",
	TextColor3 = Color3.fromRGB(255, 238, 205),
	Font = Enum.Font.GothamBold,
	TextSize = 16,
	TextXAlignment = Enum.TextXAlignment.Center,
	TextYAlignment = Enum.TextYAlignment.Center,
	ZIndex = 26,
})
contextLabel.Parent = contextFrame

-- Toast
local toast = new("Frame", {
	Name = "Toast",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 78),
	Size = UDim2.fromOffset(660, 56),
	BackgroundColor3 = Color3.fromRGB(12, 18, 16),
	BackgroundTransparency = 0.06,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 20,
})
corner(toast, 8)
local toastStroke = stroke(toast, Color3.fromRGB(90, 190, 120), 1.5, 0.15)
toast.Parent = gui

local toastLabel = new("TextLabel", {
	Size = UDim2.new(1, -24, 1, -8),
	Position = UDim2.fromOffset(12, 4),
	BackgroundTransparency = 1,
	Text = "",
	TextColor3 = Color3.fromRGB(230, 240, 220),
	Font = Enum.Font.Gotham,
	TextSize = 14,
	TextWrapped = true,
	TextYAlignment = Enum.TextYAlignment.Center,
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = 21,
})
toastLabel.Parent = toast

-- Paper document view
local paperOverlay = new("Frame", {
	Name = "PaperOverlay",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(5, 8, 10),
	BackgroundTransparency = 0.45,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 40,
})
paperOverlay.Parent = gui

local paperCard = new("Frame", {
	Name = "Paper",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.66, 0.78),
	BackgroundColor3 = Color3.fromRGB(242, 233, 210),
	BorderSizePixel = 0,
	ZIndex = 41,
})
corner(paperCard, 6)
stroke(paperCard, Color3.fromRGB(120, 95, 55), 2, 0.1)
paperCard.Parent = paperOverlay

local paperTitle = new("TextLabel", {
	Position = UDim2.fromOffset(24, 16),
	Size = UDim2.new(1, -48, 0, 26),
	BackgroundTransparency = 1,
	Text = "БИЛЕТ",
	TextColor3 = Color3.fromRGB(90, 55, 25),
	Font = Enum.Font.GothamBlack,
	TextSize = 22,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 42,
})
paperTitle.Parent = paperCard

local paperText = new("TextLabel", {
	Position = UDim2.fromOffset(24, 54),
	Size = UDim2.new(1, -48, 1, -100),
	BackgroundTransparency = 1,
	Text = "",
	TextColor3 = Color3.fromRGB(42, 34, 24),
	Font = Enum.Font.Gotham,
	TextSize = 19,
	TextWrapped = true,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 42,
})
paperText.Parent = paperCard

local paperHint = new("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -12),
	Size = UDim2.new(1, -48, 0, 18),
	BackgroundTransparency = 1,
	Text = "E — закрыть",
	TextColor3 = Color3.fromRGB(120, 95, 60),
	Font = Enum.Font.Gotham,
	TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = 42,
})
paperHint.Parent = paperCard

-- Lens
local lens = new("Frame", {
	Name = "Lens",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(360, 360),
	BackgroundTransparency = 1,
	Visible = false,
	ZIndex = 15,
})
corner(lens, 180)
local lensStroke = stroke(lens, Color3.fromRGB(8, 8, 8), 26, 0.05)
lensStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
local lensInner = new("UIStroke", {
	Color = Color3.fromRGB(255, 210, 120),
	Thickness = 2,
	Transparency = 0.25,
})
lensInner.Parent = lens
lens.Parent = gui

-- Mirror view
local mirrorOverlay = new("Frame", {
	Name = "MirrorOverlay",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(380, 460),
	BackgroundColor3 = Color3.fromRGB(18, 22, 24),
	BorderSizePixel = 0,
	Visible = false,
	ClipsDescendants = true,
	ZIndex = 18,
})
corner(mirrorOverlay, 180)
stroke(mirrorOverlay, Color3.fromRGB(190, 190, 200), 8, 0.1)
mirrorOverlay.Parent = gui

local mirrorViewport = new("ViewportFrame", {
	Name = "View",
	Position = UDim2.fromOffset(16, 16),
	Size = UDim2.new(1, -32, 1, -56),
	BackgroundColor3 = Color3.fromRGB(6, 8, 10),
	Ambient = Color3.fromRGB(150, 150, 150),
	LightColor = Color3.fromRGB(255, 240, 220),
	LightDirection = Vector3.new(-1, -1, -1),
	ZIndex = 19,
})
mirrorViewport.Parent = mirrorOverlay

local mirrorWorld = new("WorldModel", {})
mirrorWorld.Parent = mirrorViewport
local mirrorCamera = new("Camera", {
	CFrame = CFrame.lookAt(Vector3.new(0, 3.2, 8), Vector3.new(0, 2.6, 0)),
})
mirrorCamera.Parent = mirrorViewport
mirrorViewport.CurrentCamera = mirrorCamera

local mirrorCaption = new("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -10),
	Size = UDim2.new(1, -40, 0, 24),
	BackgroundTransparency = 1,
	Text = "ЗЕРКАЛО",
	TextColor3 = Color3.fromRGB(200, 210, 210),
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = 20,
})
mirrorCaption.Parent = mirrorOverlay

local mirrorHint = new("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.new(1, -60, 0, 60),
	BackgroundTransparency = 1,
	Text = "",
	TextColor3 = Color3.fromRGB(220, 225, 220),
	Font = Enum.Font.Gotham,
	TextSize = 15,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = 20,
	Visible = false,
})
mirrorHint.Parent = mirrorOverlay

-- Result
local resultOverlay = new("Frame", {
	Name = "ResultOverlay",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(5, 8, 10),
	BackgroundTransparency = 0.25,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 60,
})
resultOverlay.Parent = gui

local resultCard = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.5, 0.72),
	BackgroundColor3 = Color3.fromRGB(22, 32, 30),
	BorderSizePixel = 0,
	ZIndex = 61,
})
corner(resultCard, 14)
stroke(resultCard, Color3.fromRGB(150, 120, 60), 2, 0.2)
resultCard.Parent = resultOverlay

local resultTitle = new("TextLabel", {
	Position = UDim2.fromOffset(20, 18),
	Size = UDim2.new(1, -40, 0, 34),
	BackgroundTransparency = 1,
	Text = "СМЕНА ОКОНЧЕНА",
	TextColor3 = Color3.fromRGB(255, 225, 160),
	Font = Enum.Font.GothamBlack,
	TextSize = 26,
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = 62,
})
resultTitle.Parent = resultCard

local resultStars = new("TextLabel", {
	Position = UDim2.fromOffset(20, 58),
	Size = UDim2.new(1, -40, 0, 40),
	BackgroundTransparency = 1,
	Text = "★★★",
	TextColor3 = Color3.fromRGB(255, 210, 90),
	Font = Enum.Font.GothamBlack,
	TextSize = 30,
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = 62,
})
resultStars.Parent = resultCard

local resultStats = new("TextLabel", {
	Position = UDim2.fromOffset(28, 110),
	Size = UDim2.new(1, -56, 0, 120),
	BackgroundTransparency = 1,
	Text = "",
	TextColor3 = Color3.fromRGB(215, 225, 210),
	Font = Enum.Font.Gotham,
	TextSize = 16,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 62,
})
resultStats.Parent = resultCard

local resultPayout = new("TextLabel", {
	Position = UDim2.fromOffset(20, 238),
	Size = UDim2.new(1, -40, 0, 32),
	BackgroundTransparency = 1,
	Text = "+0 Искр",
	TextColor3 = Color3.fromRGB(255, 220, 140),
	Font = Enum.Font.GothamBold,
	TextSize = 22,
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = 62,
})
resultPayout.Parent = resultCard

local restartButton = new("TextButton", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -22),
	Size = UDim2.new(0.7, 0, 0, 44),
	BackgroundColor3 = Color3.fromRGB(115, 85, 40),
	BorderSizePixel = 0,
	Text = "ЕЩЁ РЕЙС",
	TextColor3 = Color3.fromRGB(255, 240, 215),
	Font = Enum.Font.GothamBold,
	TextSize = 16,
	ZIndex = 62,
})
corner(restartButton, 8)
restartButton.Parent = resultCard

-- State
local currentData = nil
local currentNpc = nil
local currentIndex = 0
local currentTotal = 0
local tutorialActive = false
local paperOpen = false
local paperOpenedAt = 0
local mirrorOpen = false
local mirrorBuildKey = nil
local zoomed = false
local stampBusy = false
local readTicket = false
local readPassport = false
local toolsById = {}
local props = {}
local hiddenProps = {}
local handHighlight = nil
local interactables = {}
local interactableByProp = {}
local currentInteractable = nil
local lastContextAt = 0

local function showToast(text, kind)
	toastLabel.Text = text
	toast.BackgroundColor3 = kind == "bad" and Color3.fromRGB(45, 18, 22) or (kind == "good" and Color3.fromRGB(18, 45, 32) or Color3.fromRGB(18, 24, 22))
	toastStroke.Color = kind == "bad" and Color3.fromRGB(220, 100, 100) or (kind == "good" and Color3.fromRGB(90, 190, 120) or Color3.fromRGB(160, 130, 70))
	toast.Visible = true
	local token = (toast:GetAttribute("Token") or 0) + 1
	toast:SetAttribute("Token", token)
	task.delay(3.2, function()
		if toast:GetAttribute("Token") == token then
			toast.Visible = false
		end
	end)
end

local function setTask(text)
	taskLabel.Text = text
end

local function setPapers()
	if not currentData then
		paperTitle.Text = "ДОКУМЕНТЫ"
		paperText.Text = "Пассажира ещё нет."
		return
	end
	if paperTitle.Text == "ПАСПОРТ" then
		paperTitle.Text = "ПАСПОРТ"
		paperText.Text = table.concat({
			"ИМЯ: " .. currentData.name,
			"ВОЗРАСТ: " .. tostring(currentData.age),
			"№ ПАСПОРТА: " .. currentData.passport.number,
			"МЕСТО РОЖДЕНИЯ: " .. currentData.passport.origin,
			"",
			"ФОТО: " .. currentData.passport.photoHatName .. " шляпа",
			"ГЛАЗА: " .. currentData.passport.eyeColor,
			"",
			"Печать: " .. currentData.passport.seal,
		}, "\n")
	else
		paperTitle.Text = "БИЛЕТ"
		paperText.Text = table.concat({
			"БИЛЕТ № " .. currentData.ticket.number,
			"КЛАСС: " .. (currentData.ticket.class == "first" and "Первый" or "Второй"),
			"МЕСТО: " .. currentData.ticket.seat,
			"",
			"ОТКУДА: Станция 0",
			"КУДА: " .. currentData.ticket.to,
			"ДАТА: " .. currentData.ticket.date,
			"ШТАМП: " .. currentData.ticket.stamp,
			"",
			"ЦЕНА: " .. tostring(currentData.ticket.price) .. " искр",
		}, "\n")
	end
end

local function openPaper(kind)
	if not currentData or paperOpen then
		return
	end
	paperOpen = true
	paperOpenedAt = os.clock()
	paperTitle.Text = kind == "passport" and "ПАСПОРТ" or "БИЛЕТ"
	setPapers()
	paperOverlay.Visible = true
	if kind == "ticket" then
		readTicket = true
	else
		readPassport = true
	end
	if tutorialActive and readTicket and readPassport then
		setTask("Документы прочитаны. Всё совпало? Возьми зелёную печать и поставь её на билет.")
	end
end

local function closePaper()
	paperOpen = false
	paperOverlay.Visible = false
end

local function raycastAhead(maxDistance)
	local cam = workspace.CurrentCamera
	if not cam then
		return nil
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = player.Character and { player.Character } or {}
	return workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * (maxDistance or 20), params)
end

local function getNpc()
	if currentNpc and currentNpc.Parent then
		return currentNpc
	end
	local folder = workspace:FindFirstChild("NightConductorPhysicalPassengers")
	if folder then
		currentNpc = folder:FindFirstChildWhichIsA("Model")
	end
	return currentNpc
end

local function isNpcPart(instance)
	local npc = getNpc()
	if not npc or not instance then
		return false
	end
	return instance:IsDescendantOf(npc)
end

local function clearHighlight()
	if handHighlight then
		handHighlight:Destroy()
		handHighlight = nil
	end
end

local function setZoom(on)
	if zoomed == on then
		return
	end
	zoomed = on
	local cam = workspace.CurrentCamera
	if cam then
		TweenService:Create(cam, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			FieldOfView = on and 28 or 70,
		}):Play()
	end
	lens.Visible = on
	if not on then
		clearHighlight()
	end
end

local function updateHandHighlight()
	if not zoomed then
		return
	end
	local result = raycastAhead(18)
	local part = result and result.Instance
	local hitHand = part and (part.Name:match("^Finger") or part.Name == "Palm" or part.Parent.Name == "RightHand")
	if hitHand then
		local hand = part.Parent
		if not handHighlight then
			handHighlight = Instance.new("Highlight")
			handHighlight.Name = "InspectionHighlight"
			handHighlight.FillTransparency = 1
			handHighlight.OutlineColor = Color3.fromRGB(255, 210, 110)
			handHighlight.OutlineTransparency = 0.1
			handHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			handHighlight.Parent = hand
		end
	else
		clearHighlight()
	end
end

local function rebuildMirror(force)
	if not mirrorOpen then
		return
	end
	local result = raycastAhead(20)
	local aimed = result and isNpcPart(result.Instance)
	local source = ReplicatedStorage:FindFirstChild("NightConductorReflection")
	local key = tostring(aimed) .. ":" .. tostring(source ~= nil) .. ":" .. tostring(getNpc())
	if not force and mirrorBuildKey == key then
		return
	end
	mirrorBuildKey = key

	for _, child in ipairs(mirrorWorld:GetChildren()) do
		child:Destroy()
	end

	if not aimed then
		mirrorHint.Text = "Наведи зеркало на пассажира."
		mirrorHint.Visible = true
		return
	end
	if source then
		local clone = source:Clone()
		clone.Parent = mirrorWorld
		mirrorHint.Visible = false
	else
		mirrorHint.Text = "В зеркале — пусто."
		mirrorHint.Visible = true
	end
end

local function setMirror(on)
	if mirrorOpen == on then
		return
	end
	mirrorOpen = on
	mirrorOverlay.Visible = on
	if on then
		mirrorBuildKey = nil
		rebuildMirror(true)
		setTask("Зеркало поднято. Наведи его на пассажира.")
	else
		mirrorHint.Visible = false
	end
end

local function stampLabelOnTicket(decision)
	local ticket = props.Ticket
	if not ticket then
		return
	end
	local surface = ticket:FindFirstChildOfClass("SurfaceGui")
	if not surface then
		return
	end
	local old = surface:FindFirstChild("StampMark")
	if old then
		old:Destroy()
	end
	local mark = new("TextLabel", {
		Name = "StampMark",
		Position = UDim2.fromScale(0.38, 0.42),
		Size = UDim2.fromScale(0.6, 0.3),
		Rotation = -12,
		BackgroundTransparency = 1,
		Text = decision == "admit" and "ПРОПУСТИТЬ" or "ОТКАТАТЬ",
		TextColor3 = decision == "admit" and Color3.fromRGB(30, 110, 60) or Color3.fromRGB(150, 35, 45),
		Font = Enum.Font.GothamBlack,
		TextScaled = true,
		ZIndex = 2,
	})
	mark.Parent = surface
end

local function tryStamp(decision)
	if stampBusy or not currentData then
		return
	end
	local result = raycastAhead(14)
	local part = result and result.Instance
	local hitDocument = part and (part.Name == "Ticket" or part.Name == "Passport")
	if not hitDocument or not result or result.Distance > 12 then
		showToast("Подойди к документам и наведи печать на билет.", "info")
		return
	end
	stampBusy = true
	stampLabelOnTicket(decision)
	showToast(decision == "admit" and "Печать: ПРОПУСТИТЬ" or "Печать: ОТКАТАТЬ", "info")
	Remotes.PhysicalDecide:FireServer(decision)
end

-- Tools
local function makeHandle(size, color, material)
	local handle = new("Part", {
		Name = "Handle",
		Size = size,
		Color = color,
		Material = material or Enum.Material.SmoothPlastic,
		CanCollide = false,
		Massless = true,
		CastShadow = false,
		Anchored = false,
	})
	return handle
end

local function newTool(name, handle)
	local tool = new("Tool", {
		Name = name,
		RequiresHandle = true,
		CanBeDropped = false,
	})
	handle.Parent = tool
	return tool
end

local function giveTool(kind)
	if toolsById[kind] then
		return
	end
	local backpack = player:FindFirstChild("Backpack") or player:WaitForChild("Backpack", 5)
	if not backpack then
		return
	end

	local tool
	if kind == "lamp" then
		local handle = makeHandle(Vector3.new(0.36, 0.5, 0.36), Color3.fromRGB(150, 120, 60), Enum.Material.Metal)
		local light = new("PointLight", {
			Color = Color3.fromRGB(255, 220, 160),
			Brightness = 2.4,
			Range = 22,
			Shadows = false,
			Enabled = false,
		})
		light.Parent = handle
		tool = newTool("Фонарь", handle)
		tool.Equipped:Connect(function()
			light.Enabled = true
		end)
		tool.Unequipped:Connect(function()
			light.Enabled = false
		end)
	elseif kind == "mirror" then
		local handle = makeHandle(Vector3.new(0.5, 0.7, 0.06), Color3.fromRGB(160, 165, 175), Enum.Material.Metal)
		tool = newTool("Зеркало", handle)
		tool.Activated:Connect(function()
			setMirror(not mirrorOpen)
		end)
		tool.Unequipped:Connect(function()
			setMirror(false)
		end)
	elseif kind == "magnifier" then
		local handle = makeHandle(Vector3.new(0.08, 0.4, 0.4), Color3.fromRGB(150, 120, 60), Enum.Material.Metal)
		handle.Shape = Enum.PartType.Cylinder
		handle.CFrame = CFrame.Angles(0, 0, math.rad(90))
		handle.Name = "Handle"
		tool = newTool("Лупа", handle)
		tool.Activated:Connect(function()
			setZoom(not zoomed)
		end)
		tool.Unequipped:Connect(function()
			setZoom(false)
		end)
	else
		local isAdmit = kind == "admit"
		local handle = makeHandle(Vector3.new(0.26, 0.44, 0.26), isAdmit and Color3.fromRGB(40, 110, 65) or Color3.fromRGB(120, 45, 50), Enum.Material.Metal)
		tool = newTool(isAdmit and "Печать ПРОПУСТИТЬ" or "Печать ОТКАТАТЬ", handle)
		tool:SetAttribute("Decision", isAdmit and "admit" or "deny")
		tool.Activated:Connect(function()
			tryStamp(tool:GetAttribute("Decision"))
		end)
	end

	tool.Parent = backpack
	toolsById[kind] = tool
	showToast("Взято: " .. tool.Name, "info")
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:EquipTool(tool)
	end
end

local function clearTools()
	for kind, tool in pairs(toolsById) do
		tool:Destroy()
		toolsById[kind] = nil
	end
end

-- Props
local function hideProp(prop)
	if hiddenProps[prop] then
		return
	end
	local record = {}
	if prop:IsA("BasePart") then
		record[prop] = prop.Transparency
		prop.Transparency = 1
	end
	for _, child in ipairs(prop:GetDescendants()) do
		if child:IsA("BasePart") then
			record[child] = child.Transparency
			child.Transparency = 1
		elseif child:IsA("SurfaceGui") then
			record[child] = child.Enabled
			child.Enabled = false
		end
	end
	hiddenProps[prop] = record
end

local function restoreProps()
	for prop, record in pairs(hiddenProps) do
		for instance, value in pairs(record) do
			if instance:IsA("SurfaceGui") then
				instance.Enabled = value
			else
				instance.Transparency = value
			end
		end
		local prompt = prop:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			prompt.Enabled = true
		end
	end
	hiddenProps = {}
	for _, prop in pairs(props) do
		local prompt = prop:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			prompt.Enabled = true
		end
	end
	for _, entry in ipairs(interactables) do
		entry.taken = false
	end
end

local function addInteractable(prop, actionText, objectText, handler)
	if not prop then
		return
	end
	local entry = {
		prop = prop,
		action = actionText,
		object = objectText,
		handler = handler,
		taken = false,
	}
	table.insert(interactables, entry)
	interactableByProp[prop] = entry
end

local function setupProps()
	local world = workspace:WaitForChild("NightConductorPhysicalWorld", 30)
	if not world then
		return
	end
	local propFolder = world:WaitForChild("Props", 10)
	if not propFolder then
		return
	end
	props.Lamp = propFolder:FindFirstChild("Lamp")
	props.Mirror = propFolder:FindFirstChild("Mirror")
	props.Magnifier = propFolder:FindFirstChild("Magnifier")
	props.StampAdmit = propFolder:FindFirstChild("StampAdmit")
	props.StampDeny = propFolder:FindFirstChild("StampDeny")
	props.Ticket = propFolder:FindFirstChild("Ticket")
	props.Passport = propFolder:FindFirstChild("Passport")

	local function take(kind, prop)
		if toolsById[kind] then
			return
		end
		local entry = interactableByProp[prop]
		if entry then
			entry.taken = true
		end
		hideProp(prop)
		giveTool(kind)
	end

	addInteractable(props.Lamp, "Взять", "Фонарь", function()
		take("lamp", props.Lamp)
	end)
	addInteractable(props.Mirror, "Взять", "Зеркало", function()
		take("mirror", props.Mirror)
	end)
	addInteractable(props.Magnifier, "Взять", "Лупа", function()
		take("magnifier", props.Magnifier)
	end)
	addInteractable(props.StampAdmit, "Взять", "Печать «ПРОПУСТИТЬ»", function()
		take("admit", props.StampAdmit)
	end)
	addInteractable(props.StampDeny, "Взять", "Печать «ОТКАТАТЬ»", function()
		take("deny", props.StampDeny)
	end)
	addInteractable(props.Ticket, "Прочитать", "Билет", function()
		openPaper("ticket")
	end)
	addInteractable(props.Passport, "Прочитать", "Паспорт", function()
		openPaper("passport")
	end)
end

local function updateContext()
	local now = os.clock()
	if now - lastContextAt < 0.1 then
		return
	end
	lastContextAt = now

	if paperOpen or resultOverlay.Visible or mirrorOpen then
		contextFrame.Visible = false
		currentInteractable = nil
		return
	end

	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	local best = nil
	local bestScore = -math.huge

	-- Precise selection: whatever the crosshair actually hits.
	local result = raycastAhead(12)
	if result then
		local hit = result.Instance
		for _, entry in ipairs(interactables) do
			local prop = entry.prop
			if not entry.taken and prop and (hit == prop or hit:IsDescendantOf(prop)) then
				best = entry
				break
			end
		end
	end

	if not best then
		for _, entry in ipairs(interactables) do
			local prop = entry.prop
			if not entry.taken and prop and prop.Parent then
				local delta = prop.Position - cam.CFrame.Position
				local distance = delta.Magnitude
				if distance <= 7 and distance > 0.05 then
					local dot = delta.Unit:Dot(cam.CFrame.LookVector)
					if dot > 0.97 then
						local score = dot - distance * 0.005
						if score > bestScore then
							best = entry
							bestScore = score
						end
					end
				end
			end
		end
	end

	currentInteractable = best
	if best then
		contextLabel.Text = "E — " .. best.action .. ": " .. best.object
		contextFrame.Visible = true
	else
		contextFrame.Visible = false
	end
end

-- Documents on the physical props
local function updateDocuments()
	if not currentData then
		return
	end
	if props.Ticket then
		local surface = props.Ticket:FindFirstChildOfClass("SurfaceGui")
		local label = surface and surface:FindFirstChild("Text")
		if label then
			label.Text = "БИЛЕТ № " .. currentData.ticket.number .. "\n" .. currentData.ticket.date .. "\nместо " .. currentData.ticket.seat
		end
	end
	if props.Passport then
		local surface = props.Passport:FindFirstChildOfClass("SurfaceGui")
		local label = surface and surface:FindFirstChild("Text")
		if label then
			label.Text = "ПАСПОРТ\n" .. currentData.name .. "\n" .. currentData.passport.number
		end
	end
end

local function resetPassengerState()
	currentData = nil
	currentNpc = nil
	currentIndex = 0
	currentTotal = 0
	tutorialActive = false
	stampBusy = false
	readTicket = false
	readPassport = false
	closePaper()
	setMirror(false)
	setZoom(false)
	clearHighlight()
	clearTools()
	restoreProps()
	nameLabel.Text = ""
	metaLabel.Text = ""
	progressLabel.Text = ""
	setTask("ОЖИДАНИЕ ПАССАЖИРА")
end

local function showPassenger(payload)
	currentData = payload.data
	currentIndex = payload.index or 0
	currentTotal = payload.total or 4
	tutorialActive = payload.tutorial == true
	stampBusy = false
	readTicket = false
	readPassport = false

	nameLabel.Text = currentData.name
	metaLabel.Text = "→ " .. currentData.destination .. "  ·  место " .. currentData.seat .. "  ·  " .. (currentData.class == "first" and "Первый класс" or "Второй класс")
	progressLabel.Text = tostring(currentIndex) .. " / " .. tostring(currentTotal)
	setTask(payload.hint or "Проверь документы, тень и отражение. Потом поставь печать.")

	currentNpc = nil
	local folder = workspace:FindFirstChild("NightConductorPhysicalPassengers")
	if folder then
		currentNpc = folder:FindFirstChildWhichIsA("Model")
	end

	updateDocuments()
	if props.Ticket then
		local surface = props.Ticket:FindFirstChildOfClass("SurfaceGui")
		if surface then
			local old = surface:FindFirstChild("StampMark")
			if old then
				old:Destroy()
			end
		end
	end
end

local function showResult(payload)
	resultOverlay.Visible = true
	local stars = payload.stars or 1
	resultStars.Text = string.rep("★", stars) .. string.rep("☆", math.max(0, 3 - stars))
	local stats = payload.stats or {}
	resultStats.Text = table.concat({
		"Верных решений: " .. tostring(stats.correct or 0) .. " / " .. tostring(stats.total or 4),
		"Аномалий поймано: " .. tostring(stats.caught or 0),
		"Ошибок: " .. tostring(stats.mistakes or 0),
		"Пропущено на посадке: " .. tostring(stats.missed or 0),
	}, "\n")
	resultPayout.Text = "+" .. tostring(payload.payout or 0) .. " Искр"
	resultTitle.Text = (payload.stats and payload.stats.mistakes == 0) and "СМЕНА ВЫДЕРЖАНА" or "СМЕНА ОКОНЧЕНА"

	player.CameraMode = Enum.CameraMode.Classic
	UserInputService.MouseIconEnabled = true
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end

restartButton.MouseButton1Click:Connect(function()
	resultOverlay.Visible = false
	player.CameraMode = Enum.CameraMode.LockFirstPerson
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	UserInputService.MouseIconEnabled = false
	Remotes.PhysicalRestart:FireServer()
end)

Remotes.PhysicalEvent.OnClientEvent:Connect(function(payload)
	if payload.type == "reset" then
		resetPassengerState()
		player.CameraMode = Enum.CameraMode.LockFirstPerson
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
	elseif payload.type == "passenger" then
		showPassenger(payload)
	elseif payload.type == "feedback" then
		local text = payload.text or ""
		if payload.hint then
			text = text .. "\nПОДСКАЗКА: " .. payload.hint
		end
		showToast(text, payload.kind)
		if payload.correct then
			setTask("Верно. Ждём следующего пассажира.")
		else
			setTask("Ошибка. Смотри подсказку.")
		end
		stampBusy = true
		task.delay(2, function()
			stampBusy = false
		end)
	elseif payload.type == "result" then
		showResult(payload)
	end
end)

-- Input
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.Escape then
		if paperOpen then
			if os.clock() - paperOpenedAt > 0.35 then
				closePaper()
			end
			return
		end
		if input.KeyCode == Enum.KeyCode.E and currentInteractable then
			local entry = currentInteractable
			currentInteractable = nil
			contextFrame.Visible = false
			entry.handler()
		end
	end
end)

-- First person
local function applyFirstPerson()
	player.CameraMode = Enum.CameraMode.LockFirstPerson
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	UserInputService.MouseIconEnabled = false
end

player.CharacterAdded:Connect(function()
	task.wait(0.3)
	applyFirstPerson()
end)

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
end)

applyFirstPerson()
setupProps()
setTask("Ты в тамбуре. Подойди к столу слева и возьми билет.")

RunService.RenderStepped:Connect(function()
	updateContext()
	if zoomed then
		updateHandHighlight()
	end
	if mirrorOpen then
		rebuildMirror()
	end
end)

print("[NightConductor] physical client ready")
