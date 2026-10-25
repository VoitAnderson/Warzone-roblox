-- StarterPlayer > StarterPlayerScripts > Client > AnimationController (LocalScript)
-- Читает атрибут Stance с HumanoidRootPart (ставит MovementController)
-- и проигрывает соответствующие клипы из AnimationsData.
-- Приоритет Action — перекрывает стандартный Animate-скрипт Roblox.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AnimationsData = require(ReplicatedStorage.Shared:WaitForChild("AnimationsData"))

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")
local animator = humanoid:WaitForChild("Animator")

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

RunService.Heartbeat:Connect(function()
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

humanoid.Died:Connect(function()
	stopCurrent()
end)
