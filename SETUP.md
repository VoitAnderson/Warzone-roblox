# Установка и синхронизация с Roblox Studio (Rojo)

## 1. Установка

### Плагин для Studio
1. Открой Roblox Studio
2. Плагины → Manage Plugins → найди **Rojo** → Install
3. Появится панель Rojo сверху

### CLI на компьютере (нужен для `rojo serve`)
Вариант A (проще): скачай готовый бинарник с https://rojo.space/releases — положи `rojo.exe` рядом с проектом.

Вариант B: если стоит `aftman`:
```
aftman add rojo-rbx/rojo@7.4.4
aftman install
```

## 2. Запуск синхронизации

1. Склонируй репозиторий:
```
git clone https://github.com/VoitAnderson/Warzone-roblox.git
cd Warzone-roblox
git checkout ashna/setup
```

2. Запусти сервер:
```
rojo serve default.project.json
```

3. В Roblox Studio: панель **Rojo → Connect** (кнопка с розеткой).

4. В Studio появится дерево:
```
ReplicatedStorage
  Shared/           — GameSettings, WeaponStats, AnimationsData
  Remotes/          — (пустая папка, RemoteEvents создаёшь в Studio)
ServerScriptService
  Server/           — CombatServer
StarterPlayer
  StarterPlayerScripts
    Client/         — MovementController, SwimController, AnimationController, WeaponClient
```

## 3. Что создать вручную в Studio (Rojo их не создаёт из коробки)

Rojo не синхронизирует RemoteEvents, указанные как пустая папка — создай вручную в `ReplicatedStorage > Remotes`:
- `RequestFire` (RemoteEvent)
- `FireVisual` (RemoteEvent)
- `Reload` (RemoteEvent)

## 4. Ежедневный процесс

- Я коммичу изменения в ветку `ashna/setup` (или feature-ветки) → ты делаешь `git pull`
- Studio + Rojo: файлы обновляются автоматически (плагин слушает)
- Твои правки в Studio → `rojo build` / вручную переноси в файлы, коммить

## 5. Важно

- Если Rojo подключён, **не редактируй синхронизированные скрипты прямо в Studio** — перезапишутся при следующем sync. Правь файлы в репозитории.
- `default.project.json` — карта проекта. Добавляешь новую систему → добавляешь путь туда.
