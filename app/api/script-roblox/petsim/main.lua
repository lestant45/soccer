-- ==============================================================================
-- 🐾 HipHub Main Controller — Pet Simulator 99
-- Wires up HipHub Liquid Glass UI, Feature Callbacks & Lifecycle Management
-- ==============================================================================


repeat task.wait() until game:IsLoaded()

if setthreadidentity then
    pcall(setthreadidentity, 8)
end




if getgenv then
    if getgenv().FlowPS99Unload then
        local prevUnload = getgenv().FlowPS99Unload
        getgenv().FlowPS99Unload = nil
        task.spawn(function() pcall(prevUnload) end)
    end
    local prevWindow = getgenv().HipHubUI_Window
    getgenv().HipHubUI_Window = nil
    if prevWindow then
        task.spawn(function()
            pcall(function()
                if type(prevWindow.Destroy) == "function" then
                    prevWindow:Destroy()
                elseif type(prevWindow.Close) == "function" then
                    prevWindow:Close()
                end
            end)
        end)
    end
    getgenv().FlowPS99LoadedAt = os.clock()
end



if getgenv then getgenv().FlowPS99Generation = (tonumber(getgenv().FlowPS99Generation) or 0) + 1 end
local flowSessionGeneration = (getgenv and getgenv().FlowPS99Generation) or 1







task.spawn(function()
Window = FlowLibrary.new({})
if getgenv then getgenv().HipHubUI_Window = Window end
HubSection = Window:CreateSection({})

Window:SetToggleKey(Enum.KeyCode.RightAlt)

FarmingTab = HubSection:AddTab({Name = "Farming", Icon = "loop"})
BreedingTab = HubSection:AddTab({Name = "Eggs", Icon = "rbxassetid://12120698352"})
MarketTab = HubSection:AddTab({Name = "Market", Icon = "cart"})
ProgressTab = HubSection:AddTab({Name = "Progress", Icon = "star"})
InventoryTab = HubSection:AddTab({Name = "Inventory", Icon = "bag"})
GamesTab = HubSection:AddTab({Name = "Games", Icon = "gamepad"})
HeroesTab = HubSection:AddTab({Name = "Misc", Icon = "sword"})
WorldTab = HubSection:AddTab({Name = "World", Icon = "gps"})
CharacterTab = HubSection:AddTab({Name = "Character", Icon = "user"})
ToolsTab = HubSection:AddTab({Name = "Tools", Icon = "settings"})

WorldGroup = FarmingTab:AddGroup({Name = "Auto Farm"})
ActivityGroup = FarmingTab:AddGroup({Name = "Smart Autos"})
FarmWorldGroup = FarmingTab:AddGroup({Name = "Farm World"})
EggsGroup = BreedingTab:AddGroup({Name = "Hatch Eggs"})
EggSlotGroup = BreedingTab:AddGroup({Name = "Egg Slots"})
RewardAutomationGroup = BreedingTab:AddGroup({Name = "Daycare / Goals"})
ShopGroup = MarketTab:AddGroup({Name = "Vending & Merchant"})
ShopUpgradeGroup = MarketTab:AddGroup({Name = "Machine Upgrades"})
GiftGroup = MarketTab:AddGroup({Name = "Free Gifts"})
RewardsGroup = ProgressTab:AddGroup({Name = "Rank Rewards"})
RNGRollGroup = ProgressTab:AddGroup({Name = "RNG Rolls"})
RNGUpgradeGroup = ProgressTab:AddGroup({Name = "RNG Upgrades"})
ItemFlagsGroup = InventoryTab:AddGroup({Name = "Flags"})
ItemUtilityGroup = InventoryTab:AddGroup({Name = "Utility Items"})
ItemFruitGroup = InventoryTab:AddGroup({Name = "Fruits"})
ItemBoostGroup = InventoryTab:AddGroup({Name = "Boosts"})
KeyHelperGroup = InventoryTab:AddGroup({Name = "Keys"})
InstanceGroup = GamesTab:AddGroup({Name = "Join / Rewards"})
InstanceAutomationGroup = GamesTab:AddGroup({Name = "Minigame Autos"})
MinigameAutomationGroup = GamesTab:AddGroup({Name = "Digsite / Fishing"})
MoreMinigameGroup = GamesTab:AddGroup({Name = "Extras"})
CurrentEventGroup = HeroesTab:AddGroup({Name = "Tap Heroes / Gauntlet"})
TapHeroesAutomationGroup = HeroesTab:AddGroup({Name = "Automation"})
TapHeroesItemsGroup = HeroesTab:AddGroup({Name = "Event Items"})
SoccerEventGroup = WorldTab:AddGroup({Name = "World Cup"})
EventDirectoryGroup = WorldTab:AddGroup({Name = "Live Data"})
MovementGroup = CharacterTab:AddGroup({Name = "Movement"})
FlyGroup = CharacterTab:AddGroup({Name = "Flight"})
PerformanceGroup = CharacterTab:AddGroup({Name = "Performance"})
MiscGroup = ToolsTab:AddGroup({Name = "Server & Safety"})

WorldGroup:AddLabel({
    Text = "Anti-staff protection starts automatically when a feature needs it. RightAlt toggles the UI.",
    Wrap = true
})

WorldGroup:AddDropdown({
    Name = "Breakable Farm Method",
    Options = breakableFarmMethodValues,
    Default = selectedBreakableFarmMethod,
    Callback = function(option)
        selectedBreakableFarmMethod = option
        getgenv().breakableFarmConfig.METHOD = option
    end
})

WorldGroup:AddDropdown({
    Name = "Breakable Farm Zone",
    OptionsProvider = function()
        return breakableFarmZoneValues
    end,
    Default = selectedBreakableFarmZone or breakableFarmZoneValues[1],
    AutoRefresh = true,
    RefreshInterval = 2,
    Callback = function(option)
        selectedBreakableFarmZone = option
        getgenv().breakableFarmConfig.ZONE = option
    end
})

WorldGroup:AddDropdown({
    Name = "Breakable Filter",
    Options = breakableFarmFilterValues,
    Default = selectedBreakableFarmFilters[1] or "Any",
    Callback = function(option)
        selectedBreakableFarmFilters = { option or "Any" }
        getgenv().breakableFarmConfig.FILTERS = cloneArray(selectedBreakableFarmFilters)
    end
})

WorldGroup:AddToggle({
    Name = "Auto Breakable Farm",
    Default = false,
    Callback = function(state)
        local function setRunning(value)
            autoBreakableFarmRunning = value
        end
        if state then
            stopAutomationWorker("WorldFarm", function(value) autoWorldFarmRunning = value end)
            stopAutomationWorker("CurrentStage", function(value) autoCurrentStageFarmRunning = value end)
            stopAutomationWorker("AutoQuest", function(value) autoQuestRunning = value end)
            stopAutomationWorker("AutoChest", function(value) getgenv().autoChest = value end)
            startAutomationWorker("BreakableFarm", setRunning, runAutoBreakableFarm)
        else
            stopAutomationWorker("BreakableFarm", setRunning)
            clearOwnedPetTargets()
        end
    end
})

WorldGroup:AddToggle({
    Name = "Auto Farm Current Stage",
    Default = false,
    Callback = function(state)
        local function setRunning(value)
            autoCurrentStageFarmRunning = value
        end
        if state then
            stopAutomationWorker("BreakableFarm", function(value) autoBreakableFarmRunning = value end)
            stopAutomationWorker("WorldFarm", function(value) autoWorldFarmRunning = value end)
            stopAutomationWorker("AutoQuest", function(value) autoQuestRunning = value end)
            stopAutomationWorker("AutoChest", function(value) getgenv().autoChest = value end)
            startAutomationWorker("CurrentStage", setRunning, runCurrentStageFarm)
        else
            stopAutomationWorker("CurrentStage", setRunning)
            clearOwnedPetTargets()
        end
    end
})

WorldGroup:AddToggle({
    Name = "Auto Farm To End",
    Default = false,
    Callback = function(state)
        local function setRunning(value)
            autoWorldFarmRunning = value
        end
        if state then
            stopAutomationWorker("BreakableFarm", function(value) autoBreakableFarmRunning = value end)
            stopAutomationWorker("CurrentStage", function(value) autoCurrentStageFarmRunning = value end)
            stopAutomationWorker("AutoQuest", function(value) autoQuestRunning = value end)
            stopAutomationWorker("AutoChest", function(value) getgenv().autoChest = value end)
            startAutomationWorker("WorldFarm", setRunning, runAutoWorldFarm)
        else
            stopAutomationWorker("WorldFarm", setRunning)
            clearOwnedPetTargets()
        end
    end
})

WorldGroup:AddToggle({
    Name = "Auto Farm Chests",
    Default = false,
    Callback = function(state)
        local function setRunning(value)
            getgenv().autoChest = value
        end
        if state then
            stopAutomationWorker("BreakableFarm", function(value) autoBreakableFarmRunning = value end)
            stopAutomationWorker("CurrentStage", function(value) autoCurrentStageFarmRunning = value end)
            stopAutomationWorker("WorldFarm", function(value) autoWorldFarmRunning = value end)
            startAutomationWorker("AutoChest", setRunning, function()
            ensureAntiStaff()
            ensurePetSpeed()
            local function isRunning()
                return getgenv().autoChest and not getgenv().STAFF_DETECTED
            end
            if not waitForRunningDelay(getgenv().autoChestConfig.START_DELAY, isRunning) then
                return
            end
            local mapPath = getCurrentMap()
            local BigChests = getBigChestZones()
            if not mapPath or next(BigChests) == nil then
                warn("No chest route available in this world.")
                return
            end
            local Workspace = game:GetService("Workspace")
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local Library = ReplicatedStorage:WaitForChild("Library")
            local Client = Library:WaitForChild("Client")
            local LocalPlayer = game:GetService("Players").LocalPlayer
            local function trim(string)
                if not string then
                    return false
                end
                return string:match("^%s*(.-)%s*$")
            end
            local function split(input, separator)
                if separator == nil then
                    separator = "%s"
                end
                local parts = {}
                for str in string.gmatch(input, "([^" .. separator .. "]+)") do
                    table.insert(parts, str)
                end
                return parts
            end
            local zonePath
            local function teleportToZone(selectedZone)
                local teleported = false
                while not teleported and getgenv().autoChest do
                    for _, v in pairs(mapPath:GetChildren()) do
                        local zoneName = trim(split(v.Name, "|")[2])
                        if zoneName and zoneName == selectedZone then
                            LocalPlayer.Character.HumanoidRootPart.CFrame = mapPath[v.Name].PERSISTENT.Teleport.CFrame
                            teleported = true
                            break
                        end
                    end
                    task.wait()
                end
                return teleported
            end
            local function waitForLoad(zone)
                zonePath = nil
                for _, v in pairs(mapPath:GetChildren()) do
                    local zoneName = trim(split(v.Name, "|")[2])
                    if zoneName and zoneName == zone then
                        zonePath = mapPath[v.Name]
                        break
                    end
                end
                if not zonePath or not getgenv().autoChest then
                    return false
                end
                if not zonePath:FindFirstChild("INTERACT") then
                    local loaded = false
                    local detectLoad = zonePath.ChildAdded:Connect(function(child)
                        if child.Name == "INTERACT" then
                            loaded = true
                        end
                    end)
                    repeat
                        task.wait()
                    until loaded or not getgenv().autoChest
                    detectLoad:Disconnect()
                    if not getgenv().autoChest then
                        return false
                    end
                end
                local function getBreakZonesAmount()
                    local counter = 0
                    for _ in pairs(zonePath.INTERACT.BREAK_ZONES:GetChildren()) do
                        counter = counter + 1
                    end
                    return counter
                end
                if getBreakZonesAmount() < 2 then
                    local loaded = false
                    local detectLoad = zonePath.INTERACT.BREAK_ZONES.ChildAdded:Connect(function(_)
                        if getBreakZonesAmount() == 2 then
                            loaded = true
                        end
                    end)
                    repeat
                        task.wait()
                    until loaded or not getgenv().autoChest
                    detectLoad:Disconnect()
                end
                return getgenv().autoChest == true
            end
            local function breakChest(zone)
                local chest
                while not chest and getgenv().autoChest do
                    for v in require(Client.BreakableCmds).AllByZoneAndClass(zone, "Chest") do
                        chest = v
                        break
                    end
                    task.wait()
                end
                if not chest or not getgenv().autoChest then
                    return false
                end
                if getgenv().autoChestConfig.SEND_PETS then
                    setEquippedPetsTarget(chest)
                end
                local brokeChest = false
                local breakableRemovedService = Workspace:WaitForChild("__THINGS").Breakables.ChildRemoved:Connect(function(breakable)
                    if breakable.Name == chest then
                        brokeChest = true
                        print("Broke chest")
                    end
                end)
                local chestOk, chestError = pcall(function()
                    if not isRunning() then
                        return
                    end
                    LocalPlayer.Character.HumanoidRootPart.CFrame = zonePath.INTERACT.BREAKABLE_SPAWNS.Boss.CFrame
                    repeat
                        if not isRunning() then
                            break
                        end
                        pcall(function()
                            local clientNet = require(Library.Client.Network)
                            if clientNet and clientNet.Fire then
                                clientNet.Fire("Breakables_PlayerDealDamage", chest)
                            end
                        end)
                        pcall(function()
                            local remote = ReplicatedStorage.Network:FindFirstChild("Breakables_PlayerDealDamage")
                            if remote then
                                remote:FireServer(chest)
                            end
                        end)
                        task.wait()
                    until brokeChest or not isRunning()
                end)
                disconnectConnection(breakableRemovedService)
                if not chestOk then
                    warn("[Chest] Farm action failed and listener was cleaned up: " .. tostring(chestError))
                    return false
                end
                return brokeChest
            end
            local function isWithinRange(part)
                local position
                if part:IsA("Model") then
                    position = part:GetPivot().Position
                elseif part:IsA("BasePart") then
                    position = part.Position
                end
                return position ~= nil
                    and (LocalPlayer.Character.HumanoidRootPart.Position - position).Magnitude <= 300
            end
            local function autoChest()
                local sortedKeys = {}
                for key in pairs(BigChests) do
                    table.insert(sortedKeys, key)
                end
                table.sort(sortedKeys)
                for _, key in ipairs(sortedKeys) do
                    if not getgenv().autoChest or getgenv().STAFF_DETECTED then
                        return
                    end
                    local zoneName = BigChests[key]
                    print("Starting " .. zoneName)
                    if not teleportToZone(zoneName) or not waitForLoad(zoneName) then
                        return
                    end
                    local timerFound = false
                    while not timerFound and getgenv().autoChest do
                        for _, v in pairs(Workspace.__DEBRIS:GetChildren()) do
                            local timer
                            local isTimer, _ = pcall(function()
                                timer = v.ChestTimer.Timer.Text
                            end)
                            if v.Name == "host" and isTimer and isWithinRange(v) then
                                timerFound = true
                                if timer == "00:00" then
                                    print(zoneName .. " chest is available")
                                    breakChest(zoneName)
                                else
                                    print(zoneName .. " chest is not available " .. timer)
                                end
                                break
                            end
                        end
                        if not waitForRunningDelay(getgenv().autoChestConfig.TIMER_SEARCH_DELAY, isRunning) then
                            return
                        end
                    end
                    warn("Finished " .. zoneName)
                    if getgenv().STAFF_DETECTED then
                        return
                    end
                    if not waitForRunningDelay(getgenv().autoChestConfig.CHEST_BREAK_DELAY, isRunning) then
                        return
                    end
                end
            end
            if not getgenv().autoChest then
                return
            end
                while isRunning() do
                    local originalPosition = LocalPlayer.Character.HumanoidRootPart.CFrame
                    autoChest()
                    if getgenv().STAFF_DETECTED then
                        getgenv().autoChest = false
                        break
                    end
                    if not getgenv().autoChestConfig.SERVER_HOP then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = originalPosition
                        print("Waiting 10 minutes for chests to respawn")
                        waitForRunningDelay(600, isRunning)
                    else
                        print("Server hopping in " .. getgenv().autoChestConfig.SERVER_HOP_DELAY .. " seconds")
                        local generation = automationCancellationGeneration
                        if waitForAutomationDelay(getgenv().autoChestConfig.SERVER_HOP_DELAY, function()
                            return getgenv().autoChest
                        end, generation) and getgenv().autoChest then
                            serverHop()
                        end
                    end
                end
            end, false)
        else
            stopAutomationWorker("AutoChest", setRunning)
            clearOwnedPetTargets()
        end
    end
})

ActivityGroup:AddToggle({
    Name = "Auto Quest",
    Default = false,
    Callback = function(state)
        local function setRunning(value)
            autoQuestRunning = value
        end
        if state then
            stopAutomationWorker("EggHatcher", function(value) autoEggHatcherRunning = value end)
            startAutomationWorker("AutoQuest", setRunning, runAutoQuest)
        else
            stopAutomationWorker("AutoQuest", setRunning)
            clearOwnedPetTargets()
        end
    end
})

ActivityGroup:AddToggle({
    Name = "Auto Quest Hop If Stuck",
    Default = getgenv().autoQuestConfig.STUCK_HOP_ENABLED == true,
    Callback = function(state)
        getgenv().autoQuestConfig.STUCK_HOP_ENABLED = state
    end
})

MinigameAutomationGroup:AddLabel({
    Text = "Quick autos for older minigames.",
    Wrap = true
})

MinigameAutomationGroup:AddToggle({
    Name = "Auto Chest Raid",
    Default = false,
    Callback = function(state)
        local function setRunning(value)
            getgenv().autoChestRaidRunning = value
        end
        if state then
            startAutomationWorker("ChestRaid", setRunning, function()
                local lootbagConn
                local raidOk, raidError = pcall(function()
                    local Players = game:GetService("Players")
                    local ReplicatedStorage = game:GetService("ReplicatedStorage")
                    local Workspace = game:GetService("Workspace")
                    local Things = Workspace:FindFirstChild("__THINGS")
                    local Breakables = Things and Things:FindFirstChild("Breakables")
                    local instanceContainer = Things and Things:FindFirstChild("__INSTANCE_CONTAINER")
                    local Active = instanceContainer and instanceContainer:FindFirstChild("Active")
                    local LocalPlayer = Players.LocalPlayer
                    if not Things or not Breakables or not Active then
                        error("Chest Raid folders are unavailable.")
                    end

                if not Active:FindFirstChild("ChestRaid") then
                    enterInstance("ChestRaid")
                    repeat
                        task.wait(0.1)
                    until Active:FindFirstChild("ChestRaid") or not getgenv().autoChestRaidRunning
                end

                local lootbags = Things:FindFirstChild("Lootbags")
                if lootbags and Network:FindFirstChild("Lootbags_Claim") then
                    lootbagConn = lootbags.ChildAdded:Connect(function(lootbag)
                        if not getgenv().autoChestRaidRunning then
                            return
                        end
                        task.wait(0.05)
                        if getgenv().autoChestRaidRunning then
                            claimLootbag(lootbag)
                        end
                    end)
                end

                repeat
                    task.wait(0.05)
                until Active:FindFirstChild("ChestRaid") or not getgenv().autoChestRaidRunning

                if not getgenv().autoChestRaidRunning then
                    return
                end
                ensurePetSpeed()
                if not getgenv().autoChestRaidRunning then
                    return
                end
                setRootAnchored(true, "ChestRaid")

                while getgenv().autoChestRaidRunning and Active:FindFirstChild("ChestRaid") do
                    while #Breakables:GetChildren() == 0 and getgenv().autoChestRaidRunning do
                        task.wait(0.05)
                    end

                    local closestBreakable
                    local closestDist = 999

                    for _, v in pairs(Breakables:GetChildren()) do
                        local top = v and v:FindFirstChild("Top")
                        local bottom = v and v:FindFirstChild("Bottom")
                        if v and top and bottom and v:GetAttribute("ParentID") == "ChestRaid" then
                            local dist = (LocalPlayer.Character.HumanoidRootPart.Position - top.Position).Magnitude
                            if dist < closestDist then
                                closestBreakable = {
                                    ["CFrame"] = bottom.CFrame,
                                    ["Name"] = v.Name
                                }
                                closestDist = dist
                            end
                        end
                    end

                    if closestBreakable then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = closestBreakable.CFrame
                        setEquippedPetsTarget(closestBreakable.Name)
                        repeat
                            if not getgenv().autoChestRaidRunning then break end
                            pcall(function()
                                local clientNet = require(Library.Client.Network)
                                if clientNet and clientNet.Fire then
                                    clientNet.Fire("Breakables_PlayerDealDamage", closestBreakable.Name)
                                end
                            end)
                            pcall(function()
                                local remote = ReplicatedStorage.Network:FindFirstChild("Breakables_PlayerDealDamage")
                                if remote then
                                    remote:FireServer(closestBreakable.Name)
                                end
                            end)
                            task.wait(0.05)
                        until not Breakables:FindFirstChild(closestBreakable.Name)
                    else
                        task.wait(0.05)
                    end
                end

                end)
                restoreRootAnchored("ChestRaid")
                disconnectConnection(lootbagConn)
                clearOwnedPetTargets()
                if not raidOk then
                    error(raidError, 0)
                end
            end)
        else
            stopAutomationWorker("ChestRaid", setRunning)
            restoreRootAnchored("ChestRaid")
            clearOwnedPetTargets()
        end
    end
})

ActivityGroup:AddToggle({
    Name = "Auto Shiny Relic",
    Default = false,
    Callback = function(state)
        local function setRunning(value)
            getgenv().autoShinyRelicRunning = value
        end
        if state then
            startAutomationWorker("ShinyRelic", setRunning, runAutoShinyRelic, false)
        else
            stopAutomationWorker("ShinyRelic", setRunning)
        end
    end
})

ActivityGroup:AddToggle({
    Name = "Auto Balloon + Chest",
    Default = getgenv().autoBalloonChest == true,
    Callback = function(state)
        if state then
            getgenv().autoChest = false
            stopAutomationWorker("AutoChest", function(value) getgenv().autoChest = value end)
            startAutomationWorker("BalloonChest", setAutoBalloonChestRunning, runAutoBalloonChest, false)
        else
            stopAutomationWorker("BalloonChest", setAutoBalloonChestRunning)
            restoreRootAnchored("Balloon")
            clearOwnedPetTargets()
        end
    end
})

MinigameAutomationGroup:AddToggle({
    Name = "Auto Digsite",
    Default = false,
    Callback = function(state)
        local function setRunning(value)
            autoDigsiteRunning = value
            getgenv().autoDigsite = value
        end
        if state then
            startAutomationWorker("AutoDigsite", setRunning, runAutoDigsite)
        else
            stopAutomationWorker("AutoDigsite", setRunning)
            disableActiveAutoMine()
        end
    end
})

MinigameAutomationGroup:AddToggle({
    Name = "Auto Fishing",
    Default = false,
    Callback = function(state)
        local function setRunning(value)
            autoFishingRunning = value
            getgenv().autoFishing = value
        end
        if state then
            startAutomationWorker("AutoFishing", setRunning, runAutoFishing)
        else
            stopAutomationWorker("AutoFishing", setRunning)
            restoreFishingState()
        end
    end
})

MinigameAutomationGroup:AddToggle({
    Name = "Optimize Advanced Fishing",
    Default = getgenv().autoFishingConfig.OPTIMIZE_GAME == true,
    Callback = function(state)
        getgenv().autoFishingConfig.OPTIMIZE_GAME = state
        if state and autoFishingRunning then
            pcall(optimizeFishing)
        elseif not state then
            restoreFishingState()
        end
    end
})

MinigameAutomationGroup:AddToggle({
    Name = "Hide Players While Fishing",
    Default = getgenv().autoFishingConfig.HIDE_PLAYER == true,
    Callback = function(state)
        getgenv().autoFishingConfig.HIDE_PLAYER = state
        if state and autoFishingRunning and getgenv().autoFishingConfig.OPTIMIZE_GAME then
            pcall(optimizeFishing)
        elseif not state then
            restoreFishingPlayerState()
        end
    end
})

ActivityGroup:AddDropdown({
    Name = "Pet Equip Mode",
    Options = autoEquipPetModeValues,
    Default = selectedAutoEquipPetMode,
    Callback = function(option)
        selectedAutoEquipPetMode = option
        getgenv().autoEquipBestPetsConfig.MODE = option
    end
})

ActivityGroup:AddButton({
    Name = "Equip Best Pets",
    Callback = function()
        task.spawn(function()
            equipBestPetsOnce(selectedAutoEquipPetMode)
        end)
    end
})

ActivityGroup:AddToggle({
    Name = "Auto Equip Best Pets",
    Default = false,
    Callback = function(state)
        local function setRunning(value)
            autoEquipBestPetsRunning = value
        end
        if state then
            startAutomationWorker("EquipBestPets", setRunning, runAutoEquipBestPets)
        else
            stopAutomationWorker("EquipBestPets", setRunning)
        end
    end
})

ActivityGroup:AddSlider({
    Name = "Pet Equip Delay",
    Min = 5,
    Max = 300,
    Default = getgenv().autoEquipBestPetsConfig.DELAY,
    Increment = 5,
    Callback = function(value)
        getgenv().autoEquipBestPetsConfig.DELAY = value
    end
})

EggsGroup:AddDropdown({
    Name = "Hatch Mode",
    Options = hatchModeValues,
    Default = selectedHatchMode,
    Callback = function(option)
        selectedHatchMode = option
        getgenv().autoEggHatcherConfig.MODE = option
    end
})

EggsGroup:AddDropdown({
    Name = "Select Egg",
    OptionsProvider = function()
        return eggDropdownValues
    end,
    Default = selectedEggLabel or eggDropdownValues[1],
    AutoRefresh = true,
    Callback = function(option)
        selectedEggLabel = option
        selectedEggName = eggNameLookup[option]
    end
})

EggsGroup:AddSlider({
    Name = "Egg Hatch Amount",
    Min = 1,
    Max = 99,
    Default = eggHatchAmount,
    Increment = 1,
    Callback = function(value)
        eggHatchAmount = value
        getgenv().autoEggHatcherConfig.AMOUNT = value
    end
})

EggsGroup:AddSlider({
    Name = "Egg Hatch Delay",
    Min = 0.05,
    Max = 5,
    Default = eggHatchDelay,
    Increment = 0.05,
    Callback = function(value)
        eggHatchDelay = value
        getgenv().autoEggHatcherConfig.DELAY = value
    end
})

EggsGroup:AddButton({
    Name = "Hatch Selected Egg",
    Callback = function()
        hatchSelectedEgg()
    end
})

EggsGroup:AddToggle({
    Name = "Auto Hatch Latest / Selected Egg",
    Default = false,
    Callback = function(state)
        local function setRunning(value)
            autoEggHatcherRunning = value
        end
        if state then
            startAutomationWorker("EggHatcher", setRunning, runAutoEggHatcher)
        else
            stopAutomationWorker("EggHatcher", setRunning)
        end
    end
})

EggSlotGroup:AddLabel({
    Text = "Auto Egg Slots waits for diamonds and rank unlocks, then buys the next slot automatically.",
    Wrap = true
})

EggSlotGroup:AddToggle({
    Name = "Auto Egg Slots",
    Default = false,
    Callback = function(state)
        local function setRunning(value)
            autoEggRunning = value
            getgenv().autoEgg = value
        end
        if state then
            startAutomationWorker("EggSlots", setRunning, runAutoEggSlots, false)
        else
            stopAutomationWorker("EggSlots", setRunning)
        end
    end
})

ShopGroup:AddDropdown({
    Name = "Vending Machine",
    OptionsProvider = function()
        return vendingMachineValues
    end,
    Default = selectedVendingMachine,
    AutoRefresh = true,
    Callback = function(option)
        selectedVendingMachine = option
    end
})

ShopGroup:AddDropdown({
    Name = "Vending Amount",
    Options = shopAmountValues,
    Default = tostring(selectedShopAmount),
    Callback = function(option)
        selectedShopAmount = tonumber(option) or 1
    end
})

ShopGroup:AddButton({
    Name = "Buy Selected Vending",
    Callback = function()
        purchaseVendingMachine(selectedVendingMachine)
    end
})

ShopGroup:AddButton({
    Name = "Buy Enchants",
    Callback = function()
        purchaseVendingMachine("EnchantVendingMachine1")
    end
})

ShopGroup:AddButton({
    Name = "Buy Potions",
    Callback = function()
        purchaseVendingMachine("PotionVendingMachine1")
    end
})

ShopGroup:AddDropdown({
    Name = "Merchant",
    OptionsProvider = function()
        return merchantValues
    end,
    Default = selectedMerchant,
    AutoRefresh = true,
    Callback = function(option)
        selectedMerchant = option
    end
})

ShopGroup:AddDropdown({
    Name = "Advanced Merchant Amount",
    Options = advancedMerchantValues,
    Default = tostring(selectedAdvancedMerchantAmount),
    Callback = function(option)
        selectedAdvancedMerchantAmount = tonumber(option) or 1
    end
})

ShopGroup:AddButton({
    Name = "Buy Selected Merchant Slot",
    Callback = function()
        purchaseMerchant(selectedMerchant, selectedAdvancedMerchantAmount)
    end
})

ShopGroup:AddButton({
    Name = "Buy Advanced Merchant",
    Callback = function()
        purchaseAdvancedMerchant()
    end
})

ShopUpgradeGroup:AddDropdown({
    Name = "Egg Slot Upgrade",
    Options = eggSlotUpgradeValues,
    Default = tostring(selectedEggSlotUpgrade),
    Callback = function(option)
        selectedEggSlotUpgrade = tonumber(option) or 1
    end
})

ShopUpgradeGroup:AddButton({
    Name = "Buy Egg Slot Upgrade",
    Callback = function()
        purchaseEggSlotUpgrade()
    end
})

RNGRollGroup:AddLabel({
    Text = isRngEventAvailable()
        and "RNG event transports detected."
        or "Legacy RNG event is unavailable in this update; actions fail closed.",
    Wrap = true
})

RNGRollGroup:AddButton({
    Name = "Roll Once",
    Callback = function()
        rollRNGOnce()
    end
})

RNGRollGroup:AddToggle({
    Name = "Auto Roll",
    Default = false,
    Callback = function(state)
        local function setRunning(value)
            autoRNGRollRunning = value
        end
        if state then
            startAutomationWorker("RNGRoll", setRunning, runAutoRNGRoll, false)
        else
            stopAutomationWorker("RNGRoll", setRunning)
        end
    end
})

RNGRollGroup:AddSlider({
    Name = "Auto Roll Delay",
    Min = 0.05,
    Max = 5,
    Default = rngRollDelay,
    Increment = 0.05,
    Callback = function(value)
        rngRollDelay = value
        getgenv().autoRNGConfig.DELAY = value
    end
})

RNGRollGroup:AddDropdown({
    Name = "Lucky Dice Amount",
    Options = rngDiceValues,
    Default = tostring(selectedRngDiceAmount),
    Callback = function(option)
        selectedRngDiceAmount = tonumber(option) or 1
    end
})

RNGRollGroup:AddButton({
    Name = "Buy Lucky Dice",
    Callback = function()
        purchaseRNGDice()
    end
})

RNGUpgradeGroup:AddDropdown({
    Name = "Egg Luck Amount",
    Options = rngEggLuckValues,
    Default = tostring(selectedRNGEggLuckAmount),
    Callback = function(option)
        selectedRNGEggLuckAmount = tonumber(option) or 1
    end
})

RNGUpgradeGroup:AddButton({
    Name = "Buy Egg Luck",
    Callback = function()
        purchaseRNGUpgrade("RNGEggLuck", selectedRNGEggLuckAmount)
    end
})

RNGUpgradeGroup:AddDropdown({
    Name = "Hatch Speed Amount",
    Options = rngHatchSpeedValues,
    Default = tostring(selectedRNGHatchSpeedAmount),
    Callback = function(option)
        selectedRNGHatchSpeedAmount = tonumber(option) or 1
    end
})

RNGUpgradeGroup:AddButton({
    Name = "Buy Hatch Speed",
    Callback = function()
        purchaseRNGUpgrade("RNGHatchSpeed", selectedRNGHatchSpeedAmount)
    end
})

RNGUpgradeGroup:AddDropdown({
    Name = "Bonus Luck Amount",
    Options = rngBonusLuckValues,
    Default = tostring(selectedRNGBonusLuckAmount),
    Callback = function(option)
        selectedRNGBonusLuckAmount = tonumber(option) or 1
    end
})

RNGUpgradeGroup:AddButton({
    Name = "Buy Bonus Luck",
    Callback = function()
        purchaseRNGUpgrade("RNGBonusLuck", selectedRNGBonusLuckAmount)
    end
})

RNGUpgradeGroup:AddDropdown({
    Name = "Huge Luck Amount",
    Options = rngHugeLuckValues,
    Default = tostring(selectedRNGHugeLuckAmount),
    Callback = function(option)
        selectedRNGHugeLuckAmount = tonumber(option) or 1
    end
})

RNGUpgradeGroup:AddButton({
    Name = "Buy Huge Luck",
    Callback = function()
        purchaseRNGUpgrade("RNGHugeLuck", selectedRNGHugeLuckAmount)
    end
})

RewardsGroup:AddButton({
    Name = "Claim All Rank Rewards",
    Callback = function()
        for rewardIndex = 1, getMaxRankRewardIndex() do
            claimRankReward(rewardIndex)
            task.wait(getgenv().autoRankRewardsConfig.CLAIM_DELAY)
        end
    end
})

RewardsGroup:AddToggle({
    Name = "Auto Claim Rank Rewards",
    Default = false,
    Callback = function(state)
        local function setRunning(value)
            autoRankRewardsRunning = value
        end
        if state then
            startAutomationWorker("RankRewards", setRunning, runAutoRankRewards)
        else
            stopAutomationWorker("RankRewards", setRunning)
        end
    end
})

MovementGroup:AddSlider({
    Name = "Walkspeed",
    Min = 16,
    Max = 200,
    Default = 16,
    Increment = 1,
    Callback = function(value)
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChildOfClass("Humanoid") then
            captureCharacterState()
            char:FindFirstChildOfClass("Humanoid").WalkSpeed = value
        end
    end
})

MovementGroup:AddSlider({
    Name = "Jump Power",
    Min = 50,
    Max = 300,
    Default = 50,
    Increment = 1,
    Callback = function(value)
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChildOfClass("Humanoid") then
            captureCharacterState()
            char:FindFirstChildOfClass("Humanoid").JumpPower = value
        end
    end
})

MovementGroup:AddButton({
    Name = "Reset Character",
    Callback = function()
        local char = game.Players.LocalPlayer.Character
        if char then
            char:BreakJoints()
        end
    end
})

FlyGroup:AddToggle({
    Name = "Fly",
    Default = false,
    Callback = function(state)
        flying = state
        local player = game.Players.LocalPlayer
        local character = player.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") or not character:FindFirstChildOfClass("Humanoid") then
            return
        end
        local humanoidRootPart = character.HumanoidRootPart
        local humanoid = character:FindFirstChildOfClass("Humanoid")

        if state then
            captureCharacterState()
            disconnectConnection(flyConnection)
            humanoid.PlatformStand = true
            flyConnection = game:GetService("RunService").RenderStepped:Connect(function()
                if humanoidRootPart and humanoid then
                    local moveDirection = humanoid.MoveDirection
                    local flySpeed = flySpeedValue
                    humanoidRootPart.Velocity = moveDirection * flySpeed + Vector3.new(0, 0.1, 0)
                end
            end)
        else
            if flyConnection then
                flyConnection:Disconnect()
                flyConnection = nil
            end
            local restore = characterRestoreState
            humanoid.PlatformStand = restore and restore.Humanoid == humanoid and restore.PlatformStand or false
            pcall(function()
                humanoidRootPart.AssemblyLinearVelocity = restore and restore.Root == humanoidRootPart and restore.Velocity or Vector3.zero
            end)
        end
    end
})

FlyGroup:AddSlider({
    Name = "Fly Speed",
    Min = 10,
    Max = 300,
    Default = flySpeedValue,
    Increment = 1,
    Callback = function(value)
        flySpeedValue = value
    end
})

MiscGroup:AddButton({
    Name = "Server Hop",
    Callback = function()
        task.spawn(function()
            serverHopUntilSuccess("Manual server hop")
        end)
    end
})

MiscGroup:AddButton({
    Name = "Rejoin Server",
    Callback = function()
        local TeleportService = game:GetService("TeleportService")
        TeleportService:Teleport(game.PlaceId, game.Players.LocalPlayer)
    end
})

MiscGroup:AddButton({
    Name = "Stop All Automations",
    Callback = function()
        stopPetSimAutomations()
        TapHeroesAdapter:Stop()
        notifyFlow("Safety", "All automations were stopped.", 3)
    end
})

MiscGroup:AddDivider()
MiscGroup:AddLabel({
    Text = "Use these utility actions as needed. Anti-AFK is enabled by default.",
    Wrap = true
})

MiscGroup:AddToggle({
    Name = "Anti AFK",
    Default = getgenv().antiAfkConfig.ENABLED == true,
    Callback = function(state)
        getgenv().antiAfkConfig.ENABLED = state
        if state then
            ensureAntiIdle()
            notifyFlow("Anti AFK", "Anti-AFK enabled.", 2.5)
        else
            disableAntiIdle()
            notifyFlow("Anti AFK", "Anti-AFK disabled and prior idle handlers restored.", 2.5)
        end
    end
})

PerformanceGroup:AddLabel({
    Text = "Low-end mode lowers visual cost without deleting gameplay folders.",
    Wrap = true
})

PerformanceGroup:AddButton({
    Name = "Apply FPS Boost",
    Callback = function()
        startAutomationWorker("PerformancePass", setPerformancePassRunning, function()
            local generation = automationCancellationGeneration
            applyLowEndPerformanceOnce(true, true, function()
                return performancePassRunning
            end, generation)
        end, false)
    end
})

PerformanceGroup:AddButton({
    Name = "Restore Visuals / FPS",
    Callback = function()
        getgenv().performanceConfig.ENABLED = false
        stopAutomationWorker("LowEndPerformance", setLowEndPerformanceRunning)
        stopAutomationWorker("PerformancePass", setPerformancePassRunning)
        restorePerformanceState()
    end
})

PerformanceGroup:AddToggle({
    Name = "Auto FPS Boost",
    Default = getgenv().performanceConfig.ENABLED == true,
    Callback = function(state)
        getgenv().performanceConfig.ENABLED = state
        if state then
            startAutomationWorker("LowEndPerformance", setLowEndPerformanceRunning, runLowEndPerformanceLoop)
        else
            stopAutomationWorker("LowEndPerformance", setLowEndPerformanceRunning)
            stopAutomationWorker("PerformancePass", setPerformancePassRunning)
            restorePerformanceState()
        end
    end
})

PerformanceGroup:AddSlider({
    Name = "FPS Cap",
    Min = 30,
    Max = 360,
    Default = getgenv().performanceConfig.FPS_CAP,
    Increment = 10,
    Callback = function(value)
        getgenv().performanceConfig.FPS_CAP = value
        setFlowFpsCap(value)
    end
})

PerformanceGroup:AddSlider({
    Name = "Refresh Seconds",
    Min = 5,
    Max = 120,
    Default = getgenv().performanceConfig.APPLY_INTERVAL,
    Increment = 5,
    Callback = function(value)
        getgenv().performanceConfig.APPLY_INTERVAL = value
    end
})

PerformanceGroup:AddToggle({
    Name = "Disable Effects",
    Default = getgenv().performanceConfig.DISABLE_EFFECTS == true,
    Callback = function(state)
        getgenv().performanceConfig.DISABLE_EFFECTS = state
        setPerformanceVisualOption("PerformanceEffects", state)
    end
})

PerformanceGroup:AddToggle({
    Name = "Smooth Parts",
    Default = getgenv().performanceConfig.SIMPLIFY_PARTS == true,
    Callback = function(state)
        getgenv().performanceConfig.SIMPLIFY_PARTS = state
        setPerformanceVisualOption("PerformanceParts", state)
    end
})

PerformanceGroup:AddToggle({
    Name = "Hide Pets",
    Default = getgenv().performanceConfig.HIDE_OTHER_PETS == true,
    Callback = function(state)
        getgenv().performanceConfig.HIDE_OTHER_PETS = state
        setPerformanceVisualOption("PerformancePets", state)
    end
})

PerformanceGroup:AddToggle({
    Name = "Hide Drops",
    Default = getgenv().performanceConfig.HIDE_DROPS == true,
    Callback = function(state)
        getgenv().performanceConfig.HIDE_DROPS = state
        setPerformanceVisualOption("PerformanceDrops", state)
    end
})

PerformanceGroup:AddToggle({
    Name = "Disable 3D Render",
    Default = getgenv().performanceConfig.DISABLE_RENDER == true,
    Callback = function(state)
        getgenv().performanceConfig.DISABLE_RENDER = state
        setFlowRenderingDisabled(state)
    end
})

InstanceGroup:AddLabel({
    Text = "Pick a minigame, then join, leave, or claim its chest.",
    Wrap = true
})

InstanceGroup:AddDropdown({
    Name = "Choose Instance",
    OptionsProvider = function()
        return instanceValues
    end,
    Default = selectedInstanceName or instanceValues[1],
    AutoRefresh = true,
    Callback = function(option)
        selectedInstanceName = option
        getgenv().autoInstanceConfig.INSTANCE = option
    end
})

InstanceGroup:AddSlider({
    Name = "Join Delay",
    Min = 0.1,
    Max = 10,
    Default = getgenv().autoInstanceConfig.ENTER_DELAY,
    Increment = 0.1,
    Callback = function(value)
        getgenv().autoInstanceConfig.ENTER_DELAY = value
    end
})

InstanceGroup:AddButton({
    Name = "Refresh Lists",
    Callback = function()
        clearDiscoveryCache()
        refreshInstanceList(true)
        refreshDirectorySummaryList(true)
        refreshAutoFlagNameList()
        refreshEggList()
        refreshBreakableFarmZoneList()
        refreshAutoFlagZoneList()
        refreshAutoFruitList()
        refreshAutoBundleList()
        refreshUtilityItemList()
        refreshConsumableFruitChoiceList()
        refreshBoostItemList()
        refreshMinigameAutoList()
        refreshMachineMerchantLists()
        refreshSoccerEventLists()
        notifyFlow("Discovery", "Refreshed live directories and instances.", 2.5)
    end
})

InstanceGroup:AddButton({
    Name = "Join Selected",
    Callback = function()
        task.spawn(function()
            enterInstance(selectedInstanceName)
        end)
    end
})

InstanceGroup:AddButton({
    Name = "Leave Current",
    Callback = function()
        leaveCurrentInstance()
    end
})

InstanceGroup:AddButton({
    Name = "Open Instance Chest",
    Callback = function()
        task.spawn(function()
            task.wait(math.max(getgenv().autoInstanceConfig.CLAIM_CHEST_DELAY, 0))
            claimInstanceChest(selectedInstanceName)
        end)
    end
})

InstanceGroup:AddToggle({
    Name = "Hop If Missing",
    Default = getgenv().autoInstanceConfig.SERVER_HOP == true,
    Callback = function(state)
        getgenv().autoInstanceConfig.SERVER_HOP = state
    end
})

InstanceAutomationGroup:AddLabel({
    Text = "Extra minigame autos that are not part of World Cup.",
    Wrap = true
})

InstanceAutomationGroup:AddButton({
    Name = "Catch Roaming Pet",
    Callback = function()
        task.spawn(catchRoamingPetsOnce)
    end
})

InstanceAutomationGroup:AddToggle({
    Name = "Auto Roaming Pet",
    Default = false,
    Callback = function(state)
        local function setRunning(value)
            autoRoamingPetsRunning = value
        end
        if state then
            startAutomationWorker("RoamingPets", setRunning, runAutoRoamingPets)
        else
            stopAutomationWorker("RoamingPets", setRunning)
        end
    end
})

InstanceAutomationGroup:AddButton({
    Name = "Use Prison Keys",
    Callback = function()
        task.spawn(usePrisonKeysOnce)
    end
})

InstanceAutomationGroup:AddToggle({
    Name = "Auto Prison Keys",
    Default = false,
    Callback = function(state)
        local function setRunning(value)
            autoPrisonKeysRunning = value
        end
        if state then
            startAutomationWorker("PrisonKeys", setRunning, runAutoPrisonKeys)
        else
            stopAutomationWorker("PrisonKeys", setRunning)
        end
    end
})

InstanceAutomationGroup:AddButton({
    Name = "Claim ChestRush / BankHeist",
    Callback = function()
        task.spawn(runChestRushBankHeistStep)
    end
})

InstanceAutomationGroup:AddToggle({
    Name = "Auto ChestRush / BankHeist",
    Default = false,
    Callback = function(state)
        local function setRunning(value)
            autoChestRushBankHeistRunning = value
        end
        if state then
            startAutomationWorker("ChestRushBankHeist", setRunning, runAutoChestRushBankHeist)
        else
            stopAutomationWorker("ChestRushBankHeist", setRunning)
        end
    end
})

MoreMinigameGroup:AddLabel({
    Text = "Use this for wheel, roulette, claw, trial, hideout, lucky block, and newer minigames.",
    Wrap = true
})

MoreMinigameGroup:AddButton({
    Name = "Run Release Check",
    Callback = function()
        task.spawn(runFlowReleaseDiagnostics)
    end
})

MoreMinigameGroup:AddDropdown({
    Name = "Minigame Auto",
    OptionsProvider = function()
        return minigameAutoValues
    end,
    Default = selectedMinigameAuto,
    AutoRefresh = true,
    Callback = function(option)
        selectedMinigameAuto = option
        getgenv().autoMinigameConfig.INSTANCE = option
    end
})

MoreMinigameGroup:AddButton({
    Name = "Run Selected Once",
    Callback = function()
        task.spawn(function()
            if selectedMinigameAuto == MINIGAME_AUTO_ALL then
                runAllMinigamesStep()
            else
                safeRunSelectedMinigameStep(selectedMinigameAuto)
            end
        end)
    end
})

MoreMinigameGroup:AddToggle({
    Name = "Auto Selected Minigame",
    Default = false,
    Callback = function(state)
        local function setRunning(value)
            autoSelectedMinigameRunning = value
        end
        if state then
            startAutomationWorker("SelectedMinigame", setRunning, runAutoSelectedMinigame)
        else
            stopAutomationWorker("SelectedMinigame", setRunning)
            disableActiveAutoMine()
        end
    end
})

MoreMinigameGroup:AddSlider({
    Name = "Minigame Delay",
    Min = 3,
    Max = 120,
    Default = getgenv().autoMinigameConfig.DELAY,
    Increment = 1,
    Callback = function(value)
        getgenv().autoMinigameConfig.DELAY = value
    end
})

MoreMinigameGroup:AddToggle({
    Name = "Auto Join",
    Default = getgenv().autoMinigameConfig.AUTO_ENTER == true,
    Callback = function(state)
        getgenv().autoMinigameConfig.AUTO_ENTER = state
    end
})

MoreMinigameGroup:AddToggle({
    Name = "Auto Claim Reward",
    Default = getgenv().autoMinigameConfig.AUTO_CLAIM == true,
    Callback = function(state)
        getgenv().autoMinigameConfig.AUTO_CLAIM = state
    end
})

MoreMinigameGroup:AddToggle({
    Name = "Try Game Actions",
    Default = getgenv().autoMinigameConfig.TRY_ACTIONS == true,
    Callback = function(state)
        getgenv().autoMinigameConfig.TRY_ACTIONS = state
    end
})

MoreMinigameGroup:AddToggle({
    Name = "Only Run Inside",
    Default = getgenv().autoMinigameConfig.REQUIRE_ACTIVE_FOR_ACTIONS == true,
    Callback = function(state)
        getgenv().autoMinigameConfig.REQUIRE_ACTIVE_FOR_ACTIONS = state
    end
})

MoreMinigameGroup:AddToggle({
    Name = "Experimental Found Remotes",
    Default = getgenv().autoMinigameConfig.TRY_DISCOVERED_REMOTES == true,
    Callback = function(state)
        getgenv().autoMinigameConfig.TRY_DISCOVERED_REMOTES = state
    end
})

MoreMinigameGroup:AddSlider({
    Name = "Remote Try Limit",
    Min = 1,
    Max = 20,
    Default = getgenv().autoMinigameConfig.MAX_REMOTE_ATTEMPTS,
    Increment = 1,
    Callback = function(value)
        getgenv().autoMinigameConfig.MAX_REMOTE_ATTEMPTS = value
    end
})

MoreMinigameGroup:AddToggle({
    Name = "Use Buttons / Prompts",
    Default = getgenv().autoMinigameConfig.TRY_INTERACTABLES == true,
    Callback = function(state)
        getgenv().autoMinigameConfig.TRY_INTERACTABLES = state
    end
})

MoreMinigameGroup:AddSlider({
    Name = "Button Try Limit",
    Min = 1,
    Max = 30,
    Default = getgenv().autoMinigameConfig.MAX_INTERACTABLES,
    Increment = 1,
    Callback = function(value)
        getgenv().autoMinigameConfig.MAX_INTERACTABLES = value
    end
})

MoreMinigameGroup:AddToggle({
    Name = "Leave After Run",
    Default = getgenv().autoMinigameConfig.LEAVE_AFTER_STEP == true,
    Callback = function(state)
        getgenv().autoMinigameConfig.LEAVE_AFTER_STEP = state
    end
})

InitialTapHeroesStatus = TapHeroesAdapter:RefreshStatus(true)



if setthreadidentity then
    pcall(setthreadidentity, 8)
end
TapHeroesStatusLabel = CurrentEventGroup:AddLabel({
    Text = InitialTapHeroesStatus.Text .. "\nBoosts: " .. table.concat(InitialTapHeroesStatus.Boosts or {}, ", "),
    Wrap = true
})

CurrentEventGroup:AddLabel({
    Text = "Level 180 unlocks Transcend and Tap Gauntlet. Gauntlet entry spends one Marble Key.",
    Wrap = true
})

CurrentEventGroup:AddLabel({
    Text = "Quick start: enable Auto Tap Heroes below. The recommended tap, advance, upgrade, hatch, and Frenzy options start enabled.",
    Wrap = true
})

CurrentEventGroup:AddButton({
    Name = "Refresh Event Status",
    Callback = function()
        task.spawn(function()
            TapHeroesAdapter:PollState()
            TapHeroesAdapter:RefreshStatus(true)
        end)
    end
})

CurrentEventGroup:AddButton({
    Name = "Enter Tap Heroes",
    Callback = function()
        task.spawn(function()
            TapHeroesAdapter:Enter()
            TapHeroesAdapter:RefreshStatus()
        end)
    end
})

CurrentEventGroup:AddButton({
    Name = "Run Current Event Once",
    Callback = function()
        task.spawn(function()
            TapHeroesAdapter:RunStep()
        end)
    end
})

CurrentEventGroup:AddButton({
    Name = "Unleash Tap Frenzy",
    Callback = function()
        task.spawn(function()
            if not TapHeroesAdapter:UnleashFrenzy() then
                notifyFlow("Tap Heroes", "Tap Frenzy is not ready yet.", 2.5)
            end
            TapHeroesAdapter:RefreshStatus(true)
        end)
    end
})

CurrentEventGroup:AddButton({
    Name = "Transcend Now (Resets Event Progress)",
    Callback = function()
        task.spawn(function()
            TapHeroesAdapter:Transcend()
            TapHeroesAdapter:RefreshStatus(true)
        end)
    end
})

CurrentEventGroup:AddButton({
    Name = "Enter Tap Gauntlet (Uses Marble Key)",
    Callback = function()
        task.spawn(function()
            TapHeroesAdapter:EnterGauntlet()
            TapHeroesAdapter:RefreshStatus(true)
        end)
    end
})

CurrentEventGroup:AddButton({
    Name = "Hatch Latest Affordable Egg Once",
    Callback = function()
        task.spawn(function()
            if TapHeroesAdapter:GetInstance() then
                hatchLatestEggOnce()
            else
                notifyFlow("Tap Heroes", "Enter Tap Heroes before hatching its event egg.", 3)
            end
            TapHeroesAdapter:RefreshStatus()
        end)
    end
})

CurrentEventGroup:AddButton({
    Name = "Enable Native Auto Transcend (One Way)",
    Callback = function()
        task.spawn(function()
            TapHeroesAdapter:EnableAutoTranscend()
            TapHeroesAdapter:RefreshStatus(true)
        end)
    end
})

CurrentEventGroup:AddToggle({
    Name = "Auto Tap Heroes",
    Default = false,
    Callback = function(state)
        local function setRunning(value)
            autoTapHeroesRunning = value
        end
        if state then
            startAutomationWorker("TapHeroes", setRunning, function()
                TapHeroesAdapter:Run()
            end)
        else
            stopAutomationWorker("TapHeroes", setRunning)
            TapHeroesAdapter:Stop()
        end
    end
})

TapHeroesAutomationGroup:AddToggle({
    Name = "Auto Enter Tap Heroes",
    Default = getgenv().tapHeroesConfig.ENTER == true,
    Callback = function(state)
        getgenv().tapHeroesConfig.ENTER = state
    end
})

TapHeroesAutomationGroup:AddToggle({
    Name = "Native Auto Tapper",
    Default = getgenv().tapHeroesConfig.NATIVE_AUTO_TAP == true,
    Callback = function(state)
        getgenv().tapHeroesConfig.NATIVE_AUTO_TAP = state
        if not state then
            TapHeroesAdapter:RestoreNativeAutoTapper()
        end
    end
})

TapHeroesAutomationGroup:AddToggle({
    Name = "Native Auto Advance",
    Default = getgenv().tapHeroesConfig.AUTO_ADVANCE == true,
    Callback = function(state)
        getgenv().tapHeroesConfig.AUTO_ADVANCE = state
        if not state then
            TapHeroesAdapter:RestoreAutoAdvance()
        end
    end
})

TapHeroesAutomationGroup:AddToggle({
    Name = "Auto Buy Tap Upgrades",
    Default = getgenv().tapHeroesConfig.AUTO_UPGRADES == true,
    Callback = function(state)
        getgenv().tapHeroesConfig.AUTO_UPGRADES = state
    end
})

TapHeroesAutomationGroup:AddToggle({
    Name = "Auto Buy Permanent Upgrades",
    Default = getgenv().tapHeroesConfig.AUTO_PERMANENT_UPGRADES == true,
    Callback = function(state)
        getgenv().tapHeroesConfig.AUTO_PERMANENT_UPGRADES = state
    end
})

TapHeroesAutomationGroup:AddToggle({
    Name = "Auto Hatch Latest Egg",
    Default = getgenv().tapHeroesConfig.AUTO_HATCH == true,
    Callback = function(state)
        getgenv().tapHeroesConfig.AUTO_HATCH = state
    end
})

TapHeroesAutomationGroup:AddToggle({
    Name = "Auto Unleash Tap Frenzy",
    Default = getgenv().tapHeroesConfig.AUTO_FRENZY == true,
    Callback = function(state)
        getgenv().tapHeroesConfig.AUTO_FRENZY = state
    end
})

TapHeroesAutomationGroup:AddSlider({
    Name = "Event Loop Delay",
    Min = 0.25,
    Max = 10,
    Default = getgenv().tapHeroesConfig.DELAY,
    Increment = 0.25,
    Callback = function(value)
        getgenv().tapHeroesConfig.DELAY = value
    end
})

TapHeroesItemsGroup:AddDropdown({
    Name = "Event Consumable",
    Options = tapHeroesConsumableValues,
    Default = selectedTapHeroesConsumable,
    Callback = function(option)
        selectedTapHeroesConsumable = option
        getgenv().tapHeroesConfig.CONSUMABLE = option
    end
})

TapHeroesItemsGroup:AddSlider({
    Name = "Event Item Amount",
    Min = 1,
    Max = 99,
    Default = getgenv().tapHeroesConfig.CONSUMABLE_AMOUNT,
    Increment = 1,
    Callback = function(value)
        getgenv().tapHeroesConfig.CONSUMABLE_AMOUNT = value
    end
})

TapHeroesItemsGroup:AddButton({
    Name = "Use Owned Event Items Once",
    Callback = function()
        task.spawn(useSelectedTapHeroesConsumables)
    end
})

TapHeroesItemsGroup:AddToggle({
    Name = "Auto Use Event Items",
    Default = getgenv().tapHeroesConfig.AUTO_USE_CONSUMABLES == true,
    Callback = function(state)
        getgenv().tapHeroesConfig.AUTO_USE_CONSUMABLES = state
    end
})

TapHeroesItemsGroup:AddDropdown({
    Name = "Event Gift",
    Options = tapHeroesGiftValues,
    Default = selectedTapHeroesGift,
    Callback = function(option)
        selectedTapHeroesGift = option
        getgenv().tapHeroesConfig.GIFT = option
    end
})

TapHeroesItemsGroup:AddButton({
    Name = "Open Selected Gifts Once",
    Callback = function()
        task.spawn(openSelectedTapHeroesGift)
    end
})

TapHeroesItemsGroup:AddSlider({
    Name = "Gift Amount",
    Min = 1,
    Max = 99,
    Default = getgenv().tapHeroesConfig.GIFT_AMOUNT,
    Increment = 1,
    Callback = function(value)
        getgenv().tapHeroesConfig.GIFT_AMOUNT = value
    end
})

TapHeroesItemsGroup:AddToggle({
    Name = "Auto Open Selected Gifts",
    Default = getgenv().tapHeroesConfig.AUTO_OPEN_GIFTS == true,
    Callback = function(state)
        getgenv().tapHeroesConfig.AUTO_OPEN_GIFTS = state
    end
})

SoccerEventGroup:AddLabel({
    Text = "World Cup event farm, kicks, upgrades, boosts, and eggs.",
    Wrap = true
})

SoccerEventGroup:AddDropdown({
    Name = "Boost To Use",
    Options = soccerBoostValues,
    Default = selectedSoccerBoost,
    Callback = function(option)
        selectedSoccerBoost = option
        getgenv().autoSoccerEventConfig.BOOST = option
    end
})

SoccerEventGroup:AddDropdown({
    Name = "Upgrade To Buy",
    Options = soccerUpgradeValues,
    Default = selectedSoccerUpgrade,
    Callback = function(option)
        selectedSoccerUpgrade = option
        getgenv().autoSoccerEventConfig.UPGRADE = option
    end
})

SoccerEventGroup:AddDropdown({
    Name = "Egg To Hatch",
    Options = soccerEggValues,
    Default = selectedSoccerEgg,
    Callback = function(option)
        selectedSoccerEgg = option
        getgenv().autoSoccerEventConfig.EGG = option
    end
})

SoccerEventGroup:AddSlider({
    Name = "Hatch Amount",
    Min = 1,
    Max = 99,
    Default = getgenv().autoSoccerEventConfig.HATCH_AMOUNT,
    Increment = 1,
    Callback = function(value)
        getgenv().autoSoccerEventConfig.HATCH_AMOUNT = value
    end
})

SoccerEventGroup:AddButton({
    Name = "Run Event Once",
    Callback = function()
        task.spawn(runSoccerEventStep)
    end
})

SoccerEventGroup:AddToggle({
    Name = "Auto World Cup",
    Default = false,
    Callback = function(state)
        local function setRunning(value)
            autoSoccerEventRunning = value
        end
        if state then
            startAutomationWorker("SoccerEvent", setRunning, runAutoSoccerEvent)
        else
            stopAutomationWorker("SoccerEvent", setRunning)
        end
    end
})

SoccerEventGroup:AddToggle({
    Name = "Auto Enter Event",
    Default = getgenv().autoSoccerEventConfig.ENTER == true,
    Callback = function(state)
        getgenv().autoSoccerEventConfig.ENTER = state
    end
})

SoccerEventGroup:AddToggle({
    Name = "Collect Orbs",
    Default = getgenv().autoSoccerEventConfig.COLLECT_ORBS == true,
    Callback = function(state)
        getgenv().autoSoccerEventConfig.COLLECT_ORBS = state
    end
})

SoccerEventGroup:AddToggle({
    Name = "Use Boosts",
    Default = getgenv().autoSoccerEventConfig.USE_BOOSTS == true,
    Callback = function(state)
        getgenv().autoSoccerEventConfig.USE_BOOSTS = state
    end
})

SoccerEventGroup:AddToggle({
    Name = "Buy Upgrades",
    Default = getgenv().autoSoccerEventConfig.BUY_UPGRADES == true,
    Callback = function(state)
        getgenv().autoSoccerEventConfig.BUY_UPGRADES = state
    end
})

SoccerEventGroup:AddToggle({
    Name = "Auto Kick",
    Default = getgenv().autoSoccerEventConfig.AUTO_KICK == true,
    Callback = function(state)
        getgenv().autoSoccerEventConfig.AUTO_KICK = state
    end
})

SoccerEventGroup:AddToggle({
    Name = "Perfect Kick",
    Default = getgenv().autoSoccerEventConfig.PERFECT_KICK == true,
    Callback = function(state)
        getgenv().autoSoccerEventConfig.PERFECT_KICK = state
    end
})

SoccerEventGroup:AddSlider({
    Name = "Kick Target %",
    Min = 90,
    Max = 100,
    Default = getgenv().autoSoccerEventConfig.PERFECT_KICK_TARGET,
    Increment = 1,
    Callback = function(value)
        getgenv().autoSoccerEventConfig.PERFECT_KICK_TARGET = value
    end
})

SoccerEventGroup:AddToggle({
    Name = "Hatch Event Egg",
    Default = getgenv().autoSoccerEventConfig.HATCH_EGGS == true,
    Callback = function(state)
        getgenv().autoSoccerEventConfig.HATCH_EGGS = state
    end
})

SoccerEventGroup:AddSlider({
    Name = "Loop Delay",
    Min = 2,
    Max = 120,
    Default = getgenv().autoSoccerEventConfig.DELAY,
    Increment = 1,
    Callback = function(value)
        getgenv().autoSoccerEventConfig.DELAY = value
    end
})

RewardAutomationGroup:AddLabel({
    Text = "Auto claim and re-enroll reward systems.",
    Wrap = true
})

RewardAutomationGroup:AddButton({
    Name = "Claim / Enroll Daycare",
    Callback = function()
        task.spawn(runDaycareStep)
    end
})

RewardAutomationGroup:AddToggle({
    Name = "Auto Daycare",
    Default = false,
    Callback = function(state)
        local function setRunning(value)
            autoDaycareRunning = value
        end
        if state then
            startAutomationWorker("Daycare", setRunning, runAutoDaycare)
        else
            stopAutomationWorker("Daycare", setRunning)
        end
    end
})

RewardAutomationGroup:AddSlider({
    Name = "Daycare Delay",
    Min = 15,
    Max = 600,
    Default = getgenv().autoDaycareConfig.DELAY,
    Increment = 5,
    Callback = function(value)
        getgenv().autoDaycareConfig.DELAY = value
    end
})

RewardAutomationGroup:AddButton({
    Name = "Claim Goals",
    Callback = function()
        task.spawn(claimEventGoalsOnce)
    end
})

RewardAutomationGroup:AddToggle({
    Name = "Auto Claim Goals",
    Default = false,
    Callback = function(state)
        local function setRunning(value)
            autoEventGoalsRunning = value
        end
        if state then
            startAutomationWorker("EventGoals", setRunning, runAutoEventGoals)
        else
            stopAutomationWorker("EventGoals", setRunning)
        end
    end
})

RewardAutomationGroup:AddSlider({
    Name = "Goal Claim Delay",
    Min = 5,
    Max = 300,
    Default = getgenv().autoEventGoalsConfig.DELAY,
    Increment = 5,
    Callback = function(value)
        getgenv().autoEventGoalsConfig.DELAY = value
    end
})

FarmWorldGroup:AddLabel({
    Text = "Farm World plot automation: plant, harvest, workers, sprinklers, food, and storage.",
    Wrap = true
})

FarmWorldGroup:AddButton({
    Name = "Join Farm World",
    Callback = function()
        task.spawn(function()
            enterInstance("FarmingWorld")
            task.wait(1)
            moveToFarmingPlot()
        end)
    end
})

FarmWorldGroup:AddButton({
    Name = "Run Farm Once",
    Callback = function()
        task.spawn(runFarmingWorldStep)
    end
})

FarmWorldGroup:AddToggle({
    Name = "Auto Farm World",
    Default = false,
    Callback = function(state)
        local function setRunning(value)
            autoFarmingWorldRunning = value
        end
        if state then
            startAutomationWorker("FarmingWorld", setRunning, runAutoFarmingWorld)
        else
            stopAutomationWorker("FarmingWorld", setRunning)
        end
    end
})

FarmWorldGroup:AddSlider({
    Name = "Farm Loop Delay",
    Min = 5,
    Max = 120,
    Default = getgenv().autoFarmingWorldConfig.DELAY,
    Increment = 5,
    Callback = function(value)
        getgenv().autoFarmingWorldConfig.DELAY = value
    end
})

FarmWorldGroup:AddSlider({
    Name = "Eggs Per Step",
    Min = 1,
    Max = 20,
    Default = getgenv().autoFarmingWorldConfig.MAX_PLANTS_PER_STEP,
    Increment = 1,
    Callback = function(value)
        getgenv().autoFarmingWorldConfig.MAX_PLANTS_PER_STEP = value
    end
})

FarmWorldGroup:AddToggle({
    Name = "Claim Storage",
    Default = getgenv().autoFarmingWorldConfig.CLAIM_STORAGE == true,
    Callback = function(state)
        getgenv().autoFarmingWorldConfig.CLAIM_STORAGE = state
    end
})

FarmWorldGroup:AddToggle({
    Name = "Harvest Eggs",
    Default = getgenv().autoFarmingWorldConfig.HARVEST == true,
    Callback = function(state)
        getgenv().autoFarmingWorldConfig.HARVEST = state
    end
})

FarmWorldGroup:AddToggle({
    Name = "Plant Farm Eggs",
    Default = getgenv().autoFarmingWorldConfig.PLANT_EGGS == true,
    Callback = function(state)
        getgenv().autoFarmingWorldConfig.PLANT_EGGS = state
    end
})

FarmWorldGroup:AddToggle({
    Name = "Place Workers",
    Default = getgenv().autoFarmingWorldConfig.PLACE_WORKERS == true,
    Callback = function(state)
        getgenv().autoFarmingWorldConfig.PLACE_WORKERS = state
    end
})

FarmWorldGroup:AddToggle({
    Name = "Place Sprinklers",
    Default = getgenv().autoFarmingWorldConfig.PLACE_SPRINKLERS == true,
    Callback = function(state)
        getgenv().autoFarmingWorldConfig.PLACE_SPRINKLERS = state
    end
})

FarmWorldGroup:AddToggle({
    Name = "Feed Farm Pets",
    Default = getgenv().autoFarmingWorldConfig.FEED_PETS == true,
    Callback = function(state)
        getgenv().autoFarmingWorldConfig.FEED_PETS = state
    end
})

EventDirectoryGroup:AddLabel({
    Text = "Live game data counts used by dropdown refresh.",
    Wrap = true
})

EventDirectoryGroup:AddDropdown({
    Name = "Data Family",
    OptionsProvider = function()
        return directorySummaryValues
    end,
    Default = selectedDirectorySummary,
    AutoRefresh = true,
    Callback = function(option)
        selectedDirectorySummary = option
    end
})

KeyHelperGroup:AddLabel({
    Text = "Key helpers call the matching combine or unlock remote when it exists.",
    Wrap = true
})

KeyHelperGroup:AddDropdown({
    Name = "Key Type",
    Options = keyHelperValues,
    Default = selectedKeyHelper,
    Callback = function(option)
        selectedKeyHelper = option
        getgenv().keyHelperConfig.KEY = option
    end
})

KeyHelperGroup:AddSlider({
    Name = "Combine Amount",
    Min = 1,
    Max = 50,
    Default = keyCombineAmount,
    Increment = 1,
    Callback = function(value)
        keyCombineAmount = value
        getgenv().keyHelperConfig.COMBINE_AMOUNT = value
    end
})

KeyHelperGroup:AddButton({
    Name = "Combine Selected Key",
    Callback = function()
        task.spawn(function()
            runKeyHelperAction("Combine", keyCombineAmount)
        end)
    end
})

KeyHelperGroup:AddSlider({
    Name = "Unlock Amount",
    Min = 1,
    Max = 50,
    Default = keyUnlockAmount,
    Increment = 1,
    Callback = function(value)
        keyUnlockAmount = value
        getgenv().keyHelperConfig.UNLOCK_AMOUNT = value
    end
})

KeyHelperGroup:AddButton({
    Name = "Unlock Selected Key",
    Callback = function()
        task.spawn(function()
            runKeyHelperAction("Unlock", keyUnlockAmount)
        end)
    end
})

ItemFlagsGroup:AddLabel({
    Text = "Choose Best Area or any unlocked zone. The same flag selection is reused for flag quests.",
    Wrap = true
})

ItemFlagsGroup:AddDropdown({
    Name = "Flag Variant",
    OptionsProvider = function()
        return autoFlagNameValues
    end,
    Default = selectedAutoFlagName,
    AutoRefresh = true,
    Callback = function(option)
        selectedAutoFlagName = option
        getgenv().autoFlagsConfig.FLAG = option
    end
})

ItemFlagsGroup:AddDropdown({
    Name = "Flag Zone",
    OptionsProvider = function()
        return autoFlagZoneValues
    end,
    Default = selectedAutoFlagZone,
    AutoRefresh = true,
    Callback = function(option)
        selectedAutoFlagZone = option
        getgenv().autoFlagsConfig.ZONE = option
    end
})

ItemFlagsGroup:AddSlider({
    Name = "Flag Amount",
    Min = 1,
    Max = 25,
    Default = flagUseAmount,
    Increment = 1,
    Callback = function(value)
        flagUseAmount = value
        getgenv().autoFlagsConfig.AMOUNT = value
    end
})

ItemFlagsGroup:AddSlider({
    Name = "Auto Flag Delay",
    Min = 5,
    Max = 900,
    Default = getgenv().autoFlagsConfig.USE_DELAY,
    Increment = 5,
    Callback = function(value)
        getgenv().autoFlagsConfig.USE_DELAY = value
    end
})

ItemFlagsGroup:AddButton({
    Name = "Use Selected Flag",
    Callback = function()
        task.spawn(function()
            executeFlagAction(selectedAutoFlagName, flagUseAmount, function()
                return true
            end)
        end)
    end
})

ItemFlagsGroup:AddToggle({
    Name = "Auto Use Flags",
    Default = false,
    Callback = function(state)
        local function setRunning(value)
            autoFlagsRunning = value
        end
        if state then
            startAutomationWorker("AutoFlags", setRunning, runAutoFlags)
        else
            stopAutomationWorker("AutoFlags", setRunning)
        end
    end
})

ItemUtilityGroup:AddLabel({
    Text = "Utility items use the direct remotes for toys.",
    Wrap = true
})

ItemUtilityGroup:AddDropdown({
    Name = "Item Variant",
    OptionsProvider = function()
        return utilityItemValues
    end,
    Default = selectedUtilityItemName,
    AutoRefresh = true,
    Callback = function(option)
        selectedUtilityItemName = option
        getgenv().utilityItemsConfig.ITEM = option
    end
})

ItemUtilityGroup:AddSlider({
    Name = "Item Amount",
    Min = 1,
    Max = 50,
    Default = itemUseAmount,
    Increment = 1,
    Callback = function(value)
        itemUseAmount = value
        getgenv().utilityItemsConfig.AMOUNT = value
    end
})

ItemUtilityGroup:AddButton({
    Name = "Use Selected Item",
    Callback = function()
        executeUtilityItemAction(selectedUtilityItemName, itemUseAmount)
    end
})

ItemUtilityGroup:AddToggle({
    Name = "Auto Use Items",
    Default = false,
    Callback = function(state)
        local function setRunning(value)
            autoItemRunning = value
        end
        if state then
            startAutomationWorker("AutoItems", setRunning, runAutoItems)
        else
            stopAutomationWorker("AutoItems", setRunning)
        end
    end
})

ItemUtilityGroup:AddDropdown({
    Name = "Bundle Variant",
    OptionsProvider = function()
        return autoBundleValues
    end,
    Default = selectedAutoBundle,
    Callback = function(option)
        selectedAutoBundle = option
        getgenv().autoBundlesConfig.BUNDLE = option
    end
})

ItemUtilityGroup:AddButton({
    Name = "Use Selected Bundle Once",
    Callback = function()
        task.spawn(syncAutoBundles)
    end
})

ItemUtilityGroup:AddToggle({
    Name = "Auto Use Bundles",
    Default = false,
    Callback = function(state)
        local function setRunning(value)
            autoBundleRunning = value
            getgenv().autoBundles = value
        end
        if state then
            startAutomationWorker("AutoBundles", setRunning, runAutoBundles)
        else
            stopAutomationWorker("AutoBundles", setRunning)
        end
    end
})

ItemFruitGroup:AddLabel({
    Text = "Fruit consumption uses the selected fruit remote and amount.",
    Wrap = true
})

ItemFruitGroup:AddDropdown({
    Name = "Fruit Variant",
    OptionsProvider = function()
        return consumableFruitChoiceValues
    end,
    Default = selectedConsumableFruitName,
    AutoRefresh = true,
    Callback = function(option)
        selectedConsumableFruitName = option
        getgenv().fruitConsumeConfig.FRUIT = option
    end
})

ItemFruitGroup:AddSlider({
    Name = "Fruit Amount",
    Min = 1,
    Max = 50,
    Default = fruitConsumeAmount,
    Increment = 1,
    Callback = function(value)
        fruitConsumeAmount = value
        getgenv().fruitConsumeConfig.AMOUNT = value
    end
})

ItemFruitGroup:AddButton({
    Name = "Consume Selected Fruit",
    Callback = function()
        executeFruitAction(selectedConsumableFruitName, fruitConsumeAmount)
    end
})

ItemFruitGroup:AddToggle({
    Name = "Auto Consume Fruits",
    Default = false,
    Callback = function(state)
        local function setRunning(value)
            autoFruitRunning = value
        end
        if state then
            startAutomationWorker("AutoFruits", setRunning, runAutoFruits)
        else
            stopAutomationWorker("AutoFruits", setRunning)
        end
    end
})

ItemBoostGroup:AddLabel({
    Text = "Boost actions use the selected spawn or consume remote. Comet is also reused for comet quests.",
    Wrap = true
})

ItemBoostGroup:AddDropdown({
    Name = "Boost Variant",
    OptionsProvider = function()
        return boostItemValues
    end,
    Default = selectedBoostItemName,
    AutoRefresh = true,
    Callback = function(option)
        selectedBoostItemName = option
        getgenv().boostItemsConfig.ITEM = option
    end
})

ItemBoostGroup:AddSlider({
    Name = "Boost Amount",
    Min = 1,
    Max = 50,
    Default = boostUseAmount,
    Increment = 1,
    Callback = function(value)
        boostUseAmount = value
        getgenv().boostItemsConfig.AMOUNT = value
    end
})

ItemBoostGroup:AddButton({
    Name = "Use Selected Boost",
    Callback = function()
        executeBoostAction(selectedBoostItemName, boostUseAmount)
    end
})

ItemBoostGroup:AddToggle({
    Name = "Auto Use Boosts",
    Default = false,
    Callback = function(state)
        local function setRunning(value)
            autoBoostRunning = value
        end
        if state then
            startAutomationWorker("AutoBoosts", setRunning, runAutoBoosts)
        else
            stopAutomationWorker("AutoBoosts", setRunning)
        end
    end
})

GiftGroup:AddLabel({
    Text = "Pick a free gift index, then redeem it from one button instead of twelve separate buttons.",
    Wrap = true
})

GiftGroup:AddDropdown({
    Name = "Gift Reward",
    Options = giftRewardValues,
    Default = selectedGiftReward,
    Callback = function(option)
        selectedGiftReward = option
        getgenv().giftRedeemConfig.INDEX = tonumber(option) or 1
    end
})

GiftGroup:AddButton({
    Name = "Redeem Selected Gift",
    Callback = function()
        redeemFreeGift(selectedGiftReward)
    end
})

GiftGroup:AddButton({
    Name = "Claim All Free Gifts",
    Callback = function()
        task.spawn(claimFreeGifts)
    end
})

end)

getgenv().FlowPS99Unload = function()
    getgenv().FlowPS99Unload = nil
    getgenv().FlowPS99Generation = (tonumber(getgenv().FlowPS99Generation) or flowSessionGeneration) + 1
    local unloadWindow = getgenv and getgenv().HipHubUI_Window
    pcall(function()
        stopPetSimAutomations()
    end)
    autoTapHeroesRunning = false
    pcall(function()
        TapHeroesAdapter:Stop()
    end)
    pcall(function()
        disableAntiIdle()
    end)
    pcall(function()
        restorePetSpeed()
    end)

    autoWorldFarmRunning = false
    autoCurrentStageFarmRunning = false
    autoBalloonChestRunning = false
    autoDigsiteRunning = false
    autoFishingRunning = false
    autoFruitRunning = false
    autoBundleRunning = false
    autoFlagsRunning = false
    autoItemRunning = false
    autoBoostRunning = false
    autoEggRunning = false
    autoEggHatcherRunning = false
    autoRNGRollRunning = false
    autoQuestRunning = false
    autoBreakableFarmRunning = false
    autoRankRewardsRunning = false
    autoDaycareRunning = false
    autoRoamingPetsRunning = false
    autoEventGoalsRunning = false
    autoPrisonKeysRunning = false
    autoChestRushBankHeistRunning = false
    autoFarmingWorldRunning = false
    autoEquipBestPetsRunning = false
    autoSoccerEventRunning = false
    autoSelectedMinigameRunning = false
    lowEndPerformanceRunning = false

    getgenv().autoChestRaidRunning = false
    getgenv().autoDigsite = false
    getgenv().autoFishing = false

    disconnectWorldCollectors()
    disconnectConnection(antiIdleConnection)
    antiIdleConnection = nil
    disconnectConnection(antiStaffConnection)
    antiStaffConnection = nil
    disconnectConnection(petVisualPlayerConnection)
    petVisualPlayerConnection = nil
    disconnectConnection(flyConnection)
    flyConnection = nil
    flying = false
    disconnectConnection(fruitUpdateConnection)
    fruitUpdateConnection = nil
    disconnectConnection(bundleUpdateConnection)
    bundleUpdateConnection = nil

    pcall(restorePerformanceState)
    pcall(restoreFishingState)
    pcall(restoreCharacterState)
    pcall(disconnectDiscoveryCacheInvalidators)

    TapHeroesStatusLabel = nil
    InitialTapHeroesStatus = nil
    getgenv().STAFF_DETECTED = false
    staffHopPending = false

    if Window then
        pcall(function()
            if type(Window.Destroy) == "function" then
                Window:Destroy()
            elseif type(Window.Unload) == "function" then
                Window:Unload()
            elseif type(Window.Close) == "function" then
                Window:Close()
            end
        end)
    end
end

if getgenv().autoBalloonChest and not autoBalloonChestLoopActive then
    startAutomationWorker("BalloonChest", setAutoBalloonChestRunning, runAutoBalloonChest, false)
end

if getgenv().antiAfkConfig.ENABLED then
    ensureAntiIdle()
end

installDiscoveryCacheInvalidators()

if getgenv().performanceConfig.DISABLE_RENDER == true then
    setFlowRenderingDisabled(true)
end

if getgenv().performanceConfig.ENABLED then
    startAutomationWorker("LowEndPerformance", setLowEndPerformanceRunning, runLowEndPerformanceLoop)
end

task.defer(function()
    TapHeroesAdapter:RefreshStatus()
end)