-- ServerScriptService > Server > CombatServer (Script)
-- Вся стрельба считается ЗДЕСЬ. Клиент только просит.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local WEAPONS = require(ReplicatedStorage.Shared:WaitForChild("WeaponStats"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RequestFire = Remotes:WaitForChild("RequestFire")
local FireVisual = Remotes:WaitForChild("FireVisual")
local ReloadRemote = Remotes:WaitForChild("Reload")

-- Античит-тюнинг
local TOLERANCE = 0.02  -- допуск пинга (сек)

-- Состояние каждого игрока
local combat = {}

local function getState(player)
	if not combat[player] then
		combat[player] = {
			lastShot = 0,
			ammo = {},
			reloadingUntil = 0,
		}
	end
	return combat[player]
end

local function charOf(player)
	local char = player.Character
	if not char then return nil end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	if not hum or not root or hum.Health <= 0 then return nil end
	return char, hum, root
end

-- Урон по частям тела (этап 2.5 — уже вкаркас)
local function bodyMultiplier(part)
	if part.Name == "Head" then return "head" end
	if part.Name == "UpperTorso" or part.Name == "LowerTorso" then return "torso" end
	return "limb" -- руки/ноги — 0.9 урона
end

RequestFire.OnServerEvent:Connect(function(player, weaponName, aimPos)
	-- === ВАЛИДАЦИЯ (античит) ===
	local stats = WEAPONS[weaponName]
	if not stats then return end                     -- такого оружия нет

	local state = getState(player)
	local char, hum, root = charOf(player)
	if not char then return end
	if tick() < state.reloadingUntil then return end -- идёт перезарядка

	-- 1) Скорострельность: сервер сам решает, когда можно стрелять
	if tick() - state.lastShot < stats.FireRate - TOLERANCE then
		return -- слишком часто → игнор (чит/лаг)
	end

	-- 2) aimPos не может быть NaN/inf/под полом
	if typeof(aimPos) ~= "Vector3" then return end
	if aimPos.X ~= aimPos.X or aimPos.Y ~= aimPos.Y or aimPos.Z ~= aimPos.Z then return end
	if math.abs(aimPos.X) > 1e6 or math.abs(aimPos.Y) > 1e6 or math.abs(aimPos.Z) > 1e6 then return end
	if aimPos.Y < -50 then return end

	-- 3) Дистанция прицеливания: не дальше дальности оружия + запас
	local muzzle = root.Position + root.CFrame.LookVector * 2
	if (aimPos - muzzle).Magnitude > stats.Range + 50 then
		return -- целится сквозь всю карту
	end

	-- 4) Боезапас
	local ammo = state.ammo[weaponName]
	if ammo == nil then ammo = stats.MagSize end -- первое использование
	if ammo <= 0 then return end
	ammo -= 1
	state.ammo[weaponName] = ammo
	state.lastShot = tick()

	-- === СЕРВЕРНЫЙ РЕЙКАСТ (клиенту не верим) ===
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char }

	local dir = (aimPos - muzzle).Unit * stats.Range
	local result = workspace:Raycast(muzzle, dir, params)

	local hitHumanoid = nil
	local hitPart = nil
	if result then
		local model = result.Instance:FindFirstAncestorOfClass("Model")
		local victim = model and Players:GetPlayerFromCharacter(model)
		if victim and victim ~= player then
			local vHum = model:FindFirstChildOfClass("Humanoid")
			if vHum and vHum.Health > 0 then
				hitHumanoid = vHum
				hitPart = result.Instance
			end
		end
	end

	-- === УРОН ===
	if hitHumanoid then
		local mult = 1
		local zone = bodyMultiplier(hitPart)
		if zone == "head" then mult = stats.HeadshotMultiplier
		elseif zone == "limb" then mult = 0.9 end
		hitHumanoid:TakeDamage(stats.Damage * mult)
		-- DBNO/пластины подключим в Фазе 3 — пока урон прямо в HP
	end

	-- === ВИЗУАЛ всем рядом (только эффекты, не урон) ===
	local visualData = {
		origin = muzzle,
		hitPos = result and result.Position or (muzzle + dir),
		hit = result and true or false,
	}
	FireVisual:FireAllClients(player, visualData)
end)

-- Перезарядка: сервер блокирует стрельбу на время
ReloadRemote.OnServerEvent:Connect(function(player, weaponName)
	local stats = WEAPONS[weaponName]
	if not stats then return end
	local state = getState(player)
	if tick() < state.reloadingUntil then return end
	state.reloadingUntil = tick() + stats.ReloadTime
	task.delay(stats.ReloadTime, function()
		if combat[player] then
			combat[player].ammo[weaponName] = stats.MagSize
		end
	end)
end)

-- Очистка
Players.PlayerRemoving:Connect(function(player)
	combat[player] = nil
end)
