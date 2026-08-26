-- ==============================================================================
-- ⚙️ HipHub — Settings & Configuration Manager (Jump To Steal Soccer Players)
-- ==============================================================================
local success, err = pcall(function()
	local UI = _G.HipHubUI
	if not UI then return end

	local HttpService = game:GetService("HttpService")
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local Lighting = game:GetService("Lighting")
	local Players = game:GetService("Players")
	local player = Players.LocalPlayer

	local CONFIG_FILE = "HipHub/soccer_config.json"
	if isfile and not isfile(CONFIG_FILE) and isfile("soccer_config.json") then
		CONFIG_FILE = "soccer_config.json"
	end

	-- Default Configuration Schema for Soccer Game
	local Config = {
		UI = {
			Title = "Jump To Steal Soccer Players",
			ToggleKey = "RightShift"
		},
		Farm = {
			AutoCollectLuckyBlock = false,
			FilterRarity = "All",
			FilterMutation = "All",
			AutoCollectEarnings = false,
			AutoPlaceOpenLuckyBlock = false,
			AutoPickupAllPlayers = false,
			AutoUpgradePlayers = false,
			AutoBuyJumpUpgrade = false,
			AutoBuySpeedUpgrade = false,
			JumpBuyAmount = "10 (Instant)",
			AutoPenaltyKick = false,
			AutoRebirth = false,
			AutoSellBackpack = false
		},
		Movement = {
			MoveSpeedMultiplier = 1
		},
		Visuals = {
			LuckyBlockESP = false,
			StandESP = false,
			PlayerESP = false
		},
		Settings = {
			autoSave = true,
			capFps = 60,
			lowGraphics = false
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
	_G.HipHubConfig = Config
	_G.HipHubSaveConfig = saveConfig

	------------------------------------------------
	-- 🎨 BUILD SETTINGS TAB
	------------------------------------------------
	local settingsFrame = UI.tabs["Settings"] and UI.tabs["Settings"].Frame
	if not settingsFrame then return end

	-- Profile / Config Section
	local configSec = UI.AddSection(settingsFrame, "Configuration Management", 1)
	UI.AddButton(configSec, "💾 Save Configuration", function()
		saveConfig()
		UI.Notify("Config Saved", "Configuration saved to disk.", 2, "success")
	end, 1)

	UI.AddButton(configSec, "🔄 Reset Configuration to Default", function()
		if delfile and isfile and isfile(CONFIG_FILE) then
			pcall(delfile, CONFIG_FILE)
		end
		UI.Notify("Config Reset", "Default settings restored. Re-execute to refresh values.", 3, "warning")
	end, 2)

	UI.AddToggle(configSec, "Auto Save Changes", Config.Settings.autoSave, function(v)
		Config.Settings.autoSave = v
		if v then saveConfig() end
	end, 3)

	-- Performance & Boost Section
	local perfSec = UI.AddSection(settingsFrame, "Performance & Optimization", 2)

	UI.AddSlider(perfSec, "FPS Limit Cap", 15, 240, Config.Settings.capFps or 60, function(v)
		Config.Settings.capFps = v
		if setfpscap then pcall(setfpscap, v) end
		if Config.Settings.autoSave then saveConfig() end
	end, 1, " FPS")

	UI.AddToggle(perfSec, "Low Graphics / Anti-Lag", Config.Settings.lowGraphics or false, function(v)
		Config.Settings.lowGraphics = v
		pcall(function()
			for _, obj in pairs(workspace:GetDescendants()) do
				if v then
					if obj:IsA("BasePart") and not obj:IsA("MeshPart") then
						obj.Material = Enum.Material.SmoothPlastic
					elseif obj:IsA("Decal") or obj:IsA("Texture") then
						obj.Transparency = 1
					elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") then
						obj.Enabled = false
					end
				end
			end
			if v then
				Lighting.GlobalShadows = false
				Lighting.FogEnd = 9e9
				settings().Rendering.QualityLevel = 1
			end
		end)
		if v then
			UI.Notify("Anti-Lag Enabled", "Optimized textures and world rendering.", 2, "success")
		end
		if Config.Settings.autoSave then saveConfig() end
	end, 2)

	-- UI Controls & Keybinds
	local uiSec = UI.AddSection(settingsFrame, "UI Controls & Keybind", 3)

	local currentKeyName = Config.UI.ToggleKey or "RightShift"
	local currentKey = Enum.KeyCode[currentKeyName] or Enum.KeyCode.RightShift
	local keybindBtn
	keybindBtn = UI.AddButton(uiSec, "Toggle UI Keybind: [" .. currentKey.Name .. "]", function()
		keybindBtn.Text = "Press any key to bind..."
		local conn
		conn = UserInputService.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Keyboard then
				conn:Disconnect()
				currentKey = input.KeyCode
				Config.UI.ToggleKey = currentKey.Name
				keybindBtn.Text = "Toggle UI Keybind: [" .. currentKey.Name .. "]"
				UI.Notify("Keybind Updated", "UI toggle set to " .. currentKey.Name, 2, "success")
				if Config.Settings.autoSave then saveConfig() end
			end
		end)
	end, 1)

	-- UI Toggle Listener
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not gameProcessed and input.KeyCode == currentKey then
			UI.mainFrame.Visible = not UI.mainFrame.Visible
			UI.shadowFrame.Visible = UI.mainFrame.Visible
		end
	end)

	UI.AddButton(uiSec, "❌ Close / Destroy UI", function()
		if UI.gui then UI.gui:Destroy() end
	end, 2, Color3.fromRGB(180, 40, 40))
end)

if not success then
	warn("[HipHub Settings Error]:", err)
end
