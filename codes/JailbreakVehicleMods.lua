local Players = game:GetService("Players")
local player = Players.LocalPlayer

local NitroTables = {}
--local TireTables = {}

for _, v in pairs(getgc(true)) do
    if typeof(v) == "table" then
        if rawget(v, "Nitro") ~= nil then
            table.insert(NitroTables, v)
        end
        --[[
        if rawget(v, "TirePopDuration") ~= nil then
            table.insert(TireTables, v)
        end
        ]]
    end
end

local function applyVehicleMods()
    for _, v in ipairs(NitroTables) do
        if type(v.Nitro) == "number" and v.Nitro <= 1 then
            v.Nitro = 250
        end
    end

    --[[
    for _, v in ipairs(TireTables) do
        if v.TirePopDuration ~= 0 then
            v.TirePopDuration = 0
        end
    end
    ]]
end

applyVehicleMods()

task.spawn(function()
    while true do
        applyVehicleMods()
        task.wait(0)
    end
end)

player.CharacterAdded:Connect(function()
    task.wait(1)
    applyVehicleMods()
end)