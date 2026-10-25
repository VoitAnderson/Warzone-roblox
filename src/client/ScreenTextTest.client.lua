-- StarterPlayer > StarterPlayerScripts > Client > ScreenTextTest (LocalScript)
-- Тест: постоянный текст на экране. НЕ исчезает. Удали файл, когда насмотришься. :)

local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "AshnaScreenText"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100
gui.Parent = playerGui

local label = Instance.new("TextLabel")
label.Name = "Message"
label.AnchorPoint = Vector2.new(0.5, 0.5)
label.Position = UDim2.fromScale(0.5, 0.15)
label.Size = UDim2.fromScale(0.8, 0.1)
label.BackgroundTransparency = 1
label.Font = Enum.Font.GothamBlack
label.TextScaled = true
label.TextColor3 = Color3.fromRGB(80, 255, 120)
label.TextStrokeTransparency = 0.6
label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
label.Text = "ASHNA ТУТ — ЭТО ТЕКСТ НА ЭКРАНЕ ТВОЕЙ ИГРЫ"
label.Parent = gui

local sub = label:Clone()
sub.Name = "SubMessage"
sub.Position = UDim2.fromScale(0.5, 0.24)
sub.Size = UDim2.fromScale(0.6, 0.04)
sub.TextColor3 = Color3.fromRGB(255, 210, 80)
sub.Text = "Постоянный текст · Voit x Ashna · Warzone-roblox"
sub.Parent = gui
