-- StarterPlayer > StarterPlayerScripts > Client > KnockedController (LocalScript)
-- Поведение в нокдауне: ползком, без стрельбы, без ADS, без прыжка.

local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local bound = false

local function block()
	return Enum.ContextActionResult.Sink
end

RunService.Heartbeat:Connect(function()
	local char = player.Character
	local rp = char and char:FindFirstChild("HumanoidRootPart")
	local h = char and char:FindFirstChildOfClass("Humanoid")
	if not (rp and h) then return end

	if rp:GetAttribute("Knocked") then
		h.WalkSpeed = 6
		h.JumpPower = 0
		if not bound then
			bound = true
			ContextActionService:BindActionAtPriority("KnockedBlock", block, false,
				Enum.ContextActionPriority.High.Value,
				Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2,
				Enum.KeyCode.ButtonR2, Enum.KeyCode.ButtonL2,
				Enum.KeyCode.R, Enum.KeyCode.ButtonX,
				Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3,
				Enum.KeyCode.C, Enum.KeyCode.ButtonB,
				Enum.KeyCode.Four, Enum.KeyCode.ButtonDUp)
		end
	elseif bound then
		bound = false
		ContextActionService:UnbindAction("KnockedBlock")
		h.JumpPower = 50
	end
end)
