-- ReplicatedStorage > Shared > WeaponStats (ModuleScript)
-- Статы оружия. Сервер считает урон отсюда, клиент рисует UI.

return {
	M4 = {
		DisplayName = "M4",
		Damage = 24,
		HeadshotMultiplier = 1.6,
		FireRate = 0.08,      -- секунд между выстрелами
		MagSize = 30,
		ReloadTime = 2.1,
		Range = 500,          -- дальше — урона нет
		Auto = true,
		-- ADS
		AdsFOV = 55,          -- зум при прицеливании
		AdsTime = 0.18,
		AdsSpeedMult = 0.55,  -- замедление хода в ADS
		-- Разброс (градусы)
		HipSpread = 1.6,      -- от бедра
		AdsSpread = 0.15,     -- в прицеле
		SpreadPerShot = 0.4,  -- рост за выстрел
		SpreadMax = 5,
		SpreadDecay = 4,      -- спад, град/сек
		-- Отдача (градусы за выстрел)
		RecoilPitch = 0.5,
		RecoilYaw = 0.15,
		RecoilRecovery = 12,  -- возврат, град/сек
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
		AdsFOV = 58,
		AdsTime = 0.14,
		AdsSpeedMult = 0.6,
		HipSpread = 2.2,
		AdsSpread = 0.3,
		SpreadPerShot = 0.35,
		SpreadMax = 5,
		SpreadDecay = 5,
		RecoilPitch = 0.35,
		RecoilYaw = 0.2,
		RecoilRecovery = 14,
	},
}
