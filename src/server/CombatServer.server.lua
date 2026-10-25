-- ServerScriptService > CombatServer (Script)
-- Фаза 3: полный сервер боя. Валидация выстрелов, урон по частям тела,
-- пластины брони, DBNO (нокдаун), ревайв тиммейта, кровотечение,
-- реген HP, киллфид, хит-маркеры. Всё авторитетно на сервере.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local WEAPONS = require(ReplicatedStorage.Shared:WaitForChild("WeaponStats"))

-- ================== ТЮНИНГ ==================
local PLATES_MAX = 3
local PLATE_HP = 50        -- HP одной пластины
local PLATE_TIME = 2       -- сек надевания
local KNOCKED_HEALTH = 30 -- пул нокдауна
local BLEED_RATE = 3       -- урон кровотечения в сек
local REVIVE_TIME = 5      -- сек ревайва
local REVIVE_RANGE = 8
local REGEN_DELAY = 5      -- сек без урона до регена
local REGEN_RATE = 10      -- HP в сек
-- ============================================

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RequestFire = Remotes:WaitForChild("RequestFire")
local FireVisual = Remotes:WaitForChild("FireVisual")
local Reload = Remotes:WaitForChild("Reload")

-- Дополнительные ремоуты создаются кодом — вручную ничего не надо
local function ensureRemote(name)
	local r = Remotes:FindFirstChild(name)
	if not r then
		r = Instance.new("RemoteEvent")
		r.Name = name
		r.Parent = Remotes
	end
	return r
end
local KillFeed = ensureRemote("KillFeed")
local HitFeedback = ensureRemote("HitFeedback")
local RequestPlate = ensureRemote("RequestPlate")
local RequestRevive = ensureRemote("RequestRevive")

local state = {}      -- [player] = { ammo, lastShot, plates, plateHP, regenT }
local reviving = {}   -- [reviver] = { target, t }

local function getState(p)
	local s = state[p]
	if not s then
		s = { ammo = {}, lastShot = 0, plates = 0, plateHP = 0, regenT = tick() }
		state[p] = s
	end
	return s
end

local function rootPart(p)
	local char = p.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function hum(p)
	local char = p.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function announceKill(killerName, victimName, weaponName)
	KillFeed:FireAllClients({
		killer = killerName,
		victim = victimName,
		weapon = weaponName,
	})
end

-- Множители урона по конечностям (R6 и R15)
local LIMBS = {
	["Left Arm"] = 0.9, ["Right Arm"] = 0.9,
	["LeftUpperArm"] = 0.9, ["RightUpperArm"] = 0.9,
	["LeftLowerArm"] = 0.9, ["RightLowerArm"] = 0.9,
	["LeftHand"] = 0.9, ["RightHand"] = 0.9,
	["Left Leg"] = 0.85, ["Right Leg"] = 0.85,
	["LeftUpperLeg"] = 0.85, ["RightUpperLeg"] = 0.85,
	["LeftLowerLeg"] = 0.85, ["RightLowerLeg"] = 0.85,
	["LeftFoot"] = 0.85, ["RightFoot"] = 0.85,
}

-- ============== УРОН ==============
local function applyDamage(victim, amount, attacker, weaponName)
	local h = hum(victim)
	local rp = rootPart(victim)
	if not (h and rp) or h.Health <= 0 then return end

	-- Уже в нокдауне: бьём пул нокдауна
	if rp:GetAttribute("Knocked") then
		local pool = math.max(0, (rp:GetAttribute("BleedPool") or 0) - amount)
		rp:SetAttribute("BleedPool", pool)
		if pool <= 0 then
			h.Health = 0
			announceKill(attacker and attacker.Name or "?", victim.Name, weaponName)
		end
		return
	end

	local st = getState(victim)
	st.regenT = tick()

	-- 1) Пластины впитывают урон первыми
	local remaining = amount
	if st.plates > 0 then
		local absorbed = math.min(st.plateHP, remaining)
		st.plateHP -= absorbed
		remaining -= absorbed
		if st.plateHP <= 0 then
			st.plates -= 1
			st.plateHP = st.plates > 0 and PLATE_HP or 0
		end
		rp:SetAttribute("Plates", st.plates)
		rp:SetAttribute("PlateHP", st.plateHP)
	end

	-- 2) Остальное — в здоровье; на нуле — нокдаун
	if remaining > 0 then
		h.Health -= remaining
		if h.Health <= 0 then
			h.Health = KNOCKED_HEALTH
			h.WalkSpeed = 6
			h.JumpPower = 0
			rp:SetAttribute("Knocked", true)
			rp:SetAttribute("BleedPool", KNOCKED_HEALTH)
		end
	end
end

-- ============== ВЫСТРЕЛ ==============
RequestFire.OnServerEvent:Connect(function(shooter, weaponName, aimPos)
	if typeof(weaponName) ~= "string" or typeof(aimPos) ~= "Vector3" then return end
	local weapon = WEAPONS[weaponName]
	local rp = rootPart(shooter)
	local h = hum(shooter)
	if not (weapon and rp and h) then return end
	if rp:GetAttribute("Knocked") or rp:GetAttribute("Reloading") then return end

	local st = getState(shooter)
	if not st.ammo[weaponName] then st.ammo[weaponName] = weapon.MagSize end
	if st.ammo[weaponName] <= 0 then return end

	-- Анти-спам по скорострельности (запас 15% на пинг)
	local now = tick()
	if now - st.lastShot < weapon.FireRate * 0.85 then return end
	st.lastShot = now

	-- Дальность
	local origin = rp.Position + Vector3.new(0, 1.5, 0)
	if (aimPos - origin).Magnitude > weapon.Range * 1.25 then return end

	st.ammo[weaponName] -= 1
	rp:SetAttribute("Ammo", st.ammo[weaponName])

	-- Рейкаст от персонажа
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { shooter.Character }
	local dir = (aimPos - origin).Unit
	local result = workspace:Raycast(origin, dir * weapon.Range, params)

	local hitPos = result and result.Position or aimPos
	FireVisual:FireAllClients(shooter, { origin = origin, hitPos = hitPos })

	if result then
		local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
		local victim = hitModel and Players:GetPlayerFromCharacter(hitModel)
		if victim and victim ~= shooter then
			local dmg = weapon.Damage
			local headshot = result.Instance.Name == "Head"
			if headshot then
				dmg *= weapon.HeadshotMultiplier
			else
				dmg *= LIMBS[result.Instance.Name] or 1
			end
			applyDamage(victim, dmg, shooter, weaponName)
			HitFeedback:FireClient(shooter, { hit = true, headshot = headshot })
		else
			HitFeedback:FireClient(shooter, { hit = false })
		end
	end
end)

-- ============== ПЕРЕЗАРЯДКА ==============
Reload.OnServerEvent:Connect(function(p, weaponName)
	local weapon = WEAPONS[weaponName]
	if not weapon then return end
	local st = getState(p)
	if not st.ammo[weaponName] then st.ammo[weaponName] = weapon.MagSize end
	if st.ammo[weaponName] >= weapon.MagSize then return end
	local rp = rootPart(p)
	if rp then rp:SetAttribute("Reloading", true) end
	task.delay(weapon.ReloadTime, function()
		if state[p] then
			st.ammo[weaponName] = weapon.MagSize
			local r = rootPart(p)
			if r then
				r:SetAttribute("Ammo", weapon.MagSize)
				r:SetAttribute("Reloading", false)
			end
		end
	end)
end)

-- ============== ПЛАСТИНЫ ==============
RequestPlate.OnServerEvent:Connect(function(p)
	local st = getState(p)
	local rp = rootPart(p)
	if not rp or rp:GetAttribute("Knocked") then return end
	if st.plates >= PLATES_MAX or rp:GetAttribute("ApplyingPlate") then return end
	rp:SetAttribute("ApplyingPlate", true)
	task.delay(PLATE_TIME, function()
		if state[p] and rp.Parent then
			st.plates += 1
			if st.plates == 1 then st.plateHP = PLATE_HP end
			rp:SetAttribute("Plates", st.plates)
			rp:SetAttribute("PlateHP", st.plateHP)
			rp:SetAttribute("ApplyingPlate", false)
		end
	end)
end)

-- ============== РЕВАЙВ ==============
RequestRevive.OnServerEvent:Connect(function(reviver, target)
	if typeof(target) ~= "Instance" or not target:IsA("Player") then return end
	local rpT = rootPart(target)
	local rpS = rootPart(reviver)
	if not (rpT and rpS) then return end
	if not rpT:GetAttribute("Knocked") then return end
	if (rpT.Position - rpS.Position).Magnitude > REVIVE_RANGE then return end
	rpT:SetAttribute("BeingRevived", true)
	reviving[reviver] = { target = target, t = tick() }
end)

local function cancelRevive(rpT)
	rpT:SetAttribute("BeingRevived", false)
	rpT:SetAttribute("ReviveProgress", 0)
end

-- ============== ТИК: кровотечение, реген, ревайв ==============
RunService.Heartbeat:Connect(function(dt)
	-- Ревайвы
	for reviver, data in pairs(reviving) do
		local rpT = rootPart(data.target)
		local rpS = rootPart(reviver)
		if not (rpT and rpS and rpT.Parent and rpS.Parent)
			or not rpT:GetAttribute("Knocked")
			or (rpT.Position - rpS.Position).Magnitude > REVIVE_RANGE then
			reviving[reviver] = nil
			if rpT then cancelRevive(rpT) end
		else
			local progress = math.min(1, (tick() - data.t) / REVIVE_TIME)
			rpT:SetAttribute("ReviveProgress", progress)
			if progress >= 1 then
				reviving[reviver] = nil
				rpT:SetAttribute("Knocked", false)
				cancelRevive(rpT)
				local h = hum(data.target)
				if h then
					h.Health = 50
					h.WalkSpeed = 16
					h.JumpPower = 50
				end
			end
		end
	end

	-- Кровотечение и реген
	for _, p in ipairs(Players:GetPlayers()) do
		local st = getState(p)
		local rp = rootPart(p)
		local h = hum(p)
		if rp and h and h.Health > 0 then
			if rp:GetAttribute("Knocked") then
				local pool = (rp:GetAttribute("BleedPool") or 0) - BLEED_RATE * dt
				rp:SetAttribute("BleedPool", math.max(0, pool))
				if pool <= 0 then
					h.Health = 0
				end
			elseif tick() - st.regenT > REGEN_DELAY and h.Health < h.MaxHealth then
				h.Health = math.min(h.MaxHealth, h.Health + REGEN_RATE * dt)
			end
		end
	end
end)

-- ============== СПАВН / СМЕРТЬ ==============
local function resetState(p, char)
	local st = getState(p)
	st.ammo = {}
	st.plates = 0
	st.plateHP = 0
	st.lastShot = 0
	st.regenT = tick()
	local rp = char:WaitForChild("HumanoidRootPart", 5)
	if rp then
		rp:SetAttribute("Plates", 0)
		rp:SetAttribute("PlateHP", 0)
		rp:SetAttribute("Ammo", WEAPONS.M4.MagSize)
		rp:SetAttribute("Knocked", false)
		rp:SetAttribute("Reloading", false)
		rp:SetAttribute("BeingRevived", false)
		rp:SetAttribute("ReviveProgress", 0)
	end
	local h = char:WaitForChild("Humanoid", 5)
	if h then
		h.Died:Connect(function()
			local r = rootPart(p)
			if r then
				r:SetAttribute("Knocked", false)
				r:SetAttribute("BeingRevived", false)
				r:SetAttribute("ReviveProgress", 0)
			end
			for reviver, data in pairs(reviving) do
				if data.target == p then reviving[reviver] = nil end
			end
		end)
	end
end

Players.PlayerAdded:Connect(function(p)
	p.CharacterAdded:Connect(function(char) resetState(p, char) end)
end)
for _, p in ipairs(Players:GetPlayers()) do
	p.CharacterAdded:Connect(function(char) resetState(p, char) end)
	if p.Character then resetState(p, p.Character) end
end

Players.PlayerRemoving:Connect(function(p)
	state[p] = nil
	reviving[p] = nil
end)
