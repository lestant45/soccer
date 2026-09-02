-- ==============================================================================
-- 🐾 HipHub Main Controller — Jump for Animals!
-- Wires up UI Components, Feature State, Dragging & Hotkeys
-- ==============================================================================

local success, err = pcall(function()
	local env = (getgenv and getgenv()) or _G
	local UI = env.HipHubUI or _G.HipHubUI or (shared and shared.HipHubUI)
	if not UI then return end

	local Config = env.HipHubConfig or _G.HipHubConfig or (shared and shared.HipHubConfig) or { Training = {}, Farming = {}, Shops = {}, Defense = {}, Movement = {}, Visuals = {}, Settings = {} }
	local Features = env.HipHubFeatures or _G.HipHubFeatures or (shared and shared.HipHubFeatures)
	if not Features then
		pcall(function() Features = require(script.Parent.features) end)
	end
	if not Features then
		Features = { State = {} }
	end

	-- Sync state from config
	if Config.Training then
		for k, v in pairs(Config.Training) do Features.State[k] = v end
	end
	if Config.Farming then
		for k, v in pairs(Config.Farming) do Features.State[k] = v end
	end
	if Config.Shops then
		for k, v in pairs(Config.Shops) do Features.State[k] = v end
	end
	if Config.Defense then
		for k, v in pairs(Config.Defense) do Features.State[k] = v end
	end
	if Config.Movement then
		for k, v in pairs(Config.Movement) do Features.State[k] = v end
	end
	if Config.Visuals then
		for k, v in pairs(Config.Visuals) do Features.State[k] = v end
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
	-- 🖼️ WINDOW DRAGGING & CONTROLS
	------------------------------------------------
	local dragging, dragInput, dragStart, startPos
	local isMinimized = false

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
			dragging = true
			dragStart = input.Position
			startPos = mainFrame.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
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

	-- Minimize Window
	minimizeButton.MouseButton1Click:Connect(function()
		isMinimized = not isMinimized
		if isMinimized then
			mainFrame.ClipsDescendants = true
			UI.Tween(mainFrame, { Size = UDim2.new(0, 720, 0, 48) }, 0.25)
			minimizeButton.Text = "□"
		else
			UI.Tween(mainFrame, { Size = UDim2.new(0, 720, 0, 480) }, 0.25)
			minimizeButton.Text = "—"
		end
		task.delay(0.26, syncShadow)
	end)

	-- Close Window (Toggle Visibility)
	closeButton.MouseButton1Click:Connect(function()
		mainFrame.Visible = false
		syncShadow()
	end)

	-- Toggle Menu via Keybind
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		local keyName = Config.UI and Config.UI.ToggleKey or "RightShift"
		local targetKey = Enum.KeyCode[keyName] or Enum.KeyCode.RightShift
		if input.KeyCode == targetKey then
			mainFrame.Visible = not mainFrame.Visible
			syncShadow()
		end
	end)

	------------------------------------------------
	-- 🏋️‍♂️ 1. TRAINING TAB
	------------------------------------------------
	local trainFrame = UI.tabs["Training"].Frame

	-- Live Stats Section
	local statsSec = UI.AddSection(trainFrame, "Live Jump & Player Stats", 1)
	local jumpPowerCard = UI.AddStatCard(statsSec, "⚡ Jump Power", "0", 1)
	local levelCard = UI.AddStatCard(statsSec, "🏆 Training Level", "1", 2)
	local xpCard = UI.AddStatCard(statsSec, "✨ Training XP", "0 / 0", 3)
	local cashCard = UI.AddStatCard(statsSec, "💰 Cash Balance", "$0", 4)

	-- Auto Squat Section
	local squatSec = UI.AddSection(trainFrame, "Squat Automation", 2)

	UI.AddToggle(squatSec, "🏋️‍♂️ Auto Squat Training", Features.State.AutoSquat, function(v)
		Features.State.AutoSquat = v
		if Config.Training then Config.Training.AutoSquat = v end
		if v then
			local myPlot = Features.GetMyPlot()
			local detector = myPlot and myPlot:FindFirstChild("SquatZone")
			if detector then detector = detector:FindFirstChild("Floor") end
			if detector then detector = detector:FindFirstChild("Detector") end
			if detector then
				Features.TeleportTo(detector.CFrame + Vector3.new(0, 2.5, 0))
			end
		end
		saveConfig()
	end, 1)

	UI.AddToggle(squatSec, "🎁 Auto Claim Squat Bonus", Features.State.AutoSquatBonus, function(v)
		Features.State.AutoSquatBonus = v
		if Config.Training then Config.Training.AutoSquatBonus = v end
		saveConfig()
	end, 2)

	UI.AddToggle(squatSec, "🏋️ Auto Upgrade Squat Barbell", Features.State.AutoUpgradeBarbell, function(v)
		Features.State.AutoUpgradeBarbell = v
		if Config.Training then Config.Training.AutoUpgradeBarbell = v end
		saveConfig()
	end, 3)

	UI.AddButton(squatSec, "🚀 Teleport to My Squat Zone", function()
		local myPlot = Features.GetMyPlot()
		local detector = myPlot and myPlot:FindFirstChild("SquatZone")
		if detector then detector = detector:FindFirstChild("Floor") end
		if detector then detector = detector:FindFirstChild("Detector") end
		if detector then
			Features.TeleportTo(detector.CFrame + Vector3.new(0, 2.5, 0))
		end
	end, 4)

	------------------------------------------------
	-- 🥚 2. FARMING TAB
	------------------------------------------------
	local farmFrame = UI.tabs["Farming"].Frame

	local stageList = { "All", "Meadow", "Coral Reef", "Winter", "Desert", "Crystal Mines", "Jungle", "Mystic Isles", "Prehistoric", "Celestial Heights" }

	local animalList = { "All", "ARCHAEOPTERYX", "Ankylosaurus", "Archerfish", "Barracuda", "Bat", "Bear", "Boxfish", "Brachiosaurus", "Bunny", "Butterflyfish", "CLASSIC DRAGON", "Capybara", "Cat", "Chicken", "Coral Goby", "Cowfish", "Crab", "Crocodile", "Elephant", "FIRE PHOENIX", "Frog", "GARUDA", "Gallimimus", "Giraffe", "Goat", "Golden Retriver", "Goldfish", "Gorilla", "Guienna Pig", "Hamster", "Horse", "Jellyfish", "Kangaroo", "Koala", "Lion", "Lionfish", "Lizard", "Llama", "MICRORAPTOR", "Mammoth", "Moorish Idol", "Ostrich", "Owl", "PEGASUS", "PLESIOSAUR", "Parrot", "Pigeon", "Polar Bear", "Pony", "Prehistoric Dragonfly", "Prehistoric Moth", "Pufferfish", "Regal Angelfish", "SIMURGH", "STYMPHALIANBIRD", "Sailfish", "Seahorse", "Seal", "Snail", "Spinosaurus", "Stingray", "Swordfish", "T-Rex", "Triceratops", "Triple Cobra", "Trumpetfish", "Tuna", "Turtle", "Unicorn", "Velociraptor", "WYVERN", "Whale", "Wobbegong", "Wolf", "Zebra" }

	local eggList = { "All", "ARCHAEOPTERYX Egg", "Ankylosaurus Egg", "Archerfish Egg", "Barracuda Egg", "Bat Egg", "Bear Egg", "Boxfish Egg", "Brachiosaurus Egg", "Bunny Egg", "Butterflyfish Egg", "CLASSIC DRAGON Egg", "Capybara Egg", "Cat Egg", "Chicken Egg", "Coral Goby Egg", "Cowfish Egg", "Crab Egg", "Crocodile Egg", "Elephant Egg", "FIRE PHOENIX Egg", "Frog Egg", "GARUDA Egg", "Gallimimus Egg", "Giraffe Egg", "Goat Egg", "Golden Retriver Egg", "Goldfish Egg", "Gorilla Egg", "Guienna Pig Egg", "Hamster Egg", "Horse Egg", "Jellyfish Egg", "Kangaroo Egg", "Koala Egg", "Lion Egg", "Lionfish Egg", "Lizard Egg", "Llama Egg", "MICRORAPTOR Egg", "Mammoth Egg", "Moorish Idol Egg", "Ostrich Egg", "Owl Egg", "PEGASUS Egg", "PLESIOSAUR Egg", "Parrot Egg", "Pigeon Egg", "Polar Bear Egg", "Pony Egg", "Prehistoric Dragonfly Egg", "Prehistoric Moth Egg", "Pufferfish Egg", "Regal Angelfish Egg", "SIMURGH Egg", "STYMPHALIANBIRD Egg", "Sailfish Egg", "Seahorse Egg", "Seal Egg", "Snail Egg", "Spinosaurus Egg", "Stingray Egg", "Swordfish Egg", "T-Rex Egg", "Triceratops Egg", "Triple Cobra Egg", "Trumpetfish Egg", "Tuna Egg", "Turtle Egg", "Unicorn Egg", "Velociraptor Egg", "WYVERN Egg", "Whale Egg", "Wobbegong Egg", "Wolf Egg", "Zebra Egg" }

	local stealSec = UI.AddSection(farmFrame, "Egg Auto-Stealing", 1)

	UI.AddMultiDropdown(stealSec, "Target Stages to Steal", stageList, Features.State.SelectedStages or { ["All"] = true }, function(map)
		Features.State.SelectedStages = map
		if Config.Farming then Config.Farming.SelectedStages = map end
		saveConfig()
	end, 1)

	UI.AddMultiDropdown(stealSec, "Target Animals to Steal", animalList, Features.State.SelectedAnimals or { ["All"] = true }, function(map)
		Features.State.SelectedAnimals = map
		if Config.Farming then Config.Farming.SelectedAnimals = map end
		saveConfig()
	end, 2)

	UI.AddToggle(stealSec, "🥚 Auto Steal Eggs from Stages", Features.State.AutoStealEggs, function(v)
		Features.State.AutoStealEggs = v
		if Config.Farming then Config.Farming.AutoStealEggs = v end
		saveConfig()
	end, 3)

	local plotSec = UI.AddSection(farmFrame, "Plot & Pet Management", 2)

	UI.AddMultiDropdown(plotSec, "Target Eggs to Auto-Place", eggList, Features.State.SelectedPlaceEggs or { ["All"] = true }, function(map)
		Features.State.SelectedPlaceEggs = map
		if Config.Farming then Config.Farming.SelectedPlaceEggs = map end
		saveConfig()
	end, 1)

	UI.AddToggle(plotSec, "📥 Auto Place Carried Eggs on Plot", Features.State.AutoPlaceEggs, function(v)
		Features.State.AutoPlaceEggs = v
		if Config.Farming then Config.Farming.AutoPlaceEggs = v end
		saveConfig()
	end, 2)

	UI.AddToggle(plotSec, "🐣 Auto Hatch / Claim Ready Eggs", Features.State.AutoHatchEggs, function(v)
		Features.State.AutoHatchEggs = v
		if Config.Farming then Config.Farming.AutoHatchEggs = v end
		saveConfig()
	end, 3)

	UI.AddToggle(plotSec, "⭐ Auto Equip Best Pets", Features.State.AutoEquipBest, function(v)
		Features.State.AutoEquipBest = v
		if Config.Farming then Config.Farming.AutoEquipBest = v end
		saveConfig()
	end, 4)

	UI.AddToggle(plotSec, "🏡 Auto Upgrade Pen (Equip Slots)", Features.State.AutoUpgradePen, function(v)
		Features.State.AutoUpgradePen = v
		if Config.Farming then Config.Farming.AutoUpgradePen = v end
		saveConfig()
	end, 5)

	UI.AddMultiDropdown(plotSec, "Target Animals to Auto-Sell", animalList, Features.State.SelectedSellAnimals or { ["All"] = true }, function(map)
		Features.State.SelectedSellAnimals = map
		if Config.Farming then Config.Farming.SelectedSellAnimals = map end
		saveConfig()
	end, 6)

	UI.AddToggle(plotSec, "💵 Auto Sell Animals", Features.State.AutoSellPets, function(v)
		Features.State.AutoSellPets = v
		if Config.Farming then Config.Farming.AutoSellPets = v end
		saveConfig()
	end, 7)

	UI.AddButton(plotSec, "🏠 Teleport to My Plot", function()
		local myPlot = Features.GetMyPlot()
		if myPlot then Features.TeleportTo(myPlot) end
	end, 8)

	UI.AddButton(plotSec, "🏪 Teleport to Sell Zone", function()
		Features.TeleportTo(Features.POIPositions["Sell Zone"])
	end, 9)

	------------------------------------------------
	-- 🛒 3. SHOPS & BOOSTS TAB
	------------------------------------------------
	local shopsFrame = UI.tabs["Shops"].Frame

	local upgradesSec = UI.AddSection(shopsFrame, "Upgrades & Multipliers", 1)

	UI.AddToggle(upgradesSec, "✨ Auto Buy Trails (Jump Multipliers)", Features.State.AutoBuyTrails, function(v)
		Features.State.AutoBuyTrails = v
		if Config.Shops then Config.Shops.AutoBuyTrails = v end
		saveConfig()
	end, 1)

	UI.AddToggle(upgradesSec, "🏃 Auto Buy Speed Coils", Features.State.AutoBuyCoils, function(v)
		Features.State.AutoBuyCoils = v
		if Config.Shops then Config.Shops.AutoBuyCoils = v end
		saveConfig()
	end, 2)

	local rewardsSec = UI.AddSection(shopsFrame, "Rewards & Golden Mutation", 2)

	UI.AddToggle(rewardsSec, "🌟 Auto Gold Mutation Machine", Features.State.AutoGoldMutation, function(v)
		Features.State.AutoGoldMutation = v
		if Config.Shops then Config.Shops.AutoGoldMutation = v end
		saveConfig()
	end, 1)

	UI.AddToggle(rewardsSec, "🎁 Auto Claim Animal Index Rewards", Features.State.AutoClaimIndex, function(v)
		Features.State.AutoClaimIndex = v
		if Config.Shops then Config.Shops.AutoClaimIndex = v end
		saveConfig()
	end, 2)

	UI.AddToggle(rewardsSec, "⌛ Auto Claim Offline Rewards", Features.State.AutoClaimOffline, function(v)
		Features.State.AutoClaimOffline = v
		if Config.Shops then Config.Shops.AutoClaimOffline = v end
		saveConfig()
	end, 3)

	UI.AddToggle(rewardsSec, "👥 Auto Claim Group Rewards", Features.State.AutoClaimGroup, function(v)
		Features.State.AutoClaimGroup = v
		if Config.Shops then Config.Shops.AutoClaimGroup = v end
		saveConfig()
	end, 4)

	UI.AddButton(rewardsSec, "🧬 Teleport to Mutation Machine", function()
		Features.TeleportTo(Features.POIPositions["Mutation Machine"])
	end, 5)

	UI.AddButton(rewardsSec, "🎁 Teleport to Group Rewards", function()
		Features.TeleportTo(Features.POIPositions["Group Rewards"])
	end, 6)

	------------------------------------------------
	-- 🛡️ 4. DEFENSE TAB
	------------------------------------------------
	local defFrame = UI.tabs["Defense"].Frame

	local guardSec = UI.AddSection(defFrame, "Guard & Penalty Defense", 1)

	UI.AddToggle(guardSec, "🛡️ Disable Client Guard Aggro/Follow", Features.State.DisableGuards, function(v)
		Features.State.DisableGuards = v
		if Config.Defense then Config.Defense.DisableGuards = v end
		saveConfig()
	end, 1)

	UI.AddToggle(guardSec, "🔒 Anti Egg Drop (Stay in Hand)", Features.State.AntiEggDrop, function(v)
		Features.State.AntiEggDrop = v
		if Config.Defense then Config.Defense.AntiEggDrop = v end
		saveConfig()
	end, 2)

	------------------------------------------------
	-- ⚡ 5. MOVEMENT TAB
	------------------------------------------------
	local moveFrame = UI.tabs["Movement"].Frame

	local speedSec = UI.AddSection(moveFrame, "Speed & Jump Modifications", 1)

	UI.AddToggle(speedSec, "⚡ Enable Custom WalkSpeed", Features.State.SpeedEnabled, function(v)
		Features.State.SpeedEnabled = v
		if Config.Movement then Config.Movement.SpeedEnabled = v end
		saveConfig()
	end, 1)

	UI.AddSlider(speedSec, "WalkSpeed", 16, 150, Features.State.WalkSpeed or 16, function(v)
		Features.State.WalkSpeed = v
		if Config.Movement then Config.Movement.WalkSpeed = v end
		saveConfig()
	end, 2)

	UI.AddToggle(speedSec, "🚀 Enable Custom JumpPower", Features.State.JumpEnabled, function(v)
		Features.State.JumpEnabled = v
		if Config.Movement then Config.Movement.JumpEnabled = v end
		saveConfig()
	end, 3)

	UI.AddSlider(speedSec, "JumpPower", 50, 300, Features.State.JumpPower or 50, function(v)
		Features.State.JumpPower = v
		if Config.Movement then Config.Movement.JumpPower = v end
		saveConfig()
	end, 4)

	UI.AddToggle(speedSec, "🌌 Infinite Jump", Features.State.InfiniteJump, function(v)
		Features.State.InfiniteJump = v
		if Config.Movement then Config.Movement.InfiniteJump = v end
		saveConfig()
	end, 5)

	local flightSec = UI.AddSection(moveFrame, "Flight & Noclip", 2)

	UI.AddToggle(flightSec, "🦅 Fly Mode (WASD + Space/Shift)", Features.State.FlyEnabled, function(v)
		Features.State.FlyEnabled = v
		if Config.Movement then Config.Movement.FlyEnabled = v end
		saveConfig()
	end, 1)

	UI.AddSlider(flightSec, "Fly Speed", 20, 200, Features.State.FlySpeed or 50, function(v)
		Features.State.FlySpeed = v
		if Config.Movement then Config.Movement.FlySpeed = v end
		saveConfig()
	end, 2)

	UI.AddToggle(flightSec, "👻 Noclip (Pass Through Walls)", Features.State.Noclip, function(v)
		Features.State.Noclip = v
		if Config.Movement then Config.Movement.Noclip = v end
		saveConfig()
	end, 3)

	local tpSec = UI.AddSection(moveFrame, "Stage Teleports", 3)
	for idx, stageName in ipairs(stageList) do
		if stageName ~= "All" then
			UI.AddButton(tpSec, "📍 Teleport to " .. stageName, function()
				local pos = Features.StagePositions[stageName]
				if pos then Features.TeleportTo(pos) end
			end, idx)
		end
	end

	------------------------------------------------
	-- 👁️ 6. VISUALS TAB
	------------------------------------------------
	local visFrame = UI.tabs["Visuals"].Frame

	local espSec = UI.AddSection(visFrame, "ESP & Visual Highlights", 1)

	UI.AddMultiDropdown(espSec, "Egg ESP Stage Filter", stageList, Features.State.ESPSelectedStages or { ["All"] = true }, function(map)
		Features.State.ESPSelectedStages = map
		if Config.Visuals then Config.Visuals.ESPSelectedStages = map end
		Features.UpdateESP()
		saveConfig()
	end, 1)

	UI.AddToggle(espSec, "🥚 Egg ESP (Name & Stage Distance)", Features.State.EggESP, function(v)
		Features.State.EggESP = v
		if Config.Visuals then Config.Visuals.EggESP = v end
		Features.UpdateESP()
		saveConfig()
	end, 2)

	UI.AddToggle(espSec, "👤 Player ESP (Level & Names)", Features.State.PlayerESP, function(v)
		Features.State.PlayerESP = v
		if Config.Visuals then Config.Visuals.PlayerESP = v end
		Features.UpdateESP()
		saveConfig()
	end, 3)

	------------------------------------------------
	-- 🔄 LIVE STATS UPDATER
	------------------------------------------------
	task.spawn(function()
		while true do
			pcall(function()
				local jp = LocalPlayer:FindFirstChild("JumpPower")
				if jp then jumpPowerCard.Update(tostring(jp.Value)) end

				local lvl = LocalPlayer:FindFirstChild("leaderstats") and LocalPlayer.leaderstats:FindFirstChild("Level")
				if lvl then levelCard.Update(tostring(lvl.Value)) end

				local xp = LocalPlayer:FindFirstChild("JumpTrainingXP")
				if xp then xpCard.Update(tostring(xp.Value)) end

				local cash = LocalPlayer:FindFirstChild("leaderstats") and LocalPlayer.leaderstats:FindFirstChild("Cash")
				if cash then cashCard.Update(tostring(cash.Value)) end
			end)
			task.wait(0.5)
		end
	end)

	print("[HipHub JFA Main] UI Controller fully wired and ready!")
end)

if not success then
	warn("[HipHub JFA Main Error]: " .. tostring(err))
end
