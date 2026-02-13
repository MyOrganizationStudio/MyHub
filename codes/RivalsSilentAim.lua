local rng = Random.new()
local camera = workspace.CurrentCamera 
local players = game:GetService("Players") 
local utility = require(replicatedStorage.Modules.Utility)
local replicatedStorage = game:GetService("ReplicatedStorage")

local silentAimEnabled = true
local FOV = 25
local showFOV = true
local headshotChance = 25
local predictionAmount = 0 -- how far ahead to predict movement (in seconds)

local fovCircle
if showFOV then
	fovCircle = Drawing.new("Circle")
	fovCircle.Visible = true
	fovCircle.Radius = FOV
	fovCircle.Color = Color3.fromRGB(255, 0, 0)
	fovCircle.Thickness = 2
	fovCircle.Filled = false
	fovCircle.Transparency = 1
	game:GetService("RunService").RenderStepped:Connect(function()
		fovCircle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
	end)
end

local function rollHeadshotChance()
	return rng:NextNumber(0, 100) <= headshotChance
end

local function getPlayers()
	local entities = {}
	for _, child in ipairs(workspace:GetChildren()) do
		if child:FindFirstChildOfClass("Humanoid") then
			table.insert(entities, child)
		elseif child.Name == "HurtEffect" then
			for _, hurtPlayer in ipairs(child:GetChildren()) do
				if hurtPlayer.ClassName ~= "Highlight" then
					table.insert(entities, hurtPlayer)
				end
			end
		end
	end
	return entities 
end 

local function getPredictedHeadPosition(player)
	local head = player:FindFirstChild("Head")
	local humanoidRootPart = player:FindFirstChild("HumanoidRootPart")
	if not head or not humanoidRootPart then
		return head and head.Position or nil
	end
	local velocity = humanoidRootPart.Velocity
	local predictedPosition = head.Position + (velocity * predictionAmount)
	return predictedPosition
end

local function getBodyPosition(player)
	local part = player:FindFirstChild("UpperTorso") or player:FindFirstChild("LowerTorso") or player:FindFirstChild("Torso") or player:FindFirstChild("HumanoidRootPart")
	return part and part.Position or nil
end

local function getClosestPlayer()
	local closest, closestDistance = nil, math.huge
	local character = players.LocalPlayer.Character
	if not character then
		return
	end
	local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
	for _, player in ipairs(getPlayers()) do
		if player == character then
			continue
		end
		if not player:FindFirstChild("HumanoidRootPart") then
			continue
		end
		local headPosition = getPredictedHeadPosition(player)
		if not headPosition then
			continue
		end
		local position, onScreen = camera:WorldToViewportPoint(headPosition)
		if not onScreen then
			continue
		end
		local screenPoint = Vector2.new(position.X, position.Y)
		local distance = (center - screenPoint).Magnitude
		if distance <= FOV and distance < closestDistance then
			closest = player
			closestDistance = distance
		end
	end
	return closest 
end 

local oldRaycast = utility.Raycast 
utility.Raycast = function(...)
	local arguments = {
		...
	}
	if silentAimEnabled and # arguments > 0 and arguments[4] == 999 then
		local closest = getClosestPlayer()
		if closest then
			if rollHeadshotChance() then
				local headPos = getPredictedHeadPosition(closest)
				if headPos then
					arguments[3] = headPos
				end
			else
				local bodyPos = getBodyPosition(closest)
				if bodyPos then
					arguments[3] = bodyPos
				end
			end
		end
	end
	return oldRaycast(unpack(arguments)) 
end