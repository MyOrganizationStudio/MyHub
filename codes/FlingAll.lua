local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer
local cam = workspace.CurrentCamera

local SPIN_Y = 99999
local SPIN_XZ = 45000

local MAGNET_SPEED = 800
local LEAD_TIME = 0.18

local CONTACT_RADIUS = 8
local CONTACT_TIME = 1.1
local STEP = 0.03

local IMPACT_SPIKE = 1200
local IMPACT_DECAY = 0.12

local JUMP_PUNISH_Y = 90

local SNAP_DISTANCE = 14
local SNAP_OFFSET = 3
local SNAP_COOLDOWN = 0.12

local MAX_VELOCITY = 900
local MAX_DISTANCE = 2500
local MAP_CENTER = Vector3.new(0, 20, 0)

local SPECTATE_SWITCH_DELAY = 0.6

local char, hum, hrp
local bav, linVel, linAttach

local viewingPlayer
local viewDied, viewChanged

local function setupCharacter(c)
	char = c
	hum = c:WaitForChild("Humanoid")
	hrp = c:WaitForChild("HumanoidRootPart")

	for _, v in pairs(c:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CanCollide = false
			v.Massless = true
			v.CustomPhysicalProperties = PhysicalProperties.new(100, 0.3, 0.5)
		end
	end
end

local function clearSpectate()
	if viewDied then viewDied:Disconnect() end
	if viewChanged then viewChanged:Disconnect() end
	viewDied, viewChanged = nil, nil
	viewingPlayer = nil
	cam.CameraSubject = hum
end

local function spectatePlayer(plr)
	if viewingPlayer == plr then return end
	clearSpectate()
	viewingPlayer = plr
	if not plr.Character then return end
	cam.CameraSubject = plr.Character

	viewDied = plr.CharacterAdded:Connect(function()
		repeat task.wait() until plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
		cam.CameraSubject = plr.Character
	end)

	viewChanged = cam:GetPropertyChangedSignal("CameraSubject"):Connect(function()
		if viewingPlayer == plr and plr.Character then
			cam.CameraSubject = plr.Character
		end
	end)
end

local function startSpin()
	if bav then bav:Destroy() end
	bav = Instance.new("BodyAngularVelocity")
	bav.Parent = hrp
	bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
	bav.P = math.huge

	task.spawn(function()
		while hum.Health > 0 do
			bav.AngularVelocity = Vector3.new(
				math.random(-SPIN_XZ, SPIN_XZ),
				SPIN_Y,
				math.random(-SPIN_XZ, SPIN_XZ)
			)
			RunService.Heartbeat:Wait()
		end
	end)
end

local function buildMagnet()
	if linVel then linVel:Destroy() end
	linAttach = Instance.new("Attachment", hrp)
	linVel = Instance.new("LinearVelocity")
	linVel.Parent = hrp
	linVel.Attachment0 = linAttach
	linVel.MaxForce = math.huge
	linVel.RelativeTo = Enum.ActuatorRelativeTo.World
end

local function getLeadPosition(thrp)
	local vel = thrp.AssemblyLinearVelocity
	return thrp.Position + vel * LEAD_TIME
end

local function magnetizePredictive(thrp, speed)
	if not thrp or not thrp.Parent then return end
	local aim = getLeadPosition(thrp)
	local dir = aim - hrp.Position
	if dir.Magnitude < 1 then return end
	linVel.VectorVelocity = dir.Unit * speed
end

local function stopMagnet()
	if linVel then linVel.VectorVelocity = Vector3.zero end
end

local function clampVelocity()
	if hrp.Velocity.Magnitude > MAX_VELOCITY then
		hrp.Velocity = hrp.Velocity.Unit * MAX_VELOCITY
	end
end

local function targetValid(thrp)
	return thrp and thrp.Parent and (thrp.Position - hrp.Position).Magnitude < 2000
end

RunService.Heartbeat:Connect(function()
	if not hrp then return end
	if (hrp.Position - MAP_CENTER).Magnitude > MAX_DISTANCE then
		stopMagnet()
		hrp.Velocity = Vector3.zero
		hrp.CFrame = CFrame.new(MAP_CENTER)
	end
	clampVelocity()
end)

local lastSnap = 0
local function microSnapToward(thrp)
	if os.clock() - lastSnap < SNAP_COOLDOWN then return end
	lastSnap = os.clock()

	local dir = (thrp.Position - hrp.Position)
	if dir.Magnitude <= SNAP_DISTANCE then
		hrp.CFrame = CFrame.new(thrp.Position - dir.Unit * SNAP_OFFSET)
	end
end

task.spawn(function()
	while true do
		if not hum or hum.Health <= 0 then
			clearSpectate()
			task.wait(0.1)
			continue
		end

		for _, plr in pairs(Players:GetPlayers()) do
			if plr ~= lp and plr.Character then
				local thrp = plr.Character:FindFirstChild("HumanoidRootPart")
				local thum = plr.Character:FindFirstChildOfClass("Humanoid")
				if not (thrp and thum and thum.Health > 0) then continue end

				spectatePlayer(plr)

				while hum.Health > 0 and targetValid(thrp) do
					if (hrp.Position - thrp.Position).Magnitude <= CONTACT_RADIUS then break end
					magnetizePredictive(thrp, MAGNET_SPEED)
					task.wait(STEP)
				end

				if not targetValid(thrp) then
					stopMagnet()
					hrp.Velocity *= 0.25
					task.wait(SPECTATE_SWITCH_DELAY)
					continue
				end

				local dir = (thrp.Position - hrp.Position).Unit
				hrp.Velocity = dir * IMPACT_SPIKE + Vector3.new(0, JUMP_PUNISH_Y, 0)
				clampVelocity()
				task.wait(IMPACT_DECAY)

				local t0 = os.clock()
				while hum.Health > 0 and targetValid(thrp)
					and os.clock() - t0 < CONTACT_TIME do
					magnetizePredictive(thrp, MAGNET_SPEED)
					microSnapToward(thrp)
					task.wait(STEP)
				end

				stopMagnet()
				hrp.Velocity *= 0.15
				task.wait(SPECTATE_SWITCH_DELAY)
			end
		end

		clearSpectate()
		task.wait(0.05)
	end
end)

setupCharacter(lp.Character or lp.CharacterAdded:Wait())
buildMagnet()
startSpin()

RunService.Stepped:Connect(function()
	if char then
		for _, v in pairs(char:GetChildren()) do
			if v:IsA("BasePart") then v.CanCollide = false end
		end
	end
end)

lp.CharacterAdded:Connect(function(c)
	task.wait(0.1)
	clearSpectate()
	setupCharacter(c)
	buildMagnet()
	startSpin()
end)