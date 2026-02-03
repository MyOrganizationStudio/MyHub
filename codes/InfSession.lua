pcall(function()
    local Players = game:GetService("Players")
    local TeleportService = game:GetService("TeleportService")
    local GuiService = game:GetService("GuiService")
    local VirtualUser = game:GetService("VirtualUser")
    
    local function initializeProtections()
        if not game:IsLoaded() then
            game.Loaded:Wait()
        end

        if not Players.LocalPlayer then
            Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
        end
        
        local LocalPlayer = Players.LocalPlayer

        if not hookmetamethod then
            return
        end
        
        if hookfunction then
            hookfunction(LocalPlayer.Kick, function() end)
        end

        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            if self == LocalPlayer and getnamecallmethod():lower() == "kick" then
                return
            end
            return oldNamecall(self, ...)
        end)
        
        local oldIndex
        oldIndex = hookmetamethod(game, "__index", function(self, key)
            if self == LocalPlayer and key:lower() == "kick" then
                return error("Expected ':' not '.' calling member function Kick", 2)
            end
            return oldIndex(self, key)
        end)

        local GC = getconnections or get_signal_cons
        if GC then
            local connections = GC(LocalPlayer.Idled)
            if connections then
                for _, v in pairs(connections) do
                    if v.Disable then
                        v:Disable()
                    elseif v.Disconnect then
                        v:Disconnect()
                    end
                end
            end
        else
            LocalPlayer.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end

        GuiService.ErrorMessageChanged:Connect(function()
            local PlaceId = game.PlaceId
            local JobId = game.JobId
            local playerCount = #Players:GetPlayers()
            
            task.wait(0.5)
            
            if playerCount <= 1 then
                TeleportService:Teleport(PlaceId, LocalPlayer)
            else
                TeleportService:TeleportToPlaceInstance(PlaceId, JobId, LocalPlayer)
            end
        end)
    end
    
    Players.LocalPlayer.OnTeleport:Connect(function(state)
        if state == Enum.TeleportState.InProgress then
            Players.LocalPlayer.OnTeleport:Connect(function(s2)
                if s2 == Enum.TeleportState.Completed then
                    initializeProtections()
                end
            end)
        end
    end)
    
    initializeProtections()
end)