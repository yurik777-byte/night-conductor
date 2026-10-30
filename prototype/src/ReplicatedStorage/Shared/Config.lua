-- NIGHT CONDUCTOR — prototype configuration
local Config = {}

Config.GameName = "NIGHT CONDUCTOR"
Config.Version = "0.1-prototype"
Config.TotalPassengers = 6
Config.Today = "30.10.2026"
Config.Rule = "Аномалия может быть в любом канале. Дата — только одна из проверок."
Config.Checklist = "ПРОВЕРЬ: ДАТА · ИМЯ · ФОТО · ОТРАЖЕНИЕ · ТЕНЬ · РУКИ"
Config.TutorialIntro = "Ты — ночной кондуктор.\n\n1. Сверь билет и паспорт: имя, дата, место.\n2. Сравни фото: шляпа и глаза.\n3. Проверь отражение (ЗЕРКАЛО) и тень (ЛАМПА).\n4. Аномалия может быть в любом канале.\n\nВсё совпало — ПРОПУСТИТЬ.\nЧто-то не так — ОТКАЗАТЬ."
Config.Tutorial = {
	[1] = {
		text = "УЧЕБНЫЙ ПАССАЖИР. Сверь имя и дату. Всё совпадает? Нажми ПРОПУСТИТЬ.",
		decision = "admit",
	},
	[2] = {
		text = "ДАТА НЕ СОВПАДАЕТ: 12.04.1912 вместо 30.10.2026. Нажми ОТКАЗАТЬ.",
		tool = "magnifier",
		decision = "deny",
	},
	[3] = {
		text = "ДАТА ВЕРНАЯ — ЭТО ЛОВУШКА. Проверь тень: нажми ЛАМПА.",
		tool = "lamp",
		decision = "deny",
	},
	[4] = {
		text = "ПРОВЕРЬ ОТРАЖЕНИЕ: нажми ЗЕРКАЛО.",
		tool = "mirror",
		decision = "deny",
	},
	[5] = {
		text = "ПРОВЕРЬ РУКИ: нажми ЛУПА или ОСМОТР.",
		tool = "magnifier",
		decision = "deny",
	},
	[6] = {
		text = "ТЕПЕРЬ САМ. Проверь билет, фото, отражение и тень.",
	},
}

Config.PassengerNames = {
	"Мира Вельт",
	"Оскар Пенн",
	"Лира Нокт",
	"Сол Вейд",
	"Ирис Мор",
	"Тобиас Кроу",
	"Нэя Свет",
	"Финн Гарр",
	"Ада Лун",
	"Рэй Стоун",
}

Config.Destinations = {
	"Станция Свечей",
	"Станция Зеркал",
	"Станция Забвения",
	"Станция Садов",
	"Последняя станция",
}

Config.Origins = {
	"Город Полуночи",
	"Деревня Фонарей",
	"Остров Тумана",
	"Нижние Сады",
	"Порт Снов",
}

Config.LuggageContents = {
	"книга со странными страницами",
	"банка светлячков",
	"старый компас",
	"коробка с чаем",
	"свёрток с тёплым шарфом",
	"клетка с механической птицей",
}

Config.HatColors = {
	{ name = "красная", color = Color3.fromRGB(180, 60, 60) },
	{ name = "зелёная", color = Color3.fromRGB(60, 140, 90) },
	{ name = "синяя", color = Color3.fromRGB(60, 90, 170) },
	{ name = "жёлтая", color = Color3.fromRGB(210, 180, 60) },
	{ name = "фиолетовая", color = Color3.fromRGB(120, 70, 160) },
}

Config.EyeColors = {
	"зелёные",
	"серые",
	"карие",
	"янтарные",
	"бледно-голубые",
}

Config.Anomalies = {
	wrong_date = {
		name = "Билет из прошлого",
		tier = 1,
		tool = "magnifier",
		hint = "Дата на билете не совпадает с сегодняшним днём.",
	},
	wrong_shadow = {
		name = "Тень не там",
		tier = 1,
		tool = "lamp",
		hint = "Тень падает в сторону лампы, а не от неё.",
	},
	no_reflection = {
		name = "Без отражения",
		tier = 1,
		tool = "mirror",
		hint = "В зеркале пассажир не отражается.",
	},
	six_fingers = {
		name = "Лишний палец",
		tier = 1,
		tool = "magnifier",
		hint = "На правой руке шесть пальцев.",
	},
	photo_mismatch = {
		name = "Чужое фото",
		tier = 1,
		tool = "look",
		hint = "Шляпа на фото не совпадает с той, что на пассажире.",
	},
}

Config.Questions = {
	{ id = "destination", text = "Куда вы едете?" },
	{ id = "luggage", text = "Что у вас в багаже?" },
	{ id = "name", text = "Как вас зовут?" },
}

Config.TunnelChoices = {
	{ id = "expose", text = "РАЗОБЛАЧИТЬ (зеркало)" },
	{ id = "contain", text = "ИЗОЛИРОВАТЬ ВАГОН" },
	{ id = "brake", text = "СТОП-КРАН" },
	{ id = "hide", text = "СПРЯТАТЬСЯ" },
}

return Config
