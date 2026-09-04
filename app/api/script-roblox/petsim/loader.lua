-- ==============================================================================
-- 🐾 HipHub — Local Development Loader (Pet Simulator 99)
-- ==============================================================================
local MODULE_FILES = {
	"ui.lua",
	"settings.lua",
	"features.lua",
	"main.lua"
}

local function debugLog(message)
	print("[HipHub PS99 Loader] " .. tostring(message))
end

local function loadScriptFile(fileName)
	if not readfile then
		error("Your executor does not support 'readfile'. Please run the bundled script directly.")
	end

	if isfile and not isfile(fileName) then
		error("Could not find '" .. fileName .. "' in your executor's workspace folder.")
	end

	debugLog("Reading " .. fileName .. "...")
	return readfile(fileName)
end

local function loadAll()
	local chunks = {}
	for _, file in ipairs(MODULE_FILES) do
		local content = loadScriptFile(file)
		if file == "ui.lua" or file == "settings.lua" then
			table.insert(chunks, "do\n" .. content .. "\nend")
		else
			table.insert(chunks, content)
		end
		debugLog("Loaded " .. file)
	end

	local fullCode = table.concat(chunks, "\n\n")
	debugLog("Compiling bundled HipHub Pet Simulator 99...")
	local func, err = loadstring(fullCode, "@HipHub_PS99_Bundled")
	if not func then
		error("Compilation failed: " .. tostring(err))
	end

	task.spawn(func)
	debugLog("HipHub PS99 Successfully Started!")
end

local success, err = pcall(loadAll)
if not success then
	warn("[HipHub PS99 Loader Error]: " .. tostring(err))
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = "HipHub PS99 Loader Error",
			Text = tostring(err),
			Duration = 10,
		})
	end)
end
