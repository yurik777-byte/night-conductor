-- Prototype client: inspection panel, tools, questions, tunnel and results.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local hatColors = {}
for _, hat in ipairs(Config.HatColors) do
	hatColors[hat.name] = hat.color
end

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
	local cornerInstance = Instance.new("UICorner")
	cornerInstance.CornerRadius = UDim.new(0, radius or 8)
	cornerInstance.Parent = instance
	return cornerInstance
end

local function padding(instance, top, right, bottom, left)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, top or 0)
	pad.PaddingRight = UDim.new(0, right or top or 0)
	pad.PaddingBottom = UDim.new(0, bottom or top or 0)
	pad.PaddingLeft = UDim.new(0, left or right or top or 0)
	pad.Parent = instance
	return pad
end

local function label(parent, props)
	local instance = new("TextLabel", props)
	instance.BackgroundTransparency = props.BackgroundTransparency or 1
	instance.BorderSizePixel = 0
	instance.Font = props.Font or Enum.Font.Gotham
	instance.TextColor3 = props.TextColor3 or Color3.fromRGB(235, 230, 215)
	instance.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
	instance.TextYAlignment = props.TextYAlignment or Enum.TextYAlignment.Center
	instance.TextWrapped = props.TextWrapped ~= false
	instance.Parent = parent
	return instance
end

local function button(parent, props, onClick)
	local instance = new("TextButton", props)
	instance.AutoButtonColor = true
	instance.BorderSizePixel = 0
	instance.Font = props.Font or Enum.Font.GothamBold
	instance.TextColor3 = props.TextColor3 or Color3.fromRGB(245, 240, 225)
	instance.TextWrapped = true
	instance.TextScaled = props.TextScaled == true
	instance.Parent = parent
	instance.MouseButton1Click:Connect(onClick)
	return instance
end

local gui = new("ScreenGui", {
	Name = "NightConductorUI",
	ResetOnSpawn = false,
	IgnoreGuiInset = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 100,
})
gui.Parent = playerGui

local background = new("Frame", {
	Name = "Background",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(8, 12, 15),
	BackgroundTransparency = 0.35,
	BorderSizePixel = 0,
})
background.Parent = gui

local root = new("Frame", {
	Name = "Root",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
})
root.Parent = gui

local uiScale = new("UIScale", { Scale = 1 })
uiScale.Parent = root

local topBar = new("Frame", {
	Name = "TopBar",
	Size = UDim2.new(1, 0, 0, 56),
	BackgroundColor3 = Color3.fromRGB(14, 25, 23),
	BackgroundTransparency = 0.08,
	BorderSizePixel = 0,
})
topBar.Parent = root

local title = label(topBar, {
	Name = "Title",
	Position = UDim2.new(0, 18, 0, 10),
	Size = UDim2.new(0, 330, 0, 24),
	Text = "NIGHT CONDUCTOR",
	Font = Enum.Font.GothamBlack,
	TextSize = 20,
	TextColor3 = Color3.fromRGB(255, 220, 150),
})

local subtitleLabel = label(topBar, {
	Name = "Subtitle",
	Position = UDim2.new(0, 18, 0, 33),
	Size = UDim2.new(0, 360, 0, 18),
	Text = "STATION 0  ·  LAST LIGHT  ·  v7",
	TextSize = 12,
	TextColor3 = Color3.fromRGB(160, 190, 175),
})

local progressLabel = label(topBar, {
	Name = "Progress",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -18, 0, 8),
	Size = UDim2.new(0, 240, 0, 20),
	Text = "ПОДГОТОВКА",
	TextXAlignment = Enum.TextXAlignment.Right,
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	TextColor3 = Color3.fromRGB(255, 220, 150),
})

local clockLabel = label(topBar, {
	Name = "Clock",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -18, 0, 29),
	Size = UDim2.new(0, 300, 0, 16),
	Text = Config.Today .. "  ·  00:13  ·  ПРОВЕРЬ ВСЕ КАНАЛЫ",
	TextXAlignment = Enum.TextXAlignment.Right,
	TextSize = 11,
	TextColor3 = Color3.fromRGB(150, 175, 170),
})

local panel = new("Frame", {
	Name = "Panel",
	Position = UDim2.fromScale(0.42, 0.12),
	Size = UDim2.fromScale(0.56, 0.88),
	BackgroundColor3 = Color3.fromRGB(20, 30, 28),
	BackgroundTransparency = 0.04,
	BorderSizePixel = 0,
})
corner(panel, 14)
padding(panel, 14)
panel.Parent = root

local panelStroke = new("UIStroke", {
	Color = Color3.fromRGB(150, 120, 60),
	Thickness = 1.5,
	Transparency = 0.25,
})
panelStroke.Parent = panel

local header = new("Frame", {
	Name = "Header",
	Size = UDim2.new(1, 0, 0, 56),
	BackgroundTransparency = 1,
})
header.Parent = panel

local nameLabel = label(header, {
	Name = "Name",
	Size = UDim2.new(1, 0, 0, 30),
	Text = "ОЖИДАНИЕ ПАССАЖИРА",
	Font = Enum.Font.GothamBold,
	TextSize = 24,
	TextColor3 = Color3.fromRGB(255, 230, 175),
})

local metaLabel = label(header, {
	Name = "Meta",
	Position = UDim2.new(0, 0, 0, 29),
	Size = UDim2.new(1, 0, 0, 20),
	Text = "Смена начнётся через мгновение...",
	TextSize = 13,
	TextColor3 = Color3.fromRGB(165, 190, 180),
})

local body = new("Frame", {
	Name = "Body",
	Position = UDim2.new(0, 0, 0, 60),
	Size = UDim2.new(1, 0, 1, -278),
	BackgroundTransparency = 1,
})
body.Parent = panel

local left = new("Frame", {
	Name = "Left",
	Size = UDim2.new(0.38, -6, 1, 0),
	BackgroundColor3 = Color3.fromRGB(28, 40, 36),
	BackgroundTransparency = 0.15,
	BorderSizePixel = 0,
})
corner(left, 10)
left.Parent = body

local photoBox = new("Frame", {
	Name = "PhotoBox",
	Position = UDim2.new(0, 8, 0, 8),
	Size = UDim2.new(1, -16, 0, 64),
	BackgroundColor3 = Color3.fromRGB(225, 215, 190),
	BackgroundTransparency = 0,
	BorderSizePixel = 0,
})
corner(photoBox, 6)
local photoConstraint = new("UISizeConstraint", {
	MinSize = Vector2.new(170, 64),
	MaxSize = Vector2.new(310, 64),
})
photoConstraint.Parent = photoBox
photoBox.Parent = left

local photoPaper = new("Frame", {
	Name = "Paper",
	Position = UDim2.new(0, 8, 0, 8),
	Size = UDim2.new(1, -16, 1, -16),
	BackgroundColor3 = Color3.fromRGB(238, 228, 205),
	BorderSizePixel = 0,
})
photoPaper.Parent = photoBox

local photoHat = new("Frame", {
	Name = "Hat",
	Position = UDim2.new(0.2, 0, 0.1, 0),
	Size = UDim2.new(0.6, 0, 0.2, 0),
	BackgroundColor3 = Color3.fromRGB(180, 60, 60),
	BorderSizePixel = 0,
})
corner(photoHat, 4)
photoHat.Parent = photoPaper

local photoFace = new("Frame", {
	Name = "Face",
	Position = UDim2.new(0.25, 0, 0.34, 0),
	Size = UDim2.new(0.5, 0, 0.38, 0),
	BackgroundColor3 = Color3.fromRGB(205, 170, 135),
	BorderSizePixel = 0,
})
corner(photoFace, 20)
photoFace.Parent = photoPaper

for _, x in ipairs({ 0.3, 0.7 }) do
	local eye = new("Frame", {
		Name = "Eye",
		Position = UDim2.new(x, -3, 0.3, 0),
		Size = UDim2.new(0, 6, 0, 6),
		BackgroundColor3 = Color3.fromRGB(25, 25, 25),
		BorderSizePixel = 0,
	})
	corner(eye, 3)
	eye.Parent = photoFace
end

local mouth = new("Frame", {
	Name = "Mouth",
	Position = UDim2.new(0.32, 0, 0.66, 0),
	Size = UDim2.new(0.36, 0, 0, 4),
	BackgroundColor3 = Color3.fromRGB(90, 45, 55),
	BorderSizePixel = 0,
})
corner(mouth, 2)
mouth.Parent = photoFace

local photoLabel = label(left, {
	Name = "PhotoLabel",
	Position = UDim2.new(0, 10, 0, 72),
	Size = UDim2.new(1, -20, 0, 18),
	Text = "ФОТО: —",
	TextSize = 14,
	TextColor3 = Color3.fromRGB(210, 195, 160),
})

local eyeLabel = label(left, {
	Name = "EyeLabel",
	Position = UDim2.new(0, 10, 0, 88),
	Size = UDim2.new(1, -20, 0, 18),
	Text = "ГЛАЗА: —",
	TextSize = 14,
	TextColor3 = Color3.fromRGB(180, 190, 170),
})

local infoLabel = label(left, {
	Name = "Info",
	Position = UDim2.new(0, 10, 0, 104),
	Size = UDim2.new(1, -20, 0, 48),
	Text = "",
	TextSize = 14,
	TextColor3 = Color3.fromRGB(215, 220, 205),
	TextYAlignment = Enum.TextYAlignment.Top,
})

local lookButton = button(left, {
	Name = "LookButton",
	Position = UDim2.new(0, 10, 1, -32),
	Size = UDim2.new(1, -20, 0, 30),
	Text = "ОСМОТРЕТЬ ПАССАЖИРА",
	Visible = false,
	BackgroundColor3 = Color3.fromRGB(110, 85, 45),
	TextSize = 12,
}, function()
	-- assigned after the helper exists
end)
corner(lookButton, 7)

local right = new("Frame", {
	Name = "Right",
	Position = UDim2.new(0.39, 6, 0, 0),
	Size = UDim2.new(0.61, -6, 1, 0),
	BackgroundTransparency = 1,
})
right.Parent = body

local ruleLabel = new("TextLabel", {
	Name = "Rule",
	Size = UDim2.new(1, 0, 0, 38),
	BackgroundColor3 = Color3.fromRGB(70, 55, 25),
	BackgroundTransparency = 0.15,
	BorderSizePixel = 0,
	Text = "ПРАВИЛО СМЕНЫ",
	TextColor3 = Color3.fromRGB(255, 225, 155),
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Center,
})
corner(ruleLabel, 6)
padding(ruleLabel, 0, 8, 0, 8)
ruleLabel.Parent = right

local docScroll = new("Frame", {
	Name = "Documents",
	Position = UDim2.new(0, 0, 0, 44),
	Size = UDim2.new(1, 0, 1, -44),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
})
docScroll.Parent = right

local docList = new("Frame", {
	Name = "DocList",
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
})
docList.Parent = docScroll

local docLayout = new("UIListLayout", {
	Padding = UDim.new(0, 3),
	SortOrder = Enum.SortOrder.LayoutOrder,
})
docLayout.Parent = docList

local actions = new("Frame", {
	Name = "Actions",
	Position = UDim2.new(0, 0, 1, -212),
	Size = UDim2.new(1, 0, 0, 212),
	BackgroundTransparency = 1,
})
actions.Parent = panel

local actionLayout = new("UIListLayout", {
	Padding = UDim.new(0, 4),
	SortOrder = Enum.SortOrder.LayoutOrder,
})
actionLayout.Parent = actions

local toolRow = new("Frame", {
	Name = "Tools",
	LayoutOrder = 1,
	Size = UDim2.new(1, 0, 0, 36),
	BackgroundTransparency = 1,
})
toolRow.Parent = actions

local toolGrid = new("UIGridLayout", {
	CellSize = UDim2.new(0.16, -4, 1, 0),
	CellPadding = UDim2.new(0, 4, 0, 0),
	SortOrder = Enum.SortOrder.LayoutOrder,
	FillDirectionMaxCells = 6,
})
toolGrid.Parent = toolRow

local toolResult = new("TextLabel", {
	Name = "ToolResult",
	LayoutOrder = 2,
	Size = UDim2.new(1, 0, 0, 38),
	BackgroundColor3 = Color3.fromRGB(10, 18, 16),
	BackgroundTransparency = 0.2,
	BorderSizePixel = 0,
	Text = "Используй инструменты. Сравни фото, дату и поведение.",
	TextColor3 = Color3.fromRGB(220, 225, 205),
	Font = Enum.Font.Gotham,
	TextSize = 14,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Center,
})
corner(toolResult, 6)
padding(toolResult, 0, 8, 0, 8)
toolResult.Parent = actions

local questionRow = new("Frame", {
	Name = "Questions",
	LayoutOrder = 3,
	Size = UDim2.new(1, 0, 0, 32),
	BackgroundTransparency = 1,
})
questionRow.Parent = actions

local questionGrid = new("UIGridLayout", {
	CellSize = UDim2.new(0.32, -4, 1, 0),
	CellPadding = UDim2.new(0, 4, 0, 0),
	SortOrder = Enum.SortOrder.LayoutOrder,
	FillDirectionMaxCells = 3,
})
questionGrid.Parent = questionRow

local dialogueLabel = new("TextLabel", {
	Name = "Dialogue",
	LayoutOrder = 4,
	Size = UDim2.new(1, 0, 0, 32),
	BackgroundColor3 = Color3.fromRGB(10, 18, 16),
	BackgroundTransparency = 0.2,
	BorderSizePixel = 0,
	Text = "Задай вопрос, чтобы услышать историю.",
	TextColor3 = Color3.fromRGB(190, 210, 195),
	Font = Enum.Font.Gotham,
	TextSize = 14,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Center,
})
corner(dialogueLabel, 6)
padding(dialogueLabel, 0, 8, 0, 8)
dialogueLabel.Parent = actions

local decisionRow = new("Frame", {
	Name = "Decisions",
	LayoutOrder = 5,
	Size = UDim2.new(1, 0, 0, 42),
	BackgroundTransparency = 1,
})
decisionRow.Parent = actions

local decisionGrid = new("UIGridLayout", {
	CellSize = UDim2.new(0.32, -4, 1, 0),
	CellPadding = UDim2.new(0, 4, 0, 0),
	SortOrder = Enum.SortOrder.LayoutOrder,
	FillDirectionMaxCells = 3,
})
decisionGrid.Parent = decisionRow

local toast = new("Frame", {
	Name = "Toast",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.12),
	Size = UDim2.fromScale(0.52, 0.09),
	BackgroundColor3 = Color3.fromRGB(25, 40, 35),
	BackgroundTransparency = 0.05,
	BorderSizePixel = 0,
	Visible = false,
})
corner(toast, 10)
toast.Parent = root

local toastLabel = new("TextLabel", {
	Name = "Text",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Text = "",
	TextColor3 = Color3.fromRGB(245, 240, 225),
	Font = Enum.Font.GothamBold,
	TextSize = 15,
	TextWrapped = true,
	TextScaled = true,
})
toastLabel.Parent = toast
padding(toastLabel, 8, 12, 8, 12)

local tunnelOverlay = new("Frame", {
	Name = "TunnelOverlay",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BackgroundTransparency = 0.04,
	BorderSizePixel = 0,
	Visible = false,
})
tunnelOverlay.Parent = gui

local tunnelCard = new("Frame", {
	Name = "Card",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.54, 0.6),
	BackgroundColor3 = Color3.fromRGB(12, 16, 20),
	BackgroundTransparency = 0.02,
	BorderSizePixel = 0,
})
corner(tunnelCard, 16)
tunnelCard.Parent = tunnelOverlay

local tunnelTitle = label(tunnelCard, {
	Name = "Title",
	Position = UDim2.new(0, 24, 0, 20),
	Size = UDim2.new(1, -48, 0, 34),
	Text = "ЧЁРНАЯ МИЛЯ",
	Font = Enum.Font.GothamBlack,
	TextSize = 26,
	TextColor3 = Color3.fromRGB(255, 230, 170),
	TextXAlignment = Enum.TextXAlignment.Center,
})

local tunnelText = label(tunnelCard, {
	Name = "Text",
	Position = UDim2.new(0, 24, 0, 64),
	Size = UDim2.new(1, -48, 0, 80),
	Text = "",
	TextSize = 15,
	TextColor3 = Color3.fromRGB(220, 225, 220),
	TextXAlignment = Enum.TextXAlignment.Center,
	TextYAlignment = Enum.TextYAlignment.Top,
})

local tunnelButtons = new("Frame", {
	Name = "Buttons",
	Position = UDim2.new(0, 24, 0, 160),
	Size = UDim2.new(1, -48, 1, -180),
	BackgroundTransparency = 1,
})
tunnelButtons.Parent = tunnelCard

local tunnelButtonLayout = new("UIGridLayout", {
	CellSize = UDim2.new(1, 0, 0, 30),
	CellPadding = UDim2.new(0, 0, 0, 7),
	SortOrder = Enum.SortOrder.LayoutOrder,
	FillDirectionMaxCells = 1,
})
tunnelButtonLayout.Parent = tunnelButtons

local resultsOverlay = new("Frame", {
	Name = "ResultsOverlay",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(8, 12, 15),
	BackgroundTransparency = 0.08,
	BorderSizePixel = 0,
	Visible = false,
})
resultsOverlay.Parent = gui

local resultsCard = new("Frame", {
	Name = "Card",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.5, 0.56),
	BackgroundColor3 = Color3.fromRGB(22, 32, 30),
	BackgroundTransparency = 0.02,
	BorderSizePixel = 0,
})
corner(resultsCard, 16)
resultsCard.Parent = resultsOverlay

local resultsTitle = label(resultsCard, {
	Name = "Title",
	Position = UDim2.new(0, 20, 0, 18),
	Size = UDim2.new(1, -40, 0, 34),
	Text = "СМЕНА ОКОНЧЕНА",
	Font = Enum.Font.GothamBlack,
	TextSize = 26,
	TextColor3 = Color3.fromRGB(255, 225, 160),
	TextXAlignment = Enum.TextXAlignment.Center,
})

local starsLabel = label(resultsCard, {
	Name = "Stars",
	Position = UDim2.new(0, 20, 0, 58),
	Size = UDim2.new(1, -40, 0, 38),
	Text = "★★★",
	Font = Enum.Font.GothamBlack,
	TextSize = 28,
	TextColor3 = Color3.fromRGB(255, 210, 90),
	TextXAlignment = Enum.TextXAlignment.Center,
})

local statsLabel = label(resultsCard, {
	Name = "Stats",
	Position = UDim2.new(0, 20, 0, 104),
	Size = UDim2.new(1, -40, 0, 120),
	Text = "",
	TextSize = 15,
	TextColor3 = Color3.fromRGB(215, 225, 210),
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
})

local payoutLabel = label(resultsCard, {
	Name = "Payout",
	Position = UDim2.new(0, 20, 0, 232),
	Size = UDim2.new(1, -40, 0, 34),
	Text = "+0 Искр",
	Font = Enum.Font.GothamBold,
	TextSize = 22,
	TextColor3 = Color3.fromRGB(255, 220, 140),
	TextXAlignment = Enum.TextXAlignment.Center,
})

local restartButton = button(resultsCard, {
	Name = "Restart",
	Position = UDim2.new(0.15, 0, 1, -62),
	Size = UDim2.new(0.7, 0, 0, 44),
	Text = "ЕЩЁ РЕЙС",
	BackgroundColor3 = Color3.fromRGB(115, 85, 40),
	TextSize = 16,
}, function()
	restartButton.Active = false
	resultsOverlay.Visible = false
	Remotes.Restart:FireServer()
end)
corner(restartButton, 9)

local feedbackBox = new("Frame", {
	Name = "Feedback",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.62, 0.26),
	BackgroundColor3 = Color3.fromRGB(25, 40, 35),
	BackgroundTransparency = 0.03,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 20,
	Active = true,
})
corner(feedbackBox, 12)
feedbackBox.Parent = gui

local feedbackStroke = new("UIStroke", {
	Color = Color3.fromRGB(90, 190, 120),
	Thickness = 2,
	Transparency = 0.1,
})
feedbackStroke.Parent = feedbackBox

local feedbackTitle = label(feedbackBox, {
	Name = "Title",
	Position = UDim2.new(0, 16, 0, 10),
	Size = UDim2.new(1, -32, 0, 28),
	Text = "ВЕРНО",
	Font = Enum.Font.GothamBlack,
	TextSize = 22,
	TextColor3 = Color3.fromRGB(180, 235, 170),
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = 21,
})

local feedbackText = label(feedbackBox, {
	Name = "Text",
	Position = UDim2.new(0, 16, 0, 40),
	Size = UDim2.new(1, -32, 1, -50),
	Text = "",
	TextSize = 14,
	TextColor3 = Color3.fromRGB(235, 238, 225),
	TextXAlignment = Enum.TextXAlignment.Center,
	TextYAlignment = Enum.TextYAlignment.Top,
	ZIndex = 21,
})

local feedbackToken = 0

local function showFeedback(kind, text, hint)
	feedbackToken = feedbackToken + 1
	local token = feedbackToken
	feedbackBox.Visible = true
	feedbackBox.BackgroundColor3 = kind == "good" and Color3.fromRGB(20, 55, 40) or Color3.fromRGB(70, 25, 30)
	feedbackStroke.Color = kind == "good" and Color3.fromRGB(90, 190, 120) or Color3.fromRGB(220, 100, 100)
	feedbackTitle.Text = kind == "good" and "ВЕРНО" or "ОШИБКА"
	feedbackTitle.TextColor3 = kind == "good" and Color3.fromRGB(180, 235, 170) or Color3.fromRGB(250, 170, 160)
	feedbackText.Text = text .. (hint and ("\n\nПОДСКАЗКА: " .. hint) or "")
	task.delay(2.4, function()
		if feedbackToken == token then
			feedbackBox.Visible = false
		end
	end)
end

local introOverlay = new("Frame", {
	Name = "IntroOverlay",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(5, 9, 12),
	BackgroundTransparency = 0.08,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 30,
	Active = true,
})
introOverlay.Parent = gui

local introCard = new("Frame", {
	Name = "Card",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.58, 0.62),
	BackgroundColor3 = Color3.fromRGB(22, 32, 30),
	BackgroundTransparency = 0.02,
	BorderSizePixel = 0,
	ZIndex = 31,
	Active = true,
})
corner(introCard, 14)
introCard.Parent = introOverlay

local introTitle = label(introCard, {
	Name = "Title",
	Position = UDim2.new(0, 20, 0, 18),
	Size = UDim2.new(1, -40, 0, 32),
	Text = "КАК ИГРАТЬ",
	Font = Enum.Font.GothamBlack,
	TextSize = 24,
	TextColor3 = Color3.fromRGB(255, 225, 160),
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = 32,
})

local introText = label(introCard, {
	Name = "Text",
	Position = UDim2.new(0, 24, 0, 58),
	Size = UDim2.new(1, -48, 1, -126),
	Text = "",
	TextSize = 14,
	TextColor3 = Color3.fromRGB(225, 230, 215),
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	ZIndex = 32,
})

local introButton = button(introCard, {
	Name = "Start",
	Position = UDim2.new(0.2, 0, 1, -58),
	Size = UDim2.new(0.6, 0, 0, 40),
	Text = "ПОНЯТНО",
	BackgroundColor3 = Color3.fromRGB(115, 85, 40),
	TextSize = 16,
	ZIndex = 32,
}, function()
	introOverlay.Visible = false
end)
corner(introButton, 8)

local buttonsEnabled = false
local toolBusy = false
local askedQuestions = {}
local currentData = nil
local tunnelActive = false
local compactUI = false
local progressText = ""
local startTutorial
local stopTutorial
local advanceTutorialAfterTool
local advanceTutorialAfterDecision

local toolButtons = {}
local questionButtons = {}
local decisionButtons = {}
local toolButtonById = {}
local decisionButtonById = {}
local baseColors = {}
table.insert(toolButtons, lookButton)
baseColors[lookButton] = Color3.fromRGB(110, 85, 45)

local function setButtonsEnabled(enabled)
	buttonsEnabled = enabled
	for _, item in ipairs(toolButtons) do
		item.Active = enabled
		item.AutoButtonColor = enabled
		item.TextTransparency = enabled and 0 or 0.45
	end
	for _, item in ipairs(questionButtons) do
		item.Active = enabled
		item.AutoButtonColor = enabled
		item.TextTransparency = enabled and 0 or 0.45
	end
	for _, item in ipairs(decisionButtons) do
		item.Active = enabled
		item.AutoButtonColor = enabled
		item.TextTransparency = enabled and 0 or 0.45
	end
end

local function clearHighlights()
	for buttonInstance, baseColor in pairs(baseColors) do
		if buttonInstance and buttonInstance.Parent then
			buttonInstance.BackgroundColor3 = baseColor
		end
	end
end

local function highlightButton(id, shouldHighlight)
	local buttonInstance = toolButtonById[id] or decisionButtonById[id]
	if buttonInstance and shouldHighlight then
		buttonInstance.BackgroundColor3 = Color3.fromRGB(190, 150, 45)
	end
end

local function showToast(kind, message)
	toast.Visible = true
	toast.BackgroundColor3 = kind == "good" and Color3.fromRGB(30, 75, 50)
		or kind == "bad" and Color3.fromRGB(85, 30, 35)
		or Color3.fromRGB(60, 55, 30)
	toastLabel.Text = message
	toast.BackgroundTransparency = 0.05
	toastLabel.TextTransparency = 0
	task.delay(1.4, function()
		if not toast.Visible then
			return
		end
		local tween = TweenService:Create(toast, TweenInfo.new(0.35), { BackgroundTransparency = 1 })
		local textTween = TweenService:Create(toastLabel, TweenInfo.new(0.35), { TextTransparency = 1 })
		tween:Play()
		textTween:Play()
		tween.Completed:Wait()
		toast.Visible = false
	end)
end

local function addDocument(titleText, lines, order)
	local card = new("Frame", {
		Name = "Card",
		LayoutOrder = order,
		Size = UDim2.new(1, -4, 1, 0),
		BackgroundColor3 = Color3.fromRGB(235, 225, 200),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
	})
	corner(card, 5)
	card.Parent = docList

	local title = new("TextLabel", {
		Name = "Title",
		Position = UDim2.new(0, 10, 0, 4),
		Size = UDim2.new(1, -20, 0, 16),
		BackgroundTransparency = 1,
		Text = titleText,
		TextColor3 = Color3.fromRGB(120, 75, 30),
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	title.Parent = card

	local bodyLabel = new("TextLabel", {
		Name = "Body",
		Position = UDim2.new(0, 10, 0, 21),
		Size = UDim2.new(1, -20, 1, -25),
		BackgroundTransparency = 1,
		Text = table.concat(lines, "\n"),
		TextColor3 = Color3.fromRGB(38, 32, 24),
		Font = Enum.Font.Gotham,
		TextSize = 16,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	})
	bodyLabel.Parent = card
	return bodyLabel
end

local function classLabel(value)
	return value == "first" and "Первый класс" or "Второй класс"
end

local function renderDossier(data)
	for _, child in ipairs(docList:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local dossierLines
	if compactUI then
		dossierLines = {
			"БИЛЕТ № " .. data.ticket.number .. "  ·  " .. classLabel(data.ticket.class) .. "  ·  место " .. data.ticket.seat,
			"0 → " .. data.ticket.to .. "  ·  " .. data.ticket.date,
			"ПАСПОРТ: " .. data.name .. ", " .. tostring(data.age) .. "  ·  " .. data.passport.photoHatName .. " шляпа",
			"Глаза: " .. data.passport.eyeColor .. "  ·  Багаж: " .. data.luggage.tag .. ", " .. tostring(data.luggage.weight) .. " кг",
		}
	else
		dossierLines = {
			"БИЛЕТ № " .. data.ticket.number .. "  ·  " .. classLabel(data.ticket.class) .. "  ·  место " .. data.ticket.seat,
			"0 → " .. data.ticket.to .. "  ·  " .. data.ticket.date .. "  ·  " .. data.ticket.stamp,
			"ПАСПОРТ: " .. data.name .. ", " .. tostring(data.age) .. "  ·  " .. data.passport.number .. "  ·  " .. data.passport.origin,
			"Фото: " .. data.passport.photoHatName .. " шляпа  ·  глаза: " .. data.passport.eyeColor,
			"Багаж: " .. data.luggage.tag .. "  ·  " .. tostring(data.luggage.weight) .. " кг  ·  " .. data.luggage.contents,
		}
	end

	local dossierBody = addDocument("ДОСЬЕ", dossierLines, 1)
	if compactUI and dossierBody then
		local dossierCard = dossierBody.Parent
		local dossierTitle = dossierCard and dossierCard:FindFirstChild("Title")
		if dossierTitle then
			dossierTitle.Visible = false
		end
		dossierBody.Position = UDim2.new(0, 10, 0, 2)
		dossierBody.Size = UDim2.new(1, -20, 1, -4)
		dossierBody.TextSize = 16
	end
end

local function showPassenger(data)
	currentData = data
	askedQuestions = {}
	toast.Visible = false
	feedbackBox.Visible = false
	clearHighlights()
	setButtonsEnabled(true)
	panel.Visible = true
	tunnelOverlay.Visible = false
	resultsOverlay.Visible = false

	nameLabel.Text = data.name
	metaLabel.Text = "→ " .. data.destination .. "  ·  место " .. data.seat .. "  ·  " .. classLabel(data.class) .. (progressText ~= "" and ("  ·  " .. progressText) or "")
	photoHat.BackgroundColor3 = hatColors[data.passport.photoHatName] or Color3.fromRGB(120, 120, 120)
	photoLabel.Text = "ФОТО: " .. data.passport.photoHatName .. " шляпа"
	eyeLabel.Text = "ГЛАЗА: " .. data.passport.eyeColor
	infoLabel.Text = "ВИД: " .. (data.species == "human" and "человек" or data.species) .. "  ·  МЕСТО: " .. data.seat .. "\nКЛАСС: " .. classLabel(data.class) .. "\nПУНКТ: " .. data.destination
	if data.tutorial then
		ruleLabel.Text = data.tutorial.text
		ruleLabel.BackgroundColor3 = Color3.fromRGB(95, 70, 25)
		if startTutorial then
			startTutorial(data.tutorial.index)
		end
	else
		ruleLabel.Text = Config.Checklist
		ruleLabel.BackgroundColor3 = Color3.fromRGB(70, 55, 25)
		if stopTutorial then
			stopTutorial()
		end
	end
	toolResult.Text = "Используй инструменты. Сравни фото, дату и поведение."
	dialogueLabel.Text = "Задай вопрос, чтобы услышать историю."

	renderDossier(data)
end

local function requestTool(toolId)
	if not buttonsEnabled or toolBusy or not currentData then
		return
	end
	toolBusy = true
	local ok, result = pcall(function()
		return Remotes.Inspect:InvokeServer(toolId)
	end)
	toolBusy = false
	if ok and type(result) == "table" and result.text then
		toolResult.Text = result.text
	else
		toolResult.Text = "Инструмент не отвечает."
	end
	if advanceTutorialAfterTool then
		advanceTutorialAfterTool(toolId)
	end
end

local function requestQuestion(questionId)
	if not buttonsEnabled or not currentData then
		return
	end
	if askedQuestions[questionId] then
		dialogueLabel.Text = "Ты уже задал этот вопрос."
		return
	end
	askedQuestions[questionId] = true
	local ok, result = pcall(function()
		return Remotes.Ask:InvokeServer(questionId)
	end)
	if ok and type(result) == "table" and result.text then
		local questionText = "Вопрос"
		for _, question in ipairs(Config.Questions) do
			if question.id == questionId then
				questionText = question.text
				break
			end
		end
		dialogueLabel.Text = "— " .. questionText .. "\n«" .. result.text .. "»"
		toolResult.Text = "— " .. questionText .. "\n«" .. result.text .. "»"
	else
		toolResult.Text = "Пассажир молчит."
		dialogueLabel.Text = "Пассажир молчит."
	end
end

local function decide(decision)
	if not buttonsEnabled or not currentData then
		return
	end
	setButtonsEnabled(false)
	toolResult.Text = "Решение отправлено..."
	if advanceTutorialAfterDecision then
		advanceTutorialAfterDecision(decision)
	end
	Remotes.Decide:FireServer(decision)
end

for index, tool in ipairs({
	{ id = "mirror", text = "ЗЕРКАЛО", color = Color3.fromRGB(55, 85, 105) },
	{ id = "lamp", text = "ЛАМПА", color = Color3.fromRGB(105, 80, 35) },
	{ id = "magnifier", text = "ЛУПА", color = Color3.fromRGB(70, 70, 95) },
	{ id = "compass", text = "КОМПАС", color = Color3.fromRGB(45, 90, 75) },
	{ id = "cat", text = "КОТ", color = Color3.fromRGB(95, 65, 45) },
	{ id = "look", text = "ОСМОТР", color = Color3.fromRGB(80, 75, 50) },
}) do
	local toolButton = button(toolRow, {
		Name = tool.id,
		LayoutOrder = index,
		Text = tool.text,
		BackgroundColor3 = tool.color,
		TextSize = 12,
	}, function()
		requestTool(tool.id)
	end)
	corner(toolButton, 6)
	table.insert(toolButtons, toolButton)
	toolButtonById[tool.id] = toolButton
	baseColors[toolButton] = tool.color
end

for index, question in ipairs(Config.Questions) do
	local questionButton = button(questionRow, {
		Name = question.id,
		LayoutOrder = index,
		Text = question.text,
		BackgroundColor3 = Color3.fromRGB(35, 55, 50),
		TextSize = 12,
	}, function()
		requestQuestion(question.id)
	end)
	corner(questionButton, 6)
	table.insert(questionButtons, questionButton)
end

local decisionData = {
	{ id = "admit", text = "ПРОПУСТИТЬ", color = Color3.fromRGB(35, 95, 60) },
	{ id = "deny", text = "ОТКАЗАТЬ", color = Color3.fromRGB(110, 40, 45) },
	{ id = "hold", text = "ЗАДЕРЖАТЬ", color = Color3.fromRGB(95, 80, 35) },
}
for index, decision in ipairs(decisionData) do
	local decisionButton = button(decisionRow, {
		Name = decision.id,
		LayoutOrder = index,
		Text = decision.text,
		BackgroundColor3 = decision.color,
		TextSize = 14,
	}, function()
		decide(decision.id)
	end)
	corner(decisionButton, 7)
	table.insert(decisionButtons, decisionButton)
	decisionButtonById[decision.id] = decisionButton
	baseColors[decisionButton] = decision.color
end

-- Roblox-style spotlight tutorial: dim everything except the target control.
local tutorialLayer = new("Frame", {
	Name = "TutorialLayer",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Visible = false,
	ZIndex = 40,
})
tutorialLayer.Parent = gui

local shadeTop = new("Frame", {
	Name = "ShadeTop",
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BackgroundTransparency = 0.45,
	BorderSizePixel = 0,
	Active = true,
	ZIndex = 41,
})
shadeTop.Parent = tutorialLayer

local shadeBottom = new("Frame", {
	Name = "ShadeBottom",
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BackgroundTransparency = 0.45,
	BorderSizePixel = 0,
	Active = true,
	ZIndex = 41,
})
shadeBottom.Parent = tutorialLayer

local shadeLeft = new("Frame", {
	Name = "ShadeLeft",
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BackgroundTransparency = 0.45,
	BorderSizePixel = 0,
	Active = true,
	ZIndex = 41,
})
shadeLeft.Parent = tutorialLayer

local shadeRight = new("Frame", {
	Name = "ShadeRight",
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BackgroundTransparency = 0.45,
	BorderSizePixel = 0,
	Active = true,
	ZIndex = 41,
})
shadeRight.Parent = tutorialLayer

local spotBorder = new("Frame", {
	Name = "SpotBorder",
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Active = false,
	ZIndex = 42,
})
spotBorder.Parent = tutorialLayer

local spotStroke = new("UIStroke", {
	Color = Color3.fromRGB(255, 205, 90),
	Thickness = 3,
	Transparency = 0.1,
})
spotStroke.Parent = spotBorder
spotBorder.Visible = false

local spotPulse = TweenService:Create(
	spotStroke,
	TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
	{ Transparency = 0.7 }
)
spotPulse:Play()

local tooltip = new("Frame", {
	Name = "Tooltip",
	BackgroundColor3 = Color3.fromRGB(18, 28, 26),
	BackgroundTransparency = 0,
	BorderSizePixel = 0,
	Active = true,
	ZIndex = 43,
})
corner(tooltip, 10)
tooltip.Parent = tutorialLayer

local tooltipStroke = new("UIStroke", {
	Color = Color3.fromRGB(255, 205, 90),
	Thickness = 1.5,
	Transparency = 0.2,
})
tooltipStroke.Parent = tooltip

local tooltipText = label(tooltip, {
	Name = "Text",
	Position = UDim2.new(0, 14, 0, 10),
	Size = UDim2.new(1, -28, 1, -56),
	Text = "",
	TextSize = 15,
	TextColor3 = Color3.fromRGB(240, 238, 220),
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	ZIndex = 44,
})

local currentTooltipAction = nil

local tooltipButton = button(tooltip, {
	Name = "Next",
	Position = UDim2.new(0.2, 0, 1, -40),
	Size = UDim2.new(0.6, 0, 0, 32),
	Text = "ДАЛЕЕ",
	BackgroundColor3 = Color3.fromRGB(135, 100, 40),
	TextSize = 14,
	Visible = false,
	ZIndex = 44,
}, function()
	if currentTooltipAction then
		local action = currentTooltipAction
		currentTooltipAction = nil
		action()
	end
end)
corner(tooltipButton, 7)

local arrow = label(tutorialLayer, {
	Name = "Arrow",
	Size = UDim2.fromOffset(30, 30),
	Text = "▼",
	Font = Enum.Font.GothamBlack,
	TextSize = 26,
	TextColor3 = Color3.fromRGB(255, 205, 90),
	TextXAlignment = Enum.TextXAlignment.Center,
	TextYAlignment = Enum.TextYAlignment.Center,
	BackgroundTransparency = 1,
	ZIndex = 45,
})

local tutorialFlow = {
	[1] = {
		{
			target = "docs",
			text = "Ты — ночной кондуктор.\nСверь билет и паспорт: имя, дата, место.\nАномалия может быть не только в дате.",
			button = "ДАЛЕЕ",
		},
		{
			target = "decision:admit",
			text = "Всё совпадает? Нажми ПРОПУСТИТЬ.",
		},
	},
	[2] = {
		{
			target = "tool:magnifier",
			text = "Дата на билете 12.04.1912, а сегодня 30.10.2026.\nНажми ЛУПА.",
		},
		{
			target = "decision:deny",
			text = "Дата не совпадает. Нажми ОТКАЗАТЬ.",
		},
	},
	[3] = {
		{
			target = "tool:lamp",
			text = "Дата верная — это ловушка.\nПроверь тень: нажми ЛАМПА.",
		},
		{
			target = "decision:deny",
			text = "Тень неправильная. Нажми ОТКАЗАТЬ.",
		},
	},
	[4] = {
		{
			target = "tool:mirror",
			text = "Проверь отражение: нажми ЗЕРКАЛО.",
		},
		{
			target = "decision:deny",
			text = "Отражения нет. Нажми ОТКАЗАТЬ.",
		},
	},
	[5] = {
		{
			target = "tool:magnifier",
			text = "Проверь руки: нажми ЛУПА.",
		},
		{
			target = "decision:deny",
			text = "На руке шесть пальцев. Нажми ОТКАЗАТЬ.",
		},
	},
	[6] = {},
}

local currentTutorialIndex = nil
local currentTutorialPhase = 1
local currentSpotlightTarget = nil
local tutorialAdvanceScheduled = false
local targetHighlightStroke = nil
local targetHighlightTween = nil

local function resolveTutorialTarget(targetName)
	if targetName == "docs" then
		return docScroll
	elseif targetName == "panel" then
		return panel
	elseif targetName == "look" then
		return lookButton
	elseif string.sub(targetName, 1, 5) == "tool:" then
		return toolButtonById[string.sub(targetName, 6)]
	elseif string.sub(targetName, 1, 9) == "decision:" then
		return decisionButtonById[string.sub(targetName, 10)]
	end
	return nil
end

local function setTargetHighlight(target)
	if targetHighlightTween then
		targetHighlightTween:Cancel()
		targetHighlightTween = nil
	end
	if targetHighlightStroke then
		targetHighlightStroke:Destroy()
		targetHighlightStroke = nil
	end
	if target then
		local stroke = Instance.new("UIStroke")
		stroke.Name = "TutorialHighlight"
		stroke.Color = Color3.fromRGB(255, 205, 90)
		stroke.Thickness = 3
		stroke.Transparency = 0.1
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = target
		targetHighlightStroke = stroke
		targetHighlightTween = TweenService:Create(
			stroke,
			TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ Transparency = 0.7 }
		)
		targetHighlightTween:Play()
	end
end

local function getVisibleRect(object)
	local position = object.AbsolutePosition
	local size = object.AbsoluteSize
	local x, y = position.X, position.Y
	local width, height = size.X, size.Y

	local ancestor = object.Parent
	while ancestor and ancestor ~= gui do
		if ancestor:IsA("ScrollingFrame") then
			local clipPosition = ancestor.AbsolutePosition
			local clipSize = ancestor.AbsoluteSize
			local newX = math.max(x, clipPosition.X)
			local newY = math.max(y, clipPosition.Y)
			local newRight = math.min(x + width, clipPosition.X + clipSize.X)
			local newBottom = math.min(y + height, clipPosition.Y + clipSize.Y)
			x = newX
			y = newY
			width = math.max(0, newRight - newX)
			height = math.max(0, newBottom - newY)
		end
		ancestor = ancestor.Parent
	end

	return x, y, width, height
end

local function layoutSpotlight()
	if not currentSpotlightTarget then
		return
	end

	local target = resolveTutorialTarget(currentSpotlightTarget)
	if not target or not target.Visible then
		return
	end

	local camera = workspace.CurrentCamera
	local screen = tutorialLayer.AbsoluteSize
	if screen.X < 1 or screen.Y < 1 then
		screen = camera and camera.ViewportSize or Vector2.new(1280, 720)
	end
	local x, y, width, height = getVisibleRect(target)
	if width <= 1 or height <= 1 then
		return
	end
	local padding = 4

	x = math.max(0, x - padding)
	y = math.max(0, y - padding)
	width = math.min(screen.X - x, width + padding * 2)
	height = math.min(screen.Y - y, height + padding * 2)

	shadeTop.Position = UDim2.fromOffset(0, 0)
	shadeTop.Size = UDim2.fromOffset(screen.X, y)

	shadeBottom.Position = UDim2.fromOffset(0, y + height)
	shadeBottom.Size = UDim2.fromOffset(screen.X, math.max(0, screen.Y - (y + height)))

	shadeLeft.Position = UDim2.fromOffset(0, y)
	shadeLeft.Size = UDim2.fromOffset(x, height)

	shadeRight.Position = UDim2.fromOffset(x + width, y)
	shadeRight.Size = UDim2.fromOffset(math.max(0, screen.X - (x + width)), height)

	spotBorder.Position = UDim2.fromOffset(x, y)
	spotBorder.Size = UDim2.fromOffset(width, height)

	local tooltipWidth = math.min(360, screen.X - 24)
	local tooltipHeight = 154
	local centerX = x + width / 2

	if screen.X < 900 then
		local bannerWidth = screen.X - 24
		local bannerHeight = 96
		tooltip.Position = UDim2.fromOffset(12, 2)
		tooltip.Size = UDim2.fromOffset(bannerWidth, bannerHeight)
		tooltipText.Position = UDim2.new(0, 12, 0, 4)
		tooltipText.Size = UDim2.new(1, -132, 1, -8)
		tooltipText.TextSize = 14
		tooltipButton.Position = UDim2.new(1, -106, 0.5, -16)
		tooltipButton.Size = UDim2.fromOffset(94, 32)
		tooltipButton.TextSize = 13
		arrow.Visible = false
		return
	end

	tooltipText.Position = UDim2.new(0, 14, 0, 10)
	tooltipText.Size = UDim2.new(1, -28, 1, -56)
	tooltipText.TextSize = 15
	tooltipButton.Position = UDim2.new(0.2, 0, 1, -40)
	tooltipButton.Size = UDim2.new(0.6, 0, 0, 32)
	tooltipButton.TextSize = 14
	arrow.Visible = true

	local freeLeft = panel.AbsolutePosition.X
	if freeLeft > tooltipWidth + 80 then
		local dockX = math.clamp(freeLeft / 2 - tooltipWidth / 2, 12, math.max(12, freeLeft - tooltipWidth - 12))
		local dockY = math.clamp(y + height / 2 - tooltipHeight / 2, 12, math.max(12, screen.Y - tooltipHeight - 12))
		tooltip.Position = UDim2.fromOffset(dockX, dockY)
		tooltip.Size = UDim2.fromOffset(tooltipWidth, tooltipHeight)
		arrow.Text = "▶"
		arrow.Position = UDim2.fromOffset(dockX + tooltipWidth - 4, dockY + tooltipHeight / 2 - 15)
		return
	end

	local placeAbove = (y + height / 2) > screen.Y * 0.55
	local tooltipY
	if placeAbove then
		tooltipY = y - tooltipHeight - 18
	else
		tooltipY = y + height + 18
	end
	tooltipY = math.clamp(tooltipY, 12, math.max(12, screen.Y - tooltipHeight - 12))

	local tooltipX = math.clamp(centerX - tooltipWidth / 2, 12, math.max(12, screen.X - tooltipWidth - 12))
	tooltip.Position = UDim2.fromOffset(tooltipX, tooltipY)
	tooltip.Size = UDim2.fromOffset(tooltipWidth, tooltipHeight)

	if placeAbove then
		arrow.Text = "▼"
		arrow.Position = UDim2.fromOffset(centerX - 15, tooltipY + tooltipHeight - 4)
	else
		arrow.Text = "▲"
		arrow.Position = UDim2.fromOffset(centerX - 15, tooltipY - 28)
	end
end

local function hideSpotlight()
	tutorialLayer.Visible = false
	currentSpotlightTarget = nil
	currentTooltipAction = nil
	spotBorder.Visible = false
	setTargetHighlight(nil)
end

RunService.RenderStepped:Connect(function()
	if tutorialLayer.Visible then
		layoutSpotlight()
	end
end)

local function showSpotlight(targetName, text, buttonText, action)
	currentSpotlightTarget = targetName
	currentTooltipAction = action
	tutorialLayer.Visible = true
	if targetName == "docs" then
		spotBorder.Visible = true
		setTargetHighlight(nil)
	else
		spotBorder.Visible = false
		setTargetHighlight(resolveTutorialTarget(targetName))
	end
	tooltipText.Text = text or ""
	tooltipButton.Visible = buttonText ~= nil
	tooltipButton.Text = buttonText or "ДАЛЕЕ"
	layoutSpotlight()
	task.defer(layoutSpotlight)
end

local function showTutorialPhase()
	local flow = tutorialFlow[currentTutorialIndex]
	local phase = flow and flow[currentTutorialPhase]
	if not phase then
		hideSpotlight()
		return
	end
	showSpotlight(phase.target, phase.text, phase.button, function()
		currentTutorialPhase = currentTutorialPhase + 1
		showTutorialPhase()
	end)
end

startTutorial = function(index)
	currentTutorialIndex = index
	currentTutorialPhase = 1
	tutorialAdvanceScheduled = false
	showTutorialPhase()
end

stopTutorial = function()
	currentTutorialIndex = nil
	currentTutorialPhase = 1
	tutorialAdvanceScheduled = false
	hideSpotlight()
end

advanceTutorialAfterTool = function(toolId)
	if not currentTutorialIndex or tutorialAdvanceScheduled then
		return
	end
	local flow = tutorialFlow[currentTutorialIndex]
	local phase = flow and flow[currentTutorialPhase]
	if phase and phase.target == "tool:" .. toolId then
		tutorialAdvanceScheduled = true
		task.delay(0.7, function()
			tutorialAdvanceScheduled = false
			local currentFlow = tutorialFlow[currentTutorialIndex]
			local currentPhase = currentFlow and currentFlow[currentTutorialPhase]
			if currentPhase and currentPhase.target == "tool:" .. toolId then
				currentTutorialPhase = currentTutorialPhase + 1
				showTutorialPhase()
			end
		end)
	end
end

advanceTutorialAfterDecision = function(decisionId)
	if not currentTutorialIndex then
		return
	end
	local flow = tutorialFlow[currentTutorialIndex]
	local phase = flow and flow[currentTutorialPhase]
	if phase and phase.target == "decision:" .. decisionId then
		hideSpotlight()
	end
end

lookButton.MouseButton1Click:Connect(function()
	requestTool("look")
end)

setButtonsEnabled(false)

local function layoutOverlays(short)
	if short then
		introCard.Size = UDim2.fromScale(0.94, 0.9)
		introTitle.Position = UDim2.new(0, 16, 0, 8)
		introTitle.Size = UDim2.new(1, -32, 0, 26)
		introTitle.TextSize = 20
		introText.Position = UDim2.new(0, 16, 0, 40)
		introText.Size = UDim2.new(1, -32, 1, -98)
		introText.TextSize = 13
		introButton.Position = UDim2.new(0.1, 0, 1, -46)
		introButton.Size = UDim2.new(0.8, 0, 0, 36)
		introButton.TextSize = 14

		tunnelCard.Size = UDim2.fromScale(0.96, 0.88)
		tunnelTitle.Position = UDim2.new(0, 16, 0, 6)
		tunnelTitle.Size = UDim2.new(1, -32, 0, 26)
		tunnelTitle.TextSize = 20
		tunnelText.Position = UDim2.new(0, 16, 0, 34)
		tunnelText.Size = UDim2.new(1, -32, 0, 62)
		tunnelText.TextSize = 13
		tunnelButtons.Position = UDim2.new(0, 16, 0, 100)
		tunnelButtons.Size = UDim2.new(1, -32, 1, -108)
		tunnelButtonLayout.CellSize = UDim2.new(0.49, -2, 0, 48)
		tunnelButtonLayout.CellPadding = UDim2.new(0, 4, 0, 4)
		tunnelButtonLayout.FillDirectionMaxCells = 2

		resultsCard.Size = UDim2.fromScale(0.94, 0.92)
		resultsTitle.Position = UDim2.new(0, 14, 0, 6)
		resultsTitle.Size = UDim2.new(1, -28, 0, 24)
		resultsTitle.TextSize = 20
		starsLabel.Position = UDim2.new(0, 14, 0, 30)
		starsLabel.Size = UDim2.new(1, -28, 0, 28)
		starsLabel.TextSize = 22
		statsLabel.Position = UDim2.new(0, 14, 0, 60)
		statsLabel.Size = UDim2.new(1, -28, 0, 120)
		statsLabel.TextSize = 14
		payoutLabel.Position = UDim2.new(0, 14, 0, 182)
		payoutLabel.Size = UDim2.new(1, -28, 0, 26)
		payoutLabel.TextSize = 19
		restartButton.Position = UDim2.new(0.1, 0, 1, -48)
		restartButton.Size = UDim2.new(0.8, 0, 0, 38)
		restartButton.TextSize = 14

		feedbackBox.Size = UDim2.fromScale(0.94, 0.4)
		feedbackTitle.Position = UDim2.new(0, 12, 0, 6)
		feedbackTitle.Size = UDim2.new(1, -24, 0, 22)
		feedbackTitle.TextSize = 18
		feedbackText.Position = UDim2.new(0, 12, 0, 32)
		feedbackText.Size = UDim2.new(1, -24, 1, -38)
		feedbackText.TextSize = 12
	else
		introCard.Size = UDim2.fromScale(0.58, 0.62)
		introTitle.Position = UDim2.new(0, 20, 0, 18)
		introTitle.Size = UDim2.new(1, -40, 0, 32)
		introTitle.TextSize = 24
		introText.Position = UDim2.new(0, 24, 0, 58)
		introText.Size = UDim2.new(1, -48, 1, -126)
		introText.TextSize = 14
		introButton.Position = UDim2.new(0.2, 0, 1, -58)
		introButton.Size = UDim2.new(0.6, 0, 0, 40)
		introButton.TextSize = 16

		tunnelCard.Size = UDim2.fromScale(0.54, 0.72)
		tunnelTitle.Position = UDim2.new(0, 24, 0, 20)
		tunnelTitle.Size = UDim2.new(1, -48, 0, 34)
		tunnelTitle.TextSize = 26
		tunnelText.Position = UDim2.new(0, 24, 0, 64)
		tunnelText.Size = UDim2.new(1, -48, 0, 80)
		tunnelText.TextSize = 15
		tunnelButtons.Position = UDim2.new(0, 24, 0, 160)
		tunnelButtons.Size = UDim2.new(1, -48, 1, -180)
		tunnelButtonLayout.CellSize = UDim2.new(1, 0, 0, 30)
		tunnelButtonLayout.CellPadding = UDim2.new(0, 0, 0, 7)
		tunnelButtonLayout.FillDirectionMaxCells = 1

		resultsCard.Size = UDim2.fromScale(0.5, 0.7)
		resultsTitle.Position = UDim2.new(0, 20, 0, 18)
		resultsTitle.Size = UDim2.new(1, -40, 0, 34)
		resultsTitle.TextSize = 26
		starsLabel.Position = UDim2.new(0, 20, 0, 58)
		starsLabel.Size = UDim2.new(1, -40, 0, 38)
		starsLabel.TextSize = 28
		statsLabel.Position = UDim2.new(0, 20, 0, 104)
		statsLabel.Size = UDim2.new(1, -40, 0, 120)
		statsLabel.TextSize = 15
		payoutLabel.Position = UDim2.new(0, 20, 0, 232)
		payoutLabel.Size = UDim2.new(1, -40, 0, 34)
		payoutLabel.TextSize = 22
		restartButton.Position = UDim2.new(0.15, 0, 1, -62)
		restartButton.Size = UDim2.new(0.7, 0, 0, 44)
		restartButton.TextSize = 16

		feedbackBox.Size = UDim2.fromScale(0.62, 0.26)
		feedbackTitle.Position = UDim2.new(0, 16, 0, 10)
		feedbackTitle.Size = UDim2.new(1, -32, 0, 28)
		feedbackTitle.TextSize = 22
		feedbackText.Position = UDim2.new(0, 16, 0, 40)
		feedbackText.Size = UDim2.new(1, -32, 1, -50)
		feedbackText.TextSize = 14
	end
end

local lastCompact = nil

local function updateLayout()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local viewport = camera.ViewportSize
	uiScale.Scale = 1
	local short = viewport.Y < 500
	local compactChanged = lastCompact ~= short
	lastCompact = short
	compactUI = short
	layoutOverlays(short)

	if short then
		topBar.Visible = false

		panel.Position = UDim2.fromScale(0.02, 0.02)
		panel.Size = UDim2.fromScale(0.96, 0.96)

		header.Size = UDim2.new(1, 0, 0, 44)
		nameLabel.TextSize = 19
		nameLabel.Size = UDim2.new(1, -92, 0, 21)
		metaLabel.Position = UDim2.new(0, 0, 0, 20)
		metaLabel.Size = UDim2.new(1, -92, 0, 16)
		metaLabel.TextSize = 12

		photoBox.Parent = header
		photoBox.Position = UDim2.new(1, -82, 0, 1)
		photoBox.Size = UDim2.fromOffset(78, 42)
		photoConstraint.MinSize = Vector2.new(0, 0)
		photoConstraint.MaxSize = Vector2.new(320, 64)
		photoPaper.Position = UDim2.new(0, 4, 0, 4)
		photoPaper.Size = UDim2.new(1, -8, 1, -8)

		body.Position = UDim2.new(0, 0, 0, 44)
		body.Size = UDim2.new(1, 0, 1, -156)

		left.Visible = false
		right.Position = UDim2.new(0, 0, 0, 0)
		right.Size = UDim2.new(1, 0, 1, 0)

		ruleLabel.Size = UDim2.new(1, 0, 0, 30)
		docScroll.Position = UDim2.new(0, 0, 0, 34)
		docScroll.Size = UDim2.new(1, 0, 1, -34)

		actions.Position = UDim2.new(0, 0, 1, -112)
		actions.Size = UDim2.new(1, 0, 0, 112)
		actionLayout.Padding = UDim.new(0, 2)

		toolRow.Size = UDim2.new(1, 0, 0, 24)
		toolResult.Size = UDim2.new(1, 0, 0, 28)
		toolResult.TextSize = 12
		questionRow.Size = UDim2.new(1, 0, 0, 24)
		dialogueLabel.Visible = false
		dialogueLabel.Size = UDim2.new(1, 0, 0, 0)
		decisionRow.Size = UDim2.new(1, 0, 0, 30)
	else
		topBar.Visible = true
		topBar.Size = UDim2.new(1, 0, 0, 56)
		title.Position = UDim2.new(0, 18, 0, 10)
		title.Size = UDim2.new(0, 330, 0, 24)
		title.TextSize = 20
		subtitleLabel.Visible = true
		clockLabel.Visible = true
		progressLabel.Position = UDim2.new(1, -18, 0, 8)
		progressLabel.Size = UDim2.new(0, 240, 0, 20)
		progressLabel.TextSize = 14

		local wide = viewport.X >= 1100
		panel.Position = wide and UDim2.fromScale(0.36, 0.12) or UDim2.fromScale(0.02, 0.12)
		panel.Size = wide and UDim2.fromScale(0.62, 0.88) or UDim2.fromScale(0.96, 0.88)

		header.Size = UDim2.new(1, 0, 0, 48)
		nameLabel.TextSize = 24
		metaLabel.Position = UDim2.new(0, 0, 0, 24)
		metaLabel.TextSize = 14

		body.Position = UDim2.new(0, 0, 0, 52)
		body.Size = UDim2.new(1, 0, 1, -228)

		left.Visible = true
		right.Position = UDim2.new(0.39, 6, 0, 0)
		right.Size = UDim2.new(0.61, -6, 1, 0)

		photoBox.Parent = left
		photoBox.Position = UDim2.new(0, 8, 0, 8)
		photoBox.Size = UDim2.new(1, -16, 0, 64)
		photoConstraint.MinSize = Vector2.new(170, 64)
		photoPaper.Position = UDim2.new(0, 8, 0, 8)
		photoPaper.Size = UDim2.new(1, -16, 1, -16)
		nameLabel.Size = UDim2.new(1, 0, 0, 27)
		metaLabel.Size = UDim2.new(1, 0, 0, 20)

		ruleLabel.Size = UDim2.new(1, 0, 0, 38)
		docScroll.Position = UDim2.new(0, 0, 0, 48)
		docScroll.Size = UDim2.new(1, 0, 1, -48)

		actions.Position = UDim2.new(0, 0, 1, -172)
		actions.Size = UDim2.new(1, 0, 0, 172)
		actionLayout.Padding = UDim.new(0, 4)

		toolRow.Size = UDim2.new(1, 0, 0, 36)
		toolResult.Size = UDim2.new(1, 0, 0, 42)
		toolResult.TextSize = 14
		questionRow.Size = UDim2.new(1, 0, 0, 34)
		dialogueLabel.Visible = false
		dialogueLabel.Size = UDim2.new(1, 0, 0, 0)
		decisionRow.Size = UDim2.new(1, 0, 0, 44)
	end

	if compactChanged and currentData then
		renderDossier(currentData)
	end

	if tutorialLayer.Visible then
		layoutSpotlight()
	end
end

local function connectCamera()
	local camera = workspace.CurrentCamera
	if camera then
		updateLayout()
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateLayout)
	end
end

connectCamera()
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(connectCamera)

local function showTunnel(payload)
	panel.Visible = false
	toast.Visible = false
	feedbackBox.Visible = false
	introOverlay.Visible = false
	if stopTutorial then
		stopTutorial()
	end
	tunnelOverlay.Visible = true
	resultsOverlay.Visible = false
	tunnelActive = true
	tunnelTitle.Text = payload.title or "ЧЁРНАЯ МИЛЯ"
	tunnelText.Text = payload.text or ""
	tunnelText.TextColor3 = Color3.fromRGB(220, 225, 220)

	for _, child in ipairs(tunnelButtons:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	for index, choice in ipairs(payload.choices or {}) do
		local choiceButton = button(tunnelButtons, {
			Name = choice.id,
			LayoutOrder = index,
			Size = UDim2.new(1, 0, 0, 38),
			Text = choice.text,
			BackgroundColor3 = Color3.fromRGB(65, 30, 35),
			TextSize = 13,
		}, function()
			if not tunnelActive then
				return
			end
			tunnelActive = false
			Remotes.TunnelChoice:FireServer(choice.id)
			tunnelText.Text = "Выбор сделан. Поезд входит в тоннель..."
			for _, other in ipairs(tunnelButtons:GetChildren()) do
				if other:IsA("TextButton") then
					other.Active = false
					other.TextTransparency = 0.5
				end
			end
		end)
		corner(choiceButton, 7)
	end
end

local function showTunnelResult(payload)
	tunnelText.Text = payload.text or ""
	tunnelText.TextColor3 = payload.success and Color3.fromRGB(170, 235, 180) or Color3.fromRGB(240, 150, 150)
	tunnelActive = false
	for _, child in ipairs(tunnelButtons:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
end

local function showResult(payload)
	panel.Visible = false
	toast.Visible = false
	feedbackBox.Visible = false
	introOverlay.Visible = false
	if stopTutorial then
		stopTutorial()
	end
	tunnelOverlay.Visible = false
	resultsOverlay.Visible = true
	restartButton.Active = true

	local stars = payload.stars or 1
	starsLabel.Text = string.rep("★", stars) .. string.rep("☆", math.max(0, 3 - stars))
	resultsTitle.Text = payload.tunnelSuccess and "СМЕНА ВЫДЕРЖАНА" or "СМЕНА ПРОВАЛЕНА"
	resultsTitle.TextColor3 = payload.tunnelSuccess and Color3.fromRGB(180, 235, 170) or Color3.fromRGB(245, 160, 150)

	local stats = payload.stats or {}
	statsLabel.Text = table.concat({
		"Верных решений: " .. tostring(stats.correct or 0) .. " / " .. tostring(stats.total or Config.TotalPassengers),
		"Аномалий поймано: " .. tostring(stats.caught or 0),
		"Ошибок: " .. tostring(stats.mistakes or 0),
		"Пропущено на посадке: " .. tostring(stats.missed or 0),
	}, "\n")
	payoutLabel.Text = "+" .. tostring(payload.payout or 0) .. " Искр"
end

local function handleEvent(payload)
	if type(payload) ~= "table" then
		return
	end

	if payload.type == "passenger" then
		showPassenger(payload.data)
	elseif payload.type == "progress" then
		progressText = tostring(payload.index) .. "/" .. tostring(payload.total)
		progressLabel.Text = "ПАССАЖИР " .. tostring(payload.index) .. " / " .. tostring(payload.total)
	elseif payload.type == "feedback" then
		if payload.kind == "info" then
			showToast(payload.kind, payload.text or "")
			setButtonsEnabled(true)
		else
			local text = payload.text or ""
			toolResult.Text = text
			showFeedback(payload.kind or "bad", text, payload.hint)
		end
	elseif payload.type == "intro" then
		introTitle.Text = payload.title or "КАК ИГРАТЬ"
		introText.Text = payload.text or ""
		introOverlay.Visible = true
	elseif payload.type == "tunnel" then
		showTunnel(payload)
	elseif payload.type == "tunnelResult" then
		showTunnelResult(payload)
	elseif payload.type == "quiet" then
		panel.Visible = false
		tunnelOverlay.Visible = true
		resultsOverlay.Visible = false
		tunnelActive = false
		tunnelTitle.Text = payload.title or "ТИХАЯ МИЛЯ"
		tunnelText.Text = payload.text or ""
		tunnelText.TextColor3 = Color3.fromRGB(190, 210, 220)
		for _, child in ipairs(tunnelButtons:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
	elseif payload.type == "result" then
		showResult(payload)
	elseif payload.type == "reset" then
		resultsOverlay.Visible = false
		tunnelOverlay.Visible = false
		introOverlay.Visible = false
		feedbackBox.Visible = false
		if stopTutorial then
			stopTutorial()
		end
		panel.Visible = true
		currentData = nil
		progressText = ""
		clearHighlights()
		nameLabel.Text = "ОЖИДАНИЕ ПАССАЖИРА"
		metaLabel.Text = "Смена начинается..."
		progressLabel.Text = "ПОДГОТОВКА"
		photoHat.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
		photoLabel.Text = "ФОТО: —"
		eyeLabel.Text = "ГЛАЗА: —"
		infoLabel.Text = ""
		ruleLabel.Text = Config.Checklist
		ruleLabel.BackgroundColor3 = Color3.fromRGB(70, 55, 25)
		toolResult.Text = "Смена начинается..."
		dialogueLabel.Text = "Задай вопрос, чтобы услышать историю."
		for _, child in ipairs(docList:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		setButtonsEnabled(false)
	end
end

Remotes.GameEvent.OnClientEvent:Connect(handleEvent)
handleEvent({ type = "reset" })

if RunService:IsStudio() then
	_G.NightConductorTest = {
		startTutorial = function(index)
			if startTutorial then
				startTutorial(index)
			end
		end,
		stopTutorial = function()
			if stopTutorial then
				stopTutorial()
			end
		end,
		showResult = showResult,
		showTunnel = showTunnel,
		showFeedback = showFeedback,
		layout = updateLayout,
	}
end

print("[NightConductor] client ready")

