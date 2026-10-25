-- StarterPlayer > StarterPlayerScripts > Client > AnimationController (LocalScript)
-- Читает атрибут Stance с HumanoidRootPart (ставит MovementController)
-- и проигрывает соответствующие клипы из AnimationsData.
-- Приоритет Action — перекрывает стандартный Animate-скрипт Roblox.
--
-- ВАЖНО: скрипт лежит в StarterPlayerScripts, поэтому персонажа берём
-- через LocalPlayer.Character (script.Parent здесь = PlayerScripts).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local AnimationsData = require(ReplicatedStorage.Shared:WaitForChild("AnimationsData"))

local player = Players.LocalPlayer

local character, humanoid, rootPart, animator

-- Кэш треков
local tracks = {}
local function getTrack(name)
	if tracks[name] then return tracks[name] end
	local data = AnimationsData[name]
	if not data or not data.id or data.id == 0 then return nil end -- ID ещё не вставлен
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://" .. data.id
	local track = animator:LoadAnimation(anim)
	track.Priority = data.priority
	track.Looped = data.loop
	tracks[name] = track
	return track
end

local current = nil
local oneShotPlaying = {}
local diedConn = nil

-- Стойка -> клипы
local stanceClips = {
	Stand    = { idle = nil, walk = nil },           -- стандартный Animate работает
	Crouch   = { idle = "CrouchIdle", walk = "CrouchWalk" },
	Prone    = { idle = "ProneIdle",  walk = "ProneCrawl" },
	TacticalSprint = { idle = "TacticalSprint", walk = "TacticalSprint" },
	Swim     = { idle = "Swim", walk = "Swim" },
}

local function stopCurrent()
	if current then
		current:Stop(0.1)
		current = nil
	end
end

local function play(track)
	if track == current then return end
	stopCurrent()
	if track then
		track:Play(0.1)
		current = track
	end
end

-- Привязка персонажа (работает и на респауне)
local function bind(char)
	character = char
	humanoid = char:WaitForChild("Humanoid")
	rootPart = char:WaitForChild("HumanoidRootPart")
	animator = humanoid:WaitForChild("Animator")
	-- Новый персонаж = новый Animator: кэш треков и состояние сбрасываем
	table.clear(tracks)
	stopCurrent()
	table.clear(oneShotPlaying)
	if diedConn then diedConn:Disconnect() end
	diedConn = humanoid.Died:Connect(stopCurrent)
end

if player.Character then bind(player.Character) end
player.CharacterAdded:Connect(bind)

RunService.Heartbeat:Connect(function()
	if not (rootPart and rootPart.Parent) then return end

	local stance = rootPart:GetAttribute("Stance")
	if not stance then return end

	-- One-shot поверх всего (Slide, Mantle)
	if stance == "Slide" or stance == "Mantle" then
		local shot = getTrack(stance)
		if shot and not oneShotPlaying[stance] then
			oneShotPlaying[stance] = true
			shot:Play(0.05)
			shot.Stopped:Once(function()
				oneShotPlaying[stance] = nil
			end)
		end
		return
	end

	local clips = stanceClips[stance]
	if not clips then
		stopCurrent() -- Stand/Sprint: стандартный Animate
		return
	end

	local moving = rootPart.AssemblyLinearVelocity.Magnitude > 1
	local clipName = moving and clips.walk or clips.idle
	-- Фолбэк: если walk-клипа нет, играем idle
	local track = getTrack(clipName) or getTrack(clips.idle)
	play(track)
end)
