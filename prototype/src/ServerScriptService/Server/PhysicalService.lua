-- v8 physical slice: 4 passengers in a vestibule, decisions by stamp.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local PassengerFactory = require(script.Parent:WaitForChild("PassengerFactory"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))

local PhysicalService = {}

local activePlayer = nil
local shiftRunning = false
local currentData = nil
local currentModel = nil
local locked = true
local pendingDecision = nil
local decisionSignal = Instance.new("BindableEvent")

-- First physical shift: safe -> six fingers -> wrong shadow -> no reflection.
local SCRIPTED_PLAN = {
	nil,
	"six_fingers",
	"wrong_shadow",
	"no_reflection",
}
local SCRIPTED_HINTS = {
	"Возьми билет и паспорт со стола. Сравни имя и дату. Потом поставь печать.",
	"Проверь руки пассажира. Возьми лупу со стола и поднеси к руке.",
	"Проверь тень. Возьми фонарь и обойди пассажира.",
	"Проверь отражение. Возьми зеркало и наведи его на пассажира.",
}
local SEED = 101

local function send(player, payload)
	if player and player.Parent then
		Remotes.PhysicalEvent:FireClient(player, payload)
	end
end

local function waitForDecision(timeout)
	local done = false
	local connection = decisionSignal.Event:Connect(function()
		done = true
	end)

	local started = os.clock()
	while not done and os.clock() - started < timeout do
		if not activePlayer or not activePlayer.Parent then
			break
		end
		task.wait(0.1)
	end

	connection:Disconnect()
	return done
end

local function evaluate(data, decision, stats)
	local correct = false
	local message

	if decision == "admit" then
		if data.isAnomaly then
			stats.anomaliesOnBoard = stats.anomaliesOnBoard + 1
			stats.mistakes = stats.mistakes + 1
			message = "Аномалия села в поезд. Она уже в тамбуре."
		else
			stats.correct = stats.correct + 1
			correct = true
			message = "Пассажир сел. Пока всё спокойно."
		end
	else
		if data.isAnomaly then
			stats.caught = stats.caught + 1
			stats.correct = stats.correct + 1
			correct = true
			message = "Верно. Пассажир растворился в тени."
		else
			stats.mistakes = stats.mistakes + 1
			message = "Вы отказали невиновному. Он ушёл с обидой."
		end
	end

	return correct, message
end

local function runShift(player)
	WorldBuilder.clearPhysical()

	local character = player.Character or player.CharacterAdded:Wait()
	task.wait(0.4)
	character:PivotTo(WorldBuilder.physicalSpawn)

	send(player, { type = "reset" })

	local stats = {
		correct = 0,
		mistakes = 0,
		caught = 0,
		anomaliesOnBoard = 0,
		total = #SCRIPTED_PLAN,
	}

	for index = 1, #SCRIPTED_PLAN do
		if not player.Parent then
			return
		end

		local data = PassengerFactory.create(index, SEED, SCRIPTED_PLAN[index])
		currentData = data
		currentModel = WorldBuilder.spawnPhysicalPassenger(data)
		locked = false
		pendingDecision = nil

		send(player, {
			type = "passenger",
			index = index,
			total = #SCRIPTED_PLAN,
			tutorial = index == 1,
			hint = SCRIPTED_HINTS[index],
			data = PassengerFactory.publicData(data),
		})

		local gotDecision = waitForDecision(180)
		if not gotDecision then
			send(player, {
				type = "result",
				stars = 1,
				payout = 0,
				tunnelSuccess = false,
				stats = {
					correct = stats.correct,
					mistakes = stats.mistakes,
					caught = stats.caught,
					missed = stats.anomaliesOnBoard,
					total = stats.total,
				},
			})
			return
		end

		local decision = pendingDecision
		pendingDecision = nil
		locked = true

		if decision ~= "admit" and decision ~= "deny" then
			decision = "deny"
		end

		local correct, message = evaluate(data, decision, stats)
		local hint = data.isAnomaly and data.anomalyId and Config.Anomalies[data.anomalyId] and Config.Anomalies[data.anomalyId].hint or nil
		if not correct and not data.isAnomaly then
			hint = "Все документы, тень и отражение совпадали. Невиновных нужно пропускать."
		end

		send(player, {
			type = "feedback",
			kind = correct and "good" or "bad",
			text = message,
			hint = hint,
			anomalyName = data.isAnomaly and Config.Anomalies[data.anomalyId] and Config.Anomalies[data.anomalyId].name or nil,
			correct = correct,
		})

		if currentModel then
			if decision == "admit" then
				WorldBuilder.movePassenger(currentModel, CFrame.lookAt(Vector3.new(0, 3, -4.8), Vector3.new(0, 3, -8)), 1.4)
			else
				WorldBuilder.movePassenger(currentModel, CFrame.lookAt(Vector3.new(6, 3, 3.5), Vector3.new(9, 3, 3.5)), 1.4)
			end
		end
		task.wait(0.2)
		WorldBuilder.clearPhysical()
		currentData = nil
		currentModel = nil
		task.wait(0.8)
	end

	local stars = 1
	if stats.mistakes == 0 then
		stars = 3
	elseif stats.mistakes <= 2 then
		stars = 2
	end

	local payout = 100 + stats.correct * 30 + stats.caught * 50 - stats.mistakes * 20
	payout = math.max(0, payout)

	send(player, {
		type = "result",
		stars = stars,
		payout = payout,
		tunnelSuccess = true,
		stats = {
			correct = stats.correct,
			mistakes = stats.mistakes,
			caught = stats.caught,
			missed = stats.anomaliesOnBoard,
			total = stats.total,
		},
	})
end

local function startShift(player)
	if shiftRunning or not player or not player.Parent then
		return
	end

	shiftRunning = true
	activePlayer = player

	task.spawn(function()
		local ok, err = pcall(runShift, player)
		if not ok then
			warn("[NightConductor] physical shift error: " .. tostring(err))
		end
		shiftRunning = false
	end)
end

function PhysicalService.init()
	WorldBuilder.buildVestibule()

	Remotes.PhysicalDecide.OnServerEvent:Connect(function(player, decision)
		if player ~= activePlayer or locked or not currentData then
			return
		end
		if decision ~= "admit" and decision ~= "deny" then
			return
		end
		locked = true
		pendingDecision = decision
		decisionSignal:Fire()
	end)

	Remotes.PhysicalRestart.OnServerEvent:Connect(function(player)
		if player ~= activePlayer or shiftRunning then
			return
		end
		startShift(player)
	end)

	Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			task.wait(2)
			if not activePlayer then
				startShift(player)
			end
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		if activePlayer == player then
			activePlayer = nil
			currentData = nil
			currentModel = nil
			locked = true
		end
		task.delay(1.5, function()
			if not shiftRunning then
				local nextPlayer = Players:GetPlayers()[1]
				if nextPlayer then
					startShift(nextPlayer)
				end
			end
		end)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			task.wait(1)
			if not activePlayer then
				startShift(player)
			end
		end)
	end
end

return PhysicalService
