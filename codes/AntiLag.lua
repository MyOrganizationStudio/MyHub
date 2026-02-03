if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local PhysicsService = game:GetService("PhysicsService")

pcall(function()
	settings().Rendering.QualityLevel = 3
	settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04
end)

local function applyLighting()
	Lighting.LightingStyle = Enum.LightingStyle.Soft
	Lighting.Technology = Enum.Technology.Compatibility
	Lighting.GlobalShadows = false
	Lighting.FogEnd = 9e9
	Lighting.FogStart = 9e9
end

applyLighting()

Lighting:GetPropertyChangedSignal("Technology"):Connect(applyLighting)
Lighting:GetPropertyChangedSignal("LightingStyle"):Connect(applyLighting)
Lighting:GetPropertyChangedSignal("GlobalShadows"):Connect(applyLighting)

for _, v in ipairs(Lighting:GetDescendants()) do
	if v:IsA("PostEffect") then
		v:Destroy()
	end
end

for _, v in ipairs(Lighting:GetChildren()) do
	if v:IsA("Sky") or v:IsA("Atmosphere") or v:IsA("Clouds") then
		v:Destroy()
	end
end

Lighting.ChildAdded:Connect(function(obj)
	if obj:IsA("PostEffect") or obj:IsA("Sky") or obj:IsA("Atmosphere") or obj:IsA("Clouds") then
		obj:Destroy()
	end
end)

local Terrain = Workspace:FindFirstChildWhichIsA("Terrain")
if Terrain then
	Terrain.WaterWaveSize = 0
	Terrain.WaterWaveSpeed = 0
	Terrain.WaterReflectance = 0
	Terrain.WaterTransparency = 0
end

pcall(function()
	PhysicsService:RegisterCollisionGroup("LowCost")
end)

local function batchProcess(objects, batchSize, processFn)
	for i = 1, #objects, batchSize do
		for j = i, math.min(i + batchSize - 1, #objects) do
			processFn(objects[j])
		end
		task.wait()
	end
end

task.spawn(function()
	local descendants = Workspace:GetDescendants()
	batchProcess(descendants, 100, function(v)
		if v:IsA("BasePart") then
			v.CastShadow = false
			v.Material = Enum.Material.Plastic
			v.Reflectance = 0
			
			if v.Anchored then
				pcall(function()
					v.CollisionGroup = "LowCost"
				end)
			end
		end
	end)
end)

local function throttleEffect(obj)
	if obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
		obj.Lifetime = NumberRange.new(0)
	elseif obj:IsA("Beam") then
		obj.Enabled = false
	elseif obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
		obj.Enabled = false
	end
end

for _, v in ipairs(Workspace:GetDescendants()) do
	throttleEffect(v)
end

local function stripAvatarTextures(char)
	for _, v in ipairs(char:GetDescendants()) do
		if v:IsA("Decal") or v:IsA("Texture") then
			v.Transparency = 1
		end
	end
	
	char.DescendantAdded:Connect(function(obj)
		if obj:IsA("Decal") or obj:IsA("Texture") then
			obj.Transparency = 1
		end
	end)
end

local function disableDynamicHead(char)
	local head = char:FindFirstChild("Head")
	if head then
		local faceControls = head:FindFirstChildOfClass("FaceControls")
		if faceControls then
			faceControls:Destroy()
		end
	end
	
	char.DescendantAdded:Connect(function(obj)
		if obj:IsA("FaceControls") then
			obj:Destroy()
		end
	end)
end

local function hookCharacter(char)
	stripAvatarTextures(char)
	disableDynamicHead(char)
	
	for _, v in ipairs(char:GetDescendants()) do
		throttleEffect(v)
	end
	
	char.DescendantAdded:Connect(function(obj)
		throttleEffect(obj)
	end)
end

for _, plr in ipairs(Players:GetPlayers()) do
	if plr.Character then
		hookCharacter(plr.Character)
	end
	plr.CharacterAdded:Connect(hookCharacter)
end

Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(hookCharacter)
end)

local Camera = Workspace.CurrentCamera
local LOD_DISTANCE = 150

local function setupLOD(part)
	if not (part:IsA("MeshPart") or part:IsA("UnionOperation")) then return end
	
	local originalTransparency = part.Transparency
	
	task.spawn(function()
		while part.Parent do
			local dist = (Camera.CFrame.Position - part.Position).Magnitude
			part.Transparency = dist > LOD_DISTANCE and 1 or originalTransparency
			task.wait(0.5)
		end
	end)
end

for _, v in ipairs(Workspace:GetDescendants()) do
	if v:IsA("MeshPart") or v:IsA("UnionOperation") then
		setupLOD(v)
	end
end

Workspace.DescendantAdded:Connect(function(obj)
	task.spawn(function()
		if obj:IsA("BasePart") then
			obj.CastShadow = false
			obj.Material = Enum.Material.Plastic
			obj.Reflectance = 0
			
			if obj.Anchored then
				pcall(function()
					obj.CollisionGroup = "LowCost"
				end)
			end
			
			if obj:IsA("MeshPart") or obj:IsA("UnionOperation") then
				setupLOD(obj)
			end
		elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Fire") 
			or obj:IsA("Smoke") or obj:IsA("Sparkles") or obj:IsA("Beam") then
			throttleEffect(obj)
		end
	end)
end)

task.spawn(function()
	while task.wait(60) do
		gcinfo()
	end
end)