local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local LOCAL_LINE = true

local BOX_SIZE = Vector3.new(4,6,2)
local BOX_COLOR = Color3.fromRGB(0,140,255)
local BOX_TRANSPARENCY = 0.75

local LINE_COLOR_OTHER = Color3.fromRGB(255,0,0)
local LINE_COLOR_LOCAL = Color3.fromRGB(0,255,0)
local LINE_THICKNESS = 0.15

local LINE_LENGTH = {
	[10]=71,[9]=63,[8]=57,[7]=50,[6]=42,[5]=35,[4]=28,[3]=14
}

local ESP = {}
local cachedLength
local logicAccumulator = 0

local function getFloor(char)
	if not char then return nil end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return nil end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.FilterDescendantsInstances = {char}

	local r = workspace:Raycast(
		root.Position + Vector3.new(0,-2.8,0),
		Vector3.new(0,-4,0),
		params
	)

	return r and r.Instance and r.Instance.Name or nil
end

local function removeESP(plr)
	local d = ESP[plr]
	if not d then return end
	if d.Box then d.Box:Destroy() end
	if d.Line then d.Line:Destroy() end
	ESP[plr] = nil
end

local function createESP(plr)
	if ESP[plr] then return end
	if plr == LP and not LOCAL_LINE then return end

	local char = plr.Character
	if not char then return end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	local arm = char:FindFirstChild("Right Arm")
	if not hrp or not arm then return end

	local box
	if plr ~= LP then
		box = Instance.new("BoxHandleAdornment")
		box.Name = plr.Name.."Box"
		box.Adornee = hrp
		box.Size = BOX_SIZE
		box.Color3 = BOX_COLOR
		box.Transparency = BOX_TRANSPARENCY
		box.AlwaysOnTop = true
		box.Parent = Camera
	end

	local line = Instance.new("Part")
	line.Name = plr.Name.."Line"
	line.Anchored = true
	line.CanCollide = false
	line.CanQuery = false
	line.CastShadow = false
	line.Material = Enum.Material.SmoothPlastic
	line.Color = (plr == LP) and LINE_COLOR_LOCAL or LINE_COLOR_OTHER
	line.Size = Vector3.new(LINE_THICKNESS, 10, LINE_THICKNESS)
	line.Parent = workspace

	ESP[plr] = {
		Box = box,
		Line = line,
		Arm = arm,
		IsLocal = (plr == LP)
	}
end

RunService.RenderStepped:Connect(function()
	if not cachedLength then return end

	for _,d in pairs(ESP) do
		if d.Line and d.Arm then
			local arm = d.Arm
			d.Line.CFrame =
				arm.CFrame
				* CFrame.new(0, 0, -arm.Size.Z/2)   -- palm forward
				* CFrame.new(0, -arm.Size.Y/2, 0)   -- down from hand
				* CFrame.new(0, -cachedLength/2, 0)
		end
	end
end)

RunService.Heartbeat:Connect(function(dt)
	logicAccumulator += dt
	if logicAccumulator < 0.15 then return end
	logicAccumulator = 0

	local localChar = LP.Character
	if not localChar then return end

	local localFloor = getFloor(localChar)
	if localFloor == "Baseplate" or localFloor == "SpawnLocation" then
		for p in pairs(ESP) do removeESP(p) end
		cachedLength = nil
		return
	end

	local count = 0
	for _,p in ipairs(Players:GetPlayers()) do
		if p.Character and getFloor(p.Character) == "chao" then
			count += 1
		end
	end

	if count <= 1 then
		for p in pairs(ESP) do removeESP(p) end
		cachedLength = nil
		return
	end

	for _,p in ipairs(Players:GetPlayers()) do
		if p.Character and getFloor(p.Character) == "chao" then
			if p ~= LP or LOCAL_LINE then
				createESP(p)
			end
		else
			removeESP(p)
		end
	end

	if count == 2 then
		for _,d in pairs(ESP) do
			if d.Line then
				d.Line:Destroy()
				d.Line = nil
			end
		end
		cachedLength = nil
		return
	end

	local len = LINE_LENGTH[count]
	if not len then return end
	cachedLength = len

	for _,d in pairs(ESP) do
		if d.Line then
			d.Line.Size = Vector3.new(LINE_THICKNESS, len, LINE_THICKNESS)
		end
	end
end)