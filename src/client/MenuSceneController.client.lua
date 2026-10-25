-- StarterPlayer > StarterPlayerScripts > Client > MenuSceneController (LocalScript)
-- ЖИВАЯ 3D-СЦЕНА ГЛАВНОГО МЕНЮ — OMEGA PROTOCOL // ZERO
-- Это не фон-шум, а интерактивная сцена:
--   • камера сама облетает голограмму; ПКМ + мышь — вращение, колесо — зум
--   • Q/E и стрелки — вращение/наклон; геймпад — правый стик
--   • клик по голограмме/дронам — энергетический импульс: кольца вспыхивают,
--     дроны разлетаются, FOV-панч, звук
--   • наведение прицела мыши на голограмму — ховер-пинг
-- Всё строится процедурно на лету, ни одного ассета. Сцена живёт, пока меню открыто.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local menuGui = playerGui:WaitForChild("MainMenu", 30)
if not menuGui then return end
local camera = workspace.CurrentCamera

-- ================== КОНСТАНТЫ ==================
local SCENE_POS = Vector3.new(512, 0, 512) -- далеко от карты, чтобы не мешать геймплею
local LOOK_AT = SCENE_POS + Vector3.new(0, 12, 0)

local C_DARK   = Color3.fromRGB(14, 16, 21)
local C_GROUND = Color3.fromRGB(8, 9, 12)
local C_AMBER  = Color3.fromRGB(255, 176, 64)
local C_ACCENT = Color3.fromRGB(80, 255, 120)
local C_WHITE  = Color3.fromRGB(235, 240, 245)

-- ================== СОСТОЯНИЕ ==================
local ringOuter = {}
local ringInner = {}
local drones = {}
local panels = {}
local spotHeads = {}
local interactiveFolder = nil
local emberEmitter = nil
local sfxSound = nil
local scatterUntil = 0

local camState = {
	yaw = math.rad(210),
	pitch = math.rad(17),
	radius = 44,
	lastUser = 0,
	rmbDown = false,
	savedType = nil,
}

-- ================== ХЕЛПЕРЫ ==================
local function mkPart(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		p[k] = v
	end
	return p
end

local sceneModel = Instance.new("Model")
sceneModel.Name = "MenuSceneModel"

local staticFolder = Instance.new("Folder")
staticFolder.Name = "Static"
staticFolder.Parent = sceneModel

interactiveFolder = Instance.new("Folder")
interactiveFolder.Name = "Interactive"
interactiveFolder.Parent = sceneModel

-- Звук сцены
sfxSound = Instance.new("Sound")
sfxSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
sfxSound.Volume = 0.3
sfxSound.Parent = playerGui

-- ================== ЗЕМЛЯ И СЕТКА ==================
local ground = mkPart({
	Size = Vector3.new(280, 1, 280),
	Material = Enum.Material.SmoothPlastic,
	Color = C_GROUND,
})
ground.CFrame = CFrame.new(SCENE_POS + Vector3.new(0, -0.5, 0))
ground.Parent = staticFolder

for i = -10, 10 do
	local color = (i % 5 == 0) and C_AMBER or C_ACCENT
	local lineA = mkPart({
		Size = Vector3.new(280, 0.12, 0.7),
		Material = Enum.Material.Neon,
		Color = color,
		Transparency = 0.88,
	})
	lineA.CFrame = CFrame.new(SCENE_POS + Vector3.new(0, 0.07, i * 14))
	lineA.Parent = staticFolder
	local lineB = mkPart({
		Size = Vector3.new(0.7, 0.12, 280),
		Material = Enum.Material.Neon,
		Color = color,
		Transparency = 0.88,
	})
	lineB.CFrame = CFrame.new(SCENE_POS + Vector3.new(i * 14, 0.07, 0))
	lineB.Parent = staticFolder
end

-- ================== ПЬЕДЕСТАЛ И ЛУЧ ==================
local pedestal = mkPart({
	Size = Vector3.new(2.4, 11, 11),
	Material = Enum.Material.Metal,
	Color = Color3.fromRGB(28, 32, 38),
	Reflectance = 0.05,
})
pedestal.CFrame = CFrame.new(SCENE_POS + Vector3.new(0, 1.2, 0)) * CFrame.Angles(0, 0, math.rad(90))
pedestal.Parent = staticFolder

local disc = mkPart({
	Size = Vector3.new(0.3, 9, 9),
	Material = Enum.Material.Neon,
	Color = C_ACCENT,
	Transparency = 0.4,
})
disc.CFrame = CFrame.new(SCENE_POS + Vector3.new(0, 2.6, 0)) * CFrame.Angles(0, 0, math.rad(90))
disc.Parent = staticFolder

local beam = mkPart({
	Size = Vector3.new(11, 1.2, 1.2),
	Material = Enum.Material.Neon,
	Color = C_ACCENT,
	Transparency = 0.86,
})
beam.CFrame = CFrame.new(SCENE_POS + Vector3.new(0, 8.6, 0)) * CFrame.Angles(0, 0, math.rad(90))
beam.Parent = staticFolder

-- ================== ГОЛОГРАФИЧЕСКИЕ КОЛЬЦА (OMEGA) ==================
local function makeRing(radius, height, count, color, transp, list)
	for i = 1, count do
		local a = (i / count) * math.pi * 2
		local seg = mkPart({
			Size = Vector3.new(2.4, 0.35, 0.4),
			Material = Enum.Material.Neon,
			Color = color,
			Transparency = transp,
			CanQuery = true,
		})
		local pos = SCENE_POS + Vector3.new(math.cos(a) * radius, height, math.sin(a) * radius)
		seg.CFrame = CFrame.new(pos) * CFrame.Angles(0, -(a + math.pi / 2), 0)
		seg.Parent = interactiveFolder
		list[#list + 1] = { part = seg, a = a, baseColor = color, baseTransp = transp }
	end
end

makeRing(9, 11, 26, C_AMBER, 0.25, ringOuter)
makeRing(6, 14.5, 18, C_ACCENT, 0.35, ringInner)

local function updateRing(list, rot, radius, height)
	for _, seg in ipairs(list) do
		local a = seg.a + rot
		local pos = SCENE_POS + Vector3.new(math.cos(a) * radius, height, math.sin(a) * radius)
		seg.part.CFrame = CFrame.new(pos) * CFrame.Angles(0, -(a + math.pi / 2), 0)
	end
end

-- ================== ПАРЯЩИЕ ГОЛО-ПАНЕЛИ ==================
local PANEL_TEXTS = {
	{ "OMEGA PROTOCOL", "// ZERO" },
	{ "СЕЗОН ZERO", "ПРОТОКОЛ АКТИВЕН" },
	{ "QUADS · 100 ИГРОКОВ", "GULAG: ВКЛЮЧЁН" },
	{ "ОЖИДАНИЕ ДЕПЛОЯ", "СТАТУС: ГОТОВ" },
}

local function makePanel(mainText, subText, index)
	local p = mkPart({
		Size = Vector3.new(8.5, 3.4, 0.15),
		Material = Enum.Material.Glass,
		Color = Color3.fromRGB(18, 24, 32),
		Transparency = 0.25,
		CanQuery = true,
	})

	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.LightInfluence = 0
	sg.Brightness = 2.5
	sg.PixelsPerStud = 32
	sg.Parent = p

	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(10, 14, 20)
	bg.BackgroundTransparency = 0.35
	bg.BorderSizePixel = 0
	bg.Parent = sg

	local uiStroke = Instance.new("UIStroke")
	uiStroke.Color = C_ACCENT
	uiStroke.Thickness = 2
	uiStroke.Transparency = 0.4
	uiStroke.Parent = bg

	local main = Instance.new("TextLabel")
	main.Size = UDim2.new(1, -16, 0.55, 0)
	main.Position = UDim2.new(0, 8, 0, 4)
	main.BackgroundTransparency = 1
	main.Font = Enum.Font.GothamBlack
	main.TextColor3 = C_WHITE
	main.TextScaled = true
	main.Text = mainText
	main.Parent = bg

	local sub = Instance.new("TextLabel")
	sub.AnchorPoint = Vector2.new(0.5, 1)
	sub.Position = UDim2.new(0.5, 0, 1, -6)
	sub.Size = UDim2.new(0.9, 0, 0.3, 0)
	sub.BackgroundTransparency = 1
	sub.Font = Enum.Font.GothamBold
	sub.TextColor3 = (index % 2 == 0) and C_AMBER or C_ACCENT
	sub.TextScaled = true
	sub.Text = subText
	sub.Parent = bg

	-- сканлайны для голографичности
	for i = 1, 7 do
		local line = Instance.new("Frame")
		line.Position = UDim2.fromScale(0, i / 8)
		line.Size = UDim2.new(1, 0, 0, 1)
		line.BackgroundColor3 = Color3.new(0, 0, 0)
		line.BackgroundTransparency = 0.75
		line.BorderSizePixel = 0
		line.Parent = bg
	end

	p.Parent = interactiveFolder
	panels[#panels + 1] = {
		part = p,
		r = 15 + (index % 2) * 2.5,
		h = 16.5 + index * 2.4,
		speed = 0.22 + index * 0.03,
		phase = index * (math.pi / 2),
	}
end

for i, texts in ipairs(PANEL_TEXTS) do
	makePanel(texts[1], texts[2], i)
end

-- ================== ДРОНЫ ==================
for i = 1, 6 do
	local d = mkPart({
		Size = Vector3.new(1.1, 0.3, 1.1),
		Material = Enum.Material.Neon,
		Color = (i % 2 == 0) and C_AMBER or C_WHITE,
		Transparency = 0.1,
		CanQuery = true,
	})
	d.Parent = interactiveFolder
	drones[#drones + 1] = {
		part = d,
		r = 16 + i * 1.5,
		h = 5 + (i % 3) * 3,
		speed = 0.5 + i * 0.07,
		phase = i * 1.1,
	}
end

-- ================== БАШНИ СКЛАЙНА ==================
math.randomseed(os.clock())
for i = 1, 10 do
	local ang = (i / 10) * math.pi * 2 + math.random() * 0.3
	local dist = 58 + math.random() * 22
	local h = 24 + math.random() * 40
	local w = 8 + math.random() * 6
	local dep = 8 + math.random() * 6
	local base = SCENE_POS + Vector3.new(math.cos(ang) * dist, h / 2, math.sin(ang) * dist)

	local tw = mkPart({
		Size = Vector3.new(w, h, dep),
		Material = Enum.Material.SmoothPlastic,
		Color = C_DARK,
		Reflectance = 0.02,
	})
	tw.CFrame = CFrame.new(base) * CFrame.Angles(0, -ang, 0)
	tw.Parent = staticFolder

	local strip = mkPart({
		Size = Vector3.new(0.4, h * 0.75, 0.4),
		Material = Enum.Material.Neon,
		Color = (i % 3 == 0) and C_AMBER or Color3.fromRGB(120, 200, 255),
		Transparency = 0.35,
	})
	strip.CFrame = CFrame.new(base) * CFrame.Angles(0, -ang, 0) * CFrame.new(0, 0, dep / 2 + 0.3)
	strip.Parent = staticFolder

	local bands = math.random(0, 2)
	for b = 1, bands do
		local band = mkPart({
			Size = Vector3.new(w + 0.4, 0.6, dep + 0.4),
			Material = Enum.Material.Neon,
			Color = C_AMBER,
			Transparency = 0.55,
		})
		local bandPos = SCENE_POS + Vector3.new(
			math.cos(ang) * dist,
			6 + math.random() * (h - 10),
			math.sin(ang) * dist
		)
		band.CFrame = CFrame.new(bandPos) * CFrame.Angles(0, -ang, 0)
		band.Parent = staticFolder
	end
end

-- ================== ПРОЖЕКТОРЫ (движущиеся лучи) ==================
for i = 1, 2 do
	local ang = (i == 1) and math.rad(45) or math.rad(225)
	local dist = 46
	local pos = SCENE_POS + Vector3.new(math.cos(ang) * dist, 34, math.sin(ang) * dist)

	local tower = mkPart({
		Size = Vector3.new(2, 34, 2),
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(30, 34, 40),
	})
	tower.CFrame = CFrame.new(SCENE_POS + Vector3.new(math.cos(ang) * dist, 17, math.sin(ang) * dist))
	tower.Parent = staticFolder

	local head = mkPart({
		Size = Vector3.new(2, 1.6, 2),
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(40, 46, 54),
	})
	head.CFrame = CFrame.new(pos)
	head.Parent = staticFolder

	local light = Instance.new("SpotLight")
	light.Angle = 22
	light.Range = 140
	light.Brightness = 2.5
	light.Color = C_AMBER
	light.Shadows = true
	light.Enabled = false
	light.Parent = head

	spotHeads[#spotHeads + 1] = { part = head, pos = pos, phase = i * 2.1, light = light }
end

-- ================== ПАДАЮЩИЕ УГЛИ (атмосфера) ==================
local emberPart = mkPart({
	Size = Vector3.new(150, 2, 150),
	Transparency = 1,
})
emberPart.CFrame = CFrame.new(SCENE_POS + Vector3.new(0, 48, 0))
emberPart.Parent = staticFolder

emberEmitter = Instance.new("ParticleEmitter")
emberEmitter.Texture = "rbxasset://textures/particles/fire_main.dds"
emberEmitter.Rate = 20
emberEmitter.Lifetime = NumberRange.new(5, 8)
emberEmitter.Speed = NumberRange.new(0, 0)
emberEmitter.Acceleration = Vector3.new(0, -3.5, 0)
emberEmitter.Size = NumberSequence.new(0.35)
emberEmitter.Color = ColorSequence.new(Color3.fromRGB(255, 170, 80), Color3.fromRGB(120, 90, 60))
emberEmitter.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.25),
	NumberSequenceKeypoint.new(0.8, 0.6),
	NumberSequenceKeypoint.new(1, 1),
})
emberEmitter.LightEmission = 1
emberEmitter.Enabled = false
emberEmitter.Parent = emberPart

-- ================== ЭФФЕКТЫ ОСВЕЩЕНИЯ ==================
local function getOrCreate(className, name, applyProps)
	local inst = Lighting:FindFirstChild(name)
	if not inst then
		inst = Instance.new(className)
		inst.Name = name
		applyProps(inst)
		inst.Parent = Lighting
	end
	return inst
end

local bloom = getOrCreate("BloomEffect", "MenuSceneBloom", function(b)
	b.Intensity = 0.5
	b.Size = 28
	b.Threshold = 0.95
end)

local cc = getOrCreate("ColorCorrectionEffect", "MenuSceneCC", function(c)
	c.Contrast = 0.07
	c.Saturation = -0.08
	c.TintColor = Color3.fromRGB(228, 240, 246)
end)

-- ================== ВКЛ/ВЫКЛ СЦЕНЫ ==================
local function setScene(open)
	if open then
		if camState.savedType == nil then
			camState.savedType = camera.CameraType
		end
		camera.CameraType = Enum.CameraType.Scriptable
		sceneModel.Parent = workspace
		local at = Lighting:FindFirstChild("MenuSceneAtmosphere")
		if not at then
			at = Instance.new("Atmosphere")
			at.Name = "MenuSceneAtmosphere"
			at.Density = 0.42
			at.Offset = 0.3
			at.Color = Color3.fromRGB(95, 105, 120)
			at.Decay = Color3.fromRGB(12, 14, 18)
			at.Glare = 0
			at.Haze = 2.2
			at.Parent = Lighting
		end
		bloom.Enabled = true
		cc.Enabled = true
		if emberEmitter then emberEmitter.Enabled = true end
		for _, sh in ipairs(spotHeads) do
			sh.light.Enabled = true
		end
	else
		camera.CameraType = camState.savedType or Enum.CameraType.Custom
		sceneModel.Parent = nil
		local at = Lighting:FindFirstChild("MenuSceneAtmosphere")
		if at then at:Destroy() end
		bloom.Enabled = false
		cc.Enabled = false
		if emberEmitter then emberEmitter.Enabled = false end
		for _, sh in ipairs(spotHeads) do
			sh.light.Enabled = false
		end
	end
end

-- ================== ВЗАИМОДЕЙСТВИЕ ==================
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.FilterDescendantsInstances = { interactiveFolder }

local function castToScene()
	local mp = UserInputService:GetMouseLocation()
	local ray = camera:ScreenPointToRay(mp.X, mp.Y)
	return workspace:Raycast(ray.Origin, ray.Direction * 400, rayParams)
end

local function handleClick()
	local hit = castToScene()
	if not hit then return end
	sfxSound.PlaybackSpeed = 0.85
	sfxSound.Volume = 0.4
	sfxSound:Play()
	scatterUntil = os.clock() + 2

	-- импульс по кольцам
	for _, seg in ipairs(ringOuter) do
		TweenService:Create(seg.part, TweenInfo.new(0.1), { Transparency = 0, Color = C_WHITE }):Play()
		task.delay(0.16, function()
			TweenService:Create(seg.part, TweenInfo.new(0.5), { Transparency = seg.baseTransp, Color = seg.baseColor }):Play()
		end)
	end
	for _, seg in ipairs(ringInner) do
		TweenService:Create(seg.part, TweenInfo.new(0.1), { Transparency = 0, Color = C_WHITE }):Play()
		task.delay(0.16, function()
			TweenService:Create(seg.part, TweenInfo.new(0.5), { Transparency = seg.baseTransp, Color = seg.baseColor }):Play()
		end)
	end

	-- FOV-панч
	TweenService:Create(camera, TweenInfo.new(0.08), { FieldOfView = 78 }):Play()
	task.delay(0.1, function()
		TweenService:Create(camera, TweenInfo.new(0.35, Enum.EasingStyle.Quint), { FieldOfView = 70 }):Play()
	end)
end

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe or not menuGui.Enabled then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		handleClick()
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		camState.rmbDown = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		camState.rmbDown = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not menuGui.Enabled then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		if camState.rmbDown then
			camState.yaw -= input.Delta.X * 0.004
			camState.pitch = math.clamp(camState.pitch + input.Delta.Y * 0.003, math.rad(5), math.rad(45))
			camState.lastUser = os.clock()
		end
	elseif input.UserInputType == Enum.UserInputType.MouseWheel then
		camState.radius = math.clamp(camState.radius + input.Position.Z * 3, 20, 85)
		camState.lastUser = os.clock()
	end
end)

-- ================== ГЛАВНЫЙ ЦИКЛ ==================
local hoverAcc = 0
local hovered = nil

RunService.RenderStepped:Connect(function(dt)
	if not menuGui.Enabled then return end
	local t = os.clock()

	-- клавиатура
	if UserInputService:IsKeyDown(Enum.KeyCode.Q) then
		camState.yaw -= dt * 1.2
		camState.lastUser = t
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.E) then
		camState.yaw += dt * 1.2
		camState.lastUser = t
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.Up) then
		camState.pitch = math.min(camState.pitch + dt * 0.8, math.rad(45))
		camState.lastUser = t
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.Down) then
		camState.pitch = math.max(camState.pitch - dt * 0.8, math.rad(5))
		camState.lastUser = t
	end

	-- геймпад: правый стик
	local ok, gpState = pcall(function()
		return UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1)
	end)
	if ok and gpState then
		for _, inp in ipairs(gpState) do
			if inp.KeyCode == Enum.KeyCode.Thumbstick2 and inp.Position.Magnitude > 0.15 then
				camState.yaw += inp.Position.X * dt * 2.4
				camState.pitch = math.clamp(camState.pitch + inp.Position.Y * dt * 1.6, math.rad(5), math.rad(45))
				camState.lastUser = t
			end
		end
	end

	-- авто-облёт после 4 сек простоя
	if t - camState.lastUser > 4 then
		camState.yaw += dt * 0.045
	end

	-- вращение колец
	updateRing(ringOuter, t * 0.5, 9, 11)
	updateRing(ringInner, -t * 0.75, 6, 14.5)

	-- парящие панели (смотрят на камеру)
	local camPos = camera.CFrame.Position
	for _, pd in ipairs(panels) do
		local a = t * pd.speed + pd.phase
		local pos = SCENE_POS + Vector3.new(math.cos(a) * pd.r, pd.h, math.sin(a) * pd.r)
		pd.part.CFrame = CFrame.lookAt(pos, camPos)
	end

	-- дроны (разлетаются после клика)
	local speedFactor = (t < scatterUntil) and 4 or 1
	for _, d in ipairs(drones) do
		local a = t * d.speed * speedFactor + d.phase
		local r = d.r + (speedFactor > 1 and 5 or 0)
		local pos = SCENE_POS + Vector3.new(
			math.cos(a) * r,
			d.h + math.sin(t * 2 + d.phase * 3) * 0.8,
			math.sin(a) * r
		)
		d.part.CFrame = CFrame.new(pos) * CFrame.Angles(0, -a, 0)
	end

	-- прожекторы шарят по площадке
	for _, sh in ipairs(spotHeads) do
		local sweep = math.sin(t * 0.35 + sh.phase) * 70
		local target = SCENE_POS + Vector3.new(sweep, 0, math.cos(t * 0.35 + sh.phase) * 40)
		sh.part.CFrame = CFrame.lookAt(sh.pos, target)
	end

	-- камера
	local cp = math.cos(camState.pitch)
	local camTarget = LOOK_AT + Vector3.new(
		math.cos(camState.yaw) * camState.radius * cp,
		math.sin(camState.pitch) * camState.radius,
		math.sin(camState.yaw) * camState.radius * cp
	)
	camera.CFrame = CFrame.lookAt(camTarget, LOOK_AT)

	-- ховер-пинг по голограмме
	hoverAcc += dt
	if hoverAcc > 0.15 then
		hoverAcc = 0
		local hit = castToScene()
		if hit and hit.Instance ~= hovered then
			sfxSound.PlaybackSpeed = 1.7
			sfxSound.Volume = 0.12
			sfxSound:Play()
		end
		hovered = hit and hit.Instance or nil
	end
end)

-- ================== ЗАПУСК ==================
menuGui:GetPropertyChangedSignal("Enabled"):Connect(function()
	setScene(menuGui.Enabled)
end)
setScene(menuGui.Enabled)
