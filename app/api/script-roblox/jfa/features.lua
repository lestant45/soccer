-- ==============================================================================
-- 🐾 HipHub Features — Jump for Animals! Automation & Hacks Module
-- ==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Features = {}

------------------------------------------------
-- 📊 STATE CONFIGURATION
------------------------------------------------
Features.State = {
	-- Training
	AutoSquat = false,
	AutoSquatBonus = false,
	AutoUpgradeBarbell = false,

	-- Farming
	AutoStealEggs = false,
	SelectedStages = { ["All"] = true },
	SelectedAnimals = { ["All"] = true },
	AutoPlaceEggs = false,
	SelectedPlaceEggs = { ["All"] = true },
	AutoHatchEggs = false,
	AutoEquipBest = false,
	AutoUpgradePen = false,
	AutoSellPets = false,
	SelectedSellAnimals = { ["All"] = true },

	-- Shops & Boosts
	AutoBuyTrails = false,
	AutoBuyCoils = false,
	AutoGoldMutation = false,
	AutoClaimIndex = false,
	AutoClaimOffline = false,
	AutoClaimGroup = false,

	-- Defense
	DisableGuards = false,
	AntiEggDrop = false,

	-- Movement
	WalkSpeed = 16,
	SpeedEnabled = false,
	JumpPower = 50,
	JumpEnabled = false,
	InfiniteJump = false,
	FlyEnabled = false,
	FlySpeed = 50,
	Noclip = false,

	-- Visuals / ESP
	EggESP = false,
	ESPSelectedStages = { ["All"] = true },
	GuardESP = false,
	PlayerESP = false,
	PlotESP = false,

	-- Performance / Utilities
	AntiAfk = true,
	LowGraphics = false
}

------------------------------------------------
-- 🔗 GAME REMOTES & SETTINGS REFERENCES
------------------------------------------------
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 15)
local SquatTrainingRequest = Remotes and Remotes:FindFirstChild("SquatTrainingRequest")
local StopSquattingRequest = Remotes and Remotes:FindFirstChild("StopSquattingRequest")
local SquatBonusRequest = Remotes and Remotes:FindFirstChild("SquatBonusRequest")
local PlaceEggRequest = Remotes and Remotes:FindFirstChild("PlaceEggRequest")
local DropEggRequest = Remotes and Remotes:FindFirstChild("DropEggRequest")
local ReturnToBaseRequest = Remotes and Remotes:FindFirstChild("ReturnToBaseRequest")
local PetInventoryRemote = Remotes and Remotes:FindFirstChild("PetInventory")
local SellRemote = Remotes and Remotes:FindFirstChild("Sell")
local TrailsRemote = Remotes and Remotes:FindFirstChild("Trails")
local CoilsRemote = Remotes and Remotes:FindFirstChild("Coils")
local ClaimAnimalIndexReward = Remotes and Remotes:FindFirstChild("ClaimAnimalIndexReward")
local OfflineRewardsRemote = Remotes and Remotes:FindFirstChild("OfflineRewards")
local GroupRewardRemote = Remotes and Remotes:FindFirstChild("GroupReward")

-- Settings references
local SettingsFolder = ReplicatedStorage:WaitForChild("Settings", 15)
local AreasSettings, AnimalsSettings, EggsSettings, TrailsSettings, BarbellUpgradesSettings, MutationsSettings
pcall(function() AreasSettings = require(SettingsFolder:FindFirstChild("Areas")) end)
pcall(function() AnimalsSettings = require(SettingsFolder:FindFirstChild("Animals")) end)
pcall(function() EggsSettings = require(SettingsFolder:FindFirstChild("Eggs")) end)
pcall(function() TrailsSettings = require(SettingsFolder:FindFirstChild("Trails")) end)
pcall(function() BarbellUpgradesSettings = require(SettingsFolder:FindFirstChild("BarbellUpgrades")) end)
pcall(function() MutationsSettings = require(SettingsFolder:FindFirstChild("Mutations")) end)

------------------------------------------------
-- 📍 STAGE & MAP COORDINATES
------------------------------------------------
Features.StagePositions = {
	["Meadow"] = Vector3.new(1.12, 5.5, -134.84),
	["Coral Reef"] = Vector3.new(0.62, 35.5, -270.34),
	["Winter"] = Vector3.new(0.62, 149.0, -404.34),
	["Desert"] = Vector3.new(-0.62, 256.5, -477.60),
	["Crystal Mines"] = Vector3.new(-0.62, 542.5, -617.07),
	["Jungle"] = Vector3.new(1.37, 1136.5, -828.14),
	["Mystic Isles"] = Vector3.new(-0.62, 1404.5, -898.05),
	["Prehistoric"] = Vector3.new(0.37, 2049.5, -1040.60),
	["Celestial Heights"] = Vector3.new(-0.62, 4075.5, -1243.38)
}

Features.POIPositions = {
	["Spawn / Start"] = Vector3.new(0, 5, 0),
	["Sell Zone"] = Vector3.new(142.37, -1.04, -22.36),
	["Mutation Machine"] = Vector3.new(38, 5, -25),
	["Group Rewards"] = Vector3.new(-20, 5, -40),
	["Coil Shop"] = Vector3.new(20, 5, -40)
}

------------------------------------------------
-- 🛠️ HELPER FUNCTIONS
------------------------------------------------
function Features.GetMyPlot()
	local plotVal = LocalPlayer:FindFirstChild("Plot")
	if plotVal and plotVal.Value then
		return plotVal.Value
	end
	local mapPlots = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Plots")
	if mapPlots then
		for _, plot in ipairs(mapPlots:GetChildren()) do
			local owner = plot:FindFirstChild("Owner")
			if owner and owner.Value == LocalPlayer.Name then
				return plot
			end
		end
	end
	return nil
end

function Features.GetCharacter()
	return LocalPlayer.Character
end

function Features.GetRootPart()
	local char = Features.GetCharacter()
	return char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
end

function Features.GetHumanoid()
	local char = Features.GetCharacter()
	return char and char:FindFirstChildOfClass("Humanoid")
end

function Features.TeleportTo(targetPos)
	local root = Features.GetRootPart()
	if not root then return false end
	if typeof(targetPos) == "Vector3" then
		root.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
		return true
	elseif typeof(targetPos) == "CFrame" then
		root.CFrame = targetPos + Vector3.new(0, 3, 0)
		return true
	elseif targetPos:IsA("BasePart") then
		root.CFrame = targetPos.CFrame + Vector3.new(0, 3, 0)
		return true
	elseif targetPos:IsA("Model") then
		local pivot = targetPos:GetPivot()
		root.CFrame = pivot + Vector3.new(0, 3, 0)
		return true
	end
	return false
end

function Features.InteractPrompt(prompt)
	if not prompt or not prompt:IsA("ProximityPrompt") then return false end
	pcall(function()
		prompt.HoldDuration = 0
		if fireproximityprompt then
			fireproximityprompt(prompt, 0)
			fireproximityprompt(prompt)
		else
			prompt:InputHoldBegin()
			prompt:InputHoldEnd()
		end
	end)
	return true
end

------------------------------------------------
-- 🏋️‍♂️ TRAINING (AUTO SQUAT & BARBELL)
------------------------------------------------
local isSquattingLoopActive = false
function Features.StartSquatLoop()
	if isSquattingLoopActive then return end
	isSquattingLoopActive = true

	local wasAutoSquatting = false

	task.spawn(function()
		while true do
			if Features.State.AutoSquat then
				wasAutoSquatting = true
				pcall(function()
					local myPlot = Features.GetMyPlot()
					local detector = myPlot and myPlot:FindFirstChild("SquatZone")
					if detector then detector = detector:FindFirstChild("Floor") end
					if detector then detector = detector:FindFirstChild("Detector") end

					local root = Features.GetRootPart()
					if detector and root then
						local dist = (Vector2.new(root.Position.X, root.Position.Z) - Vector2.new(detector.Position.X, detector.Position.Z)).Magnitude
						local isSquatting = LocalPlayer:GetAttribute("IsSquatting") == true

						if not isSquatting or dist > 6 then
							root.AssemblyLinearVelocity = Vector3.zero
							root.AssemblyAngularVelocity = Vector3.zero
							root.CFrame = CFrame.new(detector.Position.X, detector.Position.Y + 0.5, detector.Position.Z)
							task.wait(0.2)
							if SquatTrainingRequest then
								SquatTrainingRequest:FireServer(detector)
							end
						end
					end
				end)
			else
				if wasAutoSquatting then
					wasAutoSquatting = false
					pcall(function()
						local isSquatting = LocalPlayer:GetAttribute("IsSquatting") == true
						if isSquatting and StopSquattingRequest then
							StopSquattingRequest:FireServer()
						end
					end)
				end
			end
			task.wait(0.5)
		end
	end)
end

-- Squat Bonus Auto Claim
local lastClaimedBonusVersion = -1
task.spawn(function()
	while true do
		if Features.State.AutoSquatBonus then
			pcall(function()
				local isSquatting = LocalPlayer:GetAttribute("IsSquatting") == true
				local bonusAvailable = LocalPlayer:GetAttribute("SquatBonusAvailable") == true
				local versionVal = LocalPlayer:GetAttribute("SquatBonusVersion")
				local versionNum = math.floor(tonumber(versionVal) or 0)

				if isSquatting and bonusAvailable and versionNum > 0 and versionNum ~= lastClaimedBonusVersion then
					lastClaimedBonusVersion = versionNum
					task.wait(0.1)
					if SquatBonusRequest then
						SquatBonusRequest:FireServer(versionNum)
					end
				end
			end)
		end
		task.wait(0.25)
	end
end)

-- Auto Barbell Upgrade
task.spawn(function()
	while true do
		if Features.State.AutoUpgradeBarbell then
			pcall(function()
				local myPlot = Features.GetMyPlot()
				local upgradeB = myPlot and myPlot:FindFirstChild("SquatZone")
				if upgradeB then upgradeB = upgradeB:FindFirstChild("UpgradeB") end
				local prompt = upgradeB and upgradeB:FindFirstChildWhichIsA("ProximityPrompt", true)
				if prompt and prompt.Enabled then
					Features.InteractPrompt(prompt)
				end
			end)
		end
		task.wait(1.5)
	end
end)

------------------------------------------------
-- 🥚 EGG FARMING (AUTO STEAL, PLACE, HATCH)
------------------------------------------------
function Features.GetAllSpawnedEggs()
	local eggs = {}
	local map = Workspace:FindFirstChild("Map")
	local stages = map and map:FindFirstChild("Stages")
	if not stages then return eggs end

	local selStages = Features.State.SelectedStages or { ["All"] = true }
	local selAnimals = Features.State.SelectedAnimals or { ["All"] = true }

	for _, stage in ipairs(stages:GetChildren()) do
		local stageName = stage.Name
		if selStages["All"] or selStages[stageName] then
			local spawnedEggs = stage:FindFirstChild("SpawnedEggs")
			if spawnedEggs then
				for _, eggModel in ipairs(spawnedEggs:GetChildren()) do
					local eggName = eggModel.Name
					if selAnimals["All"] or selAnimals[eggName] then
						local prompt = eggModel:FindFirstChildWhichIsA("ProximityPrompt", true)
						local rootPart = eggModel:FindFirstChild("EggRoot") or eggModel:FindFirstChildWhichIsA("BasePart") or eggModel.PrimaryPart
						if prompt and prompt.Enabled and rootPart then
							table.insert(eggs, {
								Model = eggModel,
								Name = eggName,
								Stage = stageName,
								Prompt = prompt,
								Part = rootPart,
								Position = rootPart.Position
							})
						end
					end
				end
			end
		end
	end
	return eggs
end

-- Auto Steal Eggs Loop (Ultra-Fast Optimized)
local isStealLoopRunning = false
function Features.StartStealLoop()
	if isStealLoopRunning then return end
	isStealLoopRunning = true

	task.spawn(function()
		while true do
			if Features.State.AutoStealEggs then
				pcall(function()
					local carried = tonumber(LocalPlayer:GetAttribute("CarriedEggCount")) or 0
					local capacity = LocalPlayer:FindFirstChild("EggCarryCapacity") and LocalPlayer.EggCarryCapacity.Value or 1
					local root = Features.GetRootPart()

					if carried >= capacity then
						-- Full backpack -> Teleport directly to Plot Detector
						local myPlot = Features.GetMyPlot()
						if myPlot and root then
							local base = myPlot:FindFirstChild("Detector") or myPlot:FindFirstChild("DefaultSize") or myPlot:FindFirstChildWhichIsA("BasePart")
							if base then
								root.AssemblyLinearVelocity = Vector3.zero
								root.CFrame = base.CFrame + Vector3.new(0, 3, 0)
								task.wait(0.2)
							end
						end
					else
						-- Search for target eggs
						local eggs = Features.GetAllSpawnedEggs()
						if #eggs > 0 and root then
							-- Sort nearest egg to minimize travel
							table.sort(eggs, function(a, b)
								return (root.Position - a.Position).Magnitude < (root.Position - b.Position).Magnitude
							end)

							local targetEgg = eggs[1]
							if targetEgg and targetEgg.Part and targetEgg.Prompt and targetEgg.Prompt.Enabled then
								-- Instant Teleport & Zero Velocity
								root.AssemblyLinearVelocity = Vector3.zero
								root.AssemblyAngularVelocity = Vector3.zero
								root.CFrame = targetEgg.Part.CFrame + Vector3.new(0, 1.5, 0)
								task.wait(0.03)

								-- Instant ProximityPrompt trigger
								targetEgg.Prompt.HoldDuration = 0
								Features.InteractPrompt(targetEgg.Prompt)
								task.wait(Features.State.StealDelay or 0.05)
							end
						end
					end
				end)
			end
			task.wait(Features.State.StealDelay or 0.05)
		end
	end)
end

-- Auto Place Eggs onto Plot (Equips tool first & raycasts ground)
task.spawn(function()
	while true do
		if Features.State.AutoPlaceEggs then
			pcall(function()
				local myPlot = Features.GetMyPlot()
				if not myPlot then return end

				local eggsSettings = EggsSettings
				local regionName = eggsSettings and eggsSettings.Placement and eggsSettings.Placement.RegionName or "Detector"
				local detector = myPlot:FindFirstChild(regionName) or myPlot:FindFirstChild("Detector") or myPlot:FindFirstChild("DefaultSize") or myPlot:FindFirstChildWhichIsA("BasePart")
				if not detector then return end

				local backpack = LocalPlayer:FindFirstChild("Backpack")
				local char = Features.GetCharacter()
				local humanoid = Features.GetHumanoid()
				local selPlace = Features.State.SelectedPlaceEggs or { ["All"] = true }

				-- Scan Backpack and Character for Egg Tools
				local eggTools = {}
				local function checkTool(tool)
					if tool:IsA("Tool") and (tool:GetAttribute("IsEggTool") or tool:GetAttribute("EggId")) then
						local toolName = tool.Name -- e.g. "Chicken Egg", "Golden Retriver Egg"
						if selPlace["All"] or selPlace[toolName] then
							table.insert(eggTools, tool)
						end
					end
				end

				if backpack then
					for _, tool in ipairs(backpack:GetChildren()) do checkTool(tool) end
				end
				if char then
					for _, tool in ipairs(char:GetChildren()) do checkTool(tool) end
				end

				for _, tool in ipairs(eggTools) do
					local eggId = tool:GetAttribute("EggId")
					if eggId and PlaceEggRequest then
						-- 1. Equip the egg tool so character holds it
						if humanoid and tool.Parent == backpack then
							humanoid:EquipTool(tool)
							task.wait(0.15)
						end

						-- 2. Raycast to find exact plot ground
						local rx = detector.Position.X + math.random(-15, 15)
						local rz = detector.Position.Z + math.random(-15, 15)
						local origin = Vector3.new(rx, detector.Position.Y + 20, rz)
						local rayParams = RaycastParams.new()
						rayParams.FilterDescendantsInstances = { char, myPlot:FindFirstChild("PlacedEggs"), myPlot:FindFirstChild("PlacedAnimals") }
						rayParams.FilterType = Enum.RaycastFilterType.Exclude

						local rayResult = Workspace:Raycast(origin, Vector3.new(0, -50, 0), rayParams)
						local targetPos = rayResult and rayResult.Position or Vector3.new(rx, detector.Position.Y - detector.Size.Y * 0.5 + 0.1, rz)

						-- 3. Fire PlaceEggRequest
						PlaceEggRequest:FireServer(eggId, targetPos)
						task.wait(0.25)
					end
				end
			end)
		end
		task.wait(0.5)
	end
end)

-- Auto Hatch / Claim Ready Eggs
task.spawn(function()
	while true do
		if Features.State.AutoHatchEggs then
			pcall(function()
				local myPlot = Features.GetMyPlot()
				if myPlot then
					local placedEggs = myPlot:FindFirstChild("PlacedEggs")
					if placedEggs then
						for _, eggInstance in ipairs(placedEggs:GetChildren()) do
							local eggId = eggInstance:GetAttribute("EggId")
							local hatchReady = eggInstance:GetAttribute("HatchReady") == true
							local hatchAt = tonumber(eggInstance:GetAttribute("HatchAt")) or 0

							if eggId and (hatchReady or (hatchAt > 0 and Workspace:GetServerTimeNow() >= hatchAt)) then
								if PetInventoryRemote then
									PetInventoryRemote:FireServer("EggAction", eggId)
								end
							end
						end
					end
				end
			end)
		end
		task.wait(1.5)
	end
end)

-- Auto Equip Best Pets
task.spawn(function()
	while true do
		if Features.State.AutoEquipBest then
			pcall(function()
				if PetInventoryRemote then
					PetInventoryRemote:FireServer("EquipBest")
				end
			end)
		end
		task.wait(5)
	end
end)

-- Auto Pen / Equip Slot Upgrade
task.spawn(function()
	while true do
		if Features.State.AutoUpgradePen then
			pcall(function()
				if PetInventoryRemote then
					PetInventoryRemote:FireServer("BuyEquipSlot")
				end
			end)
		end
		task.wait(2)
	end
end)

-- Auto Sell Animals (Equips selected animals and sells at sell zone)
task.spawn(function()
	while true do
		if Features.State.AutoSellPets then
			pcall(function()
				local backpack = LocalPlayer:FindFirstChild("Backpack")
				local char = Features.GetCharacter()
				local humanoid = Features.GetHumanoid()
				local root = Features.GetRootPart()
				local sellZone = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Sell")
				local detector = sellZone and sellZone:FindFirstChild("Detector")
				if not detector or not root or not humanoid then return end

				local selSell = Features.State.SelectedSellAnimals or { ["All"] = true }

				-- Scan Backpack and Character for Animals (Pet Tools)
				local animalsToSell = {}
				local function checkPet(tool)
					if tool:IsA("Tool") and (tool:GetAttribute("IsPetInventoryTool") or tool:GetAttribute("PetId")) then
						local animalName = tool:GetAttribute("AnimalName") or tool.Name -- e.g. "Pigeon", "Coral Goby"
						if selSell["All"] or selSell[animalName] or selSell[tool.Name] then
							table.insert(animalsToSell, tool)
						end
					end
				end

				if backpack then
					for _, tool in ipairs(backpack:GetChildren()) do checkPet(tool) end
				end
				if char then
					for _, tool in ipairs(char:GetChildren()) do checkPet(tool) end
				end

				if #animalsToSell > 0 then
					-- Teleport to sell zone
					root.CFrame = detector.CFrame + Vector3.new(0, 3, 0)
					task.wait(0.2)

					for _, tool in ipairs(animalsToSell) do
						if tool and tool.Parent and (tool.Parent == backpack or tool.Parent == char) then
							if tool.Parent == backpack then
								humanoid:EquipTool(tool)
								task.wait(0.15)
							end
							if SellRemote then
								SellRemote:FireServer()
							end
							task.wait(0.3)
						end
					end
				end
			end)
		end
		task.wait(2.0)
	end
end)

------------------------------------------------
-- 🛒 SHOPS & AUTOMATED BOOSTERS
------------------------------------------------
-- Auto Buy Best Trails
task.spawn(function()
	while true do
		if Features.State.AutoBuyTrails then
			pcall(function()
				if TrailsRemote and TrailsSettings and TrailsSettings.List then
					local cashVal = LocalPlayer:FindFirstChild("leaderstats") and LocalPlayer.leaderstats:FindFirstChild("Cash")
					local currentCash = 0
					if cashVal then
						local raw = tostring(cashVal.Value):gsub("%$", ""):gsub(",", "")
						currentCash = tonumber(raw) or 0
					end

					for trailName, trailInfo in pairs(TrailsSettings.List) do
						if trailInfo.Cost and currentCash >= trailInfo.Cost then
							TrailsRemote:FireServer("Select", trailName)
						end
					end
				end
			end)
		end
		task.wait(4)
	end
end)

-- Auto Buy Speed Coils
task.spawn(function()
	while true do
		if Features.State.AutoBuyCoils then
			pcall(function()
				if CoilsRemote then
					local coilNames = { "Speed Coil", "Super Speed Coil", "Hyper Speed Coil", "Fusion Coil" }
					for _, name in ipairs(coilNames) do
						CoilsRemote:FireServer("Select", name)
					end
				end
			end)
		end
		task.wait(5)
	end
end)

-- Auto Claim Animal Index Rewards
task.spawn(function()
	while true do
		if Features.State.AutoClaimIndex then
			pcall(function()
				if ClaimAnimalIndexReward then
					ClaimAnimalIndexReward:FireServer("__ALL__")
				end
			end)
		end
		task.wait(10)
	end
end)

-- Auto Claim Offline Rewards
task.spawn(function()
	while true do
		if Features.State.AutoClaimOffline then
			pcall(function()
				if OfflineRewardsRemote then
					OfflineRewardsRemote:FireServer("Claim")
				end
			end)
		end
		task.wait(15)
	end
end)

-- Auto Claim Group Reward
task.spawn(function()
	while true do
		if Features.State.AutoClaimGroup then
			pcall(function()
				if GroupRewardRemote then
					GroupRewardRemote:FireServer("Claim")
				end
			end)
		end
		task.wait(30)
	end
end)

-- Auto Golden Mutation Machine
task.spawn(function()
	while true do
		if Features.State.AutoGoldMutation then
			pcall(function()
				local map = Workspace:FindFirstChild("Map")
				local mutations = map and map:FindFirstChild("Mutations")
				local detector = mutations and mutations:FindFirstChild("Detector")
				local prompt = detector and detector:FindFirstChild("MutationPrompt")
				if prompt and prompt.Enabled then
					Features.InteractPrompt(prompt)
				end
			end)
		end
		task.wait(1)
	end
end)

------------------------------------------------
-- 🛡️ DEFENSE & GODMODE
------------------------------------------------
task.spawn(function()
	while true do
		if Features.State.DisableGuards then
			pcall(function()
				local map = Workspace:FindFirstChild("Map")
				local clientGuards = map and map:FindFirstChild("ClientGuards")
				if clientGuards then
					for _, g in ipairs(clientGuards:GetChildren()) do
						g:Destroy()
					end
				end
			end)
		end
		task.wait(0.5)
	end
end)

------------------------------------------------
-- ⚡ MOVEMENT & PLAYER HACKS
------------------------------------------------
-- Speed & Jump Modification
RunService.RenderStepped:Connect(function()
	pcall(function()
		local hum = Features.GetHumanoid()
		if hum then
			if Features.State.SpeedEnabled then
				hum.WalkSpeed = Features.State.WalkSpeed
			end
			if Features.State.JumpEnabled then
				hum.JumpPower = Features.State.JumpPower
			end
		end
	end)
end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
	if Features.State.InfiniteJump then
		pcall(function()
			local hum = Features.GetHumanoid()
			if hum then
				hum:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end)
	end
end)

-- Noclip Handler
RunService.Stepped:Connect(function()
	if Features.State.Noclip then
		pcall(function()
			local char = Features.GetCharacter()
			if char then
				for _, part in ipairs(char:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CanCollide = false
					end
				end
			end
		end)
	end
end)

-- Smooth Fly System
local flyBodyVelocity, flyBodyGyro
local function setupFly()
	local root = Features.GetRootPart()
	if not root then return end

	flyBodyVelocity = Instance.new("BodyVelocity")
	flyBodyVelocity.Name = "HipHub_FlyVelocity"
	flyBodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
	flyBodyVelocity.Velocity = Vector3.zero
	flyBodyVelocity.Parent = root

	flyBodyGyro = Instance.new("BodyGyro")
	flyBodyGyro.Name = "HipHub_FlyGyro"
	flyBodyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
	flyBodyGyro.CFrame = root.CFrame
	flyBodyGyro.Parent = root
end

local function cleanupFly()
	if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
	if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
end

RunService.RenderStepped:Connect(function()
	if Features.State.FlyEnabled then
		pcall(function()
			local root = Features.GetRootPart()
			if not root then return end
			if not flyBodyVelocity or not flyBodyGyro then
				setupFly()
			end

			local camCF = Camera.CFrame
			local moveDir = Vector3.zero

			if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camCF.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camCF.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camCF.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camCF.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end

			if flyBodyVelocity and flyBodyGyro then
				flyBodyVelocity.Velocity = moveDir.Unit * Features.State.FlySpeed
				if moveDir.Magnitude == 0 then
					flyBodyVelocity.Velocity = Vector3.zero
				end
				flyBodyGyro.CFrame = camCF
			end
		end)
	else
		cleanupFly()
	end
end)

------------------------------------------------
-- 👁️ VISUALS & ESP SYSTEM
------------------------------------------------
local espInstances = {}

local function clearESP()
	for _, inst in ipairs(espInstances) do
		if inst and inst.Parent then
			inst:Destroy()
		end
	end
	table.clear(espInstances)
end

function Features.UpdateESP()
	clearESP()

	-- Egg ESP
	if Features.State.EggESP then
		pcall(function()
			local map = Workspace:FindFirstChild("Map")
			local stages = map and map:FindFirstChild("Stages")
			local espStages = Features.State.ESPSelectedStages or { ["All"] = true }
			if stages then
				for _, stage in ipairs(stages:GetChildren()) do
					local stageName = stage.Name
					if espStages["All"] or espStages[stageName] then
						local spawnedEggs = stage:FindFirstChild("SpawnedEggs")
						if spawnedEggs then
							for _, eggModel in ipairs(spawnedEggs:GetChildren()) do
								local rootPart = eggModel:FindFirstChild("EggRoot") or eggModel:FindFirstChildWhichIsA("BasePart") or eggModel.PrimaryPart
								if rootPart then
									local bb = Instance.new("BillboardGui")
									bb.Name = "HipHub_EggESP"
									bb.Adornee = rootPart
									bb.Size = UDim2.new(0, 140, 0, 40)
									bb.StudsOffset = Vector3.new(0, 2.5, 0)
									bb.AlwaysOnTop = true
									bb.Parent = rootPart

									local lbl = Instance.new("TextLabel")
									lbl.Size = UDim2.new(1, 0, 1, 0)
									lbl.BackgroundTransparency = 1
									lbl.Text = string.format("🥚 %s\n[%s]", eggModel.Name, stageName)
									lbl.TextColor3 = Color3.fromRGB(0, 200, 255)
									lbl.TextStrokeTransparency = 0.2
									lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
									lbl.TextSize = 12
									lbl.Font = Enum.Font.GothamBold
									lbl.Parent = bb
									table.insert(espInstances, bb)

									local highlight = Instance.new("Highlight")
									highlight.Name = "HipHub_EggHighlight"
									highlight.Adornee = eggModel
									highlight.FillColor = Color3.fromRGB(0, 200, 255)
									highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
									highlight.FillTransparency = 0.6
									highlight.OutlineTransparency = 0.2
									highlight.Parent = eggModel
									table.insert(espInstances, highlight)
								end
							end
						end
					end
				end
			end
		end)
	end

	-- Player ESP
	if Features.State.PlayerESP then
		pcall(function()
			for _, otherPlayer in ipairs(Players:GetPlayers()) do
				if otherPlayer ~= LocalPlayer and otherPlayer.Character then
					local root = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
					if root then
						local bb = Instance.new("BillboardGui")
						bb.Name = "HipHub_PlayerESP"
						bb.Adornee = root
						bb.Size = UDim2.new(0, 140, 0, 35)
						bb.StudsOffset = Vector3.new(0, 3, 0)
						bb.AlwaysOnTop = true
						bb.Parent = root

						local lvlVal = otherPlayer:FindFirstChild("leaderstats") and otherPlayer.leaderstats:FindFirstChild("Level")
						local lvlText = lvlVal and tostring(lvlVal.Value) or "?"

						local lbl = Instance.new("TextLabel")
						lbl.Size = UDim2.new(1, 0, 1, 0)
						lbl.BackgroundTransparency = 1
						lbl.Text = string.format("👤 %s\n[Lvl %s]", otherPlayer.DisplayName, lvlText)
						lbl.TextColor3 = Color3.fromRGB(6, 182, 212)
						lbl.TextStrokeTransparency = 0.2
						lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
						lbl.TextSize = 11
						lbl.Font = Enum.Font.GothamBold
						lbl.Parent = bb

						table.insert(espInstances, bb)
					end
				end
			end
		end)
	end
end

-- Refresh ESP periodically
task.spawn(function()
	while true do
		if Features.State.EggESP or Features.State.PlayerESP or Features.State.GuardESP then
			Features.UpdateESP()
		else
			clearESP()
		end
		task.wait(2)
	end
end)

------------------------------------------------
-- 🛡️ ANTI-AFK & PERFORMANCE UTILITIES
------------------------------------------------
LocalPlayer.Idled:Connect(function()
	if Features.State.AntiAfk then
		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.zero)
		end)
	end
end)

function Features.SetLowGraphics(enable)
	pcall(function()
		local Lighting = game:GetService("Lighting")
		if enable then
			Lighting.GlobalShadows = false
			Lighting.FogEnd = 9e9
			for _, v in ipairs(Lighting:GetChildren()) do
				if v:IsA("PostEffect") then v.Enabled = false end
			end
		else
			Lighting.GlobalShadows = true
			for _, v in ipairs(Lighting:GetChildren()) do
				if v:IsA("PostEffect") then v.Enabled = true end
			end
		end
	end)
end

------------------------------------------------
-- 🚀 INITIALIZATION
------------------------------------------------
function Features.Init()
	Features.StartSquatLoop()
	Features.StartStealLoop()
	print("[HipHub JFA Features] Loops and listeners initialized.")
end

local env = (getgenv and getgenv()) or _G
env.HipHubFeatures = Features
_G.HipHubFeatures = Features
if shared then shared.HipHubFeatures = Features end
