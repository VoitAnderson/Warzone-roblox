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
    Client/         — MovementController, SwimController, AnimationController, WeaponClient,
                      HudController, KnockedController, MenuController, MenuSceneController
```

## 3. Что создать вручную в Studio (Rojo их не создаёт из коробки)

Rojo не синхронизирует RemoteEvents, указанные как пустую папку — создай вручную в `ReplicatedStorage > Remotes`:
- `RequestFire` (RemoteEvent)
- `FireVisual` (RemoteEvent)
- `Reload` (RemoteEvent)

## 4. Главное меню и 3D-сцена (v0.4)

- **MenuController** — UI меню (F1): заголовок OMEGA PROTOCOL // ZERO, кнопки, карточка игрока, бегущая строка, деплой.
- **MenuSceneController** — живая 3D-сцена за меню, строится кодом при открытии меню (ничего не надо собирать руками):
  - голографическая площадка с кольцами OMEGA, парящими голо-панелями, дронами, прожекторами и падающими углями;
  - скайлайн из процедурных башен на горизонте;
  - камера сама медленно облетает сцену.
- **Управление камерой сцены (когда меню открыто):**
  - ПКМ + движение мыши — вращение; колесо мыши — зум;
  - Q / E — вращение, стрелки ↑/↓ — наклон камеры;
  - геймпад — правый стик.
- **Взаимодействие:**
  - клик (ЛКМ) по голограмме или дронам — энергетический импульс: кольца вспыхивают, дроны разлетаются, лёгкий FOV-панч;
  - наведение прицела на объекты сцены — ховер-пинг.
- Сцена отключается сама при закрытии меню (камера, свет и атмосфера возвращаются к игровым).

## 5. Ежедневный процесс

- Я коммичу изменения в ветку `ashna/setup` (или feature-ветки) → ты делаешь `git pull`
- Studio + Rojo: файлы обновляются автоматически (плагин слушает)
- Твои правки в Studio → `rojo build` / вручную переноси в файлы, коммить

## 6. Важно

- Если Rojo подключён, **не редактируй синхронизированные скрипты прямо в Studio** — перезапишутся при следующем sync. Правь файлы в репозитории.
- `default.project.json` — карта проекта. Добавляешь новую систему → добавляй путь туда.
