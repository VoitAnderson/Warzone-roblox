-- StarterPlayer > StarterPlayerScripts > Client > HudController (LocalScript)
-- AAA HUD: прицел, HP + пластины, стамина, патроны, киллфид, хит-маркеры,
-- нокдаун-оверлей с ревайвом, красная вспышка при уроне.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local WEAPONS = require(ReplicatedStorage.Shared:WaitForChild("WeaponStats"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local stats = WEAPONS.M4

local player = Players.LocalPlayer
local ACCENT = Color3.fromRGB(80, 255, 120)
local WARN = Color3.fromRGB(255, 80, 80)
local PLATE_BLUE = Color3.fromRGB(70, 130, 220)
local BG = Color3.fromRGB(12, 14, 16)

local gui = Instance.new("ScreenGui")
gui.Name = "WarzoneHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 50
gui.Parent = player:WaitForChild("PlayerGui")

local function round(parent, px)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, px)
	c.Parent = parent
end

-- ===== ПРИЦЕЛ =====
local cross = Instance.new("Frame")
cross.AnchorPoint = Vector2.new(0.5, 0.5)
cross.Position = UDim2.fromScale(0.5, 0.5)
cross.BackgroundTransparency = 1
cross.Parent = gui
local lines = {}
for _, dir in ipairs({ "Up", "Down", "Left", "Right" }) do
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.BackgroundColor3 = Color3.new(1, 1, 1)
	f.BackgroundTransparency = 0.1
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

local function setGap(g)
	lines.Up.Position = UDim2.fromOffset(0, -g - 6)
	lines.Up.Size = UDim2.fromOffset(2, 10)
	lines.Down.Position = UDim2.fromOffset(0, g + 6)
	lines.Down.Size = UDim2.fromOffset(2, 10)
	lines.Left.Position = UDim2.fromOffset(-g - 7, 0)
	lines.Left.Size = UDim2.fromOffset(10, 2)
	lines.Right.Position = UDim2.fromOffset(g + 7, 0)
	lines.Right.Size = UDim2.fromOffset(10, 2)
end
setGap(8)

-- ===== HP =====
local hpBg = Instance.new("Frame")
hpBg.Position = UDim2.new(0, 20, 1, -72)
hpBg.Size = UDim2.fromOffset(260, 20)
hpBg.BackgroundColor3 = BG
hpBg.BackgroundTransparency = 0.25
hpBg.BorderSizePixel = 0
round(hpBg, 4)
hpBg.Parent = gui

local hpFill = Instance.new("Frame")
hpFill.Size = UDim2.fromScale(1, 1)
hpFill.BackgroundColor3 = ACCENT
hpFill.BorderSizePixel = 0
round(hpFill, 4)
local hpGrad = Instance.new("UIGradient")
hpGrad.Color = ColorSequence.new(Color3.fromRGB(60, 220, 100), Color3.fromRGB(150, 255, 170))
hpGrad.Parent = hpFill
hpFill.Parent = hpBg

local hpText = Instance.new("TextLabel")
hpText.Position = UDim2.new(0, 288, 1, -74)
hpText.Size = UDim2.fromOffset(60, 24)
hpText.BackgroundTransparency = 1
hpText.Font = Enum.Font.GothamBold
hpText.TextSize = 16
hpText.TextColor3 = Color3.new(1, 1, 1)
hpText.TextXAlignment = Enum.TextXAlignment.Left
hpText.Text = "100"
hpText.Parent = gui

-- ===== ПЛАСТИНЫ =====
local plateFrames = {}
for i = 1, 3 do
	local p = Instance.new("Frame")
	p.Position = UDim2.new(0, 20 + (i - 1) * 30, 1, -98)
	p.Size = UDim2.fromOffset(26, 14)
	p.BackgroundColor3 = Color3.fromRGB(25, 28, 32)
	p.BackgroundTransparency = 0.2
	p.BorderSizePixel = 0
	round(p, 3)
	p.Parent = gui
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = PLATE_BLUE
	fill.BorderSizePixel = 0
	round(fill, 3)
	fill.Parent = p
	plateFrames[i] = fill
end

local plateHint = Instance.new("TextLabel")
plateHint.Position = UDim2.new(0, 20, 1, -120)
plateHint.Size = UDim2.fromOffset(240, 16)
plateHint.BackgroundTransparency = 1
plateHint.Font = Enum.Font.Gotham
plateHint.TextSize = 12
plateHint.TextColor3 = Color3.fromRGB(160, 165, 170)
plateHint.TextXAlignment = Enum.TextXAlignment.Left
plateHint.Text = "[4] — надеть пластину"
plateHint.Parent = gui

-- ===== СТАМИНА =====
local stamBg = Instance.new("Frame")
stamBg.Position = UDim2.new(0, 20, 1, -48)
stamBg.Size = UDim2.fromOffset(260, 6)
stamBg.BackgroundColor3 = BG
stamBg.BackgroundTransparency = 0.4
stamBg.BorderSizePixel = 0
round(stamBg, 3)
stamBg.Parent = gui
local stamFill = Instance.new("Frame")
stamFill.Size = UDim2.fromScale(1, 1)
stamFill.BackgroundColor3 = Color3.fromRGB(255, 210, 80)
stamFill.BorderSizePixel = 0
round(stamFill, 3)
stamFill.Parent = stamBg

-- ===== ПАТРОНЫ =====
local ammoText = Instance.new("TextLabel")
ammoText.AnchorPoint = Vector2.new(1, 1)
ammoText.Position = UDim2.new(1, -24, 1, -24)
ammoText.Size = UDim2.fromOffset(220, 32)
ammoText.BackgroundTransparency = 1
ammoText.Font = Enum.Font.GothamBlack
ammoText.TextSize = 24
ammoText.TextColor3 = Color3.new(1, 1, 1)
ammoText.TextXAlignment = Enum.TextXAlignment.Right
ammoText.Text = "30 / 30"
ammoText.Parent = gui

local weaponText = Instance.new("TextLabel")
weaponText.AnchorPoint = Vector2.new(1, 1)
weaponText.Position = UDim2.new(1, -24, 1, -56)
weaponText.Size = UDim2.fromOffset(220, 18)
weaponText.BackgroundTransparency = 1
weaponText.Font = Enum.Font.GothamBold
weaponText.TextSize = 14
weaponText.TextColor3 = Color3.fromRGB(190, 195, 200)
weaponText.TextXAlignment = Enum.TextXAlignment.Right
weaponText.Text = stats.DisplayName
weaponText.Parent = gui

-- ===== КИЛЛФИД =====
local feed = Instance.new("Frame")
feed.AnchorPoint = Vector2.new(1, 0)
feed.Position = UDim2.new(1, -16, 0, 16)
feed.Size = UDim2.fromOffset(320, 200)
feed.BackgroundTransparency = 1
feed.Parent = gui
local feedLayout = Instance.new("UIListLayout")
feedLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
feedLayout.Padding = UDim.new(0, 4)
feedLayout.SortOrder = Enum.SortOrder.LayoutOrder
feedLayout.Parent = feed

local KillFeedRemote = Remotes:WaitForChild("KillFeed", 5)
if KillFeedRemote then
	KillFeedRemote.OnClientEvent:Connect(function(data)
		local entry = Instance.new("TextLabel")
		entry.Size = UDim2.fromOffset(300, 20)
		entry.BackgroundColor3 = BG
		entry.BackgroundTransparency = 0.35
		entry.Font = Enum.Font.GothamBold
		entry.TextSize = 13
		entry.TextColor3 = Color3.new(1, 1, 1)
		entry.Text = ("%s  ☠  %s   [%s]"):format(data.killer, data.victim, data.weapon or "?")
		round(entry, 3)
		entry.Parent = feed
		game:GetService("Debris"):AddItem(entry, 7)
	end)
end

-- ===== ХИТ-МАРКЕР =====
local marker = Instance.new("Frame")
marker.AnchorPoint = Vector2.new(0.5, 0.5)
marker.Position = UDim2.fromScale(0.5, 0.5)
marker.BackgroundTransparency = 1
marker.Parent = gui
local markerLines = {}
for _, a in ipairs({ 45, 135, 225, 315 }) do
	local l = Instance.new("Frame")
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.Position = UDim2.fromOffset(math.cos(math.rad(a)) * 14, math.sin(math.rad(a)) * 14)
	l.Size = UDim2.fromOffset(8, 2)
	l.Rotation = a
	l.BackgroundColor3 = Color3.new(1, 1, 1)
	l.BackgroundTransparency = 1
	l.BorderSizePixel = 0
	l.Parent = marker
	markerLines[#markerLines + 1] = l
end
local function showMarker(headshot)
	for _, l in ipairs(markerLines) do
		l.BackgroundColor3 = headshot and WARN or Color3.new(1, 1, 1)
		l.BackgroundTransparency = 0
	end
	for _, l in ipairs(markerLines) do
		TweenService:Create(l, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
	end
	local s = Instance.new("Sound")
	s.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	s.Volume = 0.5
	s.Parent = gui
	s:Play()
	s.Ended:Once(function() s:Destroy() end)
end

local HitFeedbackRemote = Remotes:WaitForChild("HitFeedback", 5)
if HitFeedbackRemote then
	HitFeedbackRemote.OnClientEvent:Connect(function(data)
		if data.hit then showMarker(data.headshot) end
	end)
end

-- ===== ВСПЫШКА ПРИ УРОНЕ / НОКДАУН-ОВЕРЛЕЙ =====
local vignette = Instance.new("Frame")
vignette.Size = UDim2.fromScale(1, 1)
vignette.BackgroundColor3 = WARN
vignette.BackgroundTransparency = 1
vignette.BorderSizePixel = 0
vignette.Parent = gui

local knockedLabel = Instance.new("TextLabel")
knockedLabel.AnchorPoint = Vector2.new(0.5, 0.5)
knockedLabel.Position = UDim2.fromScale(0.5, 0.32)
knockedLabel.Size = UDim2.fromScale(0.7, 0.08)
knockedLabel.BackgroundTransparency = 1
knockedLabel.Font = Enum.Font.GothamBlack
knockedLabel.TextScaled = true
knockedLabel.TextColor3 = WARN
knockedLabel.TextStrokeTransparency = 0.4
knockedLabel.Text = ""
knockedLabel.Parent = gui

local reviveBg = Instance.new("Frame")
reviveBg.AnchorPoint = Vector2.new(0.5, 0.5)
reviveBg.Position = UDim2.fromScale(0.5, 0.42)
reviveBg.Size = UDim2.fromOffset(260, 14)
reviveBg.BackgroundColor3 = BG
reviveBg.BackgroundTransparency = 0.3
reviveBg.BorderSizePixel = 0
reviveBg.Visible = false
round(reviveBg, 4)
reviveBg.Parent = gui
local reviveFill = Instance.new("Frame")
reviveFill.Size = UDim2.fromScale(0, 1)
reviveFill.BackgroundColor3 = ACCENT
reviveFill.BorderSizePixel = 0
reviveFill.Parent = reviveBg

-- ===== ПЕРСОНАЖ =====
local character, humanoid, rootPart
local lastHP = 100
local function bind(char)
	character = char
	humanoid = char:WaitForChild("Humanoid")
	rootPart = char:WaitForChild("HumanoidRootPart")
	lastHP = humanoid.Health
	humanoid.HealthChanged:Connect(function(hp)
		if hp < lastHP - 0.5 then
			vignette.BackgroundTransparency = 0.75
			TweenService:Create(vignette, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
		end
		lastHP = hp
	end)
end
if player.Character then bind(player.Character) end
player.CharacterAdded:Connect(bind)

-- ===== ВВОД: пластины (4) и ревайв (E) =====
UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.Four or input.KeyCode == Enum.KeyCode.ButtonDUp then
		local r = Remotes:FindFirstChild("RequestPlate")
		if r then r:FireServer() end
	elseif input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonX then
		local myChar = player.Character
		local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
		local r = Remotes:FindFirstChild("RequestRevive")
		if not (myRoot and r) then return end
		for _, other in ipairs(Players:GetPlayers()) do
			if other ~= player then
				local oc = other.Character
				local oroot = oc and oc:FindFirstChild("HumanoidRootPart")
				if oroot and oroot:GetAttribute("Knocked")
					and (oroot.Position - myRoot.Position).Magnitude <= 8 then
					r:FireServer(other)
					break
				end
			end
		end
	end
end)

-- ===== ТИК =====
RunService.Heartbeat:Connect(function()
	if not (humanoid and rootPart and rootPart.Parent) then return end

	local hp = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
	hpFill.Size = UDim2.fromScale(hp, 1)
	hpText.Text = math.ceil(humanoid.Health)

	local stamina = rootPart:GetAttribute("Stamina") or 100
	stamFill.Size = UDim2.fromScale(stamina / 100, 1)
	stamFill.BackgroundTransparency = stamina >= 99 and 0.6 or 0

	local plates = rootPart:GetAttribute("Plates") or 0
	local plateHP = rootPart:GetAttribute("PlateHP") or 0
	for i = 1, 3 do
		local fillRatio = 0
		if i < plates then
			fillRatio = 1
		elseif i == plates then
			fillRatio = plateHP / 50
		end
		plateFrames[i].Size = UDim2.fromScale(fillRatio, 1)
	end
	plateHint.Text = rootPart:GetAttribute("ApplyingPlate") and "НАДЕВАЕМ ПЛАСТИНУ..." or "[4] — надеть пластину"

	local spread = rootPart:GetAttribute("Spread") or stats.HipSpread
	setGap(4 + spread * 6)
	cross.Visible = not rootPart:GetAttribute("ADS")

	if rootPart:GetAttribute("Reloading") then
		ammoText.Text = "ПЕРЕЗАРЯДКА..."
	else
		ammoText.Text = (rootPart:GetAttribute("Ammo") or stats.MagSize) .. " / " .. stats.MagSize
	end

	if rootPart:GetAttribute("Knocked") then
		vignette.BackgroundTransparency = 0.82
		knockedLabel.Text = "ВЫ В НОКДАУНЕ — ползите к тиммейту"
		local progress = rootPart:GetAttribute("ReviveProgress") or 0
		reviveBg.Visible = rootPart:GetAttribute("BeingRevived") and true or false
		reviveFill.Size = UDim2.fromScale(progress, 1)
	else
		if vignette.BackgroundTransparency > 0.99 then vignette.BackgroundTransparency = 1 end
		knockedLabel.Text = ""
		reviveBg.Visible = false
	end
end)
