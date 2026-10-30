-- Server-authoritative prototype flow: 6 passengers -> tunnel -> results.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local PassengerFactory = require(script.Parent:WaitForChild("PassengerFactory"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))

local GameService = {}

local activePlayer = nil
local shiftRunning = false
local currentPassenger = nil
local currentModel = nil
local locked = false
local held = false
local pendingDecision = nil
local tunnelChoice = nil
local tunnelOpen = false
local shiftTools = {}
local toolUses = {}
local runCounts = {}

local decisionSignal = Instance.new("BindableEvent")
local tunnelSignal = Instance.new("BindableEvent")

local validTunnelChoices = {}
for _, choice in ipairs(Config.TunnelChoices) do
	validTunnelChoices[choice.id] = true
end

local function send(player, payload)
	if player and player.Parent then
		Remotes.GameEvent:FireClient(player, payload)
	end
end

local function anomalyName(data)
	if data and data.isAnomaly and data.anomalyId and Config.Anomalies[data.anomalyId] then
		return Config.Anomalies[data.anomalyId].name
	end
	return nil
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

local function waitForTunnel(timeout)
	local done = false
	local connection = tunnelSignal.Event:Connect(function()
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

local function evaluateDecision(data, decision, stats)
	local correct = false
	local message

	if decision == "admit" then
		if data.isAnomaly then
			stats.anomaliesOnBoard = stats.anomaliesOnBoard + 1
			stats.mistakes = stats.mistakes + 1
			message = "Аномалия села в поезд. Она уже в вагоне."
		else
			stats.correct = stats.correct + 1
			correct = true
			message = "Пассажир сел. Пока всё спокойно."
		end
	elseif decision == "deny" then
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

local function runTunnel(player, stats)
	if stats.anomaliesOnBoard > 0 then
		tunnelChoice = nil
		tunnelOpen = true
		send(player, {
			type = "tunnel",
			title = "ЧЁРНАЯ МИЛЯ",
			text = "Аномалия на борту. Свет гаснет. У тебя 12 секунд, чтобы выбрать действие.",
			choices = Config.TunnelChoices,
		})

		waitForTunnel(14)
		tunnelOpen = false

		local choice = tunnelChoice or "hide"
		if not validTunnelChoices[choice] then
			choice = "hide"
		end

		local chances = {
			expose = 0.55,
			contain = 0.6,
			brake = 0.5,
			hide = 0.3,
		}
		if choice == "expose" and shiftTools.mirror then
			chances.expose = chances.expose + 0.2
		end

		local success = math.random() < chances[choice]
		local text
		if success then
			stats.caught = stats.caught + stats.anomaliesOnBoard
			if choice == "expose" then
				text = "Зеркало вспыхнуло. Аномалия закричала и рассыпалась. Поезд вышел из тоннеля."
			elseif choice == "contain" then
				text = "Вы заперли вагон. Что-то стучало всю дорогу, но поезд цел."
			elseif choice == "brake" then
				text = "Стоп-кран завизжал. Поезд встал в тоннеле. Аномалия не успела."
			else
				text = "Вы переждали в тамбуре. Аномалия прошла мимо."
			end
		else
			stats.mistakes = stats.mistakes + 1
			text = "Аномалия добралась до Сердца. Поезд потерял вагон. Смена окончена."
		end

		send(player, {
			type = "tunnelResult",
			success = success,
			text = text,
			choice = choice,
		})
		task.wait(3.2)
		return success
	end

	send(player, {
		type = "quiet",
		title = "ТИХАЯ МИЛЯ",
		text = "Аномалий нет. Поезд проходит станцию, которой нет на карте. Кот смотрит в окно.",
	})
	task.wait(3)
	return true
end

local function runShift(player)
	WorldBuilder.build()
	shiftTools = {}

	local character = player.Character or player.CharacterAdded:Wait()
	task.wait(0.3)
	character:PivotTo(WorldBuilder.spawnCFrame)

	send(player, { type = "reset" })

	local runNumber = (runCounts[player] or 0) + 1
	runCounts[player] = runNumber
	local seed = runNumber == 1 and 1 or math.random(2, 1000000000)
	local plan = PassengerFactory.buildPlan(seed)

	local stats = {
		correct = 0,
		mistakes = 0,
		caught = 0,
		anomaliesOnBoard = 0,
		total = Config.TotalPassengers,
	}

	for index = 1, Config.TotalPassengers do
		if not player.Parent then
			return
		end

		local data = PassengerFactory.create(index, seed, plan[index])
		local model = WorldBuilder.spawnPassenger(data)
		currentPassenger = data
		currentModel = model
		locked = false
		held = false
		pendingDecision = nil
		toolUses = {}

		send(player, {
			type = "progress",
			index = index,
			total = Config.TotalPassengers,
		})
		task.wait(0.25)

		WorldBuilder.movePassenger(model, WorldBuilder.boothCFrame, 1.1)
		local publicData = PassengerFactory.publicData(data)
		if runNumber == 1 then
			local tutorial = Config.Tutorial[index]
			if tutorial then
				publicData.tutorial = {
					index = index,
					text = tutorial.text,
					tool = tutorial.tool,
					decision = tutorial.decision,
				}
			end
		end
		send(player, {
			type = "passenger",
			data = publicData,
		})

		local gotDecision = waitForDecision(60)
		if not gotDecision then
			if currentModel then
				WorldBuilder.removePassenger(currentModel)
			end
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
		if decision ~= "admit" and decision ~= "deny" then
			decision = "deny"
		end

		local correct, message = evaluateDecision(data, decision, stats)
		local name = anomalyName(data)
		local hint = data.isAnomaly and data.anomalyId and Config.Anomalies[data.anomalyId] and Config.Anomalies[data.anomalyId].hint or nil
		if not correct and not data.isAnomaly then
			hint = "Все документы и фото совпадали. Невиновных нужно пропускать."
		end

		send(player, {
			type = "feedback",
			kind = correct and "good" or "bad",
			text = message,
			anomalyName = name,
			hint = hint,
			correct = correct,
		})

		if decision == "admit" then
			WorldBuilder.movePassenger(model, WorldBuilder.trainDoorCFrame, 1.0)
			task.wait(0.9)
		else
			WorldBuilder.movePassenger(model, WorldBuilder.exitCFrame, 1.0)
			task.wait(0.9)
		end

		WorldBuilder.removePassenger(model)
		currentPassenger = nil
		currentModel = nil
		locked = false
		held = false
		task.wait(0.9)
	end

	local tunnelSuccess = runTunnel(player, stats)
	if not player.Parent then
		return
	end

	local stars = 1
	if stats.mistakes == 0 then
		stars = 3
	elseif stats.mistakes <= 2 then
		stars = 2
	end
	if stats.anomaliesOnBoard > 0 and not tunnelSuccess then
		stars = math.min(stars, 1)
	end

	local payout = 100 + stats.correct * 25 + stats.caught * 50 + (tunnelSuccess and 150 or 0) - stats.mistakes * 15
	payout = math.max(0, payout)

	send(player, {
		type = "result",
		stars = stars,
		payout = payout,
		stats = {
			correct = stats.correct,
			mistakes = stats.mistakes,
			caught = stats.caught,
			missed = stats.anomaliesOnBoard,
			total = stats.total,
		},
		tunnelSuccess = tunnelSuccess,
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
			warn("[NightConductor] " .. tostring(err))
		end
		shiftRunning = false
	end)
end

function GameService.init()
	WorldBuilder.build()

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			task.wait(1)
			startShift(player)
		end)
	end

	Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			task.wait(2)
			startShift(player)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		runCounts[player] = nil
		if activePlayer == player then
			activePlayer = nil
			currentPassenger = nil
			currentModel = nil
			locked = true
			tunnelOpen = false
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

	Remotes.Inspect.OnServerInvoke = function(player, toolId)
		if player ~= activePlayer or not currentPassenger or locked then
			return { ok = false, text = "Сейчас нельзя." }
		end
		if type(toolId) ~= "string" then
			return { ok = false, text = "Неизвестный инструмент." }
		end

		local limits = {
			mirror = 2,
			lamp = 2,
			magnifier = 2,
			look = 2,
			compass = 1,
			cat = 1,
		}
		local used = (toolUses[toolId] or 0) + 1
		if used > (limits[toolId] or 2) then
			return { ok = false, text = "Инструмент уже дал всё, что мог. Попробуй другой." }
		end
		toolUses[toolId] = used

		shiftTools[toolId] = true
		local data = currentPassenger

		if toolId == "mirror" then
			if data.noReflection then
				return { ok = true, text = "В зеркале на месте пассажира — пусто. Только стена." }
			end
			return { ok = true, text = "Отражение совпадает. Пассажир выглядит обычно." }
		elseif toolId == "lamp" then
			if data.shadowWrong then
				return { ok = true, text = "Тень падает в сторону лампы, а не от неё. Это неправильно." }
			end
			return { ok = true, text = "Тень на месте, пламя ровное. Холода нет." }
		elseif toolId == "magnifier" then
			if data.ticket.date ~= Config.Today then
				return { ok = true, text = "Дата на билете: " .. data.ticket.date .. ". Сегодня " .. Config.Today .. ". Это несоответствие." }
			end
			if data.extraFinger then
				return { ok = true, text = "На правой руке шесть пальцев. Перчатка не скрывает лишний." }
			end
			if data.passport.photoHatName ~= data.appearance.hatName then
				return { ok = true, text = "На фото — " .. data.passport.photoHatName .. " шляпа. На пассажире — " .. data.appearance.hatName .. "." }
			end
			return { ok = true, text = "Печать, дата и подпись выглядят обычно." }
		elseif toolId == "compass" then
			if data.isAnomaly then
				return { ok = true, text = "Стрелка дёргается и крутится. Рядом аномалия." }
			end
			return { ok = true, text = "Стрелка спокойна." }
		elseif toolId == "cat" then
			if data.isAnomaly then
				return { ok = true, text = "Кот шипит и прячется за стойку." }
			end
			return { ok = true, text = "Кот мурчит и трётся о ногу." }
		elseif toolId == "look" then
			return { ok = true, text = "На пассажире " .. data.appearance.hatName .. " шляпа. Глаза " .. data.appearance.eyeColor .. ". Он выглядит спокойным." }
		end

		return { ok = false, text = "Инструмент не отвечает." }
	end

	Remotes.Ask.OnServerInvoke = function(player, questionId)
		if player ~= activePlayer or not currentPassenger or locked then
			return { ok = false, text = "Сейчас нельзя." }
		end

		local answer = currentPassenger.answers[questionId]
		if answer then
			return { ok = true, text = answer }
		end
		return { ok = false, text = "Пассажир не понял вопрос." }
	end

	Remotes.Decide.OnServerEvent:Connect(function(player, decision)
		if player ~= activePlayer or not currentPassenger or locked then
			return
		end

		if decision == "hold" then
			if held then
				send(player, { type = "feedback", kind = "info", text = "Пассажир уже задержан. Проверьте документы ещё раз." })
			else
				held = true
				send(player, { type = "feedback", kind = "info", text = "Пассажир ждёт в стороне. Можно использовать инструменты ещё раз." })
			end
			return
		end

		if decision ~= "admit" and decision ~= "deny" then
			return
		end

		locked = true
		pendingDecision = decision
		decisionSignal:Fire()
	end)

	Remotes.TunnelChoice.OnServerEvent:Connect(function(player, choice)
		if player ~= activePlayer or not tunnelOpen or tunnelChoice ~= nil then
			return
		end
		if not validTunnelChoices[choice] then
			return
		end
		tunnelChoice = choice
		tunnelSignal:Fire()
	end)

	Remotes.Restart.OnServerEvent:Connect(function(player)
		if player ~= activePlayer then
			return
		end

		task.spawn(function()
			local started = os.clock()
			while shiftRunning and os.clock() - started < 3 do
				task.wait(0.1)
			end
			if player == activePlayer and not shiftRunning then
				startShift(player)
			end
		end)
	end)
end

return GameService
