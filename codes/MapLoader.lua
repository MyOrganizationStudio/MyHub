local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local CURRENT_PHASE = 0
local TOTAL_PHASES = 4

local FAST_WAIT = 0.08
local SWEEP_TWEEN = 0.85
local SWEEP_WAIT = 0.15

local HEIGHT_OFFSET = 175
local CHUNK_SIZE = 500
local PHASE3_SPACE_SCALE = 2
local PHASE3_CHUNK_MULTIPLIER = 4

local ROAM_RADIUS = 80
local ROAM_BOPS = 4
local ROAM_WAIT = 0.35

local LOOK_DOWN_OFFSET = Vector3.new(0, -300, 0)

local HEIGHT_VEC = Vector3.new(0, HEIGHT_OFFSET, 0)
local DUMMY_FOLDER = Instance.new("Folder")

local running = false
local stopRequested = false
local minimized = false

local originalCFrame
local originalCameraType
local savedFramePos

local gui, frame, content
local barBg, progressFill, progressText
local actionBtn

local globalStartTime
local totalWorkItems
local globalDone

local function setRendering(on)
	RunService:Set3dRenderingEnabled(on)
end

local function restoreCamera()
	setRendering(true)
	if originalCameraType then camera.CameraType = originalCameraType end
	if originalCFrame then camera.CFrame = originalCFrame end
end

local function formatETA(startTime, done, total)
	if done >= total then
		return "00:00"
	end
	local elapsed = tick() - startTime
	local avg = elapsed / math.max(done, 1)
	local remain = math.max(0, total - done)
	local eta = math.floor(avg * remain)
	return string.format("%02d:%02d", math.floor(eta / 60), eta % 60)
end

local function phaseText(done, total, eta)
	return string.format(
		"Phase %d/%d | %d/%d | ETA %s",
		CURRENT_PHASE,
		TOTAL_PHASES,
		done,
		total,
		eta
	)
end

local function setProgress(alpha, text, active)
	progressFill.Size = UDim2.new(math.clamp(alpha, 0, 1), 0, 1, 0)
	progressText.Text = text
	barBg.BackgroundColor3 = Color3.fromHex("#1d2f49")
end

local function collectParts()
	local parts = {}
	local charModel = player.Character or DUMMY_FOLDER
	
	for _, inst in ipairs(Workspace:GetDescendants()) do
		if inst:IsA("BasePart")
			and inst.Transparency < 1
			and not inst:IsDescendantOf(charModel) then
			parts[#parts+1] = inst
		end
	end
	return parts
end

local function buildCenters(parts)
	local buckets = {}
	for _, p in ipairs(parts) do
		local cx = math.floor(p.Position.X / CHUNK_SIZE)
		local cy = math.floor(p.Position.Y / CHUNK_SIZE)
		local cz = math.floor(p.Position.Z / CHUNK_SIZE)
		local key = cx..","..cy..","..cz
		if not buckets[key] then
			buckets[key] = { sum = Vector3.zero, count = 0 }
		end
		buckets[key].sum += p.Position
		buckets[key].count += 1
	end

	local centers = {}
	for _, b in pairs(buckets) do
		centers[#centers+1] = b.sum / b.count
	end
	return centers
end

local function expandCenters(centers, scale)
	local origin = Vector3.zero
	for _, c in ipairs(centers) do
		origin += c
	end
	origin /= #centers

	local expanded = {}
	for _, c in ipairs(centers) do
		expanded[#expanded+1] = origin + (c - origin) * scale
	end

	return expanded
end

local function buildColumns(centers, chunkSize)
	chunkSize = chunkSize or CHUNK_SIZE
	
	local minX = math.huge
	for _, c in ipairs(centers) do
		minX = math.min(minX, c.X)
	end

	local columns = {}
	for _, c in ipairs(centers) do
		local col = math.floor((c.X - minX) / chunkSize)
		columns[col] = columns[col] or {}
		table.insert(columns[col], c)
	end
	return columns
end

local function cameraAboveLookingAt(targetPos)
	local camPos = targetPos + HEIGHT_VEC
	return CFrame.lookAt(camPos, targetPos + LOOK_DOWN_OFFSET)
end

local function randomBop(center)
	local offset = Vector3.new(
		math.random(-ROAM_RADIUS, ROAM_RADIUS),
		0,
		math.random(-ROAM_RADIUS, ROAM_RADIUS)
	)
	return cameraAboveLookingAt(center + offset)
end

local function tweenTo(targetPos)
	local cf = cameraAboveLookingAt(targetPos)

	local tween = TweenService:Create(
		camera,
		TweenInfo.new(SWEEP_TWEEN, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
		{ CFrame = cf }
	)

	tween:Play()
	tween.Completed:Wait()
	task.wait(SWEEP_WAIT)
end

local function roamChunks(centers)
	CURRENT_PHASE = 4
	setProgress(1, "Phase 4/4 | Roaming", true)

	while not stopRequested do
		local center = centers[math.random(1, #centers)]

		tweenTo(center)

		for i = 1, ROAM_BOPS do
			if stopRequested then return end
			camera.CFrame = randomBop(center)
			task.wait(ROAM_WAIT)
		end
	end
end

local function runLoader()
	running = true
	stopRequested = false

	originalCFrame = camera.CFrame
	originalCameraType = camera.CameraType
	camera.CameraType = Enum.CameraType.Scriptable

	actionBtn.Text = "Stop"
	actionBtn.BackgroundColor3 = Color3.fromHex("#23456d")

	local parts = collectParts()
	if #parts == 0 then
		restoreCamera()
		running = false
		setProgress(0, "No parts found", false)
		actionBtn.Text = "Start"
		return
	end

	local centers = buildCenters(parts)
	if #centers == 0 then
		restoreCamera()
		running = false
		setProgress(0, "No chunks generated", false)
		actionBtn.Text = "Start"
		return
	end
	
	local columns = buildColumns(centers)
	local centerCount = #centers

	local p1Total = centerCount
	
	local p2Total = 0
	for _, col in pairs(columns) do p2Total += #col end
	
	local phase3Centers = expandCenters(centers, PHASE3_SPACE_SCALE)
	local phase3Columns = buildColumns(phase3Centers)
	local p3Total = 0
	for _, col in pairs(phase3Columns) do p3Total += #col end
	
	totalWorkItems = p1Total + p2Total + p3Total
	globalDone = 0
	globalStartTime = tick()

	CURRENT_PHASE = 1
	setRendering(false)

	for i = 1, centerCount do
		if stopRequested then
			CURRENT_PHASE = 0
			restoreCamera()
			running = false
			actionBtn.Text = "Start"
			setProgress(0, "Stopped", false)
			return
		end
		globalDone += 1
		camera.CFrame = cameraAboveLookingAt(centers[i])
		task.wait(FAST_WAIT)

		setProgress(
			globalDone / totalWorkItems,
			phaseText(globalDone, totalWorkItems, formatETA(globalStartTime, globalDone, totalWorkItems)),
			true
		)
	end

	setRendering(true)

	CURRENT_PHASE = 2

	for col = 0, math.huge do
		local list = columns[col]
		if not list then break end

		table.sort(list, function(a, b)
			return a.Z > b.Z
		end)

		for _, c in ipairs(list) do
			if stopRequested then
				CURRENT_PHASE = 0
				restoreCamera()
				running = false
				actionBtn.Text = "Start"
				setProgress(0, "Stopped", false)
				return
			end
			globalDone += 1
			tweenTo(c)

			setProgress(
				globalDone / totalWorkItems,
				phaseText(globalDone, totalWorkItems, formatETA(globalStartTime, globalDone, totalWorkItems)),
				true
			)
		end
	end

	CURRENT_PHASE = 3

	for col = 0, math.huge do
		local list = phase3Columns[col]
		if not list then break end

		table.sort(list, function(a, b)
			return a.Y > b.Y
		end)

		for _, c in ipairs(list) do
			if stopRequested then
				CURRENT_PHASE = 0
				restoreCamera()
				running = false
				actionBtn.Text = "Start"
				setProgress(0, "Stopped", false)
				return
			end
			globalDone += 1
			tweenTo(c)

			setProgress(
				globalDone / totalWorkItems,
				phaseText(globalDone, totalWorkItems, formatETA(globalStartTime, globalDone, totalWorkItems)),
				true
			)
		end
	end

	roamChunks(centers)
	restoreCamera()
	gui:Destroy()
end

gui = Instance.new("ScreenGui", player.PlayerGui)
gui.Name = "MapLoader"
gui.ResetOnSpawn = false

frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 300, 0, 150)
frame.Position = UDim2.new(0.5, -150, 0.5, -75)
frame.BackgroundColor3 = Color3.fromHex("#151618")
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 32)
title.BackgroundColor3 = Color3.fromHex("#294a7a")
title.Text = "MapLoader"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 16
title.TextColor3 = Color3.new(1,1,1)
title.TextXAlignment = Enum.TextXAlignment.Center

local minimize = Instance.new("TextButton", frame)
minimize.Size = UDim2.new(0, 32, 0, 32)
minimize.Position = UDim2.new(1, -32, 0, 0)
minimize.Text = "-"
minimize.Font = Enum.Font.SourceSansBold
minimize.TextSize = 24
minimize.TextColor3 = Color3.new(1,1,1)
minimize.BackgroundTransparency = 1

content = Instance.new("Frame", frame)
content.Position = UDim2.new(0,0,0,32)
content.Size = UDim2.new(1,0,1,-32)
content.BackgroundTransparency = 1

barBg = Instance.new("Frame", content)
barBg.Size = UDim2.new(0.9,0,0,18)
barBg.Position = UDim2.new(0.05,0,0,20)
barBg.BackgroundColor3 = Color3.fromHex("#1d2f49")

progressFill = Instance.new("Frame", barBg)
progressFill.Size = UDim2.new(0,0,1,0)
progressFill.BackgroundColor3 = Color3.fromHex("#e6b32f")

progressText = Instance.new("TextLabel", barBg)
progressText.Size = UDim2.new(1,0,1,0)
progressText.BackgroundTransparency = 1
progressText.Text = "Idle"
progressText.Font = Enum.Font.SourceSansBold
progressText.TextSize = 14
progressText.TextColor3 = Color3.new(1,1,1)

actionBtn = Instance.new("TextButton", content)
actionBtn.Size = UDim2.new(0.8,0,0,32)
actionBtn.Position = UDim2.new(0.1,0,0,60)
actionBtn.Text = "Start"
actionBtn.Font = Enum.Font.SourceSansBold
actionBtn.TextSize = 16
actionBtn.BackgroundColor3 = Color3.fromHex("#23456d")
actionBtn.TextColor3 = Color3.new(1,1,1)

actionBtn.AutoButtonColor = false

local BTN_DEFAULT = Color3.fromHex("#23456d")
local BTN_HOVER   = Color3.fromHex("#4296fa")
local BTN_DOWN    = Color3.fromHex("#1b87fa")

local isHovering = false
local isDown = false

actionBtn.MouseEnter:Connect(function()
	isHovering = true
	if not isDown then
		actionBtn.BackgroundColor3 = BTN_HOVER
	end
end)

actionBtn.MouseLeave:Connect(function()
	isHovering = false
	if not isDown then
		actionBtn.BackgroundColor3 = BTN_DEFAULT
	end
end)

actionBtn.MouseButton1Down:Connect(function()
	isDown = true
	actionBtn.BackgroundColor3 = BTN_DOWN
end)

actionBtn.MouseButton1Up:Connect(function()
	isDown = false
	if isHovering then
		actionBtn.BackgroundColor3 = BTN_HOVER
	else
		actionBtn.BackgroundColor3 = BTN_DEFAULT
	end
end)

actionBtn.MouseButton1Click:Connect(function()
	if running then
		stopRequested = true
		CURRENT_PHASE = 0
		restoreCamera()
		running = false
		actionBtn.Text = "Start"
		actionBtn.BackgroundColor3 = Color3.fromHex("#23456d")
		setProgress(0, "Idle", false)
	else
		task.spawn(runLoader)
	end
end)

minimize.MouseButton1Click:Connect(function()
	minimized = not minimized
	if minimized then
		savedFramePos = frame.Position
		content.Visible = false
		frame.Size = UDim2.new(0, 220, 0, 32)
		frame.Position = UDim2.new(0, 10, 1, -42)
	else
		content.Visible = true
		frame.Size = UDim2.new(0, 300, 0, 150)
		frame.Position = savedFramePos or frame.Position
	end
end)