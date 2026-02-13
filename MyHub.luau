if not game:IsLoaded() then
	game.Loaded:Wait()
end

local url = "https://raw.githubusercontent.com/RiseBlox/MyHub/main/codes/"
local ImGui = loadstring(game:HttpGet(url .. "ImGui.lua", true))()
local Window = ImGui:CreateWindow({
	Title = "MyHub V4 [ENHANCED]",
	Size = UDim2.fromOffset(435, 290),
	Position = UDim2.fromOffset(9,8),
	NoResize = true
})

local function sendNotification(text, duration, title)
	if game.PlaceId == 606849621 then
		require(game:GetService("ReplicatedStorage").Game.Notification).new({
			Text = text,
			Duration = duration
		})
	else
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = title,
			Text = text
		})
	end
end
sendNotification("Successfully loaded!", 2, "MyHub V4")

local utlTab = Window:CreateTab({
	Name = "Utilities"
})
Window:ShowTab(utlTab)
utlTab:Button({
	Text = "Infinite Yield",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source", true))()
		sendNotification("Successfully loaded!", 2, "Infinite Yield")
	end
})
utlTab:Button({
	Text = "UnnamedESP",
	Callback = function()
		loadstring(game:HttpGet(url .. "UnnamedESP.lua", true))()
		sendNotification("Successfully loaded!", 2, "UnnamedESP")
	end
})
utlTab:Button({
	Text = "WRD Aimbot",
	Callback = function()
		loadstring(game:HttpGet(url .. "WRDAimbot.lua", true))()
		sendNotification("Successfully enabled!", 2, "WRD Aimbot")
	end
})
utlTab:Button({
	Text = "CachedServerhop",
	Callback = function()
		sendNotification("Switching server...", 2, "CachedServerhop")
		loadstring(game:HttpGet("https://raw.githubusercontent.com/Cesare0328/my-scripts/main/CachedServerhop.lua", true))()
	end
})
utlTab:Separator({
	Text = "GPT"
})
utlTab:Button({
	Text = "AntiLag",
	Callback = function()
		loadstring(game:HttpGet(url .. "AntiLag.lua", true))()
		sendNotification("Successfully optimized!", 2, "Anti Lag")
	end
})
utlTab:Button({
	Text = "MapLoader",
	Callback = function()
		loadstring(game:HttpGet(url .. "MapLoader.lua", true))()
		sendNotification("Successfully loaded!", 2, "Map Loader")
	end
})
utlTab:Button({
	Text = "FlingAll",
	Callback = function()
		loadstring(game:HttpGet(url .. "FlingAll.lua", true))()
		sendNotification("Successfully started!", 2, "Fling All")
	end
})
utlTab:Button({
	Text = "InfSession",
	Callback = function()
		loadstring(game:HttpGet(url .. "InfSession.lua", true))()
		sendNotification("Successfully enabled!", 2, "Infinite Session")
	end
})
utlTab:Separator()
utlTab:Button({
	Text = "Hitbox Expander",
	Callback = function()
		loadstring(game:HttpGet(url .. "HitboxExpander.lua", true))()
		sendNotification("Successfully expanded!", 2, "Hitbox Expander")
	end
})
utlTab:Button({
	Text = "Freecam",
	Callback = function()
		loadstring(game:HttpGet(url .. "Freecam.lua", true))()
		sendNotification("Successfully enabled!", 2, "Freecam")
	end
})
utlTab:Button({
	Text = "Btools",
	Callback = function()
		local btools = workspace.CurrentCamera:Clone()
		btools:ClearAllChildren()
		workspace.CurrentCamera:Destroy()
		btools.Parent = workspace
		for i=2,4 do
			Instance.new("HopperBin", game:GetService'Players'.LocalPlayer.Backpack).BinType = i
		end
		sendNotification("Successfully added to inventory!", 2, "Btools")
	end
})
utlTab:Button({
	Text = "Kick yourself",
	Callback = function()
		game.Players.LocalPlayer:Kick("kicked")
	end
})
utlTab:Button({
	Text = "Console Dumper",
	Callback = function()
		loadstring(game:HttpGet(url .. "ConsoleDumper.lua", true))()
		sendNotification("Successfully dumped!", 2, "Console Dumper")
	end
})
utlTab:Separator({
	Text = "Explorers"
})
utlTab:Button({
	Text = "Dex++",
	Callback = function()
		loadstring(game:HttpGet("https://github.com/AZYsGithub/DexPlusPlus/releases/latest/download/out.lua", true))()
	end
})
utlTab:Button({
	Text = "Dex",
	Callback = function()
		loadstring(game:HttpGet(url .. "Dex.lua", true))()
	end
})
utlTab:Button({
	Text = "True Secure Dex",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/FaithfulAC/universal-stuff/main/true-secure-dex.lua"))()
	end
})
utlTab:Separator({
	Text = "UniversalSynSaveInstances"
})
utlTab:Button({
	Text = "Original",
	Callback = function()
		local synsaveinstance = loadstring(game:HttpGet(url .. "OriginalUSSI.luau", true), "saveinstance")()
		local Options = {
			ReadMe = false,
			SafeMode = true,
			ShutdownWhenDone = true,
			mode = "full",
			timeout = -1,
			SaveBytecode = true,
			DecompileIgnore = {},
			IgnoreList = {},
			TreatUnionsAsParts = true
		}
		sendNotification("Successfully started!", 2, "Original USSI")
		synsaveinstance(Options)
	end
})
utlTab:Button({
	Text = "Rewritten",
	Callback = function()
		local synsaveinstance = loadstring(game:HttpGet(url .. "RewrittenUSSI.luau", true), "saveinstance")()
		local Options = {
			usekonstantdecompiler = false,
			ReadMe = false,
			SafeMode = true,
			ShutdownWhenDone = true,
			mode = "full",
			timeout = -1,
			SaveBytecode = true,
			DecompileIgnore = {},
			IgnoreList = {},
			TreatUnionsAsParts = true
		}
		sendNotification("Successfully started!", 2, "Rewritten USSI")
		synsaveinstance(Options)
	end
})
utlTab:Button({
	Text = "Parallelized",
	Callback = function()
		local synsaveinstance = loadstring(game:HttpGet(url .. "ParallelizedUSSI.luau", true), "saveinstance")();
		local Options = {
			ReadMe = false,
			SafeMode = true,
			ShutdownWhenDone = true,
			mode = "full",
			timeout = -1,
			SaveBytecode = true,
			DecompileIgnore = {},
			IgnoreList = {},
			TreatUnionsAsParts = true
		}
		sendNotification("Successfully started!", 2, "Parallelized USSI")
		synsaveinstance(Options)
	end
})
utlTab:Button({
	Text = "Better",
	Callback = function()
		local synsaveinstance = loadstring(game:HttpGet(url .. "BetterUSSI.luau", true), "saveinstance")()
		local Options = {
			ReadMe = false,
			SafeMode = true,
			ShutdownWhenDone = true,
			mode = "full",
			decomptype = "custom",
			timeout = -1,
			SaveBytecode = true,
			DecompileIgnore = {},
			IgnoreList = {},
			TreatUnionsAsParts = true
		}
		sendNotification("Successfully started!", 2, "Better USSI")
		synsaveinstance(Options)
	end
})
utlTab:Separator({
	Text = "3D Rendering"
})
utlTab:Button({
	Text = "Enable",
	Callback = function()
		game:GetService("RunService"):Set3dRenderingEnabled(true)
	end
})
utlTab:Button({
	Text = "Disable",
	Callback = function()
		game:GetService("RunService"):Set3dRenderingEnabled(false)
	end
})
utlTab:Separator({
	Text = "Device Spoofers"
})
utlTab:Button({
	Text = "Spoof to Console",
	Callback = function()
		loadstring(game:HttpGet(url .. "DeviceSpooferConsole.lua", true))()
		sendNotification("Successfully spoofed as Console!", 2, "Spoof as Console")
	end
})
utlTab:Button({
	Text = "Spoof to Mobile",
	Callback = function()
		loadstring(game:HttpGet(url .. "DeviceSpooferAndroid.lua", true))()
		sendNotification("Successfully spoofed as Mobile!", 2, "Spoof as Mobile")
	end
})
utlTab:Separator()
utlTab:Button({
	Text = "MassReport",
	Callback = function()
		loadstring(game:HttpGet(url .. "MassReport.lua", true))()
		sendNotification("Successfully started!", 2, "Auto Report")
	end
})

local ideTab = Window:CreateTab({
	Name = "IDE Related"
})
ideTab:Separator({
	Text = "Functions Tests"
})
ideTab:Button({
	Text = "senS' Unified Naming Convention",
	Callback = function()
		getgenv().sUNCDebug = {
			["printcheckpoints"] = false,
			["delaybetweentests"] = 0
		}
		game.StarterGui:SetCore("SendNotification", {
			Text = "Successfully started!",
			Title = "sUNC"
		})
		loadstring(game:HttpGet("https://gitlab.com/sens3/nebunu/-/raw/main/HummingBird8's_sUNC_yes_i_moved_to_gitlab_because_my_github_acc_got_brickedd/sUNCm0m3n7.lua?ref_type=heads", true))()
	end
})
ideTab:Button({
	Text = "Myriad General Validity Test",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/Proton-Utilities/Myriad/refs/heads/main/dist.luau", true))()
		game.StarterGui:SetCore("SendNotification", {
			Text = "Successfully loaded!",
			Title = "Myriad"
		})
	end
})
ideTab:Button({
	Text = "Unified Naming Convention",
	Callback = function()
		loadstring(game:HttpGet(url .. "UnifiedNamingConvention.lua", true))()
		sendNotification("Successfully tested!", 2, "UNC")
	end
})
ideTab:Separator({
	Text = "Shitsploits Enhancers"
})
ideTab:Button({
	Text = "Vulnerabilities Patcher",
	Callback = function()
		loadstring(game:HttpGet(url .. "VulnerabilitiesPatcher.lua", true))()
		sendNotification("Successfully patched!", 2, "Vulnerabilities Patcher")
	end
})
ideTab:Button({
	Text = "Compatibility Provider",
	Callback = function()
		loadstring(game:HttpGet(url .. "CompatibilityProvider.lua", true))()
		sendNotification("Successfully provided!", 2, "Compatibility Provider")
	end
})
ideTab:Button({
	Text = "Functions Improver",
	Callback = function()
		loadstring(game:HttpGet(url .. "FunctionsImprover.lua", true))()
		sendNotification("Successfully improved!", 2, "Functions Improver")
	end
})

local jbTab = Window:CreateTab({
	Name = "Jailbreak"
})
jbTab:Separator({
	Text = "Independent Mods"
})
jbTab:Button({
	Text = "Infinite Nitro",
	Callback = function()
		loadstring(game:HttpGet(url .. "JailbreakVehicleMods.lua", true))()
		require(game:GetService("ReplicatedStorage").Game.Notification).new({
			Text = "Successfully enabled!",
			Duration = 2
		})
	end
})
jbTab:Button({
	Text = "Gun Mods",
	Callback = function()
		loadstring(game:HttpGet(url .. "JailbreakGunMods.lua", true))()
		require(game:GetService("ReplicatedStorage").Game.Notification).new({
			Text = "Successfully modded all guns!",
			Duration = 2
		})
	end
})
jbTab:Button({
	Text = "QoL Mods",
	Callback = function()
		loadstring(game:HttpGet(url .. "JailbreakQoLMods.lua", true))()
		require(game:GetService("ReplicatedStorage").Game.Notification).new({
			Text = "Successfully modded!",
			Duration = 2
		})
	end
})
jbTab:Button({
	Text = "Hypershift (Client-sided)",
	Callback = function()
		loadstring(game:HttpGet(url .. "JailbreakHypershift.lua", true))()
		require(game:GetService("ReplicatedStorage").Game.Notification).new({
			Text = "Successfully enabled Client-sided Hypershift!",
			Duration = 2
		})
	end
})
jbTab:Separator({
	Text = "Project Auto"
})
jbTab:Button({
	Text = "AutoRob",
	Callback = function()
		loadstring(game:HttpGet("https://scripts.projectauto.xyz/AutoRobV6", true))()
		require(game:GetService("ReplicatedStorage").Game.Notification).new({
			Text = "Successfully loaded Project Auto - Auto Rob!",
			Duration = 2
		})
	end
})
jbTab:Button({
	Text = "AutoArrest",
	Callback = function()
		loadstring(game:HttpGet("https://scripts.projectauto.xyz/AutoArrestV4", true))()
		require(game:GetService("ReplicatedStorage").Game.Notification).new({
			Text = "Successfully loaded Project Auto - Auto Arrest!",
			Duration = 2
		})
	end
})
jbTab:Separator()
jbTab:Button({
	Text = "Sensation",
	Callback = function()
		loadstring(game:HttpGet("https://api.luarmor.net/files/v3/loaders/730854e5b6499ee91deb1080e8e12ae3.lua", true))()
		require(game:GetService("ReplicatedStorage").Game.Notification).new({
			Text = "Successfully loaded Sensation!",
			Duration = 2
		})
	end
})
jbTab:Separator({
	Text = "Universal Farm"
})
jbTab:Button({
	Text = "AutoRob",
	Callback = function()
		loadstring(game:HttpGet("https://api.luarmor.net/files/v3/loaders/cf83df89dc364d86bafd481d72bdd953.lua", true))()
		require(game:GetService("ReplicatedStorage").Game.Notification).new({
			Text = "Successfully loaded Universal Farm - Auto Rob!",
			Duration = 2
		})
	end
})
jbTab:Button({
	Text = "AutoArrest",
	Callback = function()
		loadstring(game:HttpGet("https://api.luarmor.net/files/v3/loaders/ef2b75a1c0445997d44b7371f11ee88a.lua", true))()
		require(game:GetService("ReplicatedStorage").Game.Notification).new({
			Text = "Successfully loaded Universal Farm - Auto Arrest!",
			Duration = 2
		})
	end
})
jbTab:Separator()
jbTab:Button({
	Text = "Codecoat",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/Breadido/Codecoat/main/games/rewrite.luau", true))()
		require(game:GetService("ReplicatedStorage").Game.Notification).new({
			Text = "Successfully loaded Codecoat!",
			Duration = 2
		})
	end
})
local randTab = Window:CreateTab({
	Name = "Random"
})
randTab:Separator({
	Text = "Natural Disaster Survival"
})
randTab:Button({
	Text = "No Fall Damage",
	Callback = function()
		loadstring(game:HttpGet(url .. "NaturalDisasterSurvivalNoFallDamage.lua", true))()
		game.StarterGui:SetCore("SendNotification", {
			Text = "Successfully disabled!",
			Title = "No Fall Damage"
		})
	end
})
randTab:Separator({
	Text = "Arsenal"
})
randTab:Button({
	Text = "FELIPEHUB",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/FELIPEHUB1/Felipehub-scripts/main/Arsenal", true))()
		game.StarterGui:SetCore("SendNotification", {
			Text = "Successfully loaded!",
			Title = "FELIPEHUB"
		})
	end
})
randTab:Button({
	Text = "Thunder Client",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/andrewdarkyyofficial/thunderclient/main/main.lua", true))()
		game.StarterGui:SetCore("SendNotification", {
			Text = "Successfully loaded!",
			Title = "FELIPEHUB"
		})
	end
})
randTab:Separator({
	Text = "BedWars"
})
randTab:Button({
	Text = "VapeV4 (EOL)",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/7GrandDadPGN/VapeV4ForRoblox/main/NewMainScript.lua", true))()
		sendNotification("Successfully loaded!", 2, "VapeV4")
	end
})
randTab:Button({
	Text = "VapeVoidWare",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/VapeVoidware/VWRewrite/master/NewMainScript.lua", true))()
		sendNotification("Successfully loaded!", 2, "VoidWare")
	end
})
randTab:Button({
	Text = "CatVape",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/new-qwertyui/CatV5/main/init.lua", true), "init.lua")()
		sendNotification("Successfully loaded!", 2, "CatVape")
	end
})
randTab:Separator({
	Text = "Murder Mystery 2"
})
randTab:Button({
	Text = "Reveal Everyone",
	Callback = function()
		loadstring(game:HttpGet(url .. "MurderMystery2RevealEveryone.lua", true))()
		game.StarterGui:SetCore("SendNotification", {
			Text = "Successfully revealed!",
			Title = "Reveal Everyone"
		})
	end
})
randTab:Separator({
	Text = "Flick"
})
randTab:Button({
	Text = "NEVERLOSE",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/CludeHub/NEVERLOSE/main/NEVERLOSE-FLICK-V2.lua", true))()
		game.StarterGui:SetCore("SendNotification", {
			Text = "Successfully loaded!",
			Title = "NEVERLOSE"
		})
	end
})
randTab:Separator({
	Text = "Blind Shot"
})
randTab:Button({
	Text = "ClearShot",
	Callback = function()
		loadstring(game:HttpGet(url .. "ClearShot.lua", true))()
		game.StarterGui:SetCore("SendNotification", {
			Text = "Successfully loaded!",
			Title = "Clear Shot"
		})
	end
})
randTab:Separator({
	Text = "Prison Life"
})
randTab:Button({
	Text = "ULTRA HAX",
	Callback = function()
		loadstring(game:HttpGet(url .. "PrisonLifeULTRAHAX.lua", true))()
		game.StarterGui:SetCore("SendNotification", {
			Text = "Successfully loaded!",
			Title = "ULTRA HAX"
		})
	end
})
randTab:Button({
	Text = "Silent Aim & ESP",
	Callback = function()
		loadstring(game:HttpGet(url .. "PrisonLifeSilentAimESP.lua", true))()
		game.StarterGui:SetCore("SendNotification", {
			Text = "Successfully loaded!",
			Title = "Silent Aim + ESP"
		})
	end
})
randTab:Separator({
	Text = "LUCKY BLOCKS Battlegrounds"
})
randTab:Button({
	Text = "Items Giver",
	Callback = function()
		item = 1
		while item <= 10 do
			game:GetService("ReplicatedStorage"):WaitForChild("SpawnLuckyBlock"):FireServer()
			item = item + 1
		end
		game.StarterGui:SetCore("SendNotification", {
			Text = "Successfully gave 10 items!",
			Title = "Items Giver"
		})
	end
})
randTab:Separator({
	Text = "Ink Game"
})
randTab:Button({
	Text = "VoidWare",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/VapeVoidware/VW-Add/main/inkgame.lua", true))()
		game.StarterGui:SetCore("SendNotification", {
			Text = "Successfully loaded!",
			Title = "Voidware"
		})
	end
})
randTab:Button({
	Text = "Speed Hax",
	Callback = function()
		getgenv().speed = 69
		game:GetService("Players").LocalPlayer.Boosts["Faster Sprint"].Value = speed
		game.StarterGui:SetCore("SendNotification", {
			Text = "Successfully enabled!",
			Title = "Speed Hax"
		})
	end
})
randTab:Separator({
	Text = "Bee Swarm Simulator"
})
randTab:Button({
	Text = "Atlas",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/Chris12089/atlasbss/main/script.lua", true))()
		game.StarterGui:SetCore("SendNotification", {
			Text = "Successfully loaded!",
			Title = "Atlas"
		})
	end
})
randTab:Separator({
	Text = "Rivals (DETECTED)"
})
randTab:Button({
	Text = "Duck Hub",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/HexFG/duckhub/main/loader.lua", true))()
		game.StarterGui:SetCore("SendNotification", {
			Text = "Successfully loaded!",
			Title = "Duck Hub"
		})
	end
})
randTab:Button({
	Text = "Silent Aim",
	Callback = function()
		loadstring(game:HttpGet(url .. "RivalsSilentAim.lua", true))()
		game.StarterGui:SetCore("SendNotification", {
			Text = "Successfully loaded!",
			Title = "Silent Aim"
		})
	end
})
randTab:Button({
	Text = "Gun Mods",
	Callback = function()
		loadstring(game:HttpGet(url .. "RivalsGunMods.lua", true))()
		game.StarterGui:SetCore("SendNotification", {
			Text = "Successfully modded!",
			Title = "Gun Mods"
		})
	end
})
local funTab = Window:CreateTab({
	Name = "Fun"
})
funTab:Button({
	Text = "Fake sUNC (OLD)",
	Callback = function()
		loadstring(game:HttpGet(url .. "FakeSUNC.lua", true))()
		game.StarterGui:SetCore("SendNotification", {
			Text = "Successfully faked!",
			Title = "Fake sUNC (OLD)"
		})
	end
})
funTab:Button({
	Text = "Fake UNC",
	Callback = function()
		loadstring(game:HttpGet(url .. "FakeUNC.lua", true))()
		game.StarterGui:SetCore("SendNotification", {
			Text = "Successfully faked!",
			Title = "Fake UNC"
		})
	end
})