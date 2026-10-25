-- StarterPlayer > StarterPlayerScripts > Client > ScreenTextTest (LocalScript)
-- Тест: показывает текст на экране. Доказательство, что Ashna может
-- создавать контент прямо в игре. Удали файл, когда насмотришься. :)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "AshnaScreenText"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100
gui.Parent = playerGui

-- Большой текст по центру
local label = Instance.new("TextLabel")
label.Name = "Message"
label.AnchorPoint = Vector2.new(0.5, 0.5)
label.Position = UDim2.fromScale(0.5, 0.3)
label.Size = UDim2.fromScale(0.8, 0.15)
label.BackgroundTransparency = 1
label.Font = Enum.Font.GothamBlack
label.TextScaled = true
label.TextColor3 = Color3.fromRGB(80, 255, 120) -- неоново-зелёный, HUD-стиль
label.TextStrokeTransparency = 0.6
label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
label.Text = "ASHNA ТУТ 🎮 ЭТО ТЕКСТ НА ЭКРАНЕ ТВОЕЙ ИГРЫ"
label.Parent = gui

-- Плавное появление
label.TextTransparency = 1
TweenService:Create(label, TweenInfo.new(1.5, Enum.EasingStyle.Quad), {
	TextTransparency = 0,
}):Play()

-- Маленькая подпись
local sub = label:Clone()
sub.Name = "SubMessage"
sub.Position = UDim2.fromScale(0.5, 0.42)
sub.Size = UDim2.fromScale(0.6, 0.05)
sub.TextColor3 = Color3.fromRGB(255, 210, 80)
sub.TextStrokeTransparency = 0.3
sub.Text = "Voit, Warzone-roblox · ветка ashna/setup · Rojo синк работает"
sub.Parent = gui
sub.TextTransparency = 0

-- Убирается сама через 8 секунд
task.delay(8, function()
	local out = TweenService:Create(label, TweenInfo.new(1), { TextTransparency = 1 })
	out:Play()
	TweenService:Create(sub, TweenInfo.new(1), { TextTransparency = 1 }):Play()
	out.Completed:Wait()
	gui:Destroy()
end)
