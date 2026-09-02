-- ==============================================================================
-- ⚙️ HipHub Settings — Jump for Animals! Configuration & Profile Manager
-- ==============================================================================

local success, err = pcall(function()
	local env = (getgenv and getgenv()) or _G
	local UI = env.HipHubUI or _G.HipHubUI
	if not UI then return end

	local HttpService = game:GetService("HttpService")
	local UserInputService = game:GetService("UserInputService")
	local Lighting = game:GetService("Lighting")
	local Players = game:GetService("Players")
	local player = Players.LocalPlayer

	local CONFIG_FILE = "HipHub/jfa_config.json"
	if isfile and not isfile(CONFIG_FILE) and isfile("jfa_config.json") then
		CONFIG_FILE = "jfa_config.json"
	end

	-- Default Configuration Schema for Jump for Animals
	local Config = {
		UI = {
			Title = "Jump for Animals!",
			ToggleKey = "RightShift"
		},
		Training = {
			AutoSquat = false,
			AutoSquatBonus = false,
			AutoUpgradeBarbell = false
		},
		Farming = {
			AutoStealEggs = false,
			SelectedStage = "All",
			SelectedAnimal = "All",
			AutoPlaceEggs = false,
			AutoHatchEggs = false,
			AutoEquipBest = false,
			AutoUpgradePen = false,
			AutoSellPets = false
		},
		Shops = {
			AutoBuyTrails = false,
			AutoBuyCoils = false,
			AutoGoldMutation = false,
			AutoClaimIndex = false,
			AutoClaimOffline = false,
			AutoClaimGroup = false
		},
		Defense = {
			DisableGuards = false,
			AntiEggDrop = false
		},
		Movement = {
			WalkSpeed = 16,
			SpeedEnabled = false,
			JumpPower = 50,
			JumpEnabled = false,
			InfiniteJump = false,
			FlyEnabled = false,
			FlySpeed = 50,
			Noclip = false
		},
		Visuals = {
			EggESP = false,
			GuardESP = false,
			PlayerESP = false,
			PlotESP = false
		},
		Settings = {
			autoSave = true,
			antiAfk = true,
			lowGraphics = false,
			capFps = 60
		}
	}

	-- Load saved config if available
	local function loadConfig()
		if readfile and isfile and isfile(CONFIG_FILE) then
			pcall(function()
				local raw = readfile(CONFIG_FILE)
				local decoded = HttpService:JSONDecode(raw)
				if decoded then
					for category, items in pairs(decoded) do
						if Config[category] then
							for k, v in pairs(items) do
								Config[category][k] = v
							end
						else
							Config[category] = items
						end
					end
				end
			end)
		end
	end

	local function saveConfig()
		if writefile then
			pcall(function()
				if makefolder then pcall(makefolder, "HipHub") end
				local encoded = HttpService:JSONEncode(Config)
				writefile(CONFIG_FILE, encoded)
			end)
		end
	end

	loadConfig()
	env.HipHubConfig = Config
	_G.HipHubConfig = Config
	if shared then shared.HipHubConfig = Config end
	env.HipHubSaveConfig = saveConfig
	_G.HipHubSaveConfig = saveConfig
	if shared then shared.HipHubSaveConfig = saveConfig end

	------------------------------------------------
	-- 🎨 BUILD SETTINGS TAB UI
	------------------------------------------------
	local settingsFrame = UI.tabs["Settings"] and UI.tabs["Settings"].Frame
	if not settingsFrame then return end

	-- 1. Configuration Profile Section
	local configSec = UI.AddSection(settingsFrame, "Configuration Management", 1)
	UI.AddButton(configSec, "💾 Save Configuration", function()
		saveConfig()
		pcall(function()
			game:GetService("StarterGui"):SetCore("SendNotification", {
				Title = "HipHub JFA",
				Text = "Configuration saved successfully!",
				Duration = 3
			})
		end)
	end, 1)

	UI.AddButton(configSec, "🔄 Reload Configuration", function()
		loadConfig()
		pcall(function()
			game:GetService("StarterGui"):SetCore("SendNotification", {
				Title = "HipHub JFA",
				Text = "Configuration reloaded!",
				Duration = 3
			})
		end)
	end, 2)

	UI.AddButton(configSec, "⚠️ Reset to Defaults", function()
		if readfile and isfile and isfile(CONFIG_FILE) and delfile then
			delfile(CONFIG_FILE)
		end
		pcall(function()
			game:GetService("StarterGui"):SetCore("SendNotification", {
				Title = "HipHub JFA",
				Text = "Settings reset. Rejoin or re-execute to restore defaults.",
				Duration = 4
			})
		end)
	end, 3, true)

	-- 2. Performance & Utilities Section
	local perfSec = UI.AddSection(settingsFrame, "Performance & Utilities", 2)

	UI.AddToggle(perfSec, "🛡️ Anti-AFK Disconnect Protection", Config.Settings.antiAfk ~= false, function(v)
		Config.Settings.antiAfk = v
		local Features = _G.HipHubFeatures
		if Features then Features.State.AntiAfk = v end
		saveConfig()
	end, 1)

	UI.AddToggle(perfSec, "⚡ Low Graphics Mode (FPS Booster)", Config.Settings.lowGraphics or false, function(v)
		Config.Settings.lowGraphics = v
		local Features = _G.HipHubFeatures
		if Features and Features.SetLowGraphics then
			Features.SetLowGraphics(v)
		end
		saveConfig()
	end, 2)

	UI.AddSlider(perfSec, "Target FPS Limit", 30, 240, Config.Settings.capFps or 60, function(v)
		Config.Settings.capFps = v
		if setfpscap then
			setfpscap(v)
		end
		saveConfig()
	end, 3, " FPS")

	-- 3. UI Keybinds & Customization Section
	local uiSec = UI.AddSection(settingsFrame, "Interface Settings", 3)

	UI.AddDropdown(uiSec, "Menu Toggle Keybind", { "RightShift", "RightControl", "Insert", "Delete", "F4", "F8" }, Config.UI.ToggleKey or "RightShift", function(v)
		Config.UI.ToggleKey = v
		saveConfig()
	end, 1)

	print("[HipHub JFA Settings] Config manager loaded.")
end)

if not success then
	warn("[HipHub JFA Settings Error]: " .. tostring(err))
end
