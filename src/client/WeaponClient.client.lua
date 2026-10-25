-- StarterPlayer > StarterPlayerScripts > Client > WeaponClient (LocalScript)
-- Этап 2.2: стрельба + ADS + viewmodel + отдача + разброс.
-- ПКМ/LT — прицел, ЛКМ/RT — огонь, R/X — перезарядка. Урон НЕ считается здесь.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local WEAPONS = require(ReplicatedStorage.Shared:WaitForChild("WeaponStats"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RequestFire = Remotes:WaitForChild("RequestFire")
local FireVisual = Remotes:WaitForChild("FireVisual")

local player = Players.LocalPlayer
local rng = Random.new()

local CURRENT_WEAPON = "M4"
local stats = WEAPONS[CURRENT_WEAPON]
local TRACER_COLOR = Color3.fromRGB(255, 200, 100)

-- ===== СОСТОЯНИЕ =====
local ads = false
local adsT = 0        -- 0..1, плавный переход ADS
local bloom = 0       -- накопленный разброс от стрельбы
local recoilPitch, recoilYaw = 0, 0
local vmKick = 0
local ammo = stats.MagSize
local reloading = false
local fireHeld = false
local lastShot = 0

local character, humanoid, rootPart
local function bindCharacter(char)
	character = char
	humanoid = char:WaitForChild("Humanoid")
	rootPart = char:WaitForChild("HumanoidRootPart")
	ammo = stats.MagSize
	reloading = false
	rootPart:SetAttribute("Ammo", ammo)
	rootPart:SetAttribute("ADS", false)
	rootPart:SetAttribute("Reloading", false)
end
if player.Character then bindCharacter(player.Character) end
player.CharacterAdded:Connect(bindCharacter)

-- ===== VIEWMODEL (процедурное оружие из частей) =====
local camera = workspace.CurrentCamera
local viewmodel = Instance.new("Model")
viewmodel.Name = "Viewmodel"
viewmodel.Parent = camera

local vmParts = {}
local DARK = Color3.fromRGB(40, 40, 42)
local BLACK = Color3.fromRGB(24, 24, 24)

local function vmPart(size, offset, color)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Metal
	p.Color = color or BLACK
	p.Size = size
	p.Parent = viewmodel
	vmParts[#vmParts + 1] = { part = p, offset = offset }
end

vmPart(Vector3.new(0.16, 0.22, 1.0),  CFrame.new(0, 0, 0),      DARK)  -- ствольная коробка
vmPart(Vector3.new(0.06, 0.06, 1.1),  CFrame.new(0, 0.03, -1.0))       -- ствол
vmPart(Vector3.new(0.10, 0.12, 0.7), CFrame.new(0, 0.03, -0.6))        -- цевьё
vmPart(Vector3.new(0.10, 0.34, 0.14), CFrame.new(0, -0.26, -0.1))      -- магазин
vmPart(Vector3.new(0.09, 0.22, 0.12), CFrame.new(0, -0.20, 0.3))       -- рукоять
vmPart(Vector3.new(0.10, 0.16, 0.5), CFrame.new(0, 0.01, 0.7))         -- приклад
vmPart(Vector3.new(0.05, 0.08, 0.08), CFrame.new(0, 0.17, -0.25), DARK)-- прицел

local HIP_OFFSET = CFrame.new(1.15, -1.05, -1.6) * CFrame.Angles(0, math.rad(-4), 0)
local ADS_OFFSET = CFrame.new(0, -0.58, -0.95)
local MUZZLE_OFFSET = CFrame.new(0, 0.03, -2.2)
local lastBase = HIP_OFFSET

-- ===== РАЗБРОС: направление в конусе =====
local function coneDirection(dir, maxAngleDeg)
	local angle = math.rad(maxAngleDeg)
	if angle <= 0 then return dir end
	local right = dir:Cross(Vector3.yAxis)
	if right.Magnitude < 0.001 then right = Vector3.xAxis end
	right = right.Unit
	local trueUp = right:Cross(dir).Unit
	local rot = rng:NextNumber(0, math.pi * 2)
	local tilt = rng:NextNumber(0, angle)
	return (dir * math.cos(tilt)
		+ (right * math.cos(rot) + trueUp * math.sin(rot)) * math.sin(tilt)).Unit
end

-- ===== ПЕРЕЗАРЯДКА =====
local function startReload()
	if reloading or ammo >= stats.MagSize then return end
	reloading = true
	Remotes.Reload:FireServer(CURRENT_WEAPON)
	rootPart:SetAttribute("Reloading", true)
	task.delay(stats.ReloadTime, function()
		if rootPart then
			reloading = false
			ammo = stats.MagSize
			rootPart:SetAttribute("Ammo", ammo)
			rootPart:SetAttribute("Reloading", false)
		end
	end)
end

-- ===== ВЫСТРЕЛ =====
local function shoot()
	local now = tick()
	if reloading or now - lastShot < stats.FireRate then return end
	if not (rootPart and rootPart.Parent) then return end
	if ammo <= 0 then startReload() return end

	lastShot = now
	ammo -= 1
	rootPart:SetAttribute("Ammo", ammo)

	-- цель с учётом разброса: рейкаст из центра камеры
	local cam = workspace.CurrentCamera
	local origin = cam.CFrame.Position
	local baseSpread = (ads and stats.AdsSpread or stats.HipSpread) + bloom
	local dir = coneDirection(cam.CFrame.LookVector, baseSpread)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { cam, character }
	local result = workspace:Raycast(origin, dir * stats.Range, params)
	local aimPos = result and result.Position or (origin + dir * stats.Range)

	RequestFire:FireServer(CURRENT_WEAPON, aimPos)

	-- эффекты
	bloom = math.min(stats.SpreadMax, bloom + stats.SpreadPerShot)
	recoilPitch += stats.RecoilPitch * (ads and 0.55 or 1)
	recoilYaw += (rng:NextNumber() - 0.5) * 2 * stats.RecoilYaw
	vmKick = 0.12

	-- вспышка на стволе
	local flash = Instance.new("Part")
	flash.Anchored = true
	flash.CanCollide = false
	flash.CanQuery = false
	flash.CastShadow = false
	flash.Material = Enum.Material.Neon
	flash.Color = Color3.fromRGB(255, 220, 130)
	flash.Shape = Enum.PartType.Ball
	flash.Size = Vector3.one * 0.35
	flash.CFrame = cam.CFrame * lastBase * MUZZLE_OFFSET
	flash.Parent = cam
	Debris:AddItem(flash, 0.05)
end

-- ===== ВВОД =====
UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.UserInputType == Enum.UserInputType.MouseButton2
		or input.KeyCode == Enum.KeyCode.ButtonL2 then
		ads = true
		if rootPart then rootPart:SetAttribute("ADS", true) end
	elseif input.UserInputType == Enum.UserInputType.MouseButton1
		or input.KeyCode == Enum.KeyCode.ButtonR2 then
		fireHeld = true
		shoot()
	elseif input.KeyCode == Enum.KeyCode.R or input.KeyCode == Enum.KeyCode.ButtonX then
		startReload()
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2
		or input.KeyCode == Enum.KeyCode.ButtonL2 then
		ads = false
		if rootPart then rootPart:SetAttribute("ADS", false) end
	elseif input.UserInputType == Enum.UserInputType.MouseButton1
		or input.KeyCode == Enum.KeyCode.ButtonR2 then
		fireHeld = false
	end
end)

-- ===== ТИК: автоогонь, спад разброса/отдачи =====
RunService.Heartbeat:Connect(function(dt)
	if fireHeld then shoot() end
	bloom = math.max(0, bloom - stats.SpreadDecay * dt)
	recoilPitch = math.max(0, recoilPitch - stats.RecoilRecovery * dt)
	recoilYaw = math.abs(recoilYaw) < 0.01 and 0
		or math.max(0, math.abs(recoilYaw) - stats.RecoilRecovery * dt) * math.sign(recoilYaw)
	if rootPart then
		rootPart:SetAttribute("Spread", (ads and stats.AdsSpread or stats.HipSpread) + bloom)
	end
end)

-- ===== РЕНДЕР: viewmodel, FOV, отдача камеры =====
RunService:BindToRenderStep("WarzoneViewModel", Enum.RenderPriority.Camera.Value + 1, function(dt)
	local cam = workspace.CurrentCamera
	adsT += ((ads and 1 or 0) - adsT) * math.min(dt * 12, 1)
	cam.FieldOfView = 70 + (stats.AdsFOV - 70) * adsT

	vmKick = math.max(0, vmKick - dt * 0.9)
	local base = HIP_OFFSET:Lerp(ADS_OFFSET, adsT)
		* CFrame.new(0, 0, vmKick * 0.5)
		* CFrame.Angles(math.rad(vmKick * 30), 0, 0)
	lastBase = base

	local dead = humanoid and humanoid.Health <= 0
	for _, entry in ipairs(vmParts) do
		entry.part.CFrame = cam.CFrame * base * entry.offset
		entry.part.Transparency = dead and 1 or 0
	end

	cam.CFrame = cam.CFrame * CFrame.Angles(-math.rad(recoilPitch), math.rad(recoilYaw), 0)
end)

-- ===== ВИЗУАЛ: трассеры =====
FireVisual.OnClientEvent:Connect(function(shooter, data)
	local cam = workspace.CurrentCamera
	local shooterChar = shooter and shooter.Character
	if not shooterChar then return end
	local a = Instance.new("Part")
	a.Anchored = true
	a.CanCollide = false
	a.CanQuery = false
	a.CastShadow = false
	a.Material = Enum.Material.Neon
	a.Color = TRACER_COLOR
	local dist = (data.hitPos - data.origin).Magnitude
	a.Size = Vector3.new(0.05, 0.05, dist)
	a.CFrame = CFrame.lookAt(data.origin, data.hitPos) * CFrame.new(0, 0, -dist / 2)
	a.Parent = cam
	Debris:AddItem(a, 0.06)
end)
