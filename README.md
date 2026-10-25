# Omega Protocol // Zero

Тактический Battle Royale в Roblox Studio с нуля (оригинальный код и контент).
Название: **Omega Protocol // Zero**. Режимы: Solo и Quads (DBNO + Гулаг), PC + геймпад.

## Структура проекта (Rojo)

```
src/
  shared/    — модули для сервера и клиента (GameSettings, WeaponStats, AnimationsData)
  server/    — серверные скрипты (CombatServer)
  client/    — клиентские скрипты (MovementController, SwimController, AnimationController, WeaponClient)
```

## Синхронизация с Roblox Studio (Rojo)

1. Установи плагин Rojo: https://rojo.space (Roblox Studio → Plugins → Manage Plugins)
2. Установи CLI Rojo: `aftman add rojo-rbx/rojo` или скачай бинарник
3. Запусти: `rojo serve` в корне репозитория
4. В Studio: плагин Rojo → Connect

Скрипты появятся в Studio автоматически. Изменения коммитятся сюда — Rojo подхватывает их по F5/Connect.

## План разработки

- Фаза 0: фундамент (каркас, Remotes, GameSettings) — частично готово
- Фаза 1: движение и камера (присед, prone, slide, mantle, плавание) — частично готово
- Фаза 2: оружие и стрельба (каркас готов: CombatServer + WeaponClient)
- Фаза 3: здоровье, броня, DBNO, Гулаг
- Фаза 4: матч-системы (зона, лут, дроп)
- Фаза 5: команды, транспорт, UI
- Фаза 6: карта и контент
- Фаза 7: полировка

Подробный план и весь код ведутся совместно с Ashna (AshnaAI).
