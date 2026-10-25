-- StarterPlayer > StarterPlayerScripts > Client > MenuController (LocalScript)
-- ГЛАВНОЕ МЕНЮ — OMEGA PROTOCOL // ZERO:
-- • разрядка букв в заголовке (OMEGA) + суффикс PROTOCOL
-- • параллакс глубины: 2 слоя пепла + заголовок реагируют на мышь
-- • плёночное зерно: сканлайны + мерцание
-- • единая звуковая связка: ховер выше тоном, клик ниже, деплой — бас
-- • деплой-последовательность (прогресс + вспышка)
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

-- ================== ЗВУК: единая связка ==================
local srcSound = Instance.new("Sound")
srcSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
srcSound.Volume = 0.4
srcSound.Parent = gui

local function sfx(kind)
	local p, v = 1, 0.4
	if kind == "hover" then p, v = 1.7, 0.18
	elseif kind == "click" then p, v = 0.9, 0.4
	elseif kind == "deploy" then p, v = 0.55, 0.7
	elseif kind == "back" then p, v = 1.3, 0.25
	end
	srcSound.PlaybackSpeed = p
	srcSound.Volume = v
	srcSound:Play()
end

-- ================== ФОН ==================
local root = Instance.new("Frame")
root.Size = UDim2.fromScale(1, 1)
root.BackgroundColor3 = C_BG
root.BorderSizePixel = 0
root.ClipsDescendants = true
root.Parent = gui

local rootGrad = Instance.new("UIGradient")
rootGrad.Rotation = 45
rootGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(14, 17, 22)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(8, 10, 13)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 14, 18)),
})
rootGrad.Parent = root

local function vignetteBar(side)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, 0, 0.35, 0)
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

-- ================== ПЕПЕЛ: 2 слоя параллакса ==================
local ashFar = Instance.new("Frame")
ashFar.Size = UDim2.fromScale(1.1, 1)
ashFar.Position = UDim2.fromScale(-0.05, 0)
ashFar.BackgroundTransparency = 1
ashFar.ZIndex = 3
ashFar.Parent = root

local ashNear = Instance.new("Frame")
ashNear.Size = UDim2.fromScale(1.15, 1)
ashNear.Position = UDim2.fromScale(-0.075, 0)
ashNear.BackgroundTransparency = 1
ashNear.ZIndex = 4
ashNear.Parent = root

local ashColors = {
	Color3.fromRGB(255, 176, 64),
	Color3.fromRGB(200, 200, 210),
	Color3.fromRGB(120, 130, 145),
}

math.randomseed(os.clock())

local function spawnAsh(layer, count, minSize, maxSize, minDur, maxDur, baseTransparency)
	for _ = 1, count do
		local p = Instance.new("Frame")
		local size = math.random(minSize, maxSize)
		p.Size = UDim2.fromOffset(size, size)
		p.AnchorPoint = Vector2.new(0.5, 0.5)
		p.Position = UDim2.new(math.random(), 0, 1.05, 0)
		p.BackgroundColor3 = ashColors[math.random(#ashColors)]
		p.BackgroundTransparency = math.clamp(baseTransparency + (math.random(-15, 15) / 100), 0, 0.95)
		p.BorderSizePixel = 0
		corner(p, 2)
		p.ZIndex = layer.ZIndex
		p.Parent = layer
		local dur = math.random(minDur, maxDur)
		local drift = math.random(-10, 10) / 100
		TweenService:Create(p, TweenInfo.new(dur, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, false, math.random(0, 10)), {
			Position = UDim2.new(p.Position.X.Scale + drift, 0, -0.05, 0),
		}):Play()
	end
end

spawnAsh(ashFar, 22, 2, 3, 14, 22, 0.72)
spawnAsh(ashNear, 14, 3, 5, 8, 14, 0.5)

-- ================== ПЛЁНОЧНОЕ ЗЕРНО ==================
local grain = Instance.new("Frame")
grain.Size = UDim2.fromScale(1, 1)
grain.BackgroundTransparency = 1
grain.ZIndex = 40
grain.Parent = root

for i = 0, 80 do
	local line = Instance.new("Frame")
	line.Position = UDim2.fromScale(0, i / 80)
	line.Size = UDim2.new(1, 0, 0, 1)
	line.BackgroundColor3 = Color3.new(1, 1, 1)
	line.BackgroundTransparency = 0.965
	line.BorderSizePixel = 0
	line.Parent = grain
end

local flicker = Instance.new("Frame")
flicker.Size = UDim2.fromScale(1, 1)
flicker.BackgroundColor3 = Color3.new(0, 0, 0)
flicker.BackgroundTransparency = 1
flicker.BorderSizePixel = 0
flicker.ZIndex = 41
flicker.Parent = root

task.spawn(function()
	while gui.Parent do
		if gui.Enabled then
			flicker.BackgroundTransparency = 0.94 + math.random(0, 5) / 100
			TweenService:Create(flicker, TweenInfo.new(0.12), {
				BackgroundTransparency = 0.97 + math.random(0, 3) / 100,
			}):Play()
		end
		task.wait(0.1 + math.random(0, 8) / 100)
	end
end)

-- ================== ЗАГОЛОВОК: OMEGA PROTOCOL // ZERO ==================
local titleBlock = Instance.new("Frame")
titleBlock.Position = UDim2.new(0, 64, 0, 72)
titleBlock.Size = UDim2.fromOffset(640, 130)
titleBlock.BackgroundTransparency = 1
titleBlock.ZIndex = 10
titleBlock.Parent = root

local LETTERS = { "O", "M", "E", "G", "A" }
local LETTER_W, LETTER_GAP = 46, 22
local letterLabels = {}

for i, ch in ipairs(LETTERS) do
	local l = Instance.new("TextLabel")
	l.Position = UDim2.fromOffset((i - 1) * (LETTER_W + LETTER_GAP), 0)
	l.Size = UDim2.fromOffset(LETTER_W, 78)
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.GothamBlack
	l.TextSize = 64
	l.TextColor3 = C_WHITE
	l.TextXAlignment = Enum.TextXAlignment.Center
	l.Text = ch
	l.Parent = titleBlock

	local lg = Instance.new("UIGradient")
	lg.Rotation = 90
	lg.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 158, 168)),
	})
	lg.Parent = l

	letterLabels[#letterLabels + 1] = l
end

-- Суффикс «PROTOCOL» справа от OMEGA
local titleSuffix = Instance.new("TextLabel")
titleSuffix.Position = UDim2.fromOffset(#LETTERS * (LETTER_W + LETTER_GAP) + 16, 24)
titleSuffix.Size = UDim2.fromOffset(240, 42)
titleSuffix.BackgroundTransparency = 1
titleSuffix.Font = Enum.Font.GothamBlack
titleSuffix.TextSize = 34
titleSuffix.TextColor3 = C_AMBER
titleSuffix.TextXAlignment = Enum.TextXAlignment.Left
titleSuffix.Text = "PROTOCOL"
titleSuffix.Parent = titleBlock

local subtitle = Instance.new("TextLabel")
subtitle.Position = UDim2.new(0, 2, 0, 86)
subtitle.Size = UDim2.new(1, 0, 0, 20)
subtitle.BackgroundTransparency = 1
subtitle.Font = Enum.Font.GothamBold
subtitle.TextSize = 14
subtitle.TextColor3 = C_AMBER
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Text = "// ZERO  ·  TACTICAL BATTLE ROYALE"
subtitle.Parent = titleBlock

-- ================== КНОПКИ ==================
local menuList = Instance.new("Frame")
menuList.Position = UDim2.new(0, 64, 0.5, -110)
menuList.Size = UDim2.fromOffset(320, 280)
menuList.BackgroundTransparency = 1
menuList.ZIndex = 10
menuList.Parent = root

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 14)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = menuList

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
		sfx("hover")
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
		sfx("click")
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

-- ================== ДЕПЛОЙ-ОВЕРЛЕЙ ==================
local deployOverlay = Instance.new("Frame")
deployOverlay.Size = UDim2.fromScale(1, 1)
deployOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
deployOverlay.BackgroundTransparency = 0.15
deployOverlay.BorderSizePixel = 0
deployOverlay.Visible = false
deployOverlay.ZIndex = 45
deployOverlay.Parent = root

local deployTitle = Instance.new("TextLabel")
deployTitle.AnchorPoint = Vector2.new(0.5, 0)
deployTitle.Position = UDim2.new(0.5, 0, 0.42, 0)
deployTitle.Size = UDim2.fromOffset(600, 34)
deployTitle.BackgroundTransparency = 1
deployTitle.Font = Enum.Font.GothamBlack
deployTitle.TextSize = 28
deployTitle.TextColor3 = C_WHITE
deployTitle.Text = "ПОДГОТОВКА К ВЫСАДКЕ"
deployTitle.ZIndex = 46
deployTitle.Parent = deployOverlay

local deployBarBg = Instance.new("Frame")
deployBarBg.AnchorPoint = Vector2.new(0.5, 0)
deployBarBg.Position = UDim2.new(0.5, 0, 0.5, 0)
deployBarBg.Size = UDim2.fromOffset(360, 8)
deployBarBg.BackgroundColor3 = Color3.fromRGB(30, 34, 40)
deployBarBg.BorderSizePixel = 0
deployBarBg.ZIndex = 46
corner(deployBarBg, 4)
deployBarBg.Parent = deployOverlay

local deployBarFill = Instance.new("Frame")
deployBarFill.Size = UDim2.fromScale(0, 1)
deployBarFill.BackgroundColor3 = C_ACCENT
deployBarFill.BorderSizePixel = 0
deployBarFill.ZIndex = 47
corner(deployBarFill, 4)
deployBarFill.Parent = deployBarBg

local deployTip = Instance.new("TextLabel")
deployTip.AnchorPoint = Vector2.new(0.5, 0)
deployTip.Position = UDim2.new(0.5, 0, 0.55, 0)
deployTip.Size = UDim2.fromOffset(700, 18)
deployTip.BackgroundTransparency = 1
deployTip.Font = Enum.Font.Gotham
deployTip.TextSize = 13
deployTip.TextColor3 = C_GREY
deployTip.Text = "Совет: пластины брони надеваются клавишей 4 — не лезьте в бой без них."
deployTip.ZIndex = 46
deployTip.Parent = deployOverlay

local deployTips = {
	"Совет: пластины брони надеваются клавишей 4 — не лезьте в бой без них.",
	"Совет: двойной Shift — тактический спринт, но стамина не бесконечна.",
	"Совет: тиммейта в нокдауне можно поднять на E — не бросайте своих.",
	"Совет: хедшот наносит двойной урон — цельтесь в голову.",
	"Совет: в Гулаге победа возвращает вас в бой.",
}

-- ================== ОТКРЫТИЕ / ЗАКРЫТИЕ ==================
local blackFlash = Instance.new("Frame")
blackFlash.Size = UDim2.fromScale(1, 1)
blackFlash.BackgroundColor3 = Color3.new(0, 0, 0)
blackFlash.BackgroundTransparency = 1
blackFlash.ZIndex = 50
blackFlash.BorderSizePixel = 0
blackFlash.Parent = root

local menuOpenState = false

local function setMenuOpen(open)
	menuOpenState = open
	gui.Enabled = true
	if open then
		deployOverlay.Visible = false
		blur.Size = 0
		TweenService:Create(blur, TweenInfo.new(0.5, Enum.EasingStyle.Quint), { Size = 18 }):Play()
		for i, l in ipairs(letterLabels) do
			l.TextTransparency = 1
			l.Position = UDim2.fromOffset((i - 1) * (LETTER_W + LETTER_GAP) + 30, 14)
			task.delay(0.06 * i, function()
				TweenService:Create(l, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {
					TextTransparency = 0,
					Position = UDim2.fromOffset((i - 1) * (LETTER_W + LETTER_GAP), 0),
				}):Play()
			end)
		end
		titleSuffix.TextTransparency = 1
		task.delay(0.06 * (#LETTERS + 1), function()
			TweenService:Create(titleSuffix, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {
				TextTransparency = 0,
			}):Play()
		end)
		subtitle.TextTransparency = 1
		task.delay(0.5, function()
			TweenService:Create(subtitle, TweenInfo.new(0.5), { TextTransparency = 0 }):Play()
		end)
		for i, b in ipairs(buttons) do
			b.btn.BackgroundTransparency = 1
			b.txt.TextTransparency = 1
			task.delay(0.12 * i, function()
				TweenService:Create(b.btn, TweenInfo.new(0.4, Enum.EasingStyle.Quint), { BackgroundTransparency = 0.65 }):Play()
				TweenService:Create(b.txt, TweenInfo.new(0.4, Enum.EasingStyle.Quint), { TextTransparency = 0 }):Play()
			end)
		end
	else
		TweenService:Create(blur, TweenInfo.new(0.4), { Size = 0 }):Play()
		blackFlash.BackgroundTransparency = 0
		TweenService:Create(blackFlash, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
		task.delay(0.35, function()
			if not menuOpenState then
				gui.Enabled = false
			end
		end)
	end
end

local deploying = false

local function deploy()
	if deploying then return end
	deploying = true
	sfx("deploy")
	deployOverlay.Visible = true
	deployOverlay.BackgroundTransparency = 1
	TweenService:Create(deployOverlay, TweenInfo.new(0.3), { BackgroundTransparency = 0.15 }):Play()
	deployBarFill.Size = UDim2.fromScale(0, 1)
	deployTip.Text = deployTips[math.random(#deployTips)]
	TweenService:Create(deployBarFill, TweenInfo.new(1.4, Enum.EasingStyle.Linear), {
		Size = UDim2.fromScale(1, 1),
	}):Play()
	task.delay(1.4, function()
		blackFlash.BackgroundTransparency = 0
		TweenService:Create(blackFlash, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
		deployOverlay.Visible = false
		TweenService:Create(blur, TweenInfo.new(0.4), { Size = 0 }):Play()
		task.delay(0.4, function()
			gui.Enabled = false
			deploying = false
			menuOpenState = false
		end)
	end)
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
modeLine.ZIndex = 10
modeLine.Parent = root

-- ================== КАРТОЧКА ИГРОКА ==================
local card = Instance.new("Frame")
card.AnchorPoint = Vector2.new(1, 0)
card.Position = UDim2.new(1, -24, 0, 24)
card.Size = UDim2.fromOffset(300, 92)
card.BackgroundColor3 = C_PANEL
card.BackgroundTransparency = 0.25
card.BorderSizePixel = 0
card.ZIndex = 10
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
newsBar.ZIndex = 10
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
tickerLabel.Text = "OMEGA PROTOCOL // ZERO  ///  СЕЗОН ZERO: ПРОТОКОЛ АКТИВЕН  ///  НОВОЕ: БРОНЕПЛАСТИНЫ И НОКДАУН  ///  СКОРО: СЖИМАЮЩИЙСЯ КРУГ И ГУЛАГ  ///  СООБЩАЙТЕ О БАГАХ РАЗРАБОТЧИКУ  ///  "
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
versionLabel.ZIndex = 10
versionLabel.Parent = root

-- ================== ПОДСКАЗКА F1 ==================
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

-- ================== ПАРАЛЛАКС: слои дышат от мыши ==================
local px, py = 0, 0
local tx, ty = 0, 0

UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		local cam = workspace.CurrentCamera
		if not cam then return end
		local vp = cam.ViewportSize
		tx = (input.Position.X / vp.X - 0.5) * 2
		ty = (input.Position.Y / vp.Y - 0.5) * 2
	end
end)

RunService.RenderStepped:Connect(function(dt)
	if not gui.Enabled then return end
	px += (tx - px) * math.min(dt * 6, 1)
	py += (ty - py) * math.min(dt * 6, 1)
	titleBlock.Position = UDim2.new(0, 64 + px * -14, 0, 72 + py * -6)
	ashFar.Position = UDim2.fromScale(-0.05 + px * -0.012, py * -0.008)
	ashNear.Position = UDim2.fromScale(-0.075 + px * -0.03, py * -0.02)
	card.Position = UDim2.new(1, -24 + px * 10, 0, 24 + py * 4)
end)

-- ================== ВВОД ==================
UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.F1 or input.KeyCode == Enum.KeyCode.ButtonSelect then
		if deploying then return end
		sfx("back")
		setMenuOpen(not menuOpenState)
	end
end)

-- ================== СТАРТ ==================
task.wait(0.2)
setMenuOpen(true)
