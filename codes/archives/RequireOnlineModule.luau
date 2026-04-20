local RequireCache = {} -- Store required ModuleScripts for further use (ModuleScript persistance).

-- Fake Require func
local function ARequire(ModuleScript)
	local Cached = RequireCache[ModuleScript]
	if Cached then -- If module is already loaded, return it.
		return unpack(Cached)
	end

	local Source = ModuleScript.Source
	local LoadedSource = loadstring(Source)
	local fenv = getfenv(LoadedSource) -- Fake environment

	fenv.script = ModuleScript -- Set script variable.
	fenv.require = ARequire -- Overwrite require so it can require other modulescripts and so forth.

	local Output = { LoadedSource() } -- Execute the module

	RequireCache[ModuleScript] = Output -- Store module in cache for further use.

	return unpack(Output) -- Return the result to the executor
end

local function ARequireController(AssetId)
	local ModuleScript = game:GetObjects("rbxassetid://" .. AssetId)[1]

	return ARequire(ModuleScript)
end

return ARequireController