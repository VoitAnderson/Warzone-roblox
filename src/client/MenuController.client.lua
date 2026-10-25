-- StarterPlayer > StarterPlayerScripts > Client > MenuController (LocalScript)
-- AAA ГЛАВНОЕ МЕНЮ: кинематографичный тёмный фон, летящий пепел,
-- металлический заголовок, карточка игрока с аватаром, бегущая строка,
-- блюр 3D-сцены, ховер-анимации кнопок, деплой-последовательность.
-- F1 — открыть/закрыть меню.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer

-- ================== ТЕМА ==================
local C_BG      = Color3.fromRGB(10, 12, 15)
local C_PANEL   = Color3.fromRGB(18, 21, 26)
local C_WHITE   = Color3.fromRGB(235, 240, 245)
local C_GREY    = Color3.fromRGB(140, 148, 158)
local C_AMBER   = Color3.fromRGB(255, 176, 64)
local C_ACCENT  = Color3.fromRGB(80, 255, 120)
local VERSION   = "v0.3.0 · PHASE 3"
-- ==========================================

-- ===== GUI-КОРНИ =====
local gui = Instance.new("ScreenGui")
gui.Name = "MainMenu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 90
gui.Parent = player:WaitForChild("PlayerGui")

local hintGui = Instance.new("ScreenGui")
hintGui.Name = "MenuHint"
hintGui.ResetOnSpawn = false
hintGui.IgnoreGuiInset = true
hintGui.DisplayOrder = 91
hintGui.Parent = player:WaitForChild("PlayerGui")

local function corner(parent, px)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, px)
	c.Parent = parent
end

local function stroke(parent, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness
	s.Transparency = transparency or 0.5
	s.Parent = parent
end

-- ================== ФОН ==================
local root = Instance.new("Frame")
root.Size = UDim2.fromScale(1, 1)
root.BackgroundColor3 = C_BG
root.BorderSizePixel = 0
root.Parent = gui

local rootGrad = Instance.new("UIGradient")
rootGrad.Rotation = 45
rootGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(14, 17, 22)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(8, 10, 13)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 14, 18)),
})
rootGrad.Parent = root

-- Виньетка: затемнение сверху и снизу
local function vignetteBar(side)
	local f = Instance.new("Frame")
	f.Size = side == "Top" and UDim2.new(1, 0, 0.35, 0) or UDim2.new(1, 0, 0.35, 0)
	f.AnchorPoint = side == "Top" and Vector2.new(0, 0) or Vector2.new(0, 1)
	f.Position = side == "Top" and UDim2.fromScale(0, 0) or UDim2.fromScale(0, 1)
	f.BackgroundColor3 = Color3.new(0, 0, 0)
	f.BorderSizePixel = 0
	f.BackgroundTransparency = 0.3
	f.ZIndex = 2
	f.Parent = root
	local g = Instance.new("UIGradient")
	g.Rotation = side == "Top" and 90 or -90
	g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.55),
		NumberSequenceKeypoint.new(1, 1),
	})
	g.Parent = f
end
vignetteBar("Top")
vignetteBar("Bottom")

-- ================== ПЕПЕЛ (частицы) ==================
local ashColors = {
	Color3.fromRGB(255, 176, 64),
	Color3.fromRGB(200, 200, 210),
	Color3.fromRGB(120, 130, 145),
}
math.randomseed(os.clock())
for _ = 1, 34 do
	local p = Instance.new("Frame")
	local size = math.random(2, 4)
	p.Size = UDim2.fromOffset(size, size)
	p.AnchorPoint = Vector2.new(0.5, 0.5)
	p.Position = UDim2.new(math.random(), 0, 1.05, 0)
	p.BackgroundColor3 = ashColors[math.random(#ashColors)]
	p.BackgroundTransparency = math.random(30, 75) / 100
	p.BorderSizePixel = 0
	corner(p, 2)
	p.ZIndex = 3
	p.Parent = root
	local dur = math.random(9, 18)
	TweenService:Create(p, TweenInfo.new(dur, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, false, math.random(0, 8)), {
		Position = UDim2.new(math.random(), 0, -0.05, 0),
	}):Play()
end

-- ================== ЗАГОЛОВОК ==================
local titleBlock = Instance.new("Frame")
titleBlock.Position = UDim2.new(0, 64, 0, 72)
titleBlock.Size = UDim2.fromOffset(600, 130)
titleBlock.BackgroundTransparency = 1
titleBlock.Parent = root

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 78)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.TextSize = 64
title.TextColor3 = C_WHITE
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "WARZONE"
title.Parent = titleBlock

local titleGrad = Instance.new("UIGradient")
titleGrad.Rotation = 90
titleGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 158, 168)),
})
titleGrad.Parent = title

local subtitle = Instance.new("TextLabel")
subtitle.Position = UDim2.new(0, 2, 0, 84)
subtitle.Size = UDim2.new(1, 0, 0, 20)
subtitle.BackgroundTransparency = 1
subtitle.Font = Enum.Font.GothamBold
subtitle.TextSize = 14
subtitle.TextColor3 = C_AMBER
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Text = "TACTICAL BATTLE ROYALE  //  ОПЕРАЦИЯ «ASHNA»"
subtitle.Parent = titleBlock

-- ================== КНОПКИ ==================
local menuList = Instance.new("Frame")
menuList.Position = UDim2.new(0, 64, 0.5, -110)
menuList.Size = UDim2.fromOffset(320, 280)
menuList.BackgroundTransparency = 1
menuList.Parent = root

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 14)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = menuList

local clickSound = Instance.new("Sound")
clickSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
clickSound.Volume = 0.4
clickSound.Parent = gui

local buttons = {}

local function makeButton(order, label, enabled, onClick)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 46)
	btn.BackgroundColor3 = C_PANEL
	btn.BackgroundTransparency = 0.65
	btn.AutoButtonColor = false
	btn.Text = ""
	btn.LayoutOrder = order
	btn.Parent = menuList
	corner(btn, 6)
	stroke(btn, Color3.fromRGB(70, 76, 86), 1, 0.6)

	local txt = Instance.new("TextLabel")
	txt.Position = UDim2.new(0, 18, 0, 0)
	txt.Size = UDim2.new(1, -70, 1, 0)
	txt.BackgroundTransparency = 1
	txt.Font = Enum.Font.GothamBold
	txt.TextSize = 20
	txt.TextColor3 = enabled and C_WHITE or C_GREY
	txt.TextXAlignment = Enum.TextXAlignment.Left
	txt.Text = label
	txt.Parent = btn

	local bar = Instance.new("Frame")
	bar.AnchorPoint = Vector2.new(0, 0.5)
	bar.Position = UDim2.new(1, 0, 0.5, 0)
	bar.Size = UDim2.fromOffset(0, 26)
	bar.BackgroundColor3 = C_ACCENT
	bar.BorderSizePixel = 0
	corner(bar, 2)
	bar.Parent = btn

	if not enabled then
		local soon = Instance.new("TextLabel")
		soon.AnchorPoint = Vector2.new(1, 0.5)
		soon.Position = UDim2.new(1, -14, 0.5, 0)
		soon.Size = UDim2.fromOffset(56, 18)
		soon.BackgroundTransparency = 1
		soon.Font = Enum.Font.Gotham
		soon.TextSize = 11
		soon.TextColor3 = C_AMBER
		soon.TextXAlignment = Enum.TextXAlignment.Right
		soon.Text = "СКОРО"
		soon.Parent = btn
	end

	btn.MouseEnter:Connect(function()
		if not enabled then return end
		TweenService:Create(btn, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {
			BackgroundTransparency = 0.35,
		}):Play()
		TweenService:Create(bar, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {
			Size = UDim2.fromOffset(6, 30),
		}):Play()
		clickSound.PlaybackSpeed = 1.6
		clickSound:Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {
			BackgroundTransparency = 0.65,
		}):Play()
		TweenService:Create(bar, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {
			Size = UDim2.fromOffset(0, 26),
		}):Play()
	end)
	btn.Activated:Connect(function()
		if not enabled then return end
		clickSound.PlaybackSpeed = 0.8
		clickSound:Play()
		onClick()
	end)

	buttons[#buttons + 1] = { btn = btn, txt = txt }
	return btn
end

-- ================== БЛЮР 3D-СЦЕНЫ ==================
local blur = Lighting:FindFirstChild("MenuBlur")
if not blur then
	blur = Instance.new("BlurEffect")
	blur.Name = "MenuBlur"
	blur.Size = 0
	blur.Parent = Lighting
end

-- ================== ОТКРЫТИЕ / ЗАКРЫТИЕ ==================
local blackFlash = Instance.new("Frame")
blackFlash.Size = UDim2.fromScale(1, 1)
blackFlash.BackgroundColor3 = Color3.new(0, 0, 0)
blackFlash.BackgroundTransparency = 1
blackFlash.ZIndex = 50
blackFlash.BorderSizePixel = 0
blackFlash.Parent = root

local function setMenuOpen(open)
	gui.Enabled = true
	if open then
		blur.Size = 0
		TweenService:Create(blur, TweenInfo.new(0.5, Enum.EasingStyle.Quint), { Size = 18 }):Play()
		root.BackgroundTransparency = 0
		for i, b in ipairs(buttons) do
			b.btn.Position = UDim2.fromOffset(-24, b.btn.Position.Y.Offset)
			b.btn.BackgroundTransparency = 1
			b.txt.TextTransparency = 1
			task.delay(i * 0.07, function()
				TweenService:Create(b.btn, TweenInfo.new(0.4, Enum.EasingStyle.Quint), { Position = UDim2.fromOffset(0, b.btn.Position.Y.Offset), BackgroundTransparency = 0.65 }):Play()
				TweenService:Create(b.txt, TweenInfo.new(0.4, Enum.EasingStyle.Quint), { TextTransparency = 0 }):Play()
			end)
		end
	else
		TweenService:Create(blur, TweenInfo.new(0.4), { Size = 0 }):Play()
		TweenService:Create(blackFlash, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
		blackFlash.BackgroundTransparency = 0
		task.delay(0.35, function()
			gui.Enabled = false
		end)
	end
end

local function deploy()
	-- Деплой: вспышка, звук, закрытие
	clickSound.PlaybackSpeed = 0.6
	clickSound:Play()
	blackFlash.BackgroundTransparency = 0
	TweenService:Create(blackFlash, TweenInfo.new(0.45), { BackgroundTransparency = 1 }):Play()
	setMenuOpen(false)
end

makeButton(1, "В БОЙ", true, deploy)
makeButton(2, "СНАРЯЖЕНИЕ", false, nil)
makeButton(3, "НАСТРОЙКИ", false, nil)

local modeLine = Instance.new("TextLabel")
modeLine.Position = UDim2.new(0, 66, 0.5, 172)
modeLine.Size = UDim2.fromOffset(320, 18)
modeLine.BackgroundTransparency = 1
modeLine.Font = Enum.Font.Gotham
modeLine.TextSize = 12
modeLine.TextColor3 = C_GREY
modeLine.TextXAlignment = Enum.TextXAlignment.Left
modeLine.Text = "РЕЖИМ: QUADS · 100 ИГРОКОВ · GULAG ВКЛ."
modeLine.Parent = root

-- ================== КАРТОЧКА ИГРОКА ==================
local card = Instance.new("Frame")
card.AnchorPoint = Vector2.new(1, 0)
card.Position = UDim2.new(1, -24, 0, 24)
card.Size = UDim2.fromOffset(300, 92)
card.BackgroundColor3 = C_PANEL
card.BackgroundTransparency = 0.25
card.BorderSizePixel = 0
corner(card, 8)
stroke(card, Color3.fromRGB(70, 76, 86), 1, 0.55)
card.Parent = root

local avatar = Instance.new("ImageLabel")
avatar.Position = UDim2.new(0, 12, 0.5, 0)
avatar.AnchorPoint = Vector2.new(0, 0.5)
avatar.Size = UDim2.fromOffset(64, 64)
avatar.BackgroundColor3 = Color3.fromRGB(30, 34, 40)
avatar.BorderSizePixel = 0
corner(avatar, 8)
avatar.Parent = card

task.spawn(function()
	local ok, content = pcall(function()
		return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
	end)
	if ok then
		avatar.Image = content
	end
end)

local cardName = Instance.new("TextLabel")
cardName.Position = UDim2.new(0, 88, 0, 16)
cardName.Size = UDim2.new(1, -100, 0, 24)
cardName.BackgroundTransparency = 1
cardName.Font = Enum.Font.GothamBlack
cardName.TextSize = 18
cardName.TextColor3 = C_WHITE
cardName.TextXAlignment = Enum.TextXAlignment.Left
cardName.Text = player.DisplayName
cardName.Parent = card

local cardSub = Instance.new("TextLabel")
cardName.Position = UDim2.new(0, 88, 0, 44)
cardSub.Position = UDim2.new(0, 88, 0, 46)
cardSub.Size = UDim2.new(1, -100, 0, 16)
cardSub.BackgroundTransparency = 1
cardSub.Font = Enum.Font.Gotham
cardSub.TextSize = 12
cardSub.TextColor3 = C_GREY
cardSub.TextXAlignment = Enum.TextXAlignment.Left
cardSub.Text = "УРОВЕНЬ 1  ·  ФОНД $0  ·  0 ПОБЕД"
cardSub.Parent = card

-- ================== БЕГУЩАЯ СТРОКА ==================
local newsBar = Instance.new("Frame")
newsBar.AnchorPoint = Vector2.new(0.5, 1)
newsBar.Position = UDim2.new(0.5, 0, 1, -44)
newsBar.Size = UDim2.new(1, -128, 0, 26)
newsBar.BackgroundColor3 = C_PANEL
newsBar.BackgroundTransparency = 0.4
newsBar.BorderSizePixel = 0
corner(newsBar, 5)
newsBar.Parent = root

local newsDot = Instance.new("Frame")
newsDot.Position = UDim2.new(0, 12, 0.5, 0)
newsDot.AnchorPoint = Vector2.new(0, 0.5)
newsDot.Size = UDim2.fromOffset(8, 8)
newsDot.BackgroundColor3 = C_ACCENT
newsDot.BorderSizePixel = 0
corner(newsDot, 4)
newsDot.Parent = newsBar

local tickerLabel = Instance.new("TextLabel")
tickerLabel.Position = UDim2.new(0, 36, 0, 0)
tickerLabel.Size = UDim2.fromOffset(1400, 26)
tickerLabel.BackgroundTransparency = 1
tickerLabel.Font = Enum.Font.Gotham
tickerLabel.TextSize = 13
tickerLabel.TextColor3 = C_GREY
tickerLabel.TextXAlignment = Enum.TextXAlignment.Left
tickerLabel.Text = "СЕЗОН 1: ОПЕРАЦИЯ «ASHNA»  ///  НОВОЕ: БРОНЕПЛАСТИНЫ И НОКДАУН  ///  СКОРО: СЖИМАЮЩИЙСЯ КРУГ И ГУЛАГ  ///  СООБЩАЙТЕ О БАГАХ В РАЗРАБОТЧИКУ  ///  "
tickerLabel.Parent = newsBar

local tickerX = 36
RunService.RenderStepped:Connect(function(dt)
	if not gui.Enabled then return end
	tickerX -= 70 * dt
	if tickerX < -tickerLabel.AbsoluteSize.X then
		tickerX = newsBar.AbsoluteSize.X
	end
	tickerLabel.Position = UDim2.fromOffset(tickerX, 0)
end)

-- ================== ВЕРСИЯ / ПОДВАЛ ==================
local versionLabel = Instance.new("TextLabel")
versionLabel.AnchorPoint = Vector2.new(1, 1)
versionLabel.Position = UDim2.new(1, -24, 1, -14)
versionLabel.Size = UDim2.fromOffset(300, 16)
versionLabel.BackgroundTransparency = 1
versionLabel.Font = Enum.Font.Gotham
versionLabel.TextSize = 11
versionLabel.TextColor3 = Color3.fromRGB(90, 96, 106)
versionLabel.TextXAlignment = Enum.TextXAlignment.Right
versionLabel.Text = VERSION
versionLabel.Parent = root

-- ================== ПОДСКАЗКА F1 (живёт всегда) ==================
local hint = Instance.new("TextLabel")
hint.AnchorPoint = Vector2.new(0, 1)
hint.Position = UDim2.new(0, 16, 1, -12)
hint.Size = UDim2.fromOffset(240, 16)
hint.BackgroundTransparency = 1
hint.Font = Enum.Font.Gotham
hint.TextSize = 11
hint.TextColor3 = Color3.fromRGB(120, 128, 138)
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.Text = "F1 — ГЛАВНОЕ МЕНЮ"
hint.Parent = hintGui

-- ================== ВВОД ==================
UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.F1 or input.KeyCode == Enum.KeyCode.ButtonSelect then
		setMenuOpen(not gui.Enabled)
	end
end)

-- ================== СТАРТ: торжественное открытие ==================
task.wait(0.2)
setMenuOpen(true)
