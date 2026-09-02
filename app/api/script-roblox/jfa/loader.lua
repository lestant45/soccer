-- ==============================================================================
-- 🐾 HipHub — Local Development Loader (Jump for Animals!)
-- ==============================================================================
local MODULE_FILES = {
	"ui.lua",
	"features.lua",
	"settings.lua",
	"main.lua"
}

local function debugLog(message)
	print("[HipHub JFA Loader] " .. tostring(message))
end

local function loadScriptFile(fileName)
	if not readfile then
		error("Your executor does not support 'readfile'. Please run the bundled script directly.")
	end

	if isfile and not isfile(fileName) then
		error("Could not find '" .. fileName .. "' in your executor's workspace folder.")
	end

	debugLog("Loading " .. fileName .. "...")
	local content = readfile(fileName)
	local func, err = loadstring(content, "@" .. fileName)
	if not func then
		error("Failed to compile " .. fileName .. ": " .. tostring(err))
	end

	task.spawn(func)
	debugLog("Successfully executed " .. fileName)
end

local function loadAll()
	for _, file in ipairs(MODULE_FILES) do
		local success, err = pcall(loadScriptFile, file)
		if not success then
			warn("[HipHub JFA Loader Error] Failed to load " .. file .. ": " .. tostring(err))
		end
		task.wait(0.1)
	end
end

local success, err = pcall(loadAll)
if not success then
	warn("[HipHub JFA Loader Boot Error]: " .. tostring(err))
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = "HipHub JFA Loader Error",
			Text = tostring(err),
			Duration = 10,
		})
	end)
end
