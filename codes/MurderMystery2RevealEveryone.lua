local function RunChams()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")

    local LocalPlayer = Players.LocalPlayer

    local TOOL_COLORS = {
        Gun = { fill = Color3.fromRGB(0, 0, 255), outline = Color3.fromRGB(0, 0, 128) },
        Knife = { fill = Color3.fromRGB(255, 0, 0), outline = Color3.fromRGB(128, 0, 0) },
    }
    local DEFAULT_COLORS = { fill = Color3.fromRGB(0, 255, 0), outline = Color3.fromRGB(0, 128, 0) }

    do
        local CHAM_TAG = "__ChamSystem"

        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            if player.Character then
                local h = player.Character:FindFirstChildOfClass("Highlight")
                if h then h:Destroy() end
            end
        end

        local prev = RunService:FindFirstChild(CHAM_TAG)
        if prev then prev:Fire() end

        local killSignal = Instance.new("BindableEvent")
        killSignal.Name = CHAM_TAG
        killSignal.Parent = RunService
    end

    local function applyHighlight(character, colors)
        local highlight = character:FindFirstChildOfClass("Highlight")
        if not highlight then
            highlight = Instance.new("Highlight")
            highlight.Adornee = character
            highlight.Parent = character
        end

        highlight.FillColor = colors.fill
        highlight.OutlineColor = colors.outline
        highlight.FillTransparency = 0.75
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    end

    local function resolveColors(player)
        if player.Backpack then
            for _, obj in ipairs(player.Backpack:GetChildren()) do
                if obj:IsA("Tool") and TOOL_COLORS[obj.Name] then
                    return TOOL_COLORS[obj.Name]
                end
            end
        end
        if player.Character then
            for _, obj in ipairs(player.Character:GetChildren()) do
                if obj:IsA("Tool") and TOOL_COLORS[obj.Name] then
                    return TOOL_COLORS[obj.Name]
                end
            end
        end
        return DEFAULT_COLORS
    end

    local function refreshChams(player)
        local character = player.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end
        applyHighlight(character, resolveColors(player))
    end

    local playerConnections = {}
    local masterConnections = {}

    local function cleanupPlayer(player)
        if playerConnections[player] then
            for _, c in ipairs(playerConnections[player]) do
                if c.Connected then c:Disconnect() end
            end
            playerConnections[player] = nil
        end
        if player.Character then
            local h = player.Character:FindFirstChildOfClass("Highlight")
            if h then h:Destroy() end
        end
    end

    local function teardownAll()
        for player in pairs(playerConnections) do
            cleanupPlayer(player)
        end
        for _, c in ipairs(masterConnections) do
            if c.Connected then c:Disconnect() end
        end
        masterConnections = {}
        playerConnections = {}
    end

    local function waitForCharacterReady(character)
        character:WaitForChild("HumanoidRootPart", 10)
        character:WaitForChild("Humanoid", 10)
        character:WaitForChild("Head", 10)

        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return false end

        if humanoid:GetState() == Enum.HumanoidStateType.Dead
        or humanoid:GetState() == Enum.HumanoidStateType.None then
            local ready = false
            local conn
            conn = humanoid.StateChanged:Connect(function(_, new)
                if new ~= Enum.HumanoidStateType.Dead
                and new ~= Enum.HumanoidStateType.None then
                    ready = true
                    conn:Disconnect()
                end
            end)
            local t = 0
            while not ready and t < 6 do
                task.wait(0.1)
                t += 0.1
            end
            if not ready then return false end
        end

        return true
    end

    local function setupPlayer(player)
        if player == LocalPlayer then return end

        cleanupPlayer(player)
        playerConnections[player] = {}

        local function onCharacterAdded(character)
            for _, c in ipairs(playerConnections[player]) do
                if c.Connected then c:Disconnect() end
            end
            playerConnections[player] = {}

            task.spawn(function()
                local ok = waitForCharacterReady(character)
                if not ok then return end
                if player.Character ~= character then return end

                refreshChams(player)

                local backpack = player.Backpack
                local function onChange(child)
                    if child:IsA("Tool") then refreshChams(player) end
                end

                table.insert(playerConnections[player], backpack.ChildAdded:Connect(onChange))
                table.insert(playerConnections[player], backpack.ChildRemoved:Connect(onChange))
                table.insert(playerConnections[player], character.ChildAdded:Connect(onChange))
                table.insert(playerConnections[player], character.ChildRemoved:Connect(onChange))
            end)
        end

        table.insert(playerConnections[player],
            player.CharacterAdded:Connect(onCharacterAdded)
        )

        if player.Character then
            task.spawn(onCharacterAdded, player.Character)
        end
    end

    local killSignal = RunService:FindFirstChild("__ChamSystem")
    if killSignal then
        table.insert(masterConnections, killSignal.Event:Connect(teardownAll))
    end

    for _, player in ipairs(Players:GetPlayers()) do
        setupPlayer(player)
    end

    table.insert(masterConnections, Players.PlayerAdded:Connect(setupPlayer))
    table.insert(masterConnections, Players.PlayerRemoving:Connect(cleanupPlayer))

	local HEARTBEAT_INTERVAL = 3
	local lastCheck = 0

	table.insert(masterConnections,
		RunService.Heartbeat:Connect(function()
			local now = tick()
			if now - lastCheck < HEARTBEAT_INTERVAL then return end
			lastCheck = now

			for _, player in ipairs(Players:GetPlayers()) do
				if player == LocalPlayer then continue end
				local character = player.Character
				if not character then continue end
				if not character:FindFirstChild("HumanoidRootPart") then continue end

				local highlight = character:FindFirstChildOfClass("Highlight")
				if not highlight or highlight.Adornee ~= character then
					refreshChams(player)
				end
			end
		end)
	)

    table.insert(masterConnections,
        LocalPlayer.CharacterAdded:Connect(function()
            teardownAll()
            task.delay(0.5, RunChams)
        end)
    )
end

RunChams()