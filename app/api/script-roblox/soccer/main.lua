-- ==============================================================================
-- 🧠 HipHub — Main Controller (Jump To Steal Soccer Players)
-- ==============================================================================
local success, err = pcall(function()
	local UI = _G.HipHubUI
	if not UI then return end

	local Config = _G.HipHubConfig or { Farm = {}, Movement = {}, Visuals = {}, Settings = {} }
	local Features = _G.HipHubFeatures
	if not Features then
		pcall(function()
			Features = require(script.Parent.features)
		end)
	end
	if not Features then
		Features = { State = {} }
	end

	-- Sync state from config
	if Config.Farm then
		for k, v in pairs(Config.Farm) do
			Features.State[k] = v
		end
	end
	if Config.Movement and Config.Movement.MoveSpeedMultiplier then
		Features.State.MoveSpeedMultiplier = Config.Movement.MoveSpeedMultiplier
	end
	if Config.Visuals then
		for k, v in pairs(Config.Visuals) do
			Features.State[k] = v
		end
	end

	if Features.Init and not _G.HipHubFeaturesInitialized then
		Features.Init()
		_G.HipHubFeaturesInitialized = true
	end

	local TweenService = game:GetService("TweenService")
	local UserInputService = game:GetService("UserInputService")
	local Players = game:GetService("Players")
	local LocalPlayer = Players.LocalPlayer

	local mainFrame = UI.mainFrame
	local topBar = UI.topBar
	local closeButton = UI.closeButton
	local minimizeButton = UI.minimizeButton
	local syncShadow = UI.SyncShadow
	local saveConfig = _G.HipHubSaveConfig or function() end

	------------------------------------------------
	-- 🖼️ WINDOW DRAGGING FUNCTIONALITY
	------------------------------------------------
	local dragging, dragInput, dragStart, startPos
	local isFullscreen = false
	local isMinimized = false
	local origPos = mainFrame.Position
	local origSize = mainFrame.Size

	local function update(input)
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
		syncShadow()
	end

	topBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if not isFullscreen then
				dragging = true
				dragStart = input.Position
				startPos = mainFrame.Position

				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end
	end)

	topBar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end)

	-- Minimize Action
	minimizeButton.MouseButton1Click:Connect(function()
		isMinimized = not isMinimized
		if isMinimized then
			if UI.contentArea then UI.contentArea.Visible = false end
			if UI.sidebar then UI.sidebar.Visible = false end
			local side = mainFrame:FindFirstChild("Sidebar", true)
			if side then side.Visible = false end
			TweenService:Create(mainFrame, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.new(origSize.X.Scale, origSize.X.Offset, 0, 42) }):Play()
		else
			local tw = TweenService:Create(mainFrame, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = origSize })
			tw.Completed:Connect(function()
				if UI.contentArea then UI.contentArea.Visible = true end
				if UI.sidebar then UI.sidebar.Visible = true end
				local side = mainFrame:FindFirstChild("Sidebar", true)
				if side then side.Visible = true end
			end)
			tw:Play()
		end
		task.delay(0.24, syncShadow)
	end)

	-- Close Action
	closeButton.MouseButton1Click:Connect(function()
		mainFrame.Visible = false
		UI.shadowFrame.Visible = false
		local toggleKey = (Config.UI and Config.UI.ToggleKey) or "RightShift"
		UI.Notify("HipHub Hidden", "Press [" .. toggleKey .. "] to show the menu again.", 3, "success")
	end)

	------------------------------------------------
	-- ⚡ TAB 1: AUTO FARM & AUTOMATION
	------------------------------------------------
	local mainTabFrame = UI.tabs["Main"] and UI.tabs["Main"].Frame
	if mainTabFrame then
		-- Clear existing placeholder content
		for _, child in ipairs(mainTabFrame:GetChildren()) do
			if child:IsA("Frame") then child:Destroy() end
		end

		-- Section 1: Lucky Blocks Automation
		local lbSec = UI.AddSection(mainTabFrame, "📦 Lucky Block Automation", 1)

		UI.AddToggle(lbSec, "Auto Collect Lucky Block", Config.Farm.AutoCollectLuckyBlock or false, function(v)
			Features.State.AutoCollectLuckyBlock = v
			Config.Farm.AutoCollectLuckyBlock = v
			if Config.Settings.autoSave then saveConfig() end
			if v then UI.Notify("Auto Collect", "Collecting Lucky Blocks continuously...", 2, "success") end
		end, 1)

		local rarityOptions = {
			"All",
			"LIMITED",
			"Japan",
			"Icons",
			"Spain",
			"Champions",
			"OG",
			"Exclusive",
			"Divine",
			"Soccer God",
			"Secret",
			"Mythic",
			"Legendary",
			"Epic",
			"Rare",
			"Common"
		}
		UI.AddMultiDropdown(lbSec, "Filter Rarity", rarityOptions, Config.Farm.FilterRarity or { "All" }, function(optList, optMap)
			Features.State.FilterRarity = optList
			Config.Farm.FilterRarity = optList
			if Config.Settings.autoSave then saveConfig() end
			local count = #optList
			if optMap["All"] then
				UI.Notify("Rarity Filter", "Target: All Rarities", 2, "success")
			else
				UI.Notify("Rarity Filter", "Selected " .. tostring(count) .. " Rarities", 2, "success")
			end
		end, 2)

		local mutationOptions = { "All", "None", "Gold", "Rainbow", "Volcanic", "Diamond", "Shiny", "Cursed", "Neon", "Ghost" }
		UI.AddMultiDropdown(lbSec, "Filter Mutation", mutationOptions, Config.Farm.FilterMutation or { "All" }, function(optList, optMap)
			Features.State.FilterMutation = optList
			Config.Farm.FilterMutation = optList
			if Config.Settings.autoSave then saveConfig() end
			local count = #optList
			if optMap["All"] then
				UI.Notify("Mutation Filter", "Target: All Mutations", 2, "success")
			else
				UI.Notify("Mutation Filter", "Selected " .. tostring(count) .. " Mutations", 2, "success")
			end
		end, 3)

		UI.AddToggle(lbSec, "Auto Place & Open Lucky Block", Config.Farm.AutoPlaceOpenLuckyBlock or false, function(v)
			Features.State.AutoPlaceOpenLuckyBlock = v
			Config.Farm.AutoPlaceOpenLuckyBlock = v
			if Config.Settings.autoSave then saveConfig() end
			if v then UI.Notify("Auto Place & Open", "Placing & Opening Lucky Blocks on stands...", 2, "success") end
		end, 4)

		-- Section 2: Economy & Income
		local econSec = UI.AddSection(mainTabFrame, "💰 Economy & Collection", 2)

		UI.AddToggle(econSec, "Auto Collect Earnings", Config.Farm.AutoCollectEarnings or false, function(v)
			Features.State.AutoCollectEarnings = v
			Config.Farm.AutoCollectEarnings = v
			if Config.Settings.autoSave then saveConfig() end
			if v then UI.Notify("Auto Earnings", "Continuously collecting plot earnings...", 2, "success") end
		end, 1)

		UI.AddToggle(econSec, "Auto Sell From Backpack", Config.Farm.AutoSellBackpack or false, function(v)
			Features.State.AutoSellBackpack = v
			Config.Farm.AutoSellBackpack = v
			if Config.Settings.autoSave then saveConfig() end
		end, 2)

		UI.AddButton(econSec, "💵 Quick Sell All Backpack", function()
			Features.SellFromBackpackStep()
			UI.Notify("Sold Inventory", "Sold all players in backpack.", 2, "success")
		end, 3)

		-- Section 3: Progression, Players & Upgrades
		local progSec = UI.AddSection(mainTabFrame, "⭐ Progression & Upgrades", 3)

		UI.AddToggle(progSec, "Auto Buy Speed Upgrade", Config.Farm.AutoBuySpeedUpgrade or false, function(v)
			Features.State.AutoBuySpeedUpgrade = v
			Config.Farm.AutoBuySpeedUpgrade = v
			if Config.Settings.autoSave then saveConfig() end
		end, 1)

		UI.AddToggle(progSec, "Auto Upgrade Soccer Players", Config.Farm.AutoUpgradePlayers or false, function(v)
			Features.State.AutoUpgradePlayers = v
			Config.Farm.AutoUpgradePlayers = v
			if Config.Settings.autoSave then saveConfig() end
		end, 2)

		UI.AddToggle(progSec, "Auto Rebirth", Config.Farm.AutoRebirth or false, function(v)
			Features.State.AutoRebirth = v
			Config.Farm.AutoRebirth = v
			if Config.Settings.autoSave then saveConfig() end
			if v then UI.Notify("Auto Rebirth", "Auto-rebirthing when jump requirements are met.", 2, "success") end
		end, 3)

		UI.AddToggle(progSec, "Auto Pick Up All Soccer Players", Config.Farm.AutoPickupAllPlayers or false, function(v)
			Features.State.AutoPickupAllPlayers = v
			Config.Farm.AutoPickupAllPlayers = v
			if Config.Settings.autoSave then saveConfig() end
		end, 4)

		UI.AddButton(progSec, "🧤 Pick Up All My Soccer Players Now", function()
			Features.PickupAllSoccerPlayersStep()
			UI.Notify("Picked Up", "Retrieved soccer players from plot.", 2, "success")
		end, 5)
	end

	------------------------------------------------
	-- 🏃 TAB 2: MOVEMENT & VISUALS (ESP)
	------------------------------------------------
	local moveTabFrame = (UI.tabs["Visuals"] and UI.tabs["Visuals"].Frame) or UI.AddTab("Visuals", "👁️", 2)
	if moveTabFrame then
		-- Section 1: Movement & Speed
		local moveSec = UI.AddSection(moveTabFrame, "🏃 Movement & Character Speed", 1)

		UI.AddSlider(moveSec, "Move Speed Multiplier (Capped at 3x)", 1, 10, Config.Movement.MoveSpeedMultiplier or 1, function(v)
			Features.State.MoveSpeedMultiplier = v
			Config.Movement.MoveSpeedMultiplier = v
			Features.ApplyMoveSpeed()
			if Config.Settings.autoSave then saveConfig() end
		end, 1, "x")

		UI.AddButton(moveSec, "🔄 Reset Speed to Default (1x)", function()
			Features.State.MoveSpeedMultiplier = 1
			Config.Movement.MoveSpeedMultiplier = 1
			Features.ApplyMoveSpeed()
			UI.Notify("Speed Reset", "Character speed restored to 1x.", 2, "success")
		end, 2)

		-- Section 2: ESP with Mutation Badges
		local espSec = UI.AddSection(moveTabFrame, "✨ ESP & Visuals", 2)

		UI.AddToggle(espSec, "Egg / Lucky Block ESP (Mutation: Gold/Rainbow/None)", Config.Visuals.LuckyBlockESP or false, function(v)
			Features.State.LuckyBlockESP = v
			Config.Visuals.LuckyBlockESP = v
			Features.UpdateESP()
			if Config.Settings.autoSave then saveConfig() end
			if v then UI.Notify("ESP Enabled", "Rendering Lucky Blocks with Mutation badges.", 2, "success") end
		end, 1)

		UI.AddLabel(espSec, "🏷️ Mutation Colors: Gold (#FAB026) | Rainbow | Cyan", 2)
	end

	------------------------------------------------
	-- ℹ️ TAB 4: LIVE STATS & INFO
	------------------------------------------------
	local infoTabFrame = UI.tabs["Info"] and UI.tabs["Info"].Frame
	if infoTabFrame then
		for _, child in ipairs(infoTabFrame:GetChildren()) do
			if child:IsA("Frame") then child:Destroy() end
		end

		local liveSec = UI.AddSection(infoTabFrame, "📊 Live Player Stats", 1)
		local cashLabel = UI.AddLabel(liveSec, "Cash: $0", 1)
		local jumpLabel = UI.AddLabel(liveSec, "Jump: 0", 2)
		local rebLabel = UI.AddLabel(liveSec, "Rebirth: 0", 3)
		local carryLabel = UI.AddLabel(liveSec, "Carrying: 0 / 3", 4)
		local plotLabel = UI.AddLabel(liveSec, "Plot: Searching...", 5)

		-- Live ticker
		task.spawn(function()
			while mainFrame and mainFrame.Parent do
				pcall(function()
					local data = Features.GetPlayerData()
					local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
					local cashVal = data and data.Cash or (leaderstats and leaderstats:FindFirstChild("Cash") and leaderstats.Cash.Value or "0")
					local jumpVal = data and data.Jump or (leaderstats and leaderstats:FindFirstChild("Jump") and leaderstats.Jump.Value or "0")
					local rebVal = data and data.Rebirth or (leaderstats and leaderstats:FindFirstChild("Rebirth") and leaderstats.Rebirth.Value or "0")
					local myPlot = Features.GetMyPlot()
					local carried = Features.GetCarriedCount()
					local maxCarry = Features.GetMaxCarryLimit()

					cashLabel.Text = "Cash: $" .. tostring(cashVal)
					jumpLabel.Text = "Jump: " .. tostring(jumpVal)
					rebLabel.Text = "Rebirth: " .. tostring(rebVal)
					carryLabel.Text = "Carrying: " .. tostring(carried) .. " / " .. tostring(maxCarry) .. (carried >= maxCarry and " (FULL - Safe Base)" or "")
					carryLabel.TextColor3 = carried >= maxCarry and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(225, 235, 255)
					plotLabel.Text = "Plot: " .. (myPlot and myPlot.Name or "Unknown")
				end)
				task.wait(1.5)
			end
		end)

		local sysSec = UI.AddSection(infoTabFrame, "ℹ️ System Information", 2)
		UI.AddLabel(sysSec, "Game: Jump To Steal Soccer Players", 1)
		UI.AddLabel(sysSec, "User: " .. (LocalPlayer.DisplayName or LocalPlayer.Name) .. " (@" .. LocalPlayer.Name .. ")", 2)
		UI.AddLabel(sysSec, "Place ID: " .. tostring(game.PlaceId), 3)

		local execName = "Unknown"
		pcall(function()
			local fn = identifyexecutor or getexecutorname
			if fn then execName = fn() end
		end)
		UI.AddLabel(sysSec, "Executor: " .. tostring(execName), 4)
	end

	UI.SelectTab("Main")
end)

if not success then
	warn("[HipHub Main Error]:", err)
end
