local P,RS=game:GetService("Players"),game:GetService("ReplicatedStorage")
local plr=P.LocalPlayer
local c=plr.Character or plr.CharacterAdded:Wait()
local r,h=c:WaitForChild("HumanoidRootPart",5),c:WaitForChild("Humanoid",5)
local V=require(RS.Vehicle.VehicleUtils)
local chrome="HyperShift"

plr.CharacterAdded:Connect(function(char) c,r,h=char,char:WaitForChild("HumanoidRootPart",5),char:WaitForChild("Humanoid",5) end)

spawn(function()
    while true do
        local v=V.GetLocalVehiclePacket() and V.GetLocalVehicleModel()
        if v then
            v:SetAttribute("HyperChromeAppliedName",chrome)
            for _,p in pairs(v:GetDescendants()) do
                if p:IsA("BasePart") or p:IsA("MeshPart") then p:SetAttribute("HyperChromeAppliedName",chrome) end
            end
        end
        wait(1)
    end
end)