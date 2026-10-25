-- StarterPlayer > StarterPlayerScripts > Client > HudController (LocalScript)
-- HUD: прицел (расширяется от разброса), HP, стамина, патроны, пластины.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WEAPONS = require(ReplicatedStorage.Shared:WaitForChild("WeaponStats"))
local player = Players.LocalPlayer
local stats = WEAPONS.M4 -- пока одно оружие

local gui = Instance.new("ScreenGui")
gui.Name = "WarzoneHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

-- ===== ПРИЦЕЛ =====
local cross = Instance.new("Frame")
cross.AnchorPoint = Vector2.new(0.5, 0.5)
cross.Position = UDim2.fromScale(0.5, 0.5)
cross.Size = UDim2.new()
cross.BackgroundTransparency = 1
cross.Parent = gui

local lines = {}
for _, dir in ipairs({ "Up", "Down", "Left", "Right" }) do
	local f = Instance.new("Frame")
	f.Name = dir
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.BackgroundColor3 = Color3.new(1, 1, 1)
	f.BackgroundTransparency = 0.15
	f.BorderSizePixel = 0
	f.Parent = cross
	lines[dir] = f
end
local dot = Instance.new("Frame")
dot.AnchorPoint = Vector2.new(0.5, 0.5)
dot.Position = UDim2.fromScale(0.5, 0.5)
dot.Size = UDim2.fromOffset(2, 2)
dot.BackgroundColor3 = Color3.new(1, 1, 1)
dot.BorderSizePixel = 0
dot.Parent = cross

local function setGap(gap)
	lines.Up.Position = UDim2.fromOffset(0, -gap - 5);   lines.Up.Size = UDim2.fromOffset(2, 9)
	lines.Down.Position = UDim2.fromOffset(0, gap + 5);  lines.Down.Size = UDim2.fromOffset(2, 9)
	lines.Left.Position = UDim2.fromOffset(-gap - 6, 0);  lines.Left.Size = UDim2.fromOffset(9, 2)
	lines.Right.Position = UDim2.fromOffset(gap + 6, 0);  lines.Right.Size = UDim2.fromOffset(9, 2)
end

-- ===== HP / СТАМИНА =====
local function panel(pos, size, color)
	local bg = Instance.new("Frame")
	bg.Position = pos
	bg.Size = size
	bg.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	bg.BackgroundTransparency = 0.3
	bg.BorderSizePixel = 0
	bg.Parent = gui
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = color
	fill.BorderSizePixel = 0
	fill.Parent = bg
	return fill
end

local healthFill = panel(UDim2.new(0, 20, 1, -70), UDim2.fromOffset(240, 18), Color3.fromRGB(80, 255, 120))
local staminaFill = panel(UDim2.new(0, 20, 1, -48), UDim2.fromOffset(240, 6), Color3.fromRGB(255, 210, 80))

local healthText = Instance.new("TextLabel")
healthText.Position = UDim2.new(0, 268, 1, -72)
healthText.Size = UDim2.fromOffset(60, 22)
healthText.BackgroundTransparency = 1
healthText.Font = Enum.Font.GothamBold
healthText.TextSize = 16
healthText.TextColor3 = Color3.new(1, 1, 1)
healthText.TextXAlignment = Enum.TextXAlignment.Left
healthText.Text = "100"
healthText.Parent = gui

-- пластины (визуал до Фазы 3)
for i = 1, 3 do
	local p = Instance.new("Frame")
	p.Position = UDim2.new(0, 20 + (i - 1) * 26, 1, -92)
	p.Size = UDim2.fromOffset(22, 12)
	p.BackgroundColor3 = Color3.fromRGB(70, 130, 220)
	p.BackgroundTransparency = 0.2
	p.BorderSizePixel = 0
	p.Parent = gui
end

-- ===== ПАТРОНЫ =====
local ammoText = Instance.new("TextLabel")
ammoText.AnchorPoint = Vector2.new(1, 1)
ammoText.Position = UDim2.new(1, -24, 1, -24)
ammoText.Size = UDim2.fromOffset(220, 30)
ammoText.BackgroundTransparency = 1
ammoText.Font = Enum.Font.GothamBold
ammoText.TextSize = 22
ammoText.TextColor3 = Color3.new(1, 1, 1)
ammoText.TextXAlignment = Enum.TextXAlignment.Right
ammoText.Text = "30 / 30"
ammoText.Parent = gui

local weaponText = ammoText:Clone()
weaponText.Position = UDim2.new(1, -24, 1, -54)
weaponText.Size = UDim2.fromOffset(220, 18)
weaponText.TextSize = 14
weaponText.TextColor3 = Color3.fromRGB(200, 200, 200)
weaponText.Text = stats.DisplayName
weaponText.Parent = gui

-- ===== ОБНОВЛЕНИЕ =====
local character, humanoid, rootPart
local function bind(char)
	character = char
	humanoid = char:WaitForChild("Humanoid")
	rootPart = char:WaitForChild("HumanoidRootPart")
end
if player.Character then bind(player.Character) end
player.CharacterAdded:Connect(bind)

RunService.Heartbeat:Connect(function()
	if not (humanoid and rootPart and character.Parent) then return end

	local hp = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
	healthFill.Size = UDim2.fromScale(hp, 1)
	healthFill.BackgroundColor3 = Color3.fromRGB(255, 80, 80):Lerp(Color3.fromRGB(80, 255, 120), hp)
	healthText.Text = math.ceil(humanoid.Health)

	local stamina = rootPart:GetAttribute("Stamina") or 100
	staminaFill.Size = UDim2.fromScale(stamina / 100, 1)
	staminaFill.BackgroundTransparency = stamina >= 99 and 0.5 or 0

	local spread = rootPart:GetAttribute("Spread") or stats.HipSpread
	setGap(4 + spread * 6)

	if rootPart:GetAttribute("Reloading") then
		ammoText.Text = "ПЕРЕЗАРЯДКА..."
	else
		local ammo = rootPart:GetAttribute("Ammo") or stats.MagSize
		ammoText.Text = ammo .. " / " .. stats.MagSize
	end
end)
