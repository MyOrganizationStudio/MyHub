if getgenv().haxloaded then
    return
end

getgenv().haxloaded = true
local function processPart(obj)
    if obj:IsA("BasePart") then
        obj.Transparency = 0.75
        obj.CanCollide = false
    end
end
local function recursiveProcess(obj)
    processPart(obj)
    for _, child in ipairs(obj:GetChildren()) do
        recursiveProcess(child)
    end
end
for _, v in pairs(workspace.Prison_OuterWall.prison_wall:GetChildren()) do
    recursiveProcess(v)
end
for _, v in pairs(workspace.Prison_guardtower:GetChildren()) do
    recursiveProcess(v)
end
for _, v in pairs(workspace.Prison_Fences:GetChildren()) do
    if v.Name == "fence" then
        recursiveProcess(v)
        local dmg = v:FindFirstChild("damagePart")
        if dmg then
            local ti = dmg:FindFirstChild("TouchInterest")
            if ti then
                ti:Destroy()
            end
        end
    end
end
local doors = workspace:FindFirstChild("Doors")
if doors then
    doors:Destroy()
end
task.spawn(function()
    while task.wait() do
        if game.Players.LocalPlayer and game.Players.LocalPlayer.Character then
            local hum = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = 25
                game.Players.LocalPlayer:SetAttribute("BackpackEnabled", true)
                hum.JumpHeight = 5.5
            end
            if game.Players.LocalPlayer.Character:FindFirstChild("AntiJump") then
                game.Players.LocalPlayer.Character.AntiJump:Destroy()
            end
        end
    end
end)
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TELEPORT_COOLDOWN = 1.6
local lastTeleport = 0

local function CanTeleport()
    local now = tick()
    local delta = now - lastTeleport
    if delta < TELEPORT_COOLDOWN then
        local remaining = TELEPORT_COOLDOWN - delta
        game.StarterGui:SetCore("SendNotification", {
            Title = "TP Cooldown",
            Text = "Wait " .. string.format("%.1f", remaining) .. "s before teleporting again"
        })
        return false
    end
    lastTeleport = now
    return true
end
local ScreenGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local Scrolling = Instance.new("ScrollingFrame")
local UIStroke = Instance.new("UIStroke")
local UICorner = Instance.new("UICorner")
local UIListLayout = Instance.new("UIListLayout")
local Title = Instance.new("TextLabel")
local Buttons = {
	{ name="CrimBaseTP", text="TP to Crim Base" },
	{ name="PrisonTP", text="TP to Prison" },
    { name ="GuardRoomTP", text="TP in Guard Room"},
	{ name="GunsMod", text="Mod All Guns" },
    { name = "GetMP5", text="Get MP5"},
    { name = "GetRemington", text="Get Remington 870"},
    { name = "GetAK", text = "Get AK-47"}
}
ScreenGui.Parent = game:WaitForChild("CoreGui")
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Frame.Parent = ScreenGui
Frame.BackgroundTransparency = 0.25
Frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
Frame.Position = UDim2.new(0.35, 0, 0.25, 0)
Frame.Size = UDim2.new(0, 300, 0, 260)
UIStroke.Parent = Frame
UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke.Thickness = 2
UIStroke.Color = Color3.fromRGB(255,80,80)
UICorner.Parent = Frame
Title.Parent = Frame
Title.Size = UDim2.new(1, 0, 0, 50)
Title.BackgroundTransparency = 1
Title.Text = "ULTRA HAX"
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 24
Title.TextColor3 = Color3.fromRGB(255,80,80)
Scrolling.Parent = Frame
Scrolling.Position = UDim2.new(0, 0, 0, 50)
Scrolling.Size = UDim2.new(1, 0, 1, -50)
Scrolling.BackgroundTransparency = 1
Scrolling.CanvasSize = UDim2.new(0, 0, 0, 0)
Scrolling.ScrollBarThickness = 4
Scrolling.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scrolling.ScrollingDirection = Enum.ScrollingDirection.Y
UIListLayout.Parent = Scrolling
UIListLayout.Padding = UDim.new(0, 10)
UIListLayout.FillDirection = Enum.FillDirection.Vertical
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
for _, info in ipairs(Buttons) do
	local btn = Instance.new("TextButton")
	btn.Name = info.name
	btn.Parent = Scrolling
	btn.Size = UDim2.new(0.85, 0, 0, 40)
	btn.BackgroundTransparency = 0.6
	btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	btn.Text = info.text
	btn.Font = Enum.Font.GothamBold
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextScaled = true
	Instance.new("UICorner", btn)
	btn.MouseEnter:Connect(function()
		btn.BackgroundTransparency = 0.3
	end)
	btn.MouseLeave:Connect(function()
		btn.BackgroundTransparency = 0.6
	end)
	btn.MouseButton1Click:Connect(function()
		if info.name == "GunsMod" then
            game.StarterGui:SetCore("SendNotification", {Text="Make sure you are not holding any guns!", Title="Guns Mod"})
            wait(5)
			for i, v in pairs(LocalPlayer.Backpack:GetChildren()) do
				if v:GetAttribute("FireRate") ~= nil then
					v:SetAttribute("FireRate", 0.02)
					v:SetAttribute("AutoFire", true)
					v:SetAttribute("SpreadRadius", 0)
                    game.StarterGui:SetCore("SendNotification", {Text="Modded " .. v.Name .. " successfully!", Title="Guns Mod"})
				end
			end
		elseif info.name == "CrimBaseTP" then
            if CanTeleport() then
			    LocalPlayer.Character.HumanoidRootPart.CFrame = workspace["Criminals Spawn"].SpawnLocation.CFrame
            end
		elseif info.name == "PrisonTP" then
            if CanTeleport() then
			    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(916, 100, 2369)
            end
        elseif info.name == "GuardRoomTP" then
            if CanTeleport() then
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(828, 100, 2303)
            end
         elseif info.name == "GetMP5" then
            if CanTeleport() then
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(814, 98, 2229.4)
            end
        elseif info.name == "GetRemington" then
            if CanTeleport() then
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(820, 98, 2229.4)
            end
        elseif info.name == "GetAK" then
            if CanTeleport() then
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-931, 94, 2039)
            end
		end
	end)
end

local UIS = game:GetService("UserInputService")
local dragging = false
local dragStart, startPos

Frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Frame.Position
    end
end)

Frame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)