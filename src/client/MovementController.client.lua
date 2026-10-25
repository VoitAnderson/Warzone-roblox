-- StarterPlayer > StarterPlayerScripts > Client > MovementController (LocalScript)
-- Финальный контроллер движения: стойки, спринт, слайд, mantle, плавание, стамина.
-- PC + геймпад. Экспортирует атрибут Stance для AnimationController.
--
-- Управление:
--   WASD / левый стик — движение; мышь / правый стик — камера
--   Space / A — прыжок, у стены — mantle
--   C / B (тап) — присед, hold — лёжа, во время бега — слайд
--   Shift / L3 — спринт, двойное нажатие — тактический спринт
--   Ctrl / B во время бега — слайд
--
-- ВАЖНО: скрипт лежит в StarterPlayerScripts, поэтому персонажа берём
-- через LocalPlayer.Character, а НЕ через script.Parent.

local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- ================== ТЮНИНГ ==================
local WALK_SPEED = 16
local SPRINT_SPEED = 24
local TACTICAL_SPEED = 30
local CROUCH_SPEED = 8
local PRONE_SPEED = 4
local SWIM_SPEED = 14
local SLIDE_SPEED = 40
local SLIDE_TIME = 0.8
local SLIDE_COOLDOWN = 1.5
local STAMINA_MAX = 100
local STAMINA_DRAIN = 20      -- в сек
local STAMINA_REGEN = 10      -- в сек
local SPRINT_DOUBLE_TAP = 0.3 -- окно двойного нажатия
local STANCE_HOLD_TIME = 0.35 -- тап = присед, hold = лёжа
local MANTLE_MIN_HEIGHT = 2
local MANTLE_MAX_HEIGHT = 8
local MANTLE_REACH = 4
local MANTLE_DURATION = 0.35
local HIP = { STAND = 0, CROUCH = -1.2, PRONE = -2.2 }
local ADS_SPEED_MULT = 0.55   -- замедление при прицеливании
-- ============================================

local state = {
	crouching = false,
	prone = false,
	sprinting = false,
	tactical = false,
	sliding = false,
	mantling = false,
	stamina = STAMINA_MAX,
	lastShiftTap = 0,
	stanceTapTime = 0,
	lastSlideTime = 0,
	currentSpeed = WALK_SPEED,
}

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.FilterDescendantsInstances = { character }

local function setStanceAttribute(name)
	rootPart:SetAttribute("Stance", name)
end

local function setSpeed(speed)
	state.currentSpeed = speed
	humanoid.WalkSpeed = speed
end

local function isSwimming()
	return humanoid:GetState() == Enum.HumanoidStateType.Swimming
end

local function updateStance()
	if isSwimming() then
		setSpeed(SWIM_SPEED)
		setStanceAttribute("Swim")
	elseif state.mantling then
		setStanceAttribute("Mantle")
	elseif state.sliding then
		setStanceAttribute("Slide")
	elseif state.prone then
		setSpeed(PRONE_SPEED)
		setStanceAttribute("Prone")
		humanoid.HipHeight = HIP.PRONE
	elseif state.crouching then
		setSpeed(CROUCH_SPEED)
		setStanceAttribute("Crouch")
		humanoid.HipHeight = HIP.CROUCH
	elseif state.tactical then
		setSpeed(TACTICAL_SPEED)
		setStanceAttribute("TacticalSprint")
		humanoid.HipHeight = HIP.STAND
	elseif state.sprinting then
		setSpeed(SPRINT_SPEED)
		setStanceAttribute("Sprint")
		humanoid.HipHeight = HIP.STAND
	else
		setSpeed(WALK_SPEED)
		setStanceAttribute("Stand")
		humanoid.HipHeight = HIP.STAND
	end
end

-- ================== ПРИСЕД / ЛЁЖА ==================
local function setCrouch(on)
	state.crouching = on
	if on then
		state.prone = false
		state.sprinting = false
		state.tactical = false
	end
	updateStance()
end

local function setProne(on)
	state.prone = on
	if on then
		state.crouching = false
		state.sprinting = false
		state.tactical = false
	end
	updateStance()
end

-- Тап/hold: тап — присед, hold — лёжа. Во время бега — слайд.
local function onStanceInput(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		if state.sprinting or state.tactical then
			-- Слайд во время бега
			if tick() - state.lastSlideTime < SLIDE_COOLDOWN then return Enum.ContextActionResult.Sink end
			state.lastSlideTime = tick()
			state.sliding = true
			setSpeed(SLIDE_SPEED)
			setStanceAttribute("Slide")
			task.delay(SLIDE_TIME, function()
				state.sliding = false
				updateStance()
			end)
			return Enum.ContextActionResult.Sink
		end
		state.stanceTapTime = tick()
	elseif inputState == Enum.UserInputState.End then
		local held = tick() - state.stanceTapTime
		if state.prone then
			-- из лёжа: тап — присед, hold — встать
			if held < STANCE_HOLD_TIME then setCrouch(true) else setProne(false) end
		elseif state.crouching then
			if held < STANCE_HOLD_TIME then setCrouch(false) else setProne(true) end
		else
			if held < STANCE_HOLD_TIME then setCrouch(true) else setProne(true) end
		end
	end
	return Enum.ContextActionResult.Pass
end

-- ================== СПРИНТ ==================
local function onSprintInput(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		local now = tick()
		if now - state.lastShiftTap < SPRINT_DOUBLE_TAP then
			state.tactical = true -- двойное нажатие — тактический спринт
			state.lastShiftTap = 0
		else
			state.sprinting = true
			state.lastShiftTap = now
		end
		updateStance()
	elseif inputState == Enum.UserInputState.End then
		state.sprinting = false
		state.tactical = false
		updateStance()
	end
	return Enum.ContextActionResult.Pass
end

-- ================== MANTLE ==================
local function tryMantle()
	if state.mantling then return true end
	if humanoid:GetState() == Enum.HumanoidStateType.Freefall then return false end

	local origin = rootPart.Position
	local forward = rootPart.CFrame.LookVector

	-- 1) Стена впереди?
	local wallHit = workspace:Raycast(origin, forward * MANTLE_REACH, rayParams)
	if not wallHit then return false end

	-- 2) Свободно ли сверху?
	local topOrigin = origin + Vector3.new(0, MANTLE_MAX_HEIGHT, 0)
	local clearCheck = workspace:Raycast(topOrigin, forward * MANTLE_REACH, rayParams)
	if clearCheck then return false end

	-- 3) Верх уступа
	local downOrigin = topOrigin + forward * MANTLE_REACH
	local ledgeHit = workspace:Raycast(downOrigin, Vector3.new(0, -MANTLE_MAX_HEIGHT * 2, 0), rayParams)
	if not ledgeHit then return false end

	local ledgeY = ledgeHit.Position.Y
	local height = ledgeY - origin.Y
	if height < MANTLE_MIN_HEIGHT or height > MANTLE_MAX_HEIGHT then return false end

	-- Плавный подъём
	state.mantling = true
	setStanceAttribute("Mantle")
	local target = CFrame.new(ledgeHit.Position + Vector3.new(0, humanoid.HipHeight + 2.5, 0))
	local tween = TweenService:Create(rootPart, TweenInfo.new(MANTLE_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CFrame = target,
	})
	tween:Play()
	tween.Completed:Wait()
	state.mantling = false
	updateStance()
	return true
end

-- ================== ПРЫЖОК ==================
-- Полный контроль: сами триггерим прыжок (Pass ненадёжен).
local function onJumpInput(_, inputState)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Sink
	end

	if isSwimming() then
		return Enum.ContextActionResult.Sink
	end

	if state.mantling or state.sliding then
		return Enum.ContextActionResult.Sink
	end

	-- Из лёжа Space = встать (без прыжка)
	if state.prone then
		setProne(false)
		return Enum.ContextActionResult.Sink
	end

	-- Из приседа Space = встать + прыжок
	if state.crouching then
		setCrouch(false)
	end

	-- Пытаемся mantle; если не вышло — обычный прыжок
	local mantled = tryMantle()
	if not mantled then
		humanoid.Jump = true
	end
	return Enum.ContextActionResult.Sink
end

-- ================== БИНДЫ ==================
ContextActionService:BindAction("WarzoneStance", onStanceInput, false,
	Enum.KeyCode.C, Enum.KeyCode.LeftControl, Enum.KeyCode.ButtonB)
ContextActionService:BindAction("WarzoneSprint", onSprintInput, false,
	Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3)
ContextActionService:BindAction("WarzoneJump", onJumpInput, false,
	Enum.KeyCode.Space, Enum.KeyCode.ButtonA)

-- Страховка: если прыжок был кем-то отключён — включаем
humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
humanoid.UseJumpPower = true
humanoid.JumpPower = 50

-- ================== СТАМИНА / ТИК ==================
RunService.Heartbeat:Connect(function(dt)
	-- Стамина: тактический спринт жрёт, спринт нет (как в Warzone)
	if state.tactical and rootPart.AssemblyLinearVelocity.Magnitude > 2 then
		state.stamina = math.max(0, state.stamina - STAMINA_DRAIN * dt)
		if state.stamina <= 0 then
			state.tactical = false
			updateStance()
		end
	else
		state.stamina = math.min(STAMINA_MAX, state.stamina + STAMINA_REGEN * dt)
	end

	rootPart:SetAttribute("Stamina", state.stamina)

	-- ADS: замедление при прицеливании (атрибут ставит WeaponClient)
	if rootPart:GetAttribute("ADS") and not state.mantling and not state.sliding then
		humanoid.WalkSpeed = state.currentSpeed * ADS_SPEED_MULT
	end

	-- Слайд прерывается, если скорость упала
	if state.sliding and rootPart.AssemblyLinearVelocity.Magnitude < 10 then
		state.sliding = false
		updateStance()
	end
end)

updateStance()
