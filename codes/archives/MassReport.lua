getgenv().enabled = true
local reasons = {
    {category = "Bullying", comment = "called me fat/ugly"},
    {category = "Swearing", comment = "used bad/discriminating words"},
    {category = "Cheating", comment = "hacking/exploiting in the game"},
    {category = "Scamming", comment = "tried to scam my items"},
    {category = "Off-platform links", comment = "tried to direct me off platform to third party shops to buy items/robux"},
    {category = "Personal Information", comment = "threatened to leak my address online if i didn't follow their instructions"}
}

while getgenv().enabled do
    for i, v in pairs(game.Players:GetChildren()) do
        task.wait(0.03)
        if v.Name ~= game.Players.LocalPlayer.Name then
            local reason = reasons[math.random(1, #reasons)]
            game:GetService("Players"):ReportAbuse(v, reason.category, reason.comment)
            print("Successfully Reported " .. v.Name .. " for " .. reason.category)
        end
    end
end