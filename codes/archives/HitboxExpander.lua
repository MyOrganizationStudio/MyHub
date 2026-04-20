local Configuration = {
	HitboxSize = 10,
	HitChance = 100,
	HitboxTransparency = 0.75,
	TeamCheck = true,
	WallCheck = true
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local BotEnabled = true

if _G.BotConnections then
	for _, connection in pairs(_G.BotConnections) do
		pcall(function() connection:Disconnect() end)
	end
end
_G.BotConnections = {}

_G.HitboxSize = Vector3.new(Configuration.HitboxSize, Configuration.HitboxSize, Configuration.HitboxSize)
_G.HitboxTransparency = Configuration.HitboxTransparency
_G.HitboxMaterial = Enum.Material.Plastic

local function isTeammate(player)
	if not Configuration.TeamCheck then return false end
	return player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team
end

local function isAlive(player)
	return player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0
end

local function isVisible(targetChar)
	if not Configuration.WallCheck then return true end
	if not LocalPlayer.Character then return false end

	local myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")

	if not myRoot or not targetRoot then return false end

	local origin = myRoot.Position
	local direction = targetRoot.Position - origin
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, targetChar}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local result = Workspace:Raycast(origin, direction, raycastParams)
	return result == nil
end

local function resetHitbox(player)
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local rootPart = player.Character.HumanoidRootPart
		if rootPart.Size.X > 3 or rootPart.Transparency ~= 1 then
			rootPart.Size = Vector3.new(2, 2, 1)
			rootPart.Transparency = 1
			rootPart.CanCollide = true
			rootPart.Material = Enum.Material.Plastic
			rootPart.Color = Color3.new(0.64, 0.635, 0.647)

			local glow = rootPart:FindFirstChild("GlowEffect")
			if glow then glow:Destroy() end
		end
	end
end

local function updateHitboxes()
	local currentSize = _G.HitboxSize

	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local rootPart = player.Character.HumanoidRootPart

			if isAlive(player) and not isTeammate(player) then
				rootPart.Size = currentSize
				rootPart.Transparency = Configuration.HitboxTransparency
				rootPart.Material = _G.HitboxMaterial
				rootPart.CanCollide = false
				rootPart.Color = Color3.fromRGB(0, 255, 0)

				local glow = rootPart:FindFirstChild("GlowEffect")
				if not glow then
					glow = Instance.new("SelectionBox", rootPart)
					glow.Name = "GlowEffect"
					glow.Adornee = rootPart
					glow.LineThickness = 0.05
					glow.Transparency = 1
					glow.Color3 = Color3.fromRGB(255, 0, 0)
				end
			else
				resetHitbox(player)
			end
		end
	end
end

local function makeUnstoppable()
	local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
	if humanoid then
		humanoid.PlatformStand = false
		humanoid.Sit = false
		local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if rootPart then
			rootPart.Anchored = false
		end
	end
end

local function onRenderStep()
	if BotEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
		makeUnstoppable()
	end
end

table.insert(_G.BotConnections, RunService.Stepped:Connect(updateHitboxes))
table.insert(_G.BotConnections, RunService.RenderStepped:Connect(onRenderStep))

pcall(function()
	if not ReplicatedStorage:FindFirstChild("DamageEvent") then
		local damageEvent = Instance.new("BindableEvent")
		damageEvent.Name = "DamageEvent"
		damageEvent.Parent = ReplicatedStorage

		local function onDamageEvent(player, character)
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid:TakeDamage(10)
			end
		end
		damageEvent.Event:Connect(onDamageEvent)
	end
end)