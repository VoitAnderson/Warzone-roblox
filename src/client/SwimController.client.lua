-- StarterPlayer > StarterPlayerScripts > Client > SwimController (LocalScript)
-- Дыхание и утопление. Вода — через рейкаст (GetMaterialAtPosition не существует).

local RunService = game:GetService("RunService")

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

local BREATH_MAX = 15
local DROWN_DAMAGE = 5
local breath = BREATH_MAX

local waterParams = RaycastParams.new()
waterParams.IgnoreWater = false -- рейкаст теперь попадает в поверхность воды

-- Голова под водой? Рейкаст сверху вниз: если поверхность воды
-- оказалась ВЫШЕ головы — голова погружена.
local function isHeadUnderwater()
	local head = rootPart.Position + Vector3.new(0, 1.5, 0)
	local result = workspace:Raycast(head + Vector3.new(0, 3, 0), Vector3.new(0, -8, 0), waterParams)
	return result ~= nil
		and result.Material == Enum.Material.Water
		and result.Position.Y > head.Y
end

RunService.Heartbeat:Connect(function(dt)
	local swimming = humanoid:GetState() == Enum.HumanoidStateType.Swimming
	rootPart:SetAttribute("Swimming", swimming)

	if swimming and isHeadUnderwater() then
		breath = math.max(0, breath - dt)
		if breath <= 0 then
			humanoid:TakeDamage(DROWN_DAMAGE * dt)
		end
	else
		breath = math.min(BREATH_MAX, breath + dt * 2)
	end
end)
