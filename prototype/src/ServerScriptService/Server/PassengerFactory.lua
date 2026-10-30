-- Creates deterministic passenger cases for the prototype.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local PassengerFactory = {}

local function pick(rng, list)
	return list[rng:NextInteger(1, #list)]
end

local function makeTicketNumber(rng)
	return tostring(rng:NextInteger(10000, 99999))
end

local function makePassportNumber(rng)
	return "NC-" .. tostring(rng:NextInteger(1000, 9999))
end

local function makeColor(rng)
	return Color3.fromRGB(rng:NextInteger(35, 220), rng:NextInteger(35, 220), rng:NextInteger(35, 220))
end

local function cloneTable(value)
	if type(value) ~= "table" then
		return value
	end
	local result = {}
	for key, child in pairs(value) do
		result[key] = cloneTable(child)
	end
	return result
end

-- The first shift is scripted so the player learns each tool once.
-- Later shifts get 2-3 random anomalies.
function PassengerFactory.buildPlan(seed)
	if seed == 1 then
		return {
			[1] = nil,
			[2] = "wrong_date",
			[3] = "wrong_shadow",
			[4] = "no_reflection",
			[5] = "six_fingers",
			[6] = nil,
		}
	end

	local rng = Random.new(seed)
	local anomalyIds = { "wrong_date", "wrong_shadow", "no_reflection", "six_fingers", "photo_mismatch" }
	for index = #anomalyIds, 2, -1 do
		local swap = rng:NextInteger(1, index)
		anomalyIds[index], anomalyIds[swap] = anomalyIds[swap], anomalyIds[index]
	end

	local indices = { 1, 2, 3, 4, 5, 6 }
	for index = #indices, 2, -1 do
		local swap = rng:NextInteger(1, index)
		indices[index], indices[swap] = indices[swap], indices[index]
	end

	local count = rng:NextInteger(2, 3)
	local plan = {}
	for index = 1, count do
		plan[indices[index]] = anomalyIds[index]
	end
	return plan
end

function PassengerFactory.create(index, seed, anomalyId)
	local rng = Random.new(seed + index * 7919)
	local name = pick(rng, Config.PassengerNames)
	local destination = pick(rng, Config.Destinations)
	local origin = pick(rng, Config.Origins)
	local contents = pick(rng, Config.LuggageContents)
	local hat = pick(rng, Config.HatColors)
	local eyeColor = pick(rng, Config.EyeColors)
	local seat = tostring(index + 2) .. (index % 2 == 0 and "A" or "B")
	local class = index % 3 == 0 and "first" or "second"
	local ticketNumber = makeTicketNumber(rng)
	local passportNumber = makePassportNumber(rng)
	local price = rng:NextInteger(12, 48)

	local data = {
		id = "P" .. tostring(index),
		name = name,
		age = rng:NextInteger(18, 67),
		species = "human",
		seat = seat,
		class = class,
		destination = destination,
		rule = Config.Rule,
		isAnomaly = false,
		anomalyId = nil,
		extraFinger = false,
		noReflection = false,
		shadowWrong = false,
		appearance = {
			shirtColor = makeColor(rng),
			pantsColor = makeColor(rng),
			skinColor = Color3.fromRGB(rng:NextInteger(120, 220), rng:NextInteger(90, 180), rng:NextInteger(70, 150)),
			hatColor = hat.color,
			hatName = hat.name,
			eyeColor = eyeColor,
		},
		ticket = {
			number = ticketNumber,
			from = "Станция 0",
			to = destination,
			date = Config.Today,
			seat = seat,
			class = class,
			price = price,
			stamp = "LIVE",
		},
		passport = {
			number = passportNumber,
			origin = origin,
			seal = "СОЛОВЕЙ",
			photoHatName = hat.name,
			eyeColor = eyeColor,
		},
		luggage = {
			tag = "T-" .. ticketNumber,
			weight = rng:NextInteger(4, 24),
			contents = contents,
		},
		answers = {
			destination = "На " .. destination .. ".",
			luggage = "Там " .. contents .. ".",
			name = "Меня зовут " .. name .. ".",
		},
	}

	if anomalyId == "wrong_date" then
		data.isAnomaly = true
		data.anomalyId = anomalyId
		data.ticket.date = "12.04.1912"
		data.ticket.stamp = "ARCHIVE"
		data.answers.destination = "В 1912-й. Там меня ждут."
	elseif anomalyId == "no_reflection" then
		data.isAnomaly = true
		data.anomalyId = anomalyId
		data.noReflection = true
		data.answers.name = "Я... не помню."
	elseif anomalyId == "wrong_shadow" then
		data.isAnomaly = true
		data.anomalyId = anomalyId
		data.shadowWrong = true
	elseif anomalyId == "six_fingers" then
		data.isAnomaly = true
		data.anomalyId = anomalyId
		data.extraFinger = true
		data.answers.luggage = "Перчатки. Одна пара."
	elseif anomalyId == "photo_mismatch" then
		data.isAnomaly = true
		data.anomalyId = anomalyId
		local otherHat = pick(rng, Config.HatColors)
		while otherHat.name == hat.name do
			otherHat = pick(rng, Config.HatColors)
		end
		data.passport.photoHatName = otherHat.name
	end

	return data
end

function PassengerFactory.publicData(data)
	return {
		id = data.id,
		name = data.name,
		age = data.age,
		species = data.species,
		seat = data.seat,
		class = data.class,
		destination = data.destination,
		rule = data.rule,
		ticket = cloneTable(data.ticket),
		passport = cloneTable(data.passport),
		luggage = cloneTable(data.luggage),
		appearance = cloneTable(data.appearance),
	}
end

return PassengerFactory
