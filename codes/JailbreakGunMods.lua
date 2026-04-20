local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local ItemConfig = ReplicatedStorage:WaitForChild("Game"):WaitForChild("ItemConfig")

local modified = {}

local function applyGunMods()
    for _, module in ipairs(ItemConfig:GetChildren()) do
        if module:IsA("ModuleScript") and not modified[module] then
            local ok, gun = pcall(require, module)
            if ok and typeof(gun) == "table" then

                local freq = rawget(gun, "FireFreq")
                if type(freq) == "number" and freq < 6 then
                    gun.FireFreq = 6
                end

                if rawget(gun, "FireAuto") ~= nil then
                    gun.FireAuto = true
                end

                if rawget(gun, "CamShakeMagnitude") ~= nil then
                    gun.CamShakeMagnitude = 0
                end

                if rawget(gun, "BulletSpread") ~= nil then
                    gun.BulletSpread = 0
                end

                --[[
                if rawget(gun, "ReloadTime") ~= nil then
                    gun.ReloadTime = 0
                end
                ]]

                modified[module] = true
            end
        end
    end
end

applyGunMods()