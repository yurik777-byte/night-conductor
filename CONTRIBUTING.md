# Совместная разработка

Проект: **NIGHT CONDUCTOR: Anomaly Express** — Roblox-прототип + документация.

## Что установить

1. [Roblox Studio](https://create.roblox.com/)
2. [Node.js 18+](https://nodejs.org/) — нужен для сборки `.rbxlx`
3. [Git](https://git-scm.com/)
4. По желанию: [Rojo](https://rojo.space/) — живая синхронизация `src/` со Studio

## Первый запуск

```bash
git clone <URL-репозитория>
cd roblox-train
node prototype/build-rbxlx.js
```

Открой в Roblox Studio:

```
prototype/NightConductorPrototype.rbxlx
```

Нажми **Play**. В Output должно быть `[NightConductor] Bootstrap v7 loaded`.

## Главное правило

`prototype/NightConductorPrototype.rbxlx` — **сгенерированный файл**. Источник правды — папка `prototype/src/`.

- меняешь игру → правь `prototype/src/**`;
- затем пересобери место:

```bash
node prototype/build-rbxlx.js
```

Физический прототип v8 собирается отдельно:

```bash
node prototype/build-rbxlx.js --physical
```

Он пишет `prototype/NightConductorPhysical.rbxlx` и не трогает v7-сборку.

- не редактируй `.rbxlx` напрямую: при следующей сборке изменения из Studio потеряются;
- если всё же правил в Studio — перенеси изменения в `src/` (или попроси помочь с переносом).

Если Rojo установлен, можно подключить `prototype/default.project.json` и работать без пересборки.

## Ветки и pull request

```bash
git checkout -b feature/koridor-anomaly
# ...правки в src...
node prototype/build-rbxlx.js
git add .
git commit -m "Add corridor anomaly"
git push -u origin feature/koridor-anomaly
```

Дальше — Pull Request на GitHub. Один PR = одна законченная правка.

Перед PR проверь:

- `node prototype/build-rbxlx.js` проходит без ошибок;
- в Studio игра запускается и туториал проходится;
- в консоли нет красных ошибок;
- `.rbxlx.lock` и старые `_v*.rbxlx` не попали в коммит.

## Что не коммитим

`.gitignore` уже исключает:

- `*.rbxlx.lock` — lock-файлы открытого Studio;
- `prototype/NightConductorPrototype_v*.rbxlx` — локальные тестовые сборки;
- `opencode.json` — локальная настройка AI-инструментов;
- `node_modules/`.

Канонический билд `prototype/NightConductorPrototype.rbxlx` **коммитится**, чтобы друг мог открыть игру без Node.

## Структура

```
docs/                                  — рынок, GDD, аномалии, план, техспека
prototype/
  src/ReplicatedStorage/Shared/        — Config, Remotes
  src/ServerScriptService/Server/      — смена, пассажиры, мир
  src/StarterPlayer/.../ClientMain     — весь UI, туториал, ввод
  build-rbxlx.js                       — сборка .rbxlx из src
  NightConductorPrototype.rbxlx        — готовое место (генерируется)
```

## Как позвать друга

Владелец репозитория на GitHub:

1. **Settings → Collaborators → Add people**;
2. ввести GitHub username друга;
3. друг принимает приглашение и клонирует репозиторий.

Для приватного репозитория это обязательный шаг. Для публичного друг может просто форкнуть.

## Конфликты в `.rbxlx`

Так как файл генерируется, конфликт решается пересборкой:

```bash
node prototype/build-rbxlx.js
git add prototype/NightConductorPrototype.rbxlx
git commit
```

Не трать время на ручное слияние XML.
