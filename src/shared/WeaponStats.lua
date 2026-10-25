-- ReplicatedStorage > Shared > WeaponStats (ModuleScript)
-- Статы оружия. Сервер считает урон отсюда, клиент рисует UI.

return {
	M4 = {
		DisplayName = "M4",
		Damage = 24,          -- урон в тело
		HeadshotMultiplier = 1.6,
		FireRate = 0.08,      -- секунд между выстрелами (12.5 в сек не даст сервер)
		MagSize = 30,
		ReloadTime = 2.1,
		Range = 500,          -- дальше — урона нет
		Auto = true,
	},
	MP5 = {
		DisplayName = "MP5",
		Damage = 18,
		HeadshotMultiplier = 1.5,
		FireRate = 0.06,
		MagSize = 30,
		ReloadTime = 1.8,
		Range = 300,
		Auto = true,
	},
}
