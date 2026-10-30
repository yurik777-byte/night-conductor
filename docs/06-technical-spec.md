# 06. Техническая спецификация

**Движок:** Roblox Studio / Luau  
**Архитектура:** server-authoritative, data-driven, state machine  
**Цель:** 30 FPS на среднем телефоне, 4 игрока, 8 NPC, без утечек памяти.

---

## 1. Структура проекта

```
src/
  ServerScriptService/
    Bootstrap.server.lua
    Services/
      MatchService.lua
      PassengerService.lua
      AnomalyService.lua
      InspectionService.lua
      TunnelService.lua
      EconomyService.lua
      DataService.lua
      AnalyticsService.lua
      ModerationService.lua
  ReplicatedStorage/
    Shared/
      Config/
        Anomalies.lua
        Passengers.lua
        NightRules.lua
        TunnelEvents.lua
        Economy.lua
      Types.lua
      Remotes.lua
      Util/
        RandomUtil.lua
        TableUtil.lua
        Format.lua
    Assets/
      Models/
      UI/
      Audio/
  StarterPlayer/
    StarterPlayerScripts/
      ClientMain.client.lua
      Controllers/
        UIController.lua
        InspectionController.lua
        ToolController.lua
        TunnelController.lua
        ShopController.lua
        AudioController.lua
    StarterCharacterScripts/
      ConductorController.client.lua
  StarterGui/
    HUD/
    InspectionUI/
    ShopUI/
    ResultsUI/
```

**Правило:** клиент не хранит игровую истину. Он рисует то, что прислал сервер, и отправляет интенты.

---

## 2. Состояния смены

```lua
export type NightPhase =
    "LOBBY"
    | "BOARDING"
    | "DEPARTING"
    | "IN_TRANSIT"
    | "TUNNEL"
    | "ARRIVAL"
    | "RESULTS"
```

### Переходы

```
LOBBY
  -> BOARDING (все ready)
  -> DEPARTING (очередь пуста / таймер)
  -> IN_TRANSIT (поезд едет)
  -> TUNNEL (триггер)
  -> ARRIVAL (тоннель окончен)
  -> BOARDING (следующая станция)
  -> RESULTS (последняя станция)
  -> LOBBY
```

**Сервер** хранит `phase` в атрибуте `NightState` и проверяет каждый запрос:

```lua
local function assertPhase(expected)
    if night:GetAttribute("Phase") ~= expected then
        return false, "WRONG_PHASE"
    end
    return true
end
```

---

## 3. Схемы данных

### 3.1. Аномалия

```lua
export type TellChannel =
    "document" | "visual" | "behavior" | "audio" | "object" | "social" | "meta"

export type Tell = {
    channel: TellChannel,
    text: string,          -- для codex/подсказки
    tool: string?,         -- "mirror" | "lamp" | "compass" | "watch" | "magnifier" | "cat"
    severity: number,      -- 1..3
}

export type AnomalyDef = {
    id: string,
    name: string,
    tier: 1 | 2 | 3 | 4,
    tags: { string },
    weight: number,
    minChapter: number,
    tells: { Tell },
    checks: { string },
    tunnelEvent: string?,
    reward: number,
    isBenevolent: boolean?,
}
```

### 3.2. Пассажир

```lua
export type PassengerData = {
    id: string,
    name: string,
    age: number,
    species: "human" | "mage" | "spirit" | "cat" | "other",
    seat: string,
    class: "second" | "first" | "staff",
    destination: string,
    ticket: {
        number: string,
        date: string,
        stamp: string,
        price: number,
    },
    passport: {
        number: string,
        photoId: string,
        origin: string,
        seal: string,
    },
    luggage: {
        tag: string,
        weight: number,
        contents: string,
    },
    dialogue: { string },
    -- server-only:
    isAnomaly: boolean,
    anomalyId: string?,
    tells: { Tell },
}
```

**Клиент никогда не получает `isAnomaly` и `anomalyId`.** Всё, что нужно для визуала, применяется к модели (например, `NoReflection`), но не как единый флаг «аномалия».

### 3.3. Состояние ночи

```lua
export type NightState = {
    seed: number,
    chapter: number,
    stationIndex: number,
    passengers: { PassengerData },
    onboard: { string },        -- passengerId
    decisions: { [string]: "admit" | "deny" | "hold" },
    mistakes: number,
    trust: number,              -- 5..0
    anomaliesOnBoard: number,
    tunnelPlayed: number,
}
```

---

## 4. Генерация пассажиров

### 4.1. Сид

```lua
local seed = night.seed + stationIndex * 1000 + passengerIndex
local rng = Random.new(seed)
```

Сид нужен для воспроизводимости багов и турниров.

### 4.2. Алгоритм

1. Выбрать архетип из пула главы.
2. Сгенерировать имя, возраст, вид, станцию, место.
3. Сгенерировать документы.
4. Решить, аномалия ли это:
   - `anomalyBudget > 0`;
   - `rng:NextNumber() < anomalyChance`;
   - выбрать аномалию по весу, не повторяя;
   - применить tells.
5. Иначе — «красная селёдка» с вероятностью 10–15% (странный, но не аномалия).
6. Проверить: хотя бы одна документная и одна сенсорная подсказка.
7. Записать в `NightState`.

### 4.3. Применение tells

```lua
-- Сервер:
local function applyTell(npc, tell)
    if tell.channel == "visual" and tell.tool == "mirror" then
        npc:SetAttribute("NoReflection", true)
    elseif tell.channel == "behavior" then
        npc:SetAttribute("BlinkRate", 0)
    elseif tell.channel == "object" then
        npc:SetAttribute("LuggageBreathing", true)
    end
end
```

**Важно:** атрибуты — часть модели, их можно увидеть эксплойтом. Не храните в них `IsAnomaly`. Если атрибут слишком явно выдаёт ответ (например, `AnomalyId`), не используйте его на клиенте.

---

## 5. Проверка: серверные API

### 5.1. Открытие пассажира

```lua
-- Client -> Server
RemoteFunction:InvokeServer("OpenPassenger", passengerId)
-- Server -> Client
{
    id = passengerId,
    name = "...",
    ticket = {...},
    passport = {...},
    luggage = {...},
    dialogue = {...},
    rule = "...",
}
```

Сервер проверяет:
- фаза `BOARDING`;
- пассажир в очереди;
- дистанция < 12 studs;
- rate limit (не чаще 1 раза в 0.5 сек).

### 5.2. Использование инструмента

```lua
-- Client -> Server
RemoteFunction:InvokeServer("UseTool", toolId, passengerId)
-- Server -> Client
{
    ok = true,
    channel = "visual",
    text = "В зеркале на месте пассажира пусто.",
    highlight = "mirror",
}
```

Сервер:
- проверяет кулдаун инструмента (2–4 сек);
- проверяет, что инструмент открыт;
- возвращает **текст**, а не `isAnomaly`;
- для Tier 1–2 может вернуть «ничего необычного», если подсказка не в этом канале.

### 5.3. Вопрос

```lua
RemoteFunction:InvokeServer("AskQuestion", passengerId, questionId)
```

Сервер выбирает ответ из `dialogue`, проверяет, не задавали ли уже, лимит 2 вопроса.

### 5.4. Решение

```lua
RemoteEvent:FireServer("SubmitDecision", passengerId, "admit" | "deny" | "hold")
```

Сервер:
- проверяет фазу;
- проверяет, что пассажир ещё не решён;
- применяет последствия;
- если `admit` и `isAnomaly` — добавляет в `anomaliesOnBoard`;
- если `deny` и `not isAnomaly` — `mistakes += 1`, `trust -= 1`;
- если `hold` — ставит в `held`, разрешает ещё один вопрос/инструмент;
- отправляет клиенту результат.

---

## 6. Тоннель

### 6.1. Запуск

```lua
TunnelService:Play(night, reason)
-- reason: "anomaly" | "stowaway" | "quiet" | "finale"
```

Сервер:
- выбирает событие по главе/сиду;
- блокирует обычные действия;
- отправляет клиенту `TunnelStart` с типом и таймером;
- ждёт выбор игрока (10 сек);
- если нет выбора — default `"hide"`.

### 6.2. Выбор

```lua
RemoteEvent:FireServer("TunnelChoice", "expose" | "contain" | "brake" | "hide")
```

Сервер:
- проверяет фазу `TUNNEL`;
- проверяет, что выбор ещё не сделан;
- рассчитывает исход по таблице;
- применяет урон/награду;
- отправляет `TunnelResult`.

### 6.3. Исходы

```lua
local OUTCOMES = {
    expose = { success = 0.7, partial = 0.2, fail = 0.1 },
    contain = { success = 0.5, partial = 0.4, fail = 0.1 },
    brake = { success = 0.6, partial = 0.3, fail = 0.1 },
    hide = { success = 0.3, partial = 0.4, fail = 0.3 },
}
```

Модификаторы:
- инструменты (зеркало 2+);
- `trust` (5+);
- количество аномалий;
- ночное правило.

**Никакого чистого рандома без подсказок.** Игрок должен видеть, почему шанс изменился.

---

## 7. Экономика и сохранения

### 7.1. DataStore

Рекомендуется `ProfileStore` (community) или собственный слой с:
- session locking;
- retry с exponential backoff;
- autosave каждые 60 сек;
- backup snapshot;
- версионирование схемы.

```lua
local DATA_VERSION = 3
local DEFAULT = {
    version = DATA_VERSION,
    sparks = 0,
    moons = 0,
    xp = 0,
    rank = 1,
    chapter = 1,
    unlocked = {},
    codex = {},
    badges = {},
    cosmetics = {},
    settings = { safeMode = false, music = 0.8 },
}
```

### 7.2. Награды

- Сервер считает выплату.
- Клиент только показывает.
- Purchase history — в DataStore.
- Никаких «клиент говорит, сколько у него Искр».

### 7.3. Покупки

- `MarketplaceService:PromptGamePassPurchase`.
- `ProcessReceipt` — идемпотентно, с проверкой `PurchaseId`.
- Выдавать товар только после успешной записи.
- Логировать в Analytics.

---

## 8. Античит

| Угроза | Митигация |
|---|---|
| Клиент подделывает решение | Сервер проверяет `passengerId`, фазу, право |
| Клиент читает `isAnomaly` | Не реплицировать; не хранить флаг в модели |
| Клиент накручивает Искры | Валюта только на сервере |
| Клиент спамит инструменты | Кулдаун + rate limit |
| Клиент открывает UI вне фазы | Проверка фазы |
| Клиент телепортируется | Проверка дистанции |
| Клиент подделывает purchase | `ProcessReceipt` + идемпотентность |

**Правило:** если это влияет на результат — это решает сервер.

---

## 9. Аналитика

### 9.1. Воронка

```lua
AnalyticsService:LogFunnelStepEvent(player, "onboarding", 1) -- impression
AnalyticsService:LogFunnelStepEvent(player, "onboarding", 2) -- play
AnalyticsService:LogFunnelStepEvent(player, "onboarding", 3) -- tutorial_start
AnalyticsService:LogFunnelStepEvent(player, "onboarding", 4) -- tutorial_complete
AnalyticsService:LogFunnelStepEvent(player, "onboarding", 5) -- first_decision
AnalyticsService:LogFunnelStepEvent(player, "onboarding", 6) -- first_tunnel
AnalyticsService:LogFunnelStepEvent(player, "onboarding", 7) -- first_win
```

### 9.2. События

```lua
AnalyticsService:LogCustomEvent(player, "run_start", {
    chapter = 1,
    seed = night.seed,
})

AnalyticsService:LogCustomEvent(player, "decision", {
    anomaly = passenger.isAnomaly,
    decision = decision,
    tier = anomaly.tier,
    timeMs = timeMs,
})

AnalyticsService:LogCustomEvent(player, "tunnel_result", {
    event = eventId,
    result = result,
    choice = choice,
})
```

### 9.3. Экономика

```lua
AnalyticsService:LogEconomyEvent(
    player,
    Enum.AnalyticsEconomyFlowType.Source,
    "Sparks",
    250,
    "shift_reward",
    "shift"
)
```

### 9.4. A/B

- Вариант thumbnail нельзя назначить внутри игры; используйте Roblox thumbnail personalization / внешние ссылки.
- В игре можно A/B тестировать туториал, цену, первый пассажир.

---

## 10. Производительность

### 10.1. Бюджет

| Параметр | Бюджет |
|---|---:|
| Части (parts) | < 100 000 |
| Уникальные текстуры | < 1 000 |
| NPC одновременно | 8 |
| Игроки | 4 |
| Звуки одновременно | 20 |
| FPS на среднем телефоне | 30+ |
| Время загрузки | < 15 сек |

### 10.2. Приёмы

- `StreamingEnabled = true`.
- Поезд — anchored; двигается окружение/камера, не физика.
- Тоннель — отдельный сегмент, телепорт с fade.
- NPC — R15 с простыми аксессуарами; без сложной одежды.
- Текстуры — атлас, 512–1024.
- Свет — Future/ShadowMap, ограничить тени.
- UI — один CanvasGroup, избегать 100+ Frame.
- Пул объектов для пассажиров.
- `Debris`/`Destroy` после смены.
- Профилировать в Studio (MicroProfiler).

### 10.3. Тоннель

- Не строить тоннель длиннее 200 studs.
- Затемнение + звук + тряска камеры.
- Телепорт в тоннель, а не движение поезда.
- NPC остаются anchored.
- Выход — fade back.

---

## 11. Локализация

- `LocalizationService` + `TranslatorForPlayer`.
- Все строки — ключи, не конкатенация.
- Английский — источник.
- RU/ES/PT — на старте.
- ID/TH — после 10 тыс. DAU.
- Не переводить имена собственные.
- Субтитры для всех звуковых подсказок.

---

## 12. Тестирование

### 12.1. Unit

- Генерация аномалий: 10 000 сидов, проверить:
  - нет дублей;
  - есть 2+ tells;
  - есть документная подсказка;
  - нет аномалии вне главы.
- Экономика: выплата не отрицательная; покупка идемпотентна.
- Правила: ночное правило применяется до посадки.

### 12.2. Integration

- 4 игрока, 10 смен, без крашей.
- Потеря соединения → реконнект → сохранение.
- Покупка → выдача → реконнект.

### 12.3. Device lab

- Android low-end (2 GB RAM).
- iPhone 11.
- Xbox controller.
- PC 1080p.

---

## 13. План внедрения

| Этап | Что | Выход |
|---|---|---|
| 1 | Skeleton + state machine | Комната, фазы |
| 2 | Passenger generator | 6 NPC |
| 3 | Inspection UI | Документы, печати |
| 4 | 4 аномалии | Tells, codex |
| 5 | Tunnel | 1 событие |
| 6 | Economy | Искры, магазин |
| 7 | Save | DataStore |
| 8 | Analytics | Воронка |
| 9 | Polish | Звук, VFX |
| 10 | Beta | 100 игроков |

---

## 14. Технические риски

| Риск | Митигация |
|---|---|
| Утечка `isAnomaly` | Не реплицировать; tells через поведение/UI |
| Лаги на мобиле | Streaming, бюджет частей, LOD |
| Потеря данных | ProfileStore, session lock, backup |
| Дубли покупок | Идемпотентный `ProcessReceipt` |
| Читеры | Серверная валидация, rate limit |
| Сложный UI | 3 тапа, мобильный first |
| Долгая загрузка | Атлас, preload, streaming |

---

## 15. Мини-пример: определение аномалии

```lua
-- ReplicatedStorage/Shared/Config/Anomalies.lua
local Anomalies = {}

Anomalies.no_reflection = {
    id = "no_reflection",
    name = "Без отражения",
    tier = 1,
    tags = { "visual", "mirror" },
    weight = 10,
    minChapter = 1,
    tells = {
        {
            channel = "visual",
            text = "В зеркале на месте пассажира пусто.",
            tool = "mirror",
            severity = 3,
        },
        {
            channel = "behavior",
            text = "Пассажир избегает зеркал и поворачивается боком.",
            tool = nil,
            severity = 2,
        },
    },
    checks = { "mirror", "observe" },
    tunnelEvent = "lights_out",
    reward = 50,
}

return Anomalies
```

---

## 16. Итог

- Сервер — истина.
- Клиент — UI и интенты.
- Аномалии — данные, не хардкод.
- Тоннель — state machine, не скрипт на 1000 строк.
- Экономика — сервер, идемпотентность, логи.
- Производительность — mobile-first.
- Аналитика — с первого дня.

**Главное:** не строить «поезд-симулятор». Строить **машину решений**.
