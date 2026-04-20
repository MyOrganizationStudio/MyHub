local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local character
local humanoid

local speedEnabled = false

local function bindCharacter(char)
    character = char
    humanoid = char:WaitForChild("Humanoid", 5)

    if humanoid then
        humanoid.WalkSpeed = speedEnabled and 100 or 24
    end
end

if player.Character then
    bindCharacter(player.Character)
end
player.CharacterAdded:Connect(bindCharacter)

RunService.RenderStepped:Connect(function()
    if not humanoid or not humanoid.Parent then return end

    if speedEnabled then
        if humanoid.WalkSpeed ~= 100 then
            humanoid.WalkSpeed = 100
        end
    else
        if humanoid.WalkSpeed < 24 then
            humanoid.WalkSpeed = 24
        end
    end
end)
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.X then
        speedEnabled = not speedEnabled
    end
end)

local gui = Instance.new("ScreenGui")
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function makeDraggable(btn)
    local dragging, startPos, startInput
    btn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            startInput = i.Position
            startPos = btn.Position
        end
    end)
    btn.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = i.Position - startInput
            btn.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

local speedBtn = Instance.new("TextButton")
speedBtn.Size = UDim2.fromOffset(180, 45)
speedBtn.Position = UDim2.new(0, 20, 0.45, 0)
speedBtn.Text = "Toggle SUPERSPEED [X]"
speedBtn.Parent = gui
makeDraggable(speedBtn)

speedBtn.MouseButton1Click:Connect(function()
    speedEnabled = not speedEnabled
end)

local infJumpDebounce = false
UserInputService.JumpRequest:Connect(function()
    if humanoid and humanoid.Parent and not infJumpDebounce then
        infJumpDebounce = true
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        task.wait()
        infJumpDebounce = false
    end
end)

pcall(function()
    local CircleAction = require(ReplicatedStorage.Module.UI).CircleAction
    for _, spec in pairs(CircleAction.Specs) do
        if spec.Timed ~= nil then
            spec.Timed = false
        end
    end
end)

for _, v in next, getgc(true) do
    if type(v) == "table" then
        if rawget(v, "useEvery") then v.useEvery = 0 end
        if rawget(v, "_budgetPerWindow") then
            v._budgetPerWindow = math.huge
            v._budgetWindowDuration = math.huge
        end
    end
end

for _, v in next, getgc(true) do
    if typeof(v) == "function" then
        local env = getfenv(v)
        if env and tostring(env.script):lower():find("barbedwire") then
            pcall(hookfunction, v, function() return end)
        end
    end
end

for _, v in next, getgc(true) do
    if type(v) == "table" and rawget(v, "Name") and v.Name == "Explosion" then
        v.Name = "DisabledExplosion"
    end
end

require(ReplicatedStorage.Game.Paraglide).IsFlying = function()
    return tostring(getfenv(2).script) == "Falling"
end