-- StarterPlayer > StarterPlayerScripts > Client > WeaponClient (LocalScript)
-- Ввод: ЛКМ/RT — огонь, R/X — перезарядка. Урон НЕ считается здесь.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RequestFire = Remotes:WaitForChild("RequestFire")
local FireVisual = Remotes:WaitForChild("FireVisual")

local CURRENT_WEAPON = "M4" -- потом: берётся из слотов лута
local TRACER_COLOR = Color3.fromRGB(255, 200, 100)

-- Отслеживаем геймпад-триггеры
local triggerHeld = false
UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.KeyCode == Enum.KeyCode.ButtonR2 then
		triggerHeld = true
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.KeyCode == Enum.KeyCode.ButtonR2 then
		triggerHeld = false
	end
end)

-- Автоогонь
RunService.Heartbeat:Connect(function()
	if triggerHeld then
		local mouse = Players.LocalPlayer:GetMouse()
		RequestFire:FireServer(CURRENT_WEAPON, mouse.Hit.Position)
	end
end)

-- Перезарядка
UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.R or input.KeyCode == Enum.KeyCode.ButtonX then
		Remotes.Reload:FireServer(CURRENT_WEAPON)
	end
end)

-- === ВИЗУАЛ: трассеры (для всех, кто получил FireVisual) ===
FireVisual.OnClientEvent:Connect(function(shooter, data)
	local cam = workspace.CurrentCamera
	local shooterChar = shooter and shooter.Character
	if not shooterChar then return end

	-- Рисуем трассер
	local a = Instance.new("Part")
	a.Anchored = true
	a.CanCollide = false
	a.CanQuery = false
	a.Material = Enum.Material.Neon
	a.Color = TRACER_COLOR
	local dist = (data.hitPos - data.origin).Magnitude
	a.Size = Vector3.new(0.05, 0.05, dist)
	a.CFrame = CFrame.lookAt(data.origin, data.hitPos) * CFrame.new(0, 0, -dist / 2)
	a.Parent = cam
	Debris:AddItem(a, 0.06)
end)
