local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

pcall(function()
	sethiddenproperty(Workspace, "StreamOutBehavior", Enum.StreamOutBehavior.Default)
end)

local States = {
	IDLE = "idle",
	INITIALIZING = "initializing",
	STREAMING = "streaming",
	PHASE1 = "phase1",
	PHASE2 = "phase2",
	PHASE3 = "phase3",
	ROAMING = "roaming",
	ERROR = "error"
}

local StateMachine = {
	current = States.IDLE,
	previous = nil,
	transitions = {
		[States.IDLE] = {States.INITIALIZING, States.ERROR},
		[States.INITIALIZING] = {States.STREAMING, States.PHASE1, States.ERROR, States.IDLE},
		[States.STREAMING] = {States.PHASE1, States.ERROR, States.IDLE},
		[States.PHASE1] = {States.PHASE2, States.ERROR, States.IDLE},
		[States.PHASE2] = {States.PHASE3, States.ROAMING, States.ERROR, States.IDLE},
		[States.PHASE3] = {States.ROAMING, States.ERROR, States.IDLE},
		[States.ROAMING] = {States.IDLE, States.ERROR},
		[States.ERROR] = {States.IDLE}
	}
}

function StateMachine:transition(newState)
	local allowed = self.transitions[self.current]
	if not allowed or not table.find(allowed, newState) then
		warn("[MapLoader] Invalid transition:", self.current, "->", newState)
		return false
	end
	self.previous = self.current
	self.current = newState
	return true
end

function StateMachine:canStop()
	return self.current ~= States.IDLE and self.current ~= States.ERROR
end

local LoadStrategies = {
	SPEED = {
		name = "Speed",
		chunkSize = 1000,
		skipPhase3 = true,
		renderQuality = "Low",
		batchSize = 200,
		fastWait = 0.05,
		sweepTween = 0.6,
		preloadAssets = false
	},
	BALANCED = {
		name = "Balanced",
		chunkSize = 500,
		skipPhase3 = false,
		renderQuality = "Medium",
		batchSize = 150,
		fastWait = 0.08,
		sweepTween = 0.85,
		preloadAssets = true
	},
	QUALITY = {
		name = "Quality",
		chunkSize = 250,
		skipPhase3 = false,
		renderQuality = "High",
		batchSize = 100,
		fastWait = 0.12,
		sweepTween = 1.2,
		preloadAssets = true
	}
}

local currentStrategy = LoadStrategies.QUALITY

local HEIGHT_OFFSET = 175
local PHASE3_SPACE_SCALE = 1.5
local SWEEP_WAIT = 0.15
local ROAM_RADIUS = 80
local ROAM_BOPS = 4
local ROAM_WAIT = 0.35
local LOOK_DOWN_OFFSET = Vector3.new(0, -300, 0)

local STREAMING_TIMEOUT = 15
local STABILITY_CHECK_INTERVAL = 0.5
local STABILITY_REQUIRED_TIME = 2
local MAX_CHUNK_RETRIES = 3
local GROWTH_THRESHOLD = 5
local MAX_REQUESTS_PER_SECOND = 8

local GAME_ID = game.PlaceId
local JAILBREAK_ID = 606849621

local GameConfigs = {
	[JAILBREAK_ID] = {
		name = "Jailbreak",
		useCustomBounds = true,
		bounds = {
			topLeft = Vector3.new(-2728.112, 15.561, -6993.061),
			topRight = Vector3.new(4295.353, 16.177, -5742.102),
			bottomLeft = Vector3.new(-4195.167, 15.524, 3584.259),
			bottomRight = Vector3.new(3438.196, 16.177, 3863.812)
		},
		chunkSize = 800,
		gridSpacing = 700,
		heightOffset = 150,
		skipPhase3 = false,
		skipStabilityCheck = true,
		fastWait = 0.04,
		sweepTween = 0.4,
		phaseTimeTarget = 240
	}
}

local currentGameConfig = GameConfigs[GAME_ID]

local function calculateMapBounds()
	print("[MapLoader] Calculating map bounds...")

	local minX, maxX = math.huge, -math.huge
	local minY, maxY = math.huge, -math.huge
	local minZ, maxZ = math.huge, -math.huge
	local partCount = 0

	for _, part in ipairs(Workspace:GetDescendants()) do
		if part:IsA("BasePart") and part.Anchored then
			local pos = part.Position
			local size = part.Size

			minX = math.min(minX, pos.X - size.X/2)
			maxX = math.max(maxX, pos.X + size.X/2)
			minY = math.min(minY, pos.Y - size.Y/2)
			maxY = math.max(maxY, pos.Y + size.Y/2)
			minZ = math.min(minZ, pos.Z - size.Z/2)
			maxZ = math.max(maxZ, pos.Z + size.Z/2)

			partCount += 1

			if partCount % 500 == 0 then
				task.wait()
			end
		end
	end

	if minX == math.huge then
		return nil
	end

	local avgY = (minY + maxY) / 2

	return {
		topLeft = Vector3.new(minX, avgY, minZ),
		topRight = Vector3.new(maxX, avgY, minZ),
		bottomLeft = Vector3.new(minX, avgY, maxZ),
		bottomRight = Vector3.new(maxX, avgY, maxZ),
		center = Vector3.new((minX + maxX)/2, avgY, (minZ + maxZ)/2),
		dimensions = Vector3.new(maxX - minX, maxY - minY, maxZ - minZ),
		partCount = partCount
	}
end

local function calculateOptimalSpacing(dimensions)
	local area = dimensions.X * dimensions.Z

	local targetPoints = 200
	local spacing = math.sqrt(area / targetPoints)

	return math.clamp(spacing, 300, 1000)
end

local function shouldUseBoundedMode(bounds)
	if not bounds then return false, nil end

	local dims = bounds.dimensions

	if dims.X > 3000 or dims.Z > 3000 then
		local spacing = calculateOptimalSpacing(dims)

		print(string.format("[MapLoader] Large map detected: %.0f x %.0f studs", dims.X, dims.Z))
		print(string.format("[MapLoader] Using bounded mode with %.0f stud spacing", spacing))

		return true, {
			name = "Auto-Detected Map",
			useCustomBounds = true,
			bounds = bounds,
			chunkSize = math.clamp(spacing * 1.2, 400, 1000),
			gridSpacing = spacing,
			heightOffset = 150,
			skipPhase3 = dims.X > 5000 or dims.Z > 5000,
			skipStabilityCheck = true,
			fastWait = 0.04,
			sweepTween = 0.5,
			timeTarget = nil
		}
	end

	print(string.format("[MapLoader] Standard-sized map: %.0f x %.0f studs", dims.X, dims.Z))
	print("[MapLoader] Using standard streaming mode")

	return false, nil
end

local PerformanceTracker = {
	metrics = {},
	lastSample = tick(),
	sampleInterval = 0.5,
	thresholds = {
		fps = 25,
		memory = 3500,
		loadTimeMs = 10000
	}
}

function PerformanceTracker:sample()
	local now = tick()
	if now - self.lastSample < self.sampleInterval then
		return self.metrics
	end

	self.lastSample = now
	self.metrics = {
		fps = math.floor(1 / RunService.RenderStepped:Wait()),
		memory = math.floor(gcinfo()),
		timestamp = now
	}
	return self.metrics
end

function PerformanceTracker:shouldThrottle()
	local sample = self:sample()
	return sample.fps < self.thresholds.fps or sample.memory > self.thresholds.memory
end

function PerformanceTracker:getStatus()
	local sample = self:sample()
	return string.format("FPS: %d | MEM: %dMB", sample.fps, sample.memory)
end

local StreamingMetrics = {
	totalChunks = 0,
	completedChunks = 0,
	failedChunks = 0,
	retriedChunks = 0,
	verifiedLoads = 0,
	timeouts = 0
}

local failedChunksQueue = {}
local lastTweenTime = 0
local MIN_TWEEN_INTERVAL = 1 / MAX_REQUESTS_PER_SECOND

local HEIGHT_VEC = Vector3.new(0, HEIGHT_OFFSET, 0)
local DUMMY_FOLDER = Instance.new("Folder")

local running = false
local stopRequested = false
local minimized = false

local originalCFrame
local originalCameraType
local originalAnchor
local savedFramePos

local gui, frame, content
local barBg, progressFill, progressText, perfText, metricsText
local actionBtn, strategyBtn

local globalStartTime
local totalWorkItems
local globalDone

local allParts = {}
local chunkCenters = {}
local chunkSize = currentStrategy.chunkSize

local function setRendering(on)
	RunService:Set3dRenderingEnabled(on)
end

local function restoreCamera()
	setRendering(true)
	if originalCameraType then camera.CameraType = originalCameraType end
	if originalCFrame then camera.CFrame = originalCFrame end

	local character = player.Character
	local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
	if humanoidRootPart and originalAnchor ~= nil then
		humanoidRootPart.Anchored = originalAnchor
	end
end

local function formatETA(startTime, done, total)
	if done >= total then return "00:00" end
	local elapsed = tick() - startTime
	local avg = elapsed / math.max(done, 1)
	local remain = math.max(0, total - done)
	local eta = math.floor(avg * remain)
	return string.format("%02d:%02d", math.floor(eta / 60), eta % 60)
end

local function phaseText(phase, done, total, eta)
	return string.format("Phase %s | %d/%d | ETA %s", phase, done, total, eta)
end

local function setProgress(alpha, text)
	progressFill.Size = UDim2.new(math.clamp(alpha, 0, 1), 0, 1, 0)
	progressText.Text = text
	barBg.BackgroundColor3 = Color3.fromHex("#1d2f49")
	perfText.Text = PerformanceTracker:getStatus()

	if metricsText then
		metricsText.Text = string.format(
			"Verified: %d | Retries: %d | Failed: %d | Timeouts: %d",
			StreamingMetrics.verifiedLoads,
			StreamingMetrics.retriedChunks,
			StreamingMetrics.failedChunks,
			StreamingMetrics.timeouts
		)
	end
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

	local now = tick()
	local elapsed = now - lastTweenTime
	if elapsed < MIN_TWEEN_INTERVAL then
		task.wait(MIN_TWEEN_INTERVAL - elapsed)
	end
	lastTweenTime = tick()

	local cf = cameraAboveLookingAt(targetPos)
	local tween = TweenService:Create(
		camera,
		TweenInfo.new(currentStrategy.sweepTween, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
		{ CFrame = cf }
	)
	tween:Play()
	tween.Completed:Wait()
	task.wait(SWEEP_WAIT)
end

local function generateBoundedGrid(config)
	local bounds = config.bounds
	local spacing = config.gridSpacing
	local heightOffset = config.heightOffset or HEIGHT_OFFSET

	local centerX = (bounds.topLeft.X + bounds.topRight.X + bounds.bottomLeft.X + bounds.bottomRight.X) / 4
	local centerZ = (bounds.topLeft.Z + bounds.topRight.Z + bounds.bottomLeft.Z + bounds.bottomRight.Z) / 4
	local avgY = (bounds.topLeft.Y + bounds.topRight.Y + bounds.bottomLeft.Y + bounds.bottomRight.Y) / 4

	local minX = math.min(bounds.topLeft.X, bounds.topRight.X, bounds.bottomLeft.X, bounds.bottomRight.X)
	local maxX = math.max(bounds.topLeft.X, bounds.topRight.X, bounds.bottomLeft.X, bounds.bottomRight.X)
	local minZ = math.min(bounds.topLeft.Z, bounds.topRight.Z, bounds.bottomLeft.Z, bounds.bottomRight.Z)
	local maxZ = math.max(bounds.topLeft.Z, bounds.topRight.Z, bounds.bottomLeft.Z, bounds.bottomRight.Z)

	local centers = {}

	for x = minX, maxX, spacing do
		for z = minZ, maxZ, spacing do
			local position = Vector3.new(x, avgY, z)

			local visual = Instance.new("Part")
			visual.Name = "ChunkVisual"
			visual.Anchored = true
			visual.CanCollide = false
			visual.CastShadow = false
			visual.Shape = Enum.PartType.Ball
			visual.Material = Enum.Material.ForceField
			visual.Size = Vector3.new(50, 50, 50)
			visual.Position = position
			visual.Color = Color3.fromRGB(255, 150, 0)
			visual.Transparency = 0.85
			visual.Parent = Workspace

			table.insert(centers, {
				position = position,
				parts = {},
				retries = 0,
				maxRetries = MAX_CHUNK_RETRIES,
				visual = visual,
				verified = false
			})
		end
	end

	return centers
end

local function countPartsInRadius(position, radius)
	local success, parts = pcall(function()
		return Workspace:GetPartBoundsInRadius(position, radius)
	end)

	if success and parts then
		local count = 0
		for _, part in ipairs(parts) do
			if part:IsA("BasePart") and part.Anchored then
				count += 1
			end
		end
		return count
	end

	return 0
end

local function verifyChunkStable(position, radius)
	local startTime = tick()
	local lastCount = countPartsInRadius(position, radius)
	local stableTime = 0
	local maxCount = lastCount
	local pendingGrowth = 0

	pcall(function()
		task.spawn(function()
			pcall(function()
				player:RequestStreamAroundAsync(position, STREAMING_TIMEOUT)
			end)
		end)
	end)

	while tick() - startTime < STREAMING_TIMEOUT do
		if stopRequested then
			return false
		end

		task.wait(STABILITY_CHECK_INTERVAL)

		local currentCount = countPartsInRadius(position, radius)
		local delta = math.max(0, currentCount - lastCount)

		if delta > 0 then
			pendingGrowth += delta

			if pendingGrowth >= GROWTH_THRESHOLD then
				maxCount = math.max(maxCount, currentCount)
				pendingGrowth = 0
				stableTime = 0
			end
		else
			pendingGrowth = math.max(0, pendingGrowth - 1)
			stableTime += STABILITY_CHECK_INTERVAL
		end

		lastCount = currentCount

		if stableTime >= STABILITY_REQUIRED_TIME then
			StreamingMetrics.verifiedLoads += 1
			return true
		end
	end

	StreamingMetrics.timeouts += 1
	return maxCount > 0
end

local function calculateOptimalChunkSize(parts)
	if #parts == 0 then return currentStrategy.chunkSize end

	local bounds = {
		min = Vector3.new(math.huge, math.huge, math.huge),
		max = Vector3.new(-math.huge, -math.huge, -math.huge)
	}

	for _, p in ipairs(parts) do
		bounds.min = Vector3.new(
			math.min(bounds.min.X, p.Position.X),
			math.min(bounds.min.Y, p.Position.Y),
			math.min(bounds.min.Z, p.Position.Z)
		)
		bounds.max = Vector3.new(
			math.max(bounds.max.X, p.Position.X),
			math.max(bounds.max.Y, p.Position.Y),
			math.max(bounds.max.Z, p.Position.Z)
		)
	end

	local volume = (bounds.max - bounds.min)
	local totalVolume = volume.X * volume.Y * volume.Z

	if totalVolume <= 0 then return currentStrategy.chunkSize end

	local density = #parts / totalVolume
	local adaptiveSize = math.clamp(500 / math.sqrt(math.max(density, 0.0001)), 250, 2000)

	return math.floor(adaptiveSize)
end

local function streamParts(callback)
	StateMachine:transition(States.STREAMING)

	local batch = {}
	local charModel = player.Character or DUMMY_FOLDER
	local processedCount = 0
	local batchSize = currentStrategy.batchSize

	setProgress(0, "Streaming parts... 0 found")

	for _, inst in ipairs(Workspace:GetDescendants()) do
		if stopRequested then return false end

		if inst:IsA("BasePart") and inst.Transparency < 1 and not inst:IsDescendantOf(charModel) then
			batch[#batch + 1] = inst
			processedCount += 1

			if #batch >= batchSize then
				callback(batch)
				batch = {}
				task.wait()
				setProgress(0, string.format("Streaming parts... %d found", processedCount))
			end
		end
	end

	if #batch > 0 then
		callback(batch)
	end

	return true
end

local function preloadChunkAssets(parts)
	if not currentStrategy.preloadAssets then return end

	local assets = {}
	for _, part in ipairs(parts) do
		if part:IsA("MeshPart") and part.MeshId ~= "" then
			table.insert(assets, part.MeshId)
		end
		for _, child in ipairs(part:GetChildren()) do
			if (child:IsA("Texture") or child:IsA("Decal")) and child.Texture ~= "" then
				table.insert(assets, child.Texture)
			end
		end
	end

	if #assets > 0 then
		pcall(function()
			ContentProvider:PreloadAsync(assets)
		end)
	end
end

local function buildCenters(parts, chunkSizeOverride)
	local size = chunkSizeOverride or chunkSize
	local buckets = {}

	for _, p in ipairs(parts) do
		local cx = math.floor(p.Position.X / size)
		local cy = math.floor(p.Position.Y / size)
		local cz = math.floor(p.Position.Z / size)
		local key = cx..","..cy..","..cz

		if not buckets[key] then
			buckets[key] = { sum = Vector3.zero, count = 0, parts = {} }
		end
		buckets[key].sum += p.Position
		buckets[key].count += 1
		table.insert(buckets[key].parts, p)
	end

	local centers = {}
	for _, b in pairs(buckets) do
		local center = b.sum / b.count

		local visual = Instance.new("Part")
		visual.Name = "ChunkVisual"
		visual.Anchored = true
		visual.CanCollide = false
		visual.CastShadow = false
		visual.Shape = Enum.PartType.Ball
		visual.Material = Enum.Material.ForceField
		visual.Size = Vector3.new(50, 50, 50)
		visual.Position = center
		visual.Color = Color3.fromRGB(255, 150, 0)
		visual.Transparency = 0.85
		visual.Parent = Workspace

		table.insert(centers, {
			position = center,
			parts = b.parts,
			retries = 0,
			maxRetries = MAX_CHUNK_RETRIES,
			visual = visual,
			verified = false
		})
	end

	return centers
end

local function expandCenters(centers, scale)
	local origin = Vector3.zero
	for _, c in ipairs(centers) do
		origin += c.position
	end
	origin /= #centers

	local expanded = {}
	for _, c in ipairs(centers) do
		local newPos = origin + (c.position - origin) * scale

		local visual = Instance.new("Part")
		visual.Name = "ChunkVisual"
		visual.Anchored = true
		visual.CanCollide = false
		visual.CastShadow = false
		visual.Shape = Enum.PartType.Ball
		visual.Material = Enum.Material.ForceField
		visual.Size = Vector3.new(50, 50, 50)
		visual.Position = newPos
		visual.Color = Color3.fromRGB(255, 150, 0)
		visual.Transparency = 0.85
		visual.Parent = Workspace

		table.insert(expanded, {
			position = newPos,
			parts = c.parts,
			retries = 0,
			maxRetries = MAX_CHUNK_RETRIES,
			visual = visual,
			verified = false
		})
	end

	return expanded
end

local function buildColumns(centers, chunkSizeOverride)
	local size = chunkSizeOverride or chunkSize
	local minX = math.huge

	for _, c in ipairs(centers) do
		minX = math.min(minX, c.position.X)
	end

	local columns = {}
	for _, c in ipairs(centers) do
		local col = math.floor((c.position.X - minX) / size)
		columns[col] = columns[col] or {}
		table.insert(columns[col], c)
	end

	return columns
end

local function executePhase1(centers)
	if not StateMachine:transition(States.PHASE1) then return false end

	setRendering(false)

	local skipStability = currentGameConfig and currentGameConfig.skipStabilityCheck

	for i, center in ipairs(centers) do
		if stopRequested then return false end

		if center.visual then
			center.visual.Color = Color3.fromRGB(0, 100, 255)
		end

		globalDone += 1
		camera.CFrame = cameraAboveLookingAt(center.position)

		if PerformanceTracker:shouldThrottle() then
			task.wait(currentStrategy.fastWait * 1.5)
		else
			task.wait(currentStrategy.fastWait)
		end

		local verified = true
		if not skipStability then
			verified = verifyChunkStable(center.position, 100)
			center.verified = verified
		end

		if verified then
			if center.visual then
				center.visual.Color = Color3.fromRGB(0, 255, 0)
				center.visual.Transparency = 0.95
				Debris:AddItem(center.visual, 5)
			end
			if not skipStability then
				preloadChunkAssets(center.parts)
			end
		else

			if center.visual then
				center.visual.Color = Color3.fromRGB(255, 0, 0)
			end

			if center.retries < center.maxRetries then
				center.retries += 1
				StreamingMetrics.retriedChunks += 1
				table.insert(failedChunksQueue, center)
			else
				StreamingMetrics.failedChunks += 1
				if center.visual then
					center.visual.Transparency = 0.5
					Debris:AddItem(center.visual, 10)
				end
			end
		end

		setProgress(
			globalDone / totalWorkItems,
			phaseText("1/4", globalDone, totalWorkItems, formatETA(globalStartTime, globalDone, totalWorkItems))
		)
	end

	setRendering(true)
	return true
end

local function executePhase2(columns)
	if not StateMachine:transition(States.PHASE2) then return false end

	local skipStability = currentGameConfig and currentGameConfig.skipStabilityCheck

	for col = 0, math.huge do
		local list = columns[col]
		if not list then break end

		table.sort(list, function(a, b)
			return a.position.Z > b.position.Z
		end)

		for _, c in ipairs(list) do
			if stopRequested then return false end

			if c.visual then
				c.visual.Color = Color3.fromRGB(0, 100, 255)
			end

			globalDone += 1

			local success = pcall(function()
				tweenTo(c.position)
			end)

			if success then
				local verified = true
				if not skipStability then
					verified = verifyChunkStable(c.position, 100)
					c.verified = verified
				end

				if verified then
					if c.visual then
						c.visual.Color = Color3.fromRGB(0, 255, 0)
						c.visual.Transparency = 0.95
						Debris:AddItem(c.visual, 5)
					end
				else
					if c.visual then
						c.visual.Color = Color3.fromRGB(255, 0, 0)
					end

					if c.retries < c.maxRetries then
						c.retries += 1
						StreamingMetrics.retriedChunks += 1
						table.insert(failedChunksQueue, c)
					else
						StreamingMetrics.failedChunks += 1
						if c.visual then
							Debris:AddItem(c.visual, 10)
						end
					end
				end
			else

				if c.retries < c.maxRetries then
					c.retries += 1
					StreamingMetrics.retriedChunks += 1
					table.insert(failedChunksQueue, c)
				else
					StreamingMetrics.failedChunks += 1
				end
			end

			setProgress(
				globalDone / totalWorkItems,
				phaseText("2/4", globalDone, totalWorkItems, formatETA(globalStartTime, globalDone, totalWorkItems))
			)
		end
	end

	return true
end

local function executePhase3(columns)
	if currentStrategy.skipPhase3 then return true end
	if not StateMachine:transition(States.PHASE3) then return false end

	for col = 0, math.huge do
		local list = columns[col]
		if not list then break end

		table.sort(list, function(a, b)
			return a.position.Y > b.position.Y
		end)

		for _, c in ipairs(list) do
			if stopRequested then return false end

			if c.visual then
				c.visual.Color = Color3.fromRGB(0, 100, 255)
			end

			globalDone += 1

			local success = pcall(function()
				tweenTo(c.position)
			end)

			if success then
				local verified = verifyChunkStable(c.position, 100)
				c.verified = verified

				if verified then
					if c.visual then
						c.visual.Color = Color3.fromRGB(0, 255, 0)
						c.visual.Transparency = 0.95
						Debris:AddItem(c.visual, 5)
					end
				else
					if c.visual then
						c.visual.Color = Color3.fromRGB(255, 0, 0)
					end

					if c.retries < c.maxRetries then
						c.retries += 1
						StreamingMetrics.retriedChunks += 1
						table.insert(failedChunksQueue, c)
					else
						StreamingMetrics.failedChunks += 1
						if c.visual then
							Debris:AddItem(c.visual, 10)
						end
					end
				end
			else
				if c.retries < c.maxRetries then
					c.retries += 1
					StreamingMetrics.retriedChunks += 1
					table.insert(failedChunksQueue, c)
				else
					StreamingMetrics.failedChunks += 1
				end
			end

			setProgress(
				globalDone / totalWorkItems,
				phaseText("3/4", globalDone, totalWorkItems, formatETA(globalStartTime, globalDone, totalWorkItems))
			)
		end
	end

	return true
end

local function executeRoaming(centers)
	if not StateMachine:transition(States.ROAMING) then return false end

	setProgress(1, "Phase 4/4 | Roaming")

	while not stopRequested do
		local center = centers[math.random(1, #centers)]
		tweenTo(center.position)

		for i = 1, ROAM_BOPS do
			if stopRequested then return false end
			camera.CFrame = randomBop(center.position)
			task.wait(ROAM_WAIT)
		end
	end

	return true
end

local function executeRetryPass()
	if #failedChunksQueue == 0 then return true end

	setProgress(globalDone / totalWorkItems, "Retry Pass | Processing failed chunks...")

	local retryAttempts = 0
	local maxRetryAttempts = #failedChunksQueue

	while #failedChunksQueue > 0 and retryAttempts < maxRetryAttempts do
		if stopRequested then return false end

		local chunk = table.remove(failedChunksQueue, 1)
		retryAttempts += 1

		if chunk.visual then
			chunk.visual.Color = Color3.fromRGB(255, 165, 0)  -- Orange for retry
		end

		camera.CFrame = cameraAboveLookingAt(chunk.position)
		task.wait(currentStrategy.fastWait)

		local verified = verifyChunkStable(chunk.position, 100)

		if verified then
			StreamingMetrics.completedChunks += 1
			if chunk.visual then
				chunk.visual.Color = Color3.fromRGB(0, 255, 0)
				chunk.visual.Transparency = 0.95
				Debris:AddItem(chunk.visual, 5)
			end
		else
			StreamingMetrics.failedChunks += 1
			if chunk.visual then
				chunk.visual.Color = Color3.fromRGB(100, 0, 0)
				Debris:AddItem(chunk.visual, 10)
			end
		end

		setProgress(globalDone / totalWorkItems,
			string.format("Retry Pass | %d/%d processed", retryAttempts, maxRetryAttempts))
	end

	return true
end

local function runLoader()
	running = true
	stopRequested = false

	StreamingMetrics.totalChunks = 0
	StreamingMetrics.completedChunks = 0
	StreamingMetrics.failedChunks = 0
	StreamingMetrics.retriedChunks = 0
	StreamingMetrics.verifiedLoads = 0
	StreamingMetrics.timeouts = 0
	failedChunksQueue = {}

	local character = player.Character
	local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")

	if humanoidRootPart then
		originalAnchor = humanoidRootPart.Anchored
		humanoidRootPart.Anchored = true
	end

	originalCFrame = camera.CFrame
	originalCameraType = camera.CameraType
	camera.CameraType = Enum.CameraType.Scriptable

	actionBtn.Text = "Stop"
	actionBtn.BackgroundColor3 = Color3.fromHex("#c4302b")

	if not StateMachine:transition(States.INITIALIZING) then
		restoreCamera()
		running = false
		StateMachine:transition(States.ERROR)
		return
	end

	if not currentGameConfig then
		setProgress(0.1, "Analyzing map boundaries...")
		local detectedBounds = calculateMapBounds()

		if detectedBounds then
			local useBounded, autoConfig = shouldUseBoundedMode(detectedBounds)

			if useBounded then
				currentGameConfig = autoConfig
			end
		end
	end

	if currentGameConfig and currentGameConfig.useCustomBounds then
		print("[MapLoader] Detected:", currentGameConfig.name)
		print("[MapLoader] Using custom bounds and optimized settings")

		if currentGameConfig.heightOffset then
			HEIGHT_VEC = Vector3.new(0, currentGameConfig.heightOffset, 0)
		end

		chunkCenters = generateBoundedGrid(currentGameConfig)

		if #chunkCenters == 0 then
			restoreCamera()
			running = false
			StateMachine:transition(States.IDLE)
			setProgress(0, "Grid generation failed")
			actionBtn.Text = "Start"
			return
		end

		local columns = buildColumns(chunkCenters, currentGameConfig.chunkSize)

		local p1Total = #chunkCenters
		local p2Total = 0
		for _, col in pairs(columns) do p2Total += #col end

		totalWorkItems = p1Total + p2Total
		globalDone = 0
		globalStartTime = tick()

		local originalFastWait = currentStrategy.fastWait
		local originalSkipPhase3 = currentStrategy.skipPhase3
		local originalSweepTween = currentStrategy.sweepTween

		if currentGameConfig.fastWait then
			currentStrategy.fastWait = currentGameConfig.fastWait
		end
		if currentGameConfig.skipPhase3 ~= nil then
			currentStrategy.skipPhase3 = currentGameConfig.skipPhase3
		end
		if currentGameConfig.sweepTween then
			currentStrategy.sweepTween = currentGameConfig.sweepTween
		end

		local success = executePhase1(chunkCenters)
		if not success then
			currentStrategy.fastWait = originalFastWait
			currentStrategy.skipPhase3 = originalSkipPhase3
			currentStrategy.sweepTween = originalSweepTween

			restoreCamera()
			running = false
			StateMachine:transition(States.IDLE)
			actionBtn.Text = "Start"
			setProgress(0, "Stopped")
			return
		end

		success = executePhase2(columns)
		if not success then
			currentStrategy.fastWait = originalFastWait
			currentStrategy.skipPhase3 = originalSkipPhase3
			currentStrategy.sweepTween = originalSweepTween
			restoreCamera()
			running = false
			StateMachine:transition(States.IDLE)
			actionBtn.Text = "Start"
			setProgress(0, "Stopped")
			return
		end

		currentStrategy.fastWait = originalFastWait
		currentStrategy.skipPhase3 = originalSkipPhase3
		currentStrategy.sweepTween = originalSweepTween

		if #failedChunksQueue > 0 then
			success = executeRetryPass()
			if not success then
				restoreCamera()
				running = false
				StateMachine:transition(States.IDLE)
				actionBtn.Text = "Start"
				setProgress(0, "Stopped")
				return
			end
		end

		local phaseElapsed = tick() - globalStartTime
		print(string.format("[MapLoader] Phases complete in %.1fs - starting roaming", phaseElapsed))

		executeRoaming(chunkCenters)

		restoreCamera()
		running = false
		StateMachine:transition(States.IDLE)
		actionBtn.Text = "Start"
		local elapsed = tick() - globalStartTime
		setProgress(1, string.format("Complete | %s", currentGameConfig.name))

		if not GameConfigs[GAME_ID] then
			currentGameConfig = nil
		end
		return
	end

	allParts = {}
	local streamSuccess = streamParts(function(batch)
		for _, part in ipairs(batch) do
			table.insert(allParts, part)
		end
	end)

	if not streamSuccess or #allParts == 0 then
		restoreCamera()
		running = false
		StateMachine:transition(States.IDLE)
		setProgress(0, "No parts found or stopped")
		actionBtn.Text = "Start"
		return
	end

	chunkSize = calculateOptimalChunkSize(allParts)
	chunkCenters = buildCenters(allParts, chunkSize)

	if #chunkCenters == 0 then
		restoreCamera()
		running = false
		StateMachine:transition(States.IDLE)
		setProgress(0, "No chunks generated")
		actionBtn.Text = "Start"
		return
	end

	local columns = buildColumns(chunkCenters, chunkSize)

	local p1Total = #chunkCenters
	local p2Total = 0
	for _, col in pairs(columns) do p2Total += #col end

	local p3Total = 0
	local phase3Centers, phase3Columns
	if not currentStrategy.skipPhase3 then
		phase3Centers = expandCenters(chunkCenters, PHASE3_SPACE_SCALE)
		phase3Columns = buildColumns(phase3Centers, chunkSize)
		for _, col in pairs(phase3Columns) do p3Total += #col end
	end

	totalWorkItems = p1Total + p2Total + p3Total
	globalDone = 0
	globalStartTime = tick()

	local success = executePhase1(chunkCenters)
	if not success then
		restoreCamera()
		running = false
		StateMachine:transition(States.IDLE)
		actionBtn.Text = "Start"
		setProgress(0, "Stopped")
		return
	end

	success = executePhase2(columns)
	if not success then
		restoreCamera()
		running = false
		StateMachine:transition(States.IDLE)
		actionBtn.Text = "Start"
		setProgress(0, "Stopped")
		return
	end

	if not currentStrategy.skipPhase3 then
		success = executePhase3(phase3Columns)
		if not success then
			restoreCamera()
			running = false
			StateMachine:transition(States.IDLE)
			actionBtn.Text = "Start"
			setProgress(0, "Stopped")
			return
		end
	end

	if #failedChunksQueue > 0 then
		success = executeRetryPass()
		if not success then
			restoreCamera()
			running = false
			StateMachine:transition(States.IDLE)
			actionBtn.Text = "Start"
			setProgress(0, "Stopped")
			return
		end
	end

	executeRoaming(chunkCenters)

	restoreCamera()
	running = false
	StateMachine:transition(States.IDLE)
	actionBtn.Text = "Start"
	setProgress(0, "Complete")
end

gui = Instance.new("ScreenGui", player.PlayerGui)
gui.Name = "MapLoaderPro"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 340, 0, 212)
frame.Position = UDim2.new(0.5, -170, 0.5, -107.5)
frame.BackgroundColor3 = Color3.fromHex("#151618")
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

local uiCorner = Instance.new("UICorner", frame)
uiCorner.CornerRadius = UDim.new(0, 0)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 36)
title.BackgroundColor3 = Color3.fromHex("#294a7a")
title.Text = currentGameConfig and ("MapLoader | " .. currentGameConfig.name) or "MapLoader"
title.Font = Enum.Font.BuilderSansExtraBold
title.TextSize = 18
title.TextColor3 = Color3.new(1, 1, 1)
title.TextXAlignment = Enum.TextXAlignment.Center
title.BorderSizePixel = 0

local titleCorner = Instance.new("UICorner", title)
titleCorner.CornerRadius = UDim.new(0, 0)

local minimize = Instance.new("TextButton", frame)
minimize.Size = UDim2.new(0, 36, 0, 36)
minimize.Position = UDim2.new(1, -36, 0, 0)
minimize.Text = "-"
minimize.Font = Enum.Font.BuilderSansExtraBold
minimize.TextSize = 24
minimize.TextColor3 = Color3.new(1, 1, 1)
minimize.BackgroundTransparency = 1
minimize.BorderSizePixel = 0

content = Instance.new("Frame", frame)
content.Position = UDim2.new(0, 0, 0, 36)
content.Size = UDim2.new(1, 0, 1, -36)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0

barBg = Instance.new("Frame", content)
barBg.Size = UDim2.new(0.9, 0, 0, 20)
barBg.Position = UDim2.new(0.05, 0, 0, 20)
barBg.BackgroundColor3 = Color3.fromHex("#1d2f49")
barBg.BorderSizePixel = 0

local barCorner = Instance.new("UICorner", barBg)
barCorner.CornerRadius = UDim.new(0, 0)

progressFill = Instance.new("Frame", barBg)
progressFill.Size = UDim2.new(0, 0, 1, 0)
progressFill.BackgroundColor3 = Color3.fromHex("#e6b32f")
progressFill.BorderSizePixel = 0

local fillCorner = Instance.new("UICorner", progressFill)
fillCorner.CornerRadius = UDim.new(0, 0)

progressText = Instance.new("TextLabel", barBg)
progressText.Size = UDim2.new(1, 0, 1, 0)
progressText.BackgroundTransparency = 1
progressText.Text = "Idle"
progressText.Font = Enum.Font.BuilderSansExtraBold
progressText.TextSize = 12
progressText.TextColor3 = Color3.new(1, 1, 1)
progressText.BorderSizePixel = 0

perfText = Instance.new("TextLabel", content)
perfText.Size = UDim2.new(0.9, 0, 0, 16)
perfText.Position = UDim2.new(0.05, 0, 0, 61)
perfText.BackgroundTransparency = 1
perfText.Text = "FPS: -- | MEM: --MB"
perfText.Font = Enum.Font.BuilderSansExtraBold
perfText.TextSize = 11
perfText.TextColor3 = Color3.fromHex("#ffffff")
perfText.TextXAlignment = Enum.TextXAlignment.Left
perfText.BorderSizePixel = 0

metricsText = Instance.new("TextLabel", content)
metricsText.Size = UDim2.new(0.9, 0, 0, 16)
metricsText.Position = UDim2.new(0.05, 0, 0, 44)
metricsText.BackgroundTransparency = 1
metricsText.Text = "Verified: 0 | Retries: 0 | Failed: 0 | Timeouts: 0"
metricsText.Font = Enum.Font.BuilderSansExtraBold
metricsText.TextSize = 11
metricsText.TextColor3 = Color3.fromHex("#ffffff")
metricsText.TextXAlignment = Enum.TextXAlignment.Left
metricsText.BorderSizePixel = 0

strategyBtn = Instance.new("TextButton", content)
strategyBtn.Size = UDim2.new(0.9, 0, 0, 32)
strategyBtn.Position = UDim2.new(0.05, 0, 0, 82)
strategyBtn.Text = "Strategy: " .. currentStrategy.name
strategyBtn.Font = Enum.Font.BuilderSansExtraBold
strategyBtn.TextSize = 13
strategyBtn.BackgroundColor3 = Color3.fromHex("#23456d")
strategyBtn.TextColor3 = Color3.new(1, 1, 1)
strategyBtn.BorderSizePixel = 0
strategyBtn.AutoButtonColor = false

local stratCorner = Instance.new("UICorner", strategyBtn)
stratCorner.CornerRadius = UDim.new(0, 0)

actionBtn = Instance.new("TextButton", content)
actionBtn.Size = UDim2.new(0.9, 0, 0, 32)
actionBtn.Position = UDim2.new(0.05, 0, 0, 122)
actionBtn.Text = "Start"
actionBtn.Font = Enum.Font.BuilderSansExtraBold
actionBtn.TextSize = 15
actionBtn.BackgroundColor3 = Color3.fromHex("#57993d")
actionBtn.TextColor3 = Color3.new(1, 1, 1)
actionBtn.BorderSizePixel = 0
actionBtn.AutoButtonColor = false

local actionCorner = Instance.new("UICorner", actionBtn)
actionCorner.CornerRadius = UDim.new(0, 0)

local BTN_ACTION_DEFAULT = Color3.fromHex("#57993d")
local BTN_ACTION_HOVER = Color3.fromHex("#5cb337")
local BTN_ACTION_DOWN = Color3.fromHex("#6bcd2b")

local BTN_STOP_DEFAULT = Color3.fromHex("#993d3d")
local BTN_STOP_HOVER = Color3.fromHex("#b33636")
local BTN_STOP_DOWN = Color3.fromHex("#cd362c")

local BTN_STRATEGY_DEFAULT = Color3.fromHex("#23456d")
local BTN_STRATEGY_HOVER = Color3.fromHex("#4296fa")
local BTN_STRATEGY_DOWN = Color3.fromHex("#1b87fa")

local actionHovering = false
local pauseHovering = false
local strategyHovering = false

actionBtn.MouseEnter:Connect(function()
	actionHovering = true
	if running then
		actionBtn.BackgroundColor3 = BTN_STOP_HOVER
	else
		actionBtn.BackgroundColor3 = BTN_ACTION_HOVER
	end
end)

actionBtn.MouseLeave:Connect(function()
	actionHovering = false
	if running then
		actionBtn.BackgroundColor3 = BTN_STOP_DEFAULT
	else
		actionBtn.BackgroundColor3 = BTN_ACTION_DEFAULT
	end
end)

strategyBtn.MouseEnter:Connect(function()
	strategyHovering = true
	strategyBtn.BackgroundColor3 = BTN_STRATEGY_HOVER
end)

strategyBtn.MouseLeave:Connect(function()
	strategyHovering = false
	strategyBtn.BackgroundColor3 = BTN_STRATEGY_DEFAULT
end)

actionBtn.MouseButton1Down:Connect(function()
    if running then
        actionBtn.BackgroundColor3 = BTN_STOP_DOWN
    else
        actionBtn.BackgroundColor3 = BTN_ACTION_DOWN
    end
end)
actionBtn.MouseButton1Up:Connect(function()
    if running then
        if actionHovering then
            actionBtn.BackgroundColor3 = BTN_STOP_HOVER
        else
            actionBtn.BackgroundColor3 = BTN_STOP_DEFAULT
        end
    else
        if actionHovering then
            actionBtn.BackgroundColor3 = BTN_ACTION_HOVER
        else
            actionBtn.BackgroundColor3 = BTN_ACTION_DEFAULT
        end
    end
end)

strategyBtn.MouseButton1Down:Connect(function()
    strategyBtn.BackgroundColor3 = BTN_STRATEGY_DOWN
end)
strategyBtn.MouseButton1Up:Connect(function()
    if strategyHovering then
        strategyBtn.BackgroundColor3 = BTN_STRATEGY_HOVER
    else
        strategyBtn.BackgroundColor3 = BTN_STRATEGY_DEFAULT
    end
end)

actionBtn.MouseButton1Click:Connect(function()
	if running then
		stopRequested = true
		StateMachine:transition(States.IDLE)
		restoreCamera()
		running = false
		actionBtn.Text = "Start"
		actionBtn.BackgroundColor3 = BTN_ACTION_DEFAULT
		setProgress(0, "Idle")
	else
		task.spawn(runLoader)
	end
end)

strategyBtn.MouseButton1Click:Connect(function()
	if running then return end

	if currentStrategy == LoadStrategies.SPEED then
		currentStrategy = LoadStrategies.BALANCED
		actionBtn.BackgroundColor3 = BTN_ACTION_DEFAULT
	elseif currentStrategy == LoadStrategies.BALANCED then
		currentStrategy = LoadStrategies.QUALITY
	else
		currentStrategy = LoadStrategies.SPEED
	end

	strategyBtn.Text = "Strategy: " .. currentStrategy.name
end)

minimize.MouseButton1Click:Connect(function()
	minimized = not minimized
	if minimized then
		savedFramePos = frame.Position
		content.Visible = false
		frame.Size = UDim2.new(0, 220, 0, 36)
		frame.Position = UDim2.new(0, 10, 1, -46)
	else
		content.Visible = true
		frame.Size = UDim2.new(0, 340, 0, 212)
		frame.Position = savedFramePos or frame.Position
	end
end)

task.spawn(function()
	while true do
		task.wait(0.5)
		if running then
			PerformanceTracker:sample()
		end
	end
end)

print("[MapLoader] Initialized | State:", StateMachine.current)