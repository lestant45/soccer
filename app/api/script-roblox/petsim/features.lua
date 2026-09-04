-- ==============================================================================
-- 🐾 HipHub Features Engine — Pet Simulator 99 Complete Automation
-- Full Automation Engine, Discovery Caches, Remotes & Workers
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
    getgenv().FlowPS99Generation = (tonumber(getgenv().FlowPS99Generation) or 0) + 1
    getgenv().FlowPS99LoadedAt = os.clock()
end
local flowSessionGeneration = (getgenv and getgenv().FlowPS99Generation) or 1





local autoQuestNotificationState = {}

function notifyFlow(title, description, duration)
    if Window and Window.Notify then
        pcall(function()
            Window:Notify({
                Title = tostring(title or "HipHub"),
                Description = tostring(description or ""),
                Duration = duration or 3
            })
        end)
    end
end

function shortenNotificationText(text, maxLength)
    local normalized = normalizeWhitespace(text)
    local limit = tonumber(maxLength) or 220
    if #normalized <= limit then
        return normalized
    end
    return normalized:sub(1, math.max(limit - 3, 1)) .. "..."
end

function resetAutoQuestNotifications()
    autoQuestNotificationState.ProgressKey = nil
    autoQuestNotificationState.VisibleQuestKey = nil
    autoQuestNotificationState.UnsupportedQuestKey = nil
end

function resetAutoQuestProgressNotification()
    autoQuestNotificationState.ProgressKey = nil
end

function notifyAutoQuestProgress(key, description, duration, title)
    if autoQuestNotificationState.ProgressKey == key then
        return
    end

    autoQuestNotificationState.ProgressKey = key
    notifyFlow(title or "Auto Quest", shortenNotificationText(description, 240), duration or 3)
end

function notifyAutoQuestVisibleQuests(visibleQuestTitles, questTask)
    local signature = table.concat(visibleQuestTitles or {}, " | ")
    if signature == "" or autoQuestNotificationState.VisibleQuestKey == signature then
        return
    end

    autoQuestNotificationState.VisibleQuestKey = signature

    local description = signature
    if questTask and questTask.Text then
        description = string.format("Selected: %s%s | Visible: %s", questTask.Text, formatQuestTaskStatus and formatQuestTaskStatus(questTask) or "", signature)
    end

    notifyFlow("Quest List", shortenNotificationText(description, 260), 4)
end

function notifyAutoQuestUnsupportedQuests(unsupportedQuestTitles)
    local signature = table.concat(unsupportedQuestTitles or {}, " | ")
    if signature == "" then
        autoQuestNotificationState.UnsupportedQuestKey = nil
        return
    end

    if autoQuestNotificationState.UnsupportedQuestKey == signature then
        return
    end

    autoQuestNotificationState.UnsupportedQuestKey = signature
    notifyFlow("Unsupported Quest", shortenNotificationText(signature, 260), 4)
end

function reportAutoQuestStatus(key, message, duration)
    print("[Auto Quest] " .. tostring(message))
    notifyAutoQuestProgress(key, message, duration or 3.2, "Auto Quest")
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer
local Network = ReplicatedStorage:WaitForChild("Network")
local Library = ReplicatedStorage:WaitForChild("Library")

local autoWorldFarmRunning = false
local autoCurrentStageFarmRunning = false
local autoBalloonChestRunning = false
local autoBalloonChestLoopActive = false
local autoDigsiteRunning = false
local autoFishingRunning = false
local autoFruitRunning = false
local autoBundleRunning = false
local autoFlagsRunning = false
local autoItemRunning = false
local autoBoostRunning = false
local autoEggRunning = false
local autoEggHatcherRunning = false
local autoRNGRollRunning = false
local autoQuestRunning = false
local autoBreakableFarmRunning = false
local autoRankRewardsRunning = false
local autoDaycareRunning = false
local autoRoamingPetsRunning = false
local autoEventGoalsRunning = false
local autoPrisonKeysRunning = false
local autoChestRushBankHeistRunning = false
local autoFarmingWorldRunning = false
local autoEquipBestPetsRunning = false
local autoSoccerEventRunning = false
local autoTapHeroesRunning = false
local autoSelectedMinigameRunning = false
local lowEndPerformanceRunning = false
local flying = false
local flyConnection
local flySpeedValue = 80

local lootbagCollectorInstalled = false
local orbCollectorInstalled = false
local antiIdleInstalled = false
local antiStaffInstalled = false
local staffHopPending = false
local lootbagCollectorConnection
local orbCollectorConnection
local antiIdleConnection
local antiStaffConnection
local petVisualPlayerConnection
local fruitUpdateConnection
local bundleUpdateConnection
local lastPetTargetId = nil
antiIdleRestoreState = {
    DisabledConnections = {},
    IdleTracking = nil,
    IdleTrackingEnabled = nil
}
petSpeedRestoreState = {
    Module = nil,
    Original = nil,
    Applied = false
}
characterRestoreState = nil
local rootAnchorOwners = {}
visualRestoreState = setmetatable({}, { __mode = "k" })
local visualMutationSequence = 0
performanceRestoreState = {
    FpsCaptured = false,
    FpsCap = nil,
    FpsApplied = nil,
    RenderingOwned = false,
    VisualApplied = false
}
local performanceVisualGeneration = 0
local performancePassRunning = false
fishingCharacterConnections = {}
local fishingVisualGeneration = 0
autoMineActive = false
automationWorkers = {}
local automationThreadState = {
    Generations = setmetatable({}, { __mode = "k" }),
    Workers = setmetatable({}, { __mode = "k" }),
    Serials = setmetatable({}, { __mode = "k" })
}
automationCancellationGeneration = 0

function disconnectConnection(connection)
    if connection then
        pcall(function()
            connection:Disconnect()
        end)
    end
end

function captureCharacterState()
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root then
        return nil
    end
    if not characterRestoreState or characterRestoreState.Character ~= character then
        characterRestoreState = {
            Character = character,
            Humanoid = humanoid,
            Root = root,
            WalkSpeed = humanoid.WalkSpeed,
            JumpPower = humanoid.JumpPower,
            PlatformStand = humanoid.PlatformStand,
            Anchored = root.Anchored,
            Velocity = root.AssemblyLinearVelocity
        }
    end
    return characterRestoreState
end

function setRootAnchored(anchored, owner)
    owner = owner or "Legacy"
    if anchored ~= true then
        return restoreRootAnchored(owner)
    end
    local state = captureCharacterState()
    if not state or not state.Root or not state.Root.Parent then
        return false
    end
    rootAnchorOwners[owner] = true
    state.Root.Anchored = true
    return true
end

function restoreRootAnchored(owner)
    local state = characterRestoreState
    if owner == nil then
        table.clear(rootAnchorOwners)
    else
        rootAnchorOwners[owner] = nil
    end
    if next(rootAnchorOwners) ~= nil then
        if state and state.Root and state.Root.Parent then
            state.Root.Anchored = true
            return true
        end
        return false
    end
    if state and state.Root and state.Root.Parent then
        state.Root.Anchored = state.Anchored
        return true
    end
    return false
end

function restoreCharacterState()
    disconnectConnection(flyConnection)
    flyConnection = nil
    flying = false
    local state = characterRestoreState
    characterRestoreState = nil
    table.clear(rootAnchorOwners)
    if not state then
        return
    end
    pcall(function()
        if state.Humanoid and state.Humanoid.Parent then
            state.Humanoid.WalkSpeed = state.WalkSpeed
            state.Humanoid.JumpPower = state.JumpPower
            state.Humanoid.PlatformStand = state.PlatformStand
        end
        if state.Root and state.Root.Parent then
            state.Root.Anchored = state.Anchored
            state.Root.AssemblyLinearVelocity = state.Velocity
        end
    end)
end

function setRestorableProperty(owner, object, propertyName, value)
    if not owner or not object then
        return false
    end
    local properties = visualRestoreState[object]
    local record = properties and properties[propertyName]
    local original
    if record then
        original = record.Original
    else
        local readOk, readValue = pcall(function()
            return object[propertyName]
        end)
        if not readOk then
            return false
        end
        original = readValue
    end

    local writeOk = pcall(function()
        object[propertyName] = value
    end)
    if not writeOk then
        return false
    end

    if not properties then
        properties = {}
        visualRestoreState[object] = properties
    end
    if not record then
        record = {
            Original = original,
            Applied = value,
            Owners = {}
        }
        properties[propertyName] = record
    end
    visualMutationSequence = visualMutationSequence + 1
    record.Owners[owner] = {
        Value = value,
        Sequence = visualMutationSequence
    }
    record.Applied = value
    return true
end

function restoreVisualState(owner)
    for object, properties in pairs(visualRestoreState) do
        for propertyName, record in pairs(properties) do
            if owner == nil then
                pcall(function()
                    if object[propertyName] == record.Applied then
                        object[propertyName] = record.Original
                    end
                end)
                properties[propertyName] = nil
            elseif record.Owners and record.Owners[owner] ~= nil then
                record.Owners[owner] = nil
                local hasRemainingOwner = false
                local remainingValue
                local remainingSequence = -math.huge
                for _, ownedRecord in pairs(record.Owners) do
                    if type(ownedRecord) == "table" and (tonumber(ownedRecord.Sequence) or 0) >= remainingSequence then
                        hasRemainingOwner = true
                        remainingValue = ownedRecord.Value
                        remainingSequence = tonumber(ownedRecord.Sequence) or 0
                    end
                end

                pcall(function()
                    if object[propertyName] ~= record.Applied then
                        return
                    end
                    if hasRemainingOwner then
                        object[propertyName] = remainingValue
                    else
                        object[propertyName] = record.Original
                    end
                end)

                if hasRemainingOwner then
                    record.Applied = remainingValue
                else
                    properties[propertyName] = nil
                end
            end
        end
        if next(properties) == nil then
            visualRestoreState[object] = nil
        end
    end
end

function invalidateAutomationWorkers()
    automationCancellationGeneration = automationCancellationGeneration + 1
    for _, worker in pairs(automationWorkers) do
        worker.Requested = false
    end
end

function startAutomationWorker(name, setter, runner, restartOnReturn)
    local worker = automationWorkers[name]
    if not worker then
        worker = { Active = false, Requested = false }
        automationWorkers[name] = worker
    end
    local wasRequested = worker.Requested
    worker.Setter = setter
    worker.Runner = runner
    worker.RestartOnReturn = restartOnReturn ~= false
    worker.Requested = true

    if worker.Active and wasRequested and worker.Generation == automationCancellationGeneration then
        return
    end

    worker.Serial = (worker.Serial or 0) + 1
    if worker.Active and (worker.Generation ~= automationCancellationGeneration or not wasRequested) then
        if not worker.PendingRestart then
            worker.PendingRestart = true
            task.spawn(function()
                while worker.Active
                    and worker.Requested
                    and flowSessionGeneration == getgenv().FlowPS99Generation do
                    task.wait(0.03)
                end
                worker.PendingRestart = false
                if worker.Requested
                    and flowSessionGeneration == getgenv().FlowPS99Generation then
                    startAutomationWorker(name, worker.Setter, worker.Runner, worker.RestartOnReturn)
                end
            end)
        end
        return
    end
    setter(true)
    if worker.Active then
        return
    end
    worker.Active = true
    local generation = automationCancellationGeneration
    local launchSerial = worker.Serial
    worker.Generation = generation
    worker.LaunchSerial = launchSerial
    task.spawn(function()
        local workerThread = coroutine.running()
        automationThreadState.Generations[workerThread] = generation
        automationThreadState.Workers[workerThread] = worker
        automationThreadState.Serials[workerThread] = launchSerial
        while worker.Requested
            and worker.Serial == launchSerial
            and generation == automationCancellationGeneration
            and flowSessionGeneration == getgenv().FlowPS99Generation do
            local cycleSerial = worker.Serial
            worker.Setter(true)
            local ok, err = pcall(worker.Runner)
            if not ok then
                warn("[HipHub Worker] " .. tostring(name) .. " failed: " .. tostring(err))
                if worker.Serial == launchSerial then
                    worker.Requested = false
                end
            elseif getgenv().STAFF_DETECTED then
                worker.Requested = false
            elseif not worker.RestartOnReturn and worker.Serial == cycleSerial then
                worker.Requested = false
            elseif worker.Requested then
                task.wait()
            end
        end
        if generation == automationCancellationGeneration then
            pcall(worker.Setter, false)
        end
        automationThreadState.Generations[workerThread] = nil
        automationThreadState.Workers[workerThread] = nil
        automationThreadState.Serials[workerThread] = nil
        worker.Active = false
    end)
end

function stopAutomationWorker(name, setter)
    local worker = automationWorkers[name]
    if worker then
        worker.Requested = false
        worker.Serial = (worker.Serial or 0) + 1
    end
    setter(false)
end
local eggDropdownValues = { "No eggs found" }
local eggNameLookup = {}
local selectedEggLabel = "No eggs found"
local selectedEggName
local HATCH_MODE_LATEST = "Latest Unlocked"
local HATCH_MODE_SELECTED = "Selected Egg"
local hatchModeValues = { HATCH_MODE_LATEST, HATCH_MODE_SELECTED }
local selectedHatchMode = HATCH_MODE_LATEST
local eggHatchAmount = 1
local eggHatchDelay = 0.2
local shopAmountValues = {}
local selectedShopAmount = 1
local advancedMerchantValues = {}
local selectedAdvancedMerchantAmount = 1
local eggSlotUpgradeValues = {}
local selectedEggSlotUpgrade = 1
local rngEventId = "First"
local rngRollDelay = 0.2
local rngDiceValues = {}
local selectedRngDiceAmount = 1
local rngEggLuckValues = {}
local rngHatchSpeedValues = {}
local rngBonusLuckValues = {}
local rngHugeLuckValues = {}
local selectedRNGEggLuckAmount = 1
local selectedRNGHatchSpeedAmount = 1
local selectedRNGBonusLuckAmount = 1
local selectedRNGHugeLuckAmount = 1
local BREAKABLE_FARM_RANDOM_ZONE = "Random Zone"
local AUTO_FLAG_BEST_AREA = "Best Area"
local AUTO_FRUIT_ALL = "All Fruits"
local AUTO_BUNDLE_ALL = "All Bundles"
local breakableFarmMethodValues = { "Best Area", "Selected Zone" }
local breakableFarmZoneValues = {}
local autoFlagZoneValues = {}
local autoFruitValues = { AUTO_FRUIT_ALL }
local autoBundleValues = { AUTO_BUNDLE_ALL }
local instanceValues = { "FarmingWorld" }
local MINIGAME_AUTO_ALL = "All Supported"
local minigameAutoValues = { MINIGAME_AUTO_ALL }
local selectedInstanceName
local selectedMinigameAuto = MINIGAME_AUTO_ALL
local directorySummaryValues = { "Farming" }
local selectedDirectorySummary = "Farming"
local keyHelperValues = {
    "Crystal Key",
    "Tech Key",
    "Void Key",
    "Prison Key",
    "Hacker Key",
    "Fantasy Key",
    "Secret Key",
    "MVP Key"
}
local selectedKeyHelper = keyHelperValues[1]
local autoFlagNameValues = {
    "Fortune Flag",
    "Diamonds Flag",
    "Hasty Flag",
    "Coins Flag",
    "Magnet Flag",
    "Strength Flag"
}
local utilityItemValues = {
    "Squeaky Toy",
    "Toy Ball",
    "Toy Bone"
}
local consumableFruitChoiceValues = {
    "Rainbow Fruit",
    "Banana",
    "Apple",
    "Orange",
    "Pineapple",
    "Watermelon"
}
local boostItemValues = {
    "Lucky Block",
    "Giant Coin Jar",
    "Party Box",
    "Mini Pinata",
    "TNT Crate",
    "Comet",
    "Magic Coin Jar",
    "Basic Coin Jar",
    "TNT"
}
local giftRewardValues = {}
vendingMachineValues = { "EnchantVendingMachine1", "PotionVendingMachine1" }
merchantValues = { "AdvancedMerchant" }
selectedVendingMachine = vendingMachineValues[1]
selectedMerchant = merchantValues[1]
local AUTO_EQUIP_DAMAGE_MODE = "Best Damage"
local AUTO_EQUIP_RARE_MODE = "Rarest First"
local autoEquipPetModeValues = { AUTO_EQUIP_DAMAGE_MODE, AUTO_EQUIP_RARE_MODE }
local selectedAutoEquipPetMode = AUTO_EQUIP_DAMAGE_MODE
local SOCCER_UPGRADE_ALL = "All Soccer Upgrades"
local soccerUpgradeValues = {
    SOCCER_UPGRADE_ALL,
    "SoccerYeetOrbStrength",
    "SoccerYeetOrbsReach",
    "SoccerBetterYeetEgg",
    "SoccerCriticalThrowChance",
    "SoccerTrickshotThrowChance",
    "SoccerPowerStrikePower",
    "SoccerPowerStrikeRequirement"
}
local SOCCER_BOOST_ALL = "All Soccer Boosts"
local soccerBoostValues = {
    SOCCER_BOOST_ALL,
    "Cleats",
    "Golden Cleats",
    "Soccer Orb Frenzy"
}
local soccerEggValues = {
    "Soccer Egg 1",
    "Soccer Egg 2",
    "Soccer Egg 3",
    "Soccer Egg 4",
    "Soccer Egg 5",
    "Soccer Egg 6",
    "Soccer Egg 7",
    "Soccer Egg 8 Tier 1",
    "Soccer Egg 8 Tier 2",
    "Soccer Egg 8 Tier 3",
    "Soccer Egg 8 Tier 4",
    "Soccer Egg 8 Tier 5",
    "Soccer Egg 8 Tier 6"
}
local selectedSoccerUpgrade = SOCCER_UPGRADE_ALL
local selectedSoccerBoost = SOCCER_BOOST_ALL
local selectedSoccerEgg = "Soccer Egg 8 Tier 6"
local TAP_HEROES_CONSUMABLE_ALL = "All Owned Event Consumables"
local tapHeroesConsumableDefinitions = {
    ["Tap Damage Booster"] = { Name = "Tap Damage Booster", Tier = 1 },
    ["Tap Damage Boost II"] = { Name = "Tap Damage Booster", Tier = 2 },
    ["Cracked Marble Clover"] = { Name = "Cracked Marble Clover", Tier = 1 },
    ["Polished Marble Clover"] = { Name = "Polished Marble Clover", Tier = 1 },
    ["Pristine Marble Clover"] = { Name = "Pristine Marble Clover", Tier = 1 },
    ["Chest Luck Boost"] = { Name = "Chest Luck Boost", Tier = 1 },
    ["Chest Luck Boost II"] = { Name = "Chest Luck Boost", Tier = 2 }
}
local tapHeroesConsumableValues = {
    TAP_HEROES_CONSUMABLE_ALL,
    "Tap Damage Booster",
    "Tap Damage Boost II",
    "Cracked Marble Clover",
    "Polished Marble Clover",
    "Pristine Marble Clover",
    "Chest Luck Boost",
    "Chest Luck Boost II"
}
local tapHeroesGiftValues = { "Marble Gift", "Obsidian Gift" }
local selectedTapHeroesConsumable = TAP_HEROES_CONSUMABLE_ALL
local selectedTapHeroesGift = "Marble Gift"
local soccerUpgradeAttemptTimes = {}
local soccerHatchWarnTimes = {}
local breakableFarmFilterValues = {
    "Any",
    "Coin",
    "Small Coin",
    "Medium Coin",
    "Large Coin",
    "Big Coin",
    "Chest",
    "Mini Chest",
    "Safe",
    "Vault",
    "Crate",
    "Present",
    "Diamond Present",
    "Diamond Pile",
    "Comet",
    "Ice Block",
    "Lucky Block"
}
local selectedBreakableFarmMethod = "Best Area"
local selectedBreakableFarmZone
local selectedBreakableFarmFilters = { "Any" }
local selectedAutoFlagName = autoFlagNameValues[1]
local selectedAutoFlagZone = AUTO_FLAG_BEST_AREA
local selectedAutoFruit = AUTO_FRUIT_ALL
local selectedAutoBundle = AUTO_BUNDLE_ALL
local selectedUtilityItemName = utilityItemValues[1]
local selectedConsumableFruitName = consumableFruitChoiceValues[1]
local selectedBoostItemName = boostItemValues[1]
local selectedGiftReward = "1"
local keyCombineAmount = 1
local keyUnlockAmount = 1
local flagUseAmount = 1
local itemUseAmount = 1
local fruitConsumeAmount = 1
local boostUseAmount = 1

function setDefault(tbl, key, value)
    if tbl[key] == nil then
        tbl[key] = value
    end
end

function cloneArray(source)
    local result = {}
    for _, value in ipairs(source or {}) do
        table.insert(result, value)
    end
    return result
end

function selectLatestAffordableEggCandidate(candidates, maxTier, currencyAmount, requestedAmount)
    local unlocked = {}
    local tierLimit = tonumber(maxTier) or math.huge
    local wanted = math.max(math.floor(tonumber(requestedAmount) or 1), 1)

    for _, candidate in ipairs(candidates or {}) do
        local tier = tonumber(candidate and candidate.Tier) or 0
        if tier >= 1 and tier <= tierLimit then
            table.insert(unlocked, candidate)
        end
    end

    table.sort(unlocked, function(a, b)
        return (tonumber(a.Tier) or 0) > (tonumber(b.Tier) or 0)
    end)

    for _, candidate in ipairs(unlocked) do
        local cost = tonumber(candidate.Cost)
        if currencyAmount ~= nil and cost and cost > 0 then
            local affordable = math.floor(math.max(tonumber(currencyAmount) or 0, 0) / cost)
            if affordable >= 1 then
                return candidate, math.min(wanted, affordable)
            end
        end
    end

    return nil, 0
end

getgenv().autoWorldConfig = getgenv().autoWorldConfig or {}
setDefault(getgenv().autoWorldConfig, "PURCHASE_CHECK_DELAY", 1)
setDefault(getgenv().autoWorldConfig, "ZONE_TO_REACH", 999)
setDefault(getgenv().autoWorldConfig, "AUTO_REBIRTH", false)
setDefault(getgenv().autoWorldConfig, "AUTO_BUY_UPGRADES", true)
setDefault(getgenv().autoWorldConfig, "AUTO_HATCH_ZONE_EGG", true)
setDefault(getgenv().autoWorldConfig, "MOVE_TO_BREAKABLES", true)
setDefault(getgenv().autoWorldConfig, "CLICK_BREAKABLES", true)
setDefault(getgenv().autoWorldConfig, "SWEEP_ORBS", true)
setDefault(getgenv().autoWorldConfig, "TELEPORT_INTERVAL", 1.2)

getgenv().autoStageFarmConfig = getgenv().autoStageFarmConfig or {}
setDefault(getgenv().autoStageFarmConfig, "MOVE_DELAY", 0.75)

getgenv().autoChestConfig = getgenv().autoChestConfig or {}
setDefault(getgenv().autoChestConfig, "START_DELAY", 1)
setDefault(getgenv().autoChestConfig, "TIMER_SEARCH_DELAY", 0.5)
setDefault(getgenv().autoChestConfig, "CHEST_BREAK_DELAY", 1)
setDefault(getgenv().autoChestConfig, "SERVER_HOP", false)
setDefault(getgenv().autoChestConfig, "SERVER_HOP_DELAY", 5)
setDefault(getgenv().autoChestConfig, "SEND_PETS", true)

getgenv().autoBalloonChestConfig = getgenv().autoBalloonChestConfig or {}
setDefault(getgenv().autoBalloonChestConfig, "START_DELAY", 1)
setDefault(getgenv().autoBalloonChestConfig, "BALLOON_DELAY", 1)
setDefault(getgenv().autoBalloonChestConfig, "SWITCH_DELAY", 1)
setDefault(getgenv().autoBalloonChestConfig, "SERVER_HOP_DELAY", 5)
setDefault(getgenv().autoBalloonChestConfig, "TIMER_SEARCH_DELAY", 0.5)
setDefault(getgenv().autoBalloonChestConfig, "TIMER_SEARCH_TIMEOUT", 12)
setDefault(getgenv().autoBalloonChestConfig, "CHEST_BREAK_DELAY", 1)

getgenv().autoDigsiteConfig = getgenv().autoDigsiteConfig or {}
setDefault(getgenv().autoDigsiteConfig, "SERVER_HOP_DELAY", 5)
setDefault(getgenv().autoDigsiteConfig, "NOT_LOADED_SERVER_HOP_DELAY", 30)
setDefault(getgenv().autoDigsiteConfig, "NO_CHEST_SERVER_HOP", 120)
setDefault(getgenv().autoDigsiteConfig, "MODULE_DELAY", 1)

getgenv().autoFishingConfig = getgenv().autoFishingConfig or {}
setDefault(getgenv().autoFishingConfig, "OPTIMIZE_GAME", false)
setDefault(getgenv().autoFishingConfig, "HIDE_PLAYER", false)
setDefault(getgenv().autoFishingConfig, "MODULE_DELAY", 1)

getgenv().autoEggConfig = getgenv().autoEggConfig or {}
setDefault(getgenv().autoEggConfig, "GEM_WAIT_DELAY", 10)
setDefault(getgenv().autoEggConfig, "RANK_WAIT_DELAY", 30)

getgenv().autoEggHatcherConfig = getgenv().autoEggHatcherConfig or {}
setDefault(getgenv().autoEggHatcherConfig, "AMOUNT", 99)
setDefault(getgenv().autoEggHatcherConfig, "DELAY", 0.2)
setDefault(getgenv().autoEggHatcherConfig, "MODE", HATCH_MODE_LATEST)
if getgenv().autoEggHatcherConfig.AMOUNT == 1 and not getgenv().autoEggHatcherConfig.FLOW_99_HATCH_AMOUNT_DEFAULT_APPLIED then
    getgenv().autoEggHatcherConfig.AMOUNT = 99
end
setDefault(getgenv().autoEggHatcherConfig, "FLOW_99_HATCH_AMOUNT_DEFAULT_APPLIED", true)

getgenv().autoQuestConfig = getgenv().autoQuestConfig or {}
setDefault(getgenv().autoQuestConfig, "SCAN_DELAY", 0.4)
setDefault(getgenv().autoQuestConfig, "TELEPORT_RETRY_DELAY", 2)
setDefault(getgenv().autoQuestConfig, "REPOSITION_INTERVAL", 8)
setDefault(getgenv().autoQuestConfig, "RANDOM_BREAKABLE_TELEPORT_INTERVAL", 5)
setDefault(getgenv().autoQuestConfig, "EGG_UNLOCK_RETRY_DELAY", 5)
setDefault(getgenv().autoQuestConfig, "ACTION_DELAY", 0.1)
setDefault(getgenv().autoQuestConfig, "UNSUPPORTED_LOG_DELAY", 3)
setDefault(getgenv().autoQuestConfig, "COLLECT_ROUTE_WAIT", 2)
setDefault(getgenv().autoQuestConfig, "STUCK_HOP_ENABLED", false)
setDefault(getgenv().autoQuestConfig, "STUCK_HOP_DELAY", 30)
setDefault(getgenv().autoQuestConfig, "DEBUG", true)
getgenv().autoQuestConfig.TELEPORT_RETRY_DELAY = 2
getgenv().autoQuestConfig.COLLECT_ROUTE_WAIT = 2

getgenv().breakableFarmConfig = getgenv().breakableFarmConfig or {}
setDefault(getgenv().breakableFarmConfig, "METHOD", "Best Area")
setDefault(getgenv().breakableFarmConfig, "ZONE", "")
setDefault(getgenv().breakableFarmConfig, "FILTERS", { "Any" })
setDefault(getgenv().breakableFarmConfig, "REPOSITION_INTERVAL", 8)
setDefault(getgenv().breakableFarmConfig, "TELEPORT_INTERVAL", 1.2)
setDefault(getgenv().breakableFarmConfig, "MOVE_TO_BREAKABLES", true)
setDefault(getgenv().breakableFarmConfig, "CLICK_BREAKABLES", true)
setDefault(getgenv().breakableFarmConfig, "SWEEP_ORBS", true)

getgenv().autoRNGConfig = getgenv().autoRNGConfig or {}
setDefault(getgenv().autoRNGConfig, "DELAY", 0.2)

getgenv().autoRankRewardsConfig = getgenv().autoRankRewardsConfig or {}
setDefault(getgenv().autoRankRewardsConfig, "CLAIM_DELAY", 0.15)
setDefault(getgenv().autoRankRewardsConfig, "SWEEP_DELAY", 5)

getgenv().autoFlagsConfig = getgenv().autoFlagsConfig or {}
setDefault(getgenv().autoFlagsConfig, "FLAG", autoFlagNameValues[1])
setDefault(getgenv().autoFlagsConfig, "ZONE", AUTO_FLAG_BEST_AREA)
setDefault(getgenv().autoFlagsConfig, "USE_DELAY", 300)
setDefault(getgenv().autoFlagsConfig, "AMOUNT", 1)

getgenv().autoFruitsConfig = getgenv().autoFruitsConfig or {}
setDefault(getgenv().autoFruitsConfig, "FRUIT", AUTO_FRUIT_ALL)

getgenv().autoBundlesConfig = getgenv().autoBundlesConfig or {}
setDefault(getgenv().autoBundlesConfig, "BUNDLE", AUTO_BUNDLE_ALL)

getgenv().utilityItemsConfig = getgenv().utilityItemsConfig or {}
setDefault(getgenv().utilityItemsConfig, "ITEM", utilityItemValues[1])
setDefault(getgenv().utilityItemsConfig, "AMOUNT", 1)

getgenv().fruitConsumeConfig = getgenv().fruitConsumeConfig or {}
setDefault(getgenv().fruitConsumeConfig, "FRUIT", consumableFruitChoiceValues[1])
setDefault(getgenv().fruitConsumeConfig, "AMOUNT", 1)

getgenv().boostItemsConfig = getgenv().boostItemsConfig or {}
setDefault(getgenv().boostItemsConfig, "ITEM", boostItemValues[1])
setDefault(getgenv().boostItemsConfig, "AMOUNT", 1)

getgenv().giftRedeemConfig = getgenv().giftRedeemConfig or {}
setDefault(getgenv().giftRedeemConfig, "INDEX", 1)

getgenv().pet99DiscoveryConfig = getgenv().pet99DiscoveryConfig or {}
setDefault(getgenv().pet99DiscoveryConfig, "REFRESH_DELAY", 5)
setDefault(getgenv().pet99DiscoveryConfig, "INCLUDE_UNSUPPORTED_ITEMS", false)

getgenv().autoInstanceConfig = getgenv().autoInstanceConfig or {}
setDefault(getgenv().autoInstanceConfig, "INSTANCE", "")
setDefault(getgenv().autoInstanceConfig, "ENTER_DELAY", 1)
setDefault(getgenv().autoInstanceConfig, "CLAIM_CHEST_DELAY", 1)
setDefault(getgenv().autoInstanceConfig, "SERVER_HOP", false)

getgenv().keyHelperConfig = getgenv().keyHelperConfig or {}
setDefault(getgenv().keyHelperConfig, "KEY", keyHelperValues[1])
setDefault(getgenv().keyHelperConfig, "COMBINE_AMOUNT", 1)
setDefault(getgenv().keyHelperConfig, "UNLOCK_AMOUNT", 1)

getgenv().autoDaycareConfig = getgenv().autoDaycareConfig or {}
setDefault(getgenv().autoDaycareConfig, "DELAY", 60)
setDefault(getgenv().autoDaycareConfig, "ENROLL_NORMAL", true)
setDefault(getgenv().autoDaycareConfig, "ENROLL_EXCLUSIVE", true)
setDefault(getgenv().autoDaycareConfig, "PET_LIMIT", 10)

getgenv().autoRoamingPetsConfig = getgenv().autoRoamingPetsConfig or {}
setDefault(getgenv().autoRoamingPetsConfig, "DELAY", 3)

getgenv().autoEventGoalsConfig = getgenv().autoEventGoalsConfig or {}
setDefault(getgenv().autoEventGoalsConfig, "DELAY", 10)
setDefault(getgenv().autoEventGoalsConfig, "MAX_GOALS", 12)

getgenv().autoPrisonKeysConfig = getgenv().autoPrisonKeysConfig or {}
setDefault(getgenv().autoPrisonKeysConfig, "DELAY", 5)
setDefault(getgenv().autoPrisonKeysConfig, "CHEST_SCAN", 20)

getgenv().autoChestRushBankHeistConfig = getgenv().autoChestRushBankHeistConfig or {}
setDefault(getgenv().autoChestRushBankHeistConfig, "DELAY", 15)
setDefault(getgenv().autoChestRushBankHeistConfig, "LEAVE_AFTER_CLAIM", false)

getgenv().autoMinigameConfig = getgenv().autoMinigameConfig or {}
setDefault(getgenv().autoMinigameConfig, "INSTANCE", MINIGAME_AUTO_ALL)
setDefault(getgenv().autoMinigameConfig, "DELAY", 10)
setDefault(getgenv().autoMinigameConfig, "AUTO_ENTER", true)
setDefault(getgenv().autoMinigameConfig, "AUTO_CLAIM", true)
setDefault(getgenv().autoMinigameConfig, "TRY_ACTIONS", true)
setDefault(getgenv().autoMinigameConfig, "REQUIRE_ACTIVE_FOR_ACTIONS", true)
setDefault(getgenv().autoMinigameConfig, "TRY_DISCOVERED_REMOTES", false)
setDefault(getgenv().autoMinigameConfig, "TRY_INTERACTABLES", true)
setDefault(getgenv().autoMinigameConfig, "MAX_REMOTE_ATTEMPTS", 8)
setDefault(getgenv().autoMinigameConfig, "MAX_INTERACTABLES", 10)
setDefault(getgenv().autoMinigameConfig, "LEAVE_AFTER_STEP", false)
if getgenv().autoMinigameConfig.TRY_DISCOVERED_REMOTES == true and not getgenv().autoMinigameConfig.FLOW_99_DISCOVERED_REMOTES_SAFE_DEFAULT_APPLIED then
    getgenv().autoMinigameConfig.TRY_DISCOVERED_REMOTES = false
end
setDefault(getgenv().autoMinigameConfig, "FLOW_99_DISCOVERED_REMOTES_SAFE_DEFAULT_APPLIED", true)

getgenv().autoFarmingWorldConfig = getgenv().autoFarmingWorldConfig or {}
setDefault(getgenv().autoFarmingWorldConfig, "DELAY", 10)
setDefault(getgenv().autoFarmingWorldConfig, "ENTER", true)
setDefault(getgenv().autoFarmingWorldConfig, "CLAIM_STORAGE", true)
setDefault(getgenv().autoFarmingWorldConfig, "HARVEST", true)
setDefault(getgenv().autoFarmingWorldConfig, "PLANT_EGGS", true)
setDefault(getgenv().autoFarmingWorldConfig, "PLACE_WORKERS", true)
setDefault(getgenv().autoFarmingWorldConfig, "PLACE_SPRINKLERS", true)
setDefault(getgenv().autoFarmingWorldConfig, "FEED_PETS", true)
setDefault(getgenv().autoFarmingWorldConfig, "MAX_PLANTS_PER_STEP", 3)
setDefault(getgenv().autoFarmingWorldConfig, "MAX_WORKERS_PER_STEP", 2)
setDefault(getgenv().autoFarmingWorldConfig, "MAX_SPRINKLERS_PER_STEP", 1)
setDefault(getgenv().autoFarmingWorldConfig, "FOOD_AMOUNT", 1)
setDefault(getgenv().autoFarmingWorldConfig, "GRID_SPACING", 11)

getgenv().autoEquipBestPetsConfig = getgenv().autoEquipBestPetsConfig or {}
setDefault(getgenv().autoEquipBestPetsConfig, "MODE", AUTO_EQUIP_DAMAGE_MODE)
setDefault(getgenv().autoEquipBestPetsConfig, "DELAY", 30)

getgenv().autoSoccerEventConfig = getgenv().autoSoccerEventConfig or {}
setDefault(getgenv().autoSoccerEventConfig, "DELAY", 5)
setDefault(getgenv().autoSoccerEventConfig, "ENTER", true)
setDefault(getgenv().autoSoccerEventConfig, "COLLECT_ORBS", true)
setDefault(getgenv().autoSoccerEventConfig, "USE_BOOSTS", true)
setDefault(getgenv().autoSoccerEventConfig, "BUY_UPGRADES", true)
setDefault(getgenv().autoSoccerEventConfig, "CLAIM_GOALS", true)
setDefault(getgenv().autoSoccerEventConfig, "AUTO_KICK", true)
setDefault(getgenv().autoSoccerEventConfig, "PERFECT_KICK", true)
setDefault(getgenv().autoSoccerEventConfig, "PERFECT_KICK_TARGET", 100)
setDefault(getgenv().autoSoccerEventConfig, "PERFECT_KICK_MIN_PERCENT", 99)
setDefault(getgenv().autoSoccerEventConfig, "PERFECT_KICK_WINDOW", 4)
setDefault(getgenv().autoSoccerEventConfig, "PERFECT_KICK_POLL", 0.03)
setDefault(getgenv().autoSoccerEventConfig, "HATCH_EGGS", true)
setDefault(getgenv().autoSoccerEventConfig, "BOOST", SOCCER_BOOST_ALL)
setDefault(getgenv().autoSoccerEventConfig, "UPGRADE", SOCCER_UPGRADE_ALL)
setDefault(getgenv().autoSoccerEventConfig, "EGG", "Soccer Egg 8 Tier 6")
setDefault(getgenv().autoSoccerEventConfig, "HATCH_AMOUNT", 99)
if getgenv().autoSoccerEventConfig.HATCH_AMOUNT == 10 and not getgenv().autoSoccerEventConfig.FLOW_99_HATCH_DEFAULT_APPLIED then
    getgenv().autoSoccerEventConfig.HATCH_AMOUNT = 99
end
setDefault(getgenv().autoSoccerEventConfig, "FLOW_99_HATCH_DEFAULT_APPLIED", true)
if getgenv().autoSoccerEventConfig.HATCH_EGGS == false and not getgenv().autoSoccerEventConfig.FLOW_99_SOCCER_HATCH_ENABLED_APPLIED then
    getgenv().autoSoccerEventConfig.HATCH_EGGS = true
end
setDefault(getgenv().autoSoccerEventConfig, "FLOW_99_SOCCER_HATCH_ENABLED_APPLIED", true)
if tonumber(getgenv().autoSoccerEventConfig.PERFECT_KICK_TARGET) == 99 then
    getgenv().autoSoccerEventConfig.PERFECT_KICK_TARGET = 100
end
if tonumber(getgenv().autoSoccerEventConfig.PERFECT_KICK_MIN_PERCENT) == 98 then
    getgenv().autoSoccerEventConfig.PERFECT_KICK_MIN_PERCENT = 99
end
if tonumber(getgenv().autoSoccerEventConfig.PERFECT_KICK_WINDOW) == 3 then
    getgenv().autoSoccerEventConfig.PERFECT_KICK_WINDOW = 4
end
if tonumber(getgenv().autoSoccerEventConfig.PERFECT_KICK_POLL) == 0.05 then
    getgenv().autoSoccerEventConfig.PERFECT_KICK_POLL = 0.03
end
setDefault(getgenv().autoSoccerEventConfig, "FLOW_99_PERFECT_KICK_DEFAULT_APPLIED", true)

getgenv().tapHeroesConfig = getgenv().tapHeroesConfig or {}
setDefault(getgenv().tapHeroesConfig, "DELAY", 1)
setDefault(getgenv().tapHeroesConfig, "ENTER", true)
setDefault(getgenv().tapHeroesConfig, "NATIVE_AUTO_TAP", true)
setDefault(getgenv().tapHeroesConfig, "AUTO_ADVANCE", true)
setDefault(getgenv().tapHeroesConfig, "AUTO_UPGRADES", true)
setDefault(getgenv().tapHeroesConfig, "AUTO_PERMANENT_UPGRADES", true)
setDefault(getgenv().tapHeroesConfig, "AUTO_HATCH", true)
setDefault(getgenv().tapHeroesConfig, "AUTO_FRENZY", true)
setDefault(getgenv().tapHeroesConfig, "UPGRADE_DELAY", 4)
setDefault(getgenv().tapHeroesConfig, "AUTO_USE_CONSUMABLES", false)
setDefault(getgenv().tapHeroesConfig, "CONSUMABLE", TAP_HEROES_CONSUMABLE_ALL)
setDefault(getgenv().tapHeroesConfig, "CONSUMABLE_AMOUNT", 1)
setDefault(getgenv().tapHeroesConfig, "CONSUMABLE_DELAY", 30)
setDefault(getgenv().tapHeroesConfig, "AUTO_OPEN_MARBLE_GIFTS", false)
setDefault(getgenv().tapHeroesConfig, "MARBLE_GIFT_AMOUNT", 1)
setDefault(getgenv().tapHeroesConfig, "MARBLE_GIFT_DELAY", 30)
setDefault(getgenv().tapHeroesConfig, "GIFT", "Marble Gift")
setDefault(getgenv().tapHeroesConfig, "GIFT_AMOUNT", getgenv().tapHeroesConfig.MARBLE_GIFT_AMOUNT)
setDefault(getgenv().tapHeroesConfig, "GIFT_DELAY", getgenv().tapHeroesConfig.MARBLE_GIFT_DELAY)
setDefault(getgenv().tapHeroesConfig, "AUTO_OPEN_GIFTS", getgenv().tapHeroesConfig.AUTO_OPEN_MARBLE_GIFTS == true)
selectedTapHeroesConsumable = getgenv().tapHeroesConfig.CONSUMABLE
selectedTapHeroesGift = getgenv().tapHeroesConfig.GIFT

getgenv().antiAfkConfig = getgenv().antiAfkConfig or {}
setDefault(getgenv().antiAfkConfig, "ENABLED", true)

getgenv().performanceConfig = getgenv().performanceConfig or {}
setDefault(getgenv().performanceConfig, "ENABLED", false)
setDefault(getgenv().performanceConfig, "DISABLE_EFFECTS", true)
setDefault(getgenv().performanceConfig, "SIMPLIFY_PARTS", true)
setDefault(getgenv().performanceConfig, "HIDE_OTHER_PETS", false)
setDefault(getgenv().performanceConfig, "HIDE_DROPS", true)
setDefault(getgenv().performanceConfig, "DISABLE_RENDER", false)
setDefault(getgenv().performanceConfig, "FPS_CAP", 240)
setDefault(getgenv().performanceConfig, "APPLY_INTERVAL", 20)

eggHatchAmount = getgenv().autoEggHatcherConfig.AMOUNT
eggHatchDelay = getgenv().autoEggHatcherConfig.DELAY
selectedHatchMode = getgenv().autoEggHatcherConfig.MODE
rngRollDelay = getgenv().autoRNGConfig.DELAY
selectedBreakableFarmMethod = getgenv().breakableFarmConfig.METHOD
selectedBreakableFarmZone = getgenv().breakableFarmConfig.ZONE
selectedBreakableFarmFilters = cloneArray(getgenv().breakableFarmConfig.FILTERS)
selectedAutoFlagName = getgenv().autoFlagsConfig.FLAG
selectedAutoFlagZone = getgenv().autoFlagsConfig.ZONE
selectedAutoFruit = getgenv().autoFruitsConfig.FRUIT
selectedAutoBundle = getgenv().autoBundlesConfig.BUNDLE
selectedUtilityItemName = getgenv().utilityItemsConfig.ITEM
selectedConsumableFruitName = getgenv().fruitConsumeConfig.FRUIT
selectedBoostItemName = getgenv().boostItemsConfig.ITEM
selectedGiftReward = tostring(getgenv().giftRedeemConfig.INDEX or 1)
selectedInstanceName = getgenv().autoInstanceConfig.INSTANCE
selectedKeyHelper = getgenv().keyHelperConfig.KEY
keyCombineAmount = getgenv().keyHelperConfig.COMBINE_AMOUNT
keyUnlockAmount = getgenv().keyHelperConfig.UNLOCK_AMOUNT
flagUseAmount = getgenv().autoFlagsConfig.AMOUNT
itemUseAmount = getgenv().utilityItemsConfig.AMOUNT
fruitConsumeAmount = getgenv().fruitConsumeConfig.AMOUNT
boostUseAmount = getgenv().boostItemsConfig.AMOUNT
selectedAutoEquipPetMode = getgenv().autoEquipBestPetsConfig.MODE
selectedSoccerBoost = getgenv().autoSoccerEventConfig.BOOST
selectedSoccerUpgrade = getgenv().autoSoccerEventConfig.UPGRADE
selectedSoccerEgg = getgenv().autoSoccerEventConfig.EGG
selectedTapHeroesConsumable = getgenv().tapHeroesConfig.CONSUMABLE
selectedMinigameAuto = getgenv().autoMinigameConfig.INSTANCE

if not table.find(hatchModeValues, selectedHatchMode) then
    selectedHatchMode = HATCH_MODE_LATEST
    getgenv().autoEggHatcherConfig.MODE = selectedHatchMode
end

getgenv().STAFF_DETECTED = false
getgenv().autoBalloonChest = getgenv().autoBalloonChest == true
autoBalloonChestRunning = getgenv().autoBalloonChest

function waitForCharacter(timeout)
    local deadline = os.clock() + math.max(tonumber(timeout) or 10, 0.1)
    while os.clock() < deadline do
        local workerThread = coroutine.running()
        local worker = automationThreadState.Workers[coroutine.running()]
        local generation = automationThreadState.Generations[workerThread]
        local launchSerial = automationThreadState.Serials[workerThread]
        if flowSessionGeneration ~= getgenv().FlowPS99Generation
            or (worker and not worker.Requested)
            or (worker and launchSerial and worker.Serial ~= launchSerial)
            or (generation and generation ~= automationCancellationGeneration) then
            return nil
        end

        local character = LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            return character
        end
        task.wait(0.05)
    end
    return nil
end

function getHumanoidRootPart(timeout)
    local character = waitForCharacter(timeout)
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        error("HumanoidRootPart is unavailable or the automation was cancelled.", 2)
    end
    return root
end

function toCFrame(value)
    if typeof(value) == "CFrame" then
        return value
    end
    if typeof(value) == "Vector3" then
        return CFrame.new(value)
    end
    return nil
end

function trim(value)
    if not value then
        return nil
    end
    return tostring(value):match("^%s*(.-)%s*$")
end

function split(input, separator)
    separator = separator or "%s"
    local parts = {}
    for str in string.gmatch(tostring(input), "([^" .. separator .. "]+)") do
        table.insert(parts, str)
    end
    return parts
end

function getDirectoryFolder(folderName)
    local directory = ReplicatedStorage:FindFirstChild("__DIRECTORY")
    return directory and directory:FindFirstChild(folderName)
end

local discoveryCache = {}
local discoveryCacheConnections = {}

function getCachedDiscovery(cacheKey, ttl, forceRefresh, producer)
    local now = os.clock()
    local cached = discoveryCache[cacheKey]
    if not forceRefresh and cached and now - cached.Time <= ttl then
        return cached.Value
    end

    local value = producer()
    discoveryCache[cacheKey] = {
        Time = now,
        Value = value
    }
    return value
end

function clearDiscoveryCache(cacheKey)
    if type(cacheKey) == "string" then
        discoveryCache[cacheKey] = nil
    else
        table.clear(discoveryCache)
    end
end

function disconnectDiscoveryCacheInvalidators()
    for _, connection in ipairs(discoveryCacheConnections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    table.clear(discoveryCacheConnections)
end

function addDiscoveryCacheInvalidator(signal)
    local ok, connection = pcall(function()
        return signal:Connect(clearDiscoveryCache)
    end)
    if ok and connection then
        table.insert(discoveryCacheConnections, connection)
    end
end

function installDiscoveryCacheInvalidators()
    if #discoveryCacheConnections > 0 then
        return
    end

    local directory = ReplicatedStorage:FindFirstChild("__DIRECTORY")
    if directory then
        addDiscoveryCacheInvalidator(directory.DescendantAdded)
        addDiscoveryCacheInvalidator(directory.DescendantRemoving)
    end

    local things = Workspace:FindFirstChild("__THINGS")
    local instances = things and things:FindFirstChild("Instances")
    if instances then
        addDiscoveryCacheInvalidator(instances.ChildAdded)
        addDiscoveryCacheInvalidator(instances.ChildRemoved)
    end

    addDiscoveryCacheInvalidator(Workspace.ChildAdded)
    addDiscoveryCacheInvalidator(Workspace.ChildRemoved)
end

function parseDirectoryLabel(rawName)
    local number, name = tostring(rawName):match("(%d+)%s*|%s*(.+)$")
    if name then
        return tonumber(number), trim(name)
    end
    return nil, trim(rawName)
end

function discoverDirectoryEntries(folderName, limit, forceRefresh)
    local cacheKey = "directory:" .. tostring(folderName) .. ":" .. tostring(limit or "all")
    return getCachedDiscovery(cacheKey, 10, forceRefresh, function()
        local folder = getDirectoryFolder(folderName)
        local entries = {}
        if not folder then
            return entries
        end

        for _, item in ipairs(folder:GetDescendants()) do
            if item:IsA("ModuleScript") then
                local number, name = parseDirectoryLabel(item.Name)
                table.insert(entries, {
                    Number = number or 0,
                    Name = name or item.Name,
                    FullName = item.Name,
                    Path = item,
                    Folder = folderName
                })
                if limit and #entries >= limit then
                    break
                end
            end
        end

        table.sort(entries, function(a, b)
            if a.Number == b.Number then
                return a.Name < b.Name
            end
            return a.Number < b.Number
        end)

        return entries
    end)
end

function getDirectoryEntryId(entry)
    if type(entry) ~= "table" then
        return nil
    end

    local ok, definition = pcall(require, entry.Path)
    if ok and type(definition) == "table" then
        local canonicalId = definition._id or definition.id or definition.ID or definition.Id
        if type(canonicalId) == "string" or type(canonicalId) == "number" then
            canonicalId = trim(tostring(canonicalId))
            if canonicalId ~= "" then
                return canonicalId
            end
        end
    end

    local fallbackId = trim(tostring(entry.Name or entry.FullName or ""))
    if fallbackId ~= "" then
        return fallbackId
    end
    return nil
end

function discoverWorldMaps(forceRefresh)
    return getCachedDiscovery("worldMaps", 3, forceRefresh, function()
        local maps = {}
        for _, child in ipairs(Workspace:GetChildren()) do
            if child:IsA("Folder") and (child.Name == "Map" or child.Name:match("^Map%d+$")) then
                local worldNumber = child.Name == "Map" and 1 or tonumber(child.Name:match("^Map(%d+)$")) or 0
                table.insert(maps, {
                    Number = worldNumber,
                    Name = child.Name,
                    Path = child
                })
            end
        end

        table.sort(maps, function(a, b)
            return a.Number < b.Number
        end)

        return maps
    end)
end

function getCurrentMaps(forceRefresh)
    local maps = discoverWorldMaps(forceRefresh)
    if #maps > 0 then
        return maps
    end

    for _, child in ipairs(Workspace:GetChildren()) do
        if child.Name == "Map" or child.Name:match("^Map%d+$") then
            local worldNumber = child.Name == "Map" and 1 or tonumber(child.Name:match("^Map(%d+)$")) or 0
            table.insert(maps, {
                Number = worldNumber,
                Name = child.Name,
                Path = child
            })
        end
    end

    if #maps > 0 then
        table.sort(maps, function(a, b)
            return a.Number < b.Number
        end)
    end

    return maps
end

function discoverInstances(forceRefresh)
    return getCachedDiscovery("instances", 3, forceRefresh, function()
        local things = Workspace:FindFirstChild("__THINGS")
        local instances = things and things:FindFirstChild("Instances")
        local values = {}
        if instances then
            for _, child in ipairs(instances:GetChildren()) do
                table.insert(values, child.Name)
            end
        end

        table.sort(values)

        if #values == 0 then
            table.insert(values, "No instances found")
        end

        return values
    end)
end

function refreshInstanceList(forceRefresh)
    table.clear(instanceValues)
    for _, value in ipairs(discoverInstances(forceRefresh)) do
        table.insert(instanceValues, value)
    end

    if not selectedInstanceName or selectedInstanceName == "" or not table.find(instanceValues, selectedInstanceName) then
        selectedInstanceName = instanceValues[1]
    end

    getgenv().autoInstanceConfig.INSTANCE = selectedInstanceName

    if refreshMinigameAutoList then
        refreshMinigameAutoList()
    end
end

function refreshMinigameAutoList()
    local seen = {}
    local skip = {
        FarmingWorld = true,
        SoccerEvent = true,
        TapHeroes = true,
        Backrooms = true,
        TreehouseMerchant = true
    }
    table.clear(minigameAutoValues)
    table.insert(minigameAutoValues, MINIGAME_AUTO_ALL)
    seen[MINIGAME_AUTO_ALL] = true

    local known = {
        "ChestRush",
        "BankHeist",
        "ChestRoulette",
        "ClawMachine",
        "DiamondWheelInstance",
        "TimeTrial",
        "TreasureHideout",
        "LuckyBlocks",
        "ChestRaid",
        "GrinchRaid",
        "Digsite",
        "AdvancedDigsite",
        "AdvancedFishing",
        "Fishing",
        "FishingEvent",
        "Woodcutting",
        "BlockParty",
        "FlowerGarden",
        "CrystalKeyCastle",
        "MillionaireRun",
        "Minefield",
        "SledRace",
        "Atlantis",
        "HackerObby",
        "HoverboardTechObby",
        "IceObby",
        "JungleObby",
        "PyramidObby",
        "SpawnObby",
        "StairwayToHeaven",
        "TreehouseMerchant",
        "EnchantEmpoweringInstance"
    }

    for _, name in ipairs(known) do
        if table.find(instanceValues, name) and not seen[name] and not skip[name] then
            table.insert(minigameAutoValues, name)
            seen[name] = true
        end
    end

    if not selectedMinigameAuto or not table.find(minigameAutoValues, selectedMinigameAuto) then
        selectedMinigameAuto = minigameAutoValues[1]
    end

    getgenv().autoMinigameConfig.INSTANCE = selectedMinigameAuto
end

function refreshDirectorySummaryList(forceRefresh)
    table.clear(directorySummaryValues)

    local groups = {
        { Label = "Farming", Folders = { "EggFarm", "EggFarmItems", "WorkerItems", "FarmingFoods", "FarmingAttributes" } },
        { Label = "Fishing / Catch", Folders = { "CatchItems", "FishingRods", "EventFishingRods", "EventFishingIslands", "EventFishingPOIs" } },
        { Label = "Tower / Pillars", Folders = { "TowerDefenseTowers", "TowerDefenseMaps", "HPillarItems", "CardItems" } },
        { Label = "Worlds / Zones", Folders = { "Worlds", "Zones" } },
        { Label = "Keys / Event Items", Folders = { "MiscItems", "InstanceChests", "EventGoals", "InstanceQuests" } }
    }

    for _, group in ipairs(groups) do
        local total = 0
        for _, folderName in ipairs(group.Folders) do
            total = total + #discoverDirectoryEntries(folderName, nil, forceRefresh)
        end
        table.insert(directorySummaryValues, string.format("%s (%d)", group.Label, total))
    end

    if not table.find(directorySummaryValues, selectedDirectorySummary) then
        selectedDirectorySummary = directorySummaryValues[1]
    end
end

function refreshMachineMerchantLists()
    local vending = discoverDirectoryEntries("VendingMachines", nil, true)
    local merchants = discoverDirectoryEntries("Merchants", nil, true)
    if #vending > 0 then
        table.clear(vendingMachineValues)
        local seen = {}
        for _, machineEntry in ipairs(vending) do
            local machineId = getDirectoryEntryId(machineEntry)
            if machineId and not seen[machineId] then
                table.insert(vendingMachineValues, machineId)
                seen[machineId] = true
            end
        end
    end
    if #merchants > 0 then
        table.clear(merchantValues)
        local seen = {}
        for _, merchantEntry in ipairs(merchants) do
            local merchantId = getDirectoryEntryId(merchantEntry)
            if merchantId and not seen[merchantId] then
                table.insert(merchantValues, merchantId)
                seen[merchantId] = true
            end
        end
    end
    if not table.find(vendingMachineValues, selectedVendingMachine) then
        selectedVendingMachine = vendingMachineValues[1]
    end
    if not table.find(merchantValues, selectedMerchant) then
        selectedMerchant = merchantValues[1]
    end
end

function parseEggLabel(rawName)
    local eggNumber, eggName = tostring(rawName):match("^(%d+)%s*|%s*(.+)$")
    if eggNumber and eggName then
        return tonumber(eggNumber), eggName
    end
    return nil, nil
end

function refreshEggList()
    local oldEggName = selectedEggName
    table.clear(eggDropdownValues)
    table.clear(eggNameLookup)

    local directory = ReplicatedStorage:FindFirstChild("__DIRECTORY")
    local eggsFolder = directory and directory:FindFirstChild("Eggs")

    if not eggsFolder then
        table.insert(eggDropdownValues, "No eggs found")
        selectedEggLabel = eggDropdownValues[1]
        selectedEggName = nil
        return
    end

    local entries = {}
    local seen = {}
    local roots = {
        eggsFolder:FindFirstChild("Zone Eggs"),
        eggsFolder:FindFirstChild("Events"),
        eggsFolder:FindFirstChild("Other"),
        eggsFolder:FindFirstChild("Gifts")
    }

    local function walk(node, category)
        if not node then
            return
        end

        for _, child in ipairs(node:GetChildren()) do
            local eggNumber, eggName = parseEggLabel(child.Name)
            if child:IsA("ModuleScript") then
                local purchaseName = eggName or child.Name
                local label = eggNumber and string.format("%d | %s", eggNumber, purchaseName) or purchaseName
                if category and category ~= "" and not label:find(category, 1, true) then
                    label = string.format("%s / %s", category, label)
                end
                if not seen[purchaseName] then
                    seen[purchaseName] = true
                    table.insert(entries, {
                        Number = eggNumber or 100000 + #entries,
                        Label = label,
                        PurchaseName = purchaseName
                    })
                end
            elseif child:IsA("Folder") then
                walk(child, category or child.Name)
            elseif eggNumber and eggName and not seen[eggName] then
                seen[eggName] = true
                table.insert(entries, {
                    Number = eggNumber,
                    Label = string.format("%d | %s", eggNumber, eggName),
                    PurchaseName = eggName
                })
            end
        end
    end

    for _, root in ipairs(roots) do
        walk(root, root and root.Name or nil)
    end

    table.sort(entries, function(a, b)
        if a.Number == b.Number then
            return a.PurchaseName < b.PurchaseName
        end
        return a.Number < b.Number
    end)

    for _, entry in ipairs(entries) do
        table.insert(eggDropdownValues, entry.Label)
        eggNameLookup[entry.Label] = entry.PurchaseName
    end

    if #eggDropdownValues == 0 then
        table.insert(eggDropdownValues, "No eggs found")
        selectedEggLabel = eggDropdownValues[1]
        selectedEggName = nil
        return
    end

    if oldEggName then
        for label, purchaseName in pairs(eggNameLookup) do
            if purchaseName == oldEggName then
                selectedEggLabel = label
                selectedEggName = purchaseName
                return
            end
        end
    end

    selectedEggLabel = eggDropdownValues[1]
    selectedEggName = eggNameLookup[selectedEggLabel]
end

function getEggDirectoryData(eggName)
    local wanted = normalizeWhitespace(eggName)
    if wanted == "" then
        return nil
    end

    return getCachedDiscovery("eggData:" .. wanted, 10, false, function()
        local eggsFolder = getDirectoryFolder("Eggs")
        if not eggsFolder then
            return nil
        end

        for _, moduleScript in ipairs(eggsFolder:GetDescendants()) do
            if moduleScript:IsA("ModuleScript") then
                local _, parsedName = parseEggLabel(moduleScript.Name)
                if parsedName == wanted or moduleScript.Name == wanted then
                    local ok, data = pcall(require, moduleScript)
                    if ok and type(data) == "table" then
                        return data
                    end
                end
            end
        end

        for _, moduleScript in ipairs(eggsFolder:GetDescendants()) do
            if moduleScript:IsA("ModuleScript") then
                local ok, data = pcall(require, moduleScript)
                if ok and type(data) == "table" then
                    local name = data.name or data.Name or data._id or data.id
                    if normalizeWhitespace(name) == wanted then
                        return data
                    end
                end
            end
        end

        return nil
    end)
end

for i = 1, 99 do
    table.insert(shopAmountValues, tostring(i))
    table.insert(eggSlotUpgradeValues, tostring(i))
end

for i = 1, 6 do
    table.insert(advancedMerchantValues, tostring(i))
    table.insert(rngDiceValues, tostring(i))
end

for i = 1, 15 do
    table.insert(rngEggLuckValues, tostring(i))
    table.insert(rngHatchSpeedValues, tostring(i))
end

for i = 1, 8 do
    table.insert(rngBonusLuckValues, tostring(i))
end

for i = 1, 13 do
    table.insert(rngHugeLuckValues, tostring(i))
end

for i = 1, 12 do
    table.insert(giftRewardValues, tostring(i))
end

function purchaseVendingMachine(machineId)
    local ok, result = pcall(function()
        return Network.VendingMachines_Purchase:InvokeServer(machineId, selectedShopAmount)
    end)

    if not ok then
        warn("Vending purchase failed for " .. tostring(machineId) .. ": " .. tostring(result))
        return
    end

    print("Purchased from " .. tostring(machineId) .. " x" .. tostring(selectedShopAmount))
    return result
end

function purchaseEggSlotUpgrade()
    local ok, result = pcall(function()
        return Network.EggHatchSlotsMachine_RequestPurchase:InvokeServer(selectedEggSlotUpgrade)
    end)

    if not ok then
        warn("Egg slot upgrade purchase failed: " .. tostring(result))
        return
    end

    print("Requested egg slot upgrade " .. tostring(selectedEggSlotUpgrade))
    return result
end

function purchaseAdvancedMerchant()
    local ok, result = pcall(function()
        return Network.Merchant_RequestPurchase:InvokeServer("AdvancedMerchant", selectedAdvancedMerchantAmount)
    end)

    if not ok then
        warn("Advanced merchant purchase failed: " .. tostring(result))
        return
    end

    print("Purchased from AdvancedMerchant x" .. tostring(selectedAdvancedMerchantAmount))
    return result
end

function purchaseMerchant(merchantId, slotIndex)
    local remote = Network:FindFirstChild("Merchant_RequestPurchase")
    if not remote or not merchantId then
        return false
    end
    local ok, result = pcall(function()
        return remote:InvokeServer(merchantId, math.max(math.floor(tonumber(slotIndex) or 1), 1))
    end)
    if not ok or result == false then
        warn("Merchant purchase failed for " .. tostring(merchantId) .. ": " .. tostring(result))
        return false
    end
    return true
end

function isRngEventAvailable()
    return Network:FindFirstChild("Rng_Roll_V2") ~= nil
        and Network:FindFirstChild("Rng_PurchaseUpgrade_V2") ~= nil
end

function rollRNGOnce()
    local remote = Network:FindFirstChild("Rng_Roll_V2")
    if not remote then
        return false
    end

    local ok, result = pcall(function()
        return remote:InvokeServer(rngEventId)
    end)

    if not ok then
        warn("RNG roll failed: " .. tostring(result))
        return false
    end

    if result ~= false then
        print("Rolled RNG event " .. tostring(rngEventId))
    end
    return result
end

function purchaseRNGUpgrade(upgradeId, amount)
    amount = tonumber(amount) or 1
    local remote = Network:FindFirstChild("Rng_PurchaseUpgrade_V2")
    if not remote then
        return false
    end

    local purchased = 0
    for _ = 1, amount do
        local ok, result = pcall(function()
            return remote:InvokeServer(rngEventId, upgradeId)
        end)

        if not ok then
            warn("RNG upgrade purchase failed for " .. tostring(upgradeId) .. ": " .. tostring(result))
            return purchased > 0
        end

        if result ~= false then
            purchased = purchased + 1
        end
        task.wait(0.05)
    end

    if purchased > 0 then
        print("Purchased RNG upgrade " .. tostring(upgradeId) .. " x" .. tostring(purchased))
    end
    return purchased > 0
end

function purchaseRNGDice()
    if not isRngEventAvailable() then
        notifyFlow("RNG Event", "This legacy event is not active in the current update.", 3)
        return false
    end
    local ok, result = pcall(function()
        return Network.Merchant_RequestPurchase:InvokeServer("LuckyDiceMerchantV2", selectedRngDiceAmount)
    end)

    if not ok then
        warn("Lucky dice purchase failed: " .. tostring(result))
        return false
    end

    if result ~= false then
        print("Purchased lucky dice x" .. tostring(selectedRngDiceAmount))
    end
    return result
end

function getMaxOwnedZoneNumber()
    local zoneCmds = requireClientModule("ZoneCmds")
    if type(zoneCmds) == "table" and type(zoneCmds.GetMaxOwnedZone) == "function" then
        local ok, _, zoneData = pcall(zoneCmds.GetMaxOwnedZone)
        local zoneNumber = ok and type(zoneData) == "table" and tonumber(zoneData.ZoneNumber) or nil
        if zoneNumber then
            return zoneNumber
        end
    end

    local saveData = getSaveData and getSaveData() or nil
    if type(saveData) == "table" then
        for _, key in ipairs({ "MaximumAvailableZone", "MaxZone", "MaxOwnedZone" }) do
            local value = saveData[key]
            local zoneNumber = tonumber(type(value) == "table" and value.ZoneNumber or value)
            if zoneNumber then
                return zoneNumber
            end
        end
    end
    return nil
end

function getCurrentMap()
    local maps = getCurrentMaps()
    if #maps == 0 then
        return nil, "Unknown"
    end

    local ownedZone = getMaxOwnedZoneNumber and getMaxOwnedZoneNumber()
    if ownedZone then
        for i = #maps, 1, -1 do
            local mapEntry = maps[i]
            local path = mapEntry.Path
            if path then
                for _, child in ipairs(path:GetChildren()) do
                    local zoneNumber = tonumber(tostring(child.Name):match("^(%d+)%s*|"))
                    if zoneNumber and zoneNumber <= ownedZone then
                        return path, mapEntry.Name
                    end
                end
            end
        end
    end

    local entry = maps[#maps]
    return entry.Path, entry.Name
end

function findZonePathByName(map, zoneName)
    local normalizedTarget = normalizeWhitespace and normalizeWhitespace(zoneName) or trim(zoneName)
    if normalizedTarget == "" then
        return nil
    end

    local maps = map and { { Path = map } } or getCurrentMaps()
    for _, mapEntry in ipairs(maps) do
        local mapPath = mapEntry.Path or mapEntry
        if mapPath then
            for _, zone in ipairs(mapPath:GetChildren()) do
                local parsedZoneName = trim(split(zone.Name, "|")[2])
                if parsedZoneName == normalizedTarget then
                    return zone
                end
            end
        end
    end
    return nil
end

function findZonePathByData(map, zoneNumber, zoneName)
    local prefix = tostring(zoneNumber) .. " | " .. tostring(zoneName)
    local maps = map and { { Path = map } } or getCurrentMaps()
    for _, mapEntry in ipairs(maps) do
        local mapPath = mapEntry.Path or mapEntry
        if mapPath then
            for _, zone in ipairs(mapPath:GetChildren()) do
                if string.find(zone.Name, prefix, 1, true) then
                    return zone
                end
            end
        end
    end
    return findZonePathByName(map, zoneName)
end

function waitForZoneInteract(zonePath, isRunning)
    if not zonePath then
        return false
    end
    if zonePath:FindFirstChild("INTERACT") then
        return isRunning == nil or isRunning()
    end

    local loaded = false
    local connection
    connection = zonePath.ChildAdded:Connect(function(child)
        if child.Name == "INTERACT" then
            loaded = true
        end
    end)

    repeat
        if not waitForRunningDelay(0.03, isRunning) then
            break
        end
    until loaded or zonePath:FindFirstChild("INTERACT") or (isRunning and not isRunning())

    disconnectConnection(connection)

    return zonePath:FindFirstChild("INTERACT") ~= nil
        and (isRunning == nil or isRunning())
end

function getClosestBreakZone(zonePath)
    if not zonePath or not zonePath:FindFirstChild("INTERACT") then
        return nil
    end

    local breakZones = zonePath.INTERACT:FindFirstChild("BREAK_ZONES")
    if not breakZones then
        return nil
    end

    local hrp = getHumanoidRootPart()
    local closest
    local closestDistance = math.huge

    for _, breakZone in ipairs(breakZones:GetChildren()) do
        if breakZone:IsA("BasePart") then
            local distance = (hrp.Position - breakZone.Position).Magnitude
            if distance < closestDistance then
                closestDistance = distance
                closest = breakZone
            end
        end
    end

    return closest
end

function ensurePetSpeed()
    if petSpeedRestoreState.Applied then
        return true
    end

    local ok = pcall(function()
        local playerPet = require(Library.Client.PlayerPet)
        petSpeedRestoreState.Module = playerPet
        petSpeedRestoreState.Original = playerPet.CalculateSpeedMultiplier
        playerPet.CalculateSpeedMultiplier = function()
            return 200
        end
        petSpeedRestoreState.Applied = true
    end)
    return ok and petSpeedRestoreState.Applied
end

function restorePetSpeed()
    if petSpeedRestoreState.Applied and petSpeedRestoreState.Module then
        pcall(function()
            petSpeedRestoreState.Module.CalculateSpeedMultiplier = petSpeedRestoreState.Original
        end)
    end
    petSpeedRestoreState.Module = nil
    petSpeedRestoreState.Original = nil
    petSpeedRestoreState.Applied = false
end

function clearOwnedPetTargets()
    local ownedTargetId = lastPetTargetId
    lastPetTargetId = nil
    if ownedTargetId == nil then
        return false
    end

    local client = Library:FindFirstChild("Client")
    local playerPetModule = client and client:FindFirstChild("PlayerPet")
    if not playerPetModule then
        return false
    end

    local moduleOk, PlayerPet = pcall(require, playerPetModule)
    if not moduleOk or type(PlayerPet) ~= "table" or type(PlayerPet.GetByPlayer) ~= "function" then
        return false
    end

    local petsOk, pets = pcall(function()
        return PlayerPet.GetByPlayer(LocalPlayer)
    end)
    if not petsOk or type(pets) ~= "table" then
        return false
    end

    local cleared = false
    for _, pet in pairs(pets) do
        pcall(function()
            if type(pet.GetTargetType) == "function"
                and type(pet.GetTargetValue) == "function"
                and type(pet.ClearTarget) == "function"
                and pet:GetTargetType() == "Breakable"
                and tostring(pet:GetTargetValue()) == tostring(ownedTargetId) then
                pet:ClearTarget()
                cleared = true
            end
        end)
    end
    return cleared
end

function claimLootbag(lootbag)
    if not lootbag then
        return false
    end

    local remote = Network:FindFirstChild("Lootbags_Claim")
    if not remote then
        return false
    end

    local ok = pcall(function()
        remote:FireServer({ { lootbag.Name } })
    end)
    return ok
end

function getCurrentLootables()
    local things = Workspace:FindFirstChild("__THINGS")
    local lootables = things and things:FindFirstChild("Lootables")
    return lootables and lootables:GetChildren() or {}
end




function claimLootable(lootable)
    if not lootable then
        return false
    end
    local lootableId = lootable:GetAttribute("Id") or lootable:GetAttribute("ID")
        or lootable:GetAttribute("LootableId") or lootable.Name
    if lootableId == nil or tostring(lootableId) == "" then
        return false
    end
    local remote = Network:FindFirstChild("Lootables_Open")
    if not remote or not remote:IsA("RemoteFunction") then
        return false
    end
    local ok, result = pcall(function()
        return remote:InvokeServer(lootableId)
    end)
    return ok and result ~= false
end

function claimOrb(orb)
    if not orb then
        return false
    end

    local orbId = tonumber(orb.Name) or orb.Name
    pcall(function()
        local clientNet = require(Library.Client.Network)
        if clientNet and clientNet.Fire then
            clientNet.Fire("Orbs: Collect", { orbId })
        end
    end)
    pcall(function()
        local remote = Network:FindFirstChild("Orbs: Collect")
        if remote then
            remote:FireServer({ orbId })
        end
    end)
    return true
end

local QUEST_DIFFICULTIES = { "Extreme", "Hard", "Medium", "Easy" }
local QUEST_TYPES = {
    HATCH = "HatchBestEggs",
    BREAK = "BreakBestAreaBreakables",
    EARN_DIAMONDS = "EarnDiamonds",
    COLLECT_ENCHANTS = "CollectEnchants",
    COLLECT_POTIONS = "CollectPotions",
    USE_FRUITS = "UseFruits",
    USE_FLAGS = "UseFlags",
    USE_POTIONS = "UsePotions",
    EARN_COINS = "EarnCoins",
    OPEN_GIFTS = "OpenGifts",
    ROLL_RNG = "RollRNG",
    USE_BOOSTS = "UseBoosts",
    COLLECT_LOOTBAGS = "CollectLootbags",
    MAKE_GOLD = "MakeBestPetsGold",
    MAKE_RAINBOW = "MakeBestPetsRainbow",
    LEVEL_UP_PETS = "LevelUpPets",
    SEND_TO_INDEX = "SendPetsToIndex",
    UPGRADE_ENCHANT = "UpgradeEnchant"
}
local BREAKABLE_RANDOM = Random.new()
local NUMBER_SUFFIXES = {
    k = 1e3,
    m = 1e6,
    b = 1e9,
    t = 1e12,
    qa = 1e15,
    qi = 1e18,
    sx = 1e21,
    sp = 1e24,
    oc = 1e27,
    no = 1e30,
    dc = 1e33,
    ud = 1e36,
    dd = 1e39,
    td = 1e42,
    qd = 1e45
}
local BREAKABLE_FARM_FILTER_KEYS = {
    ["Any"] = "any",
    ["Coin"] = "coin",
    ["Small Coin"] = "smallcoin",
    ["Medium Coin"] = "mediumcoin",
    ["Large Coin"] = "largecoin",
    ["Big Coin"] = "bigcoin",
    ["Chest"] = "chest",
    ["Mini Chest"] = "minichest",
    ["Safe"] = "safe",
    ["Vault"] = "vault",
    ["Crate"] = "crate",
    ["Present"] = "present",
    ["Diamond Present"] = "diamondpresent",
    ["Diamond Pile"] = "diamondpile",
    ["Comet"] = "comet",
    ["Ice Block"] = "iceblock",
    ["Lucky Block"] = "luckyblock"
}

function normalizeWhitespace(text)
    local normalized = tostring(text or "")
    normalized = normalized:gsub("%s+", " ")
    return normalized:match("^%s*(.-)%s*$")
end

function getLabelText(label)
    if not label then
        return nil
    end

    local contentText
    pcall(function()
        contentText = label.ContentText
    end)

    if type(contentText) == "string" and contentText ~= "" then
        return normalizeWhitespace(contentText)
    end

    local rawText
    pcall(function()
        rawText = label.Text
    end)

    if type(rawText) == "string" and rawText ~= "" then
        return normalizeWhitespace(rawText)
    end

    return nil
end

function extractQuestNumber(text, actionWord)
    local normalized = normalizeWhitespace(text)
    local amountText

    if actionWord then
        amountText = normalized:match(actionWord .. "%s+([%d,]+)")
    end

    amountText = amountText or normalized:match("([%d,]+)")
    return amountText and tonumber((amountText:gsub(",", ""))) or 0
end

function extractHatchQuestAmount(text)
    local normalized = normalizeWhitespace(text)
    if normalized == "" then
        return nil
    end

    local lower = normalized:lower()
    local mentionsEggs = lower:find("egg", 1, true) ~= nil
    local mentionsBestEggs = lower:find("best egg", 1, true) ~= nil
        or lower:find("your best egg", 1, true) ~= nil

    if not lower:find("hatch", 1, true) or (not mentionsBestEggs and not mentionsEggs) then
        return nil
    end

    local amount = extractQuestNumber(normalized, "[Hh]atch")
    return amount, normalized
end

function extractBreakQuestAmount(text)
    local normalized = normalizeWhitespace(text)
    if normalized == "" then
        return nil
    end

    local lower = normalized:lower()
    if not lower:find("break", 1, true) then
        return nil
    end

    local amount = extractQuestNumber(normalized, "[Bb]reak")
    return amount, normalized
end

function collapseKey(text)
    if text == nil then
        return ""
    end
    return tostring(text):lower():gsub("[^%w]", "")
end

function stripTrailingMode(text)
    return normalizeWhitespace((tostring(text or ""):gsub("%s*%b()$", "")))
end

function normalizeBreakableTarget(text)
    local key = collapseKey(stripTrailingMode(text))
    if key == "" then
        return nil
    end
    if key:find("diamond", 1, true) and key:find("breakable", 1, true) then
        return "diamond"
    end
    if key == "diamond" then
        return "diamond"
    end
    if key:find("luckyblock", 1, true) then
        return "luckyblock"
    end
    if key:find("diamondpresent", 1, true) then
        return "diamondpresent"
    end
    if key:find("diamondpile", 1, true) then
        return "diamondpile"
    end
    if key:find("iceblock", 1, true) then
        return "iceblock"
    end
    if key:find("chest", 1, true) then
        return "chest"
    end
    if key:find("vault", 1, true) then
        return "vault"
    end
    if key:find("safe", 1, true) then
        return "safe"
    end
    if key:find("crate", 1, true) then
        return "crate"
    end
    if key:find("present", 1, true) then
        return "present"
    end
    if key:find("comet", 1, true) then
        return "comet"
    end
    if key:find("coin", 1, true) or key:find("bar", 1, true) or key:find("pile", 1, true) then
        return "coin"
    end
    return key
end

function extractBreakQuestTask(text)
    local amount, normalized = extractBreakQuestAmount(text)
    if not amount then
        return nil
    end

    local loweredNormalized = normalized:lower()
    local targetText = normalizeWhitespace(normalized:gsub("^[Bb]reak%s+", "", 1))
    targetText = normalizeWhitespace(targetText:gsub("^[%d,]+%s*", "", 1))
    local inBestArea = targetText ~= nil and targetText:lower():find("best area", 1, true) ~= nil

    targetText = normalizeWhitespace(targetText:gsub("[Ii]n%s+[Tt]he%s+[Bb]est%s+[Aa]rea", ""))
    targetText = normalizeWhitespace(targetText:gsub("[Ii]n%s+[Bb]est%s+[Aa]rea", ""))
    targetText = normalizeWhitespace(targetText:gsub("%s+[Bb]reakables?$", ""))
    targetText = normalizeWhitespace(targetText:gsub("^breakables?%s*", ""))

    if loweredNormalized:find("breakables in best area", 1, true)
        or loweredNormalized:find("breakables in the best area", 1, true) then
        targetText = nil
        inBestArea = true
    end

    if not targetText or targetText == "" or targetText:lower() == "breakables" then
        targetText = nil
    end

    if not targetText then
        inBestArea = true
    end

    return {
        Amount = amount,
        Text = normalized,
        TargetText = targetText,
        TargetKey = normalizeBreakableTarget(targetText),
        InBestArea = inBestArea
    }
end

function extractEarnDiamondsQuest(text)
    local normalized = normalizeWhitespace(text)
    if normalized == "" then
        return nil
    end

    local lower = normalized:lower()
    if not lower:find("earn", 1, true) or not lower:find("diamond", 1, true) then
        return nil
    end

    return {
        Amount = extractQuestNumber(normalized, "[Ee]arn"),
        Text = normalized
    }
end

function extractCollectEnchantsQuest(text)
    local normalized = normalizeWhitespace(text)
    if normalized == "" then
        return nil
    end

    local lower = normalized:lower()
    if not lower:find("collect", 1, true) or not lower:find("enchant", 1, true) then
        return nil
    end

    return {
        Amount = extractQuestNumber(normalized, "[Cc]ollect"),
        Text = normalized
    }
end

function extractCollectPotionsQuest(text)
    local normalized = normalizeWhitespace(text)
    if normalized == "" then
        return nil
    end

    local lower = normalized:lower()
    if not lower:find("collect", 1, true) or not lower:find("potion", 1, true) then
        return nil
    end

    return {
        Amount = extractQuestNumber(normalized, "[Cc]ollect"),
        Text = normalized
    }
end

function extractUseFlagsQuest(text)
    local normalized = normalizeWhitespace(text)
    if normalized == "" then
        return nil
    end

    local lower = normalized:lower()
    if not lower:find("use", 1, true) or not lower:find("flag", 1, true) then
        return nil
    end

    return {
        Amount = extractQuestNumber(normalized, "[Uu]se"),
        Text = normalized
    }
end

function extractUseFruitsQuest(text)
    local normalized = normalizeWhitespace(text)
    if normalized == "" then
        return nil
    end

    local lower = normalized:lower()
    if not lower:find("use", 1, true) or not lower:find("fruit", 1, true) then
        return nil
    end

    return {
        Amount = extractQuestNumber(normalized, "[Uu]se"),
        Text = normalized
    }
end

function extractUsePotionsQuest(text)
    local normalized = normalizeWhitespace(text)
    if normalized == "" then
        return nil
    end

    local lower = normalized:lower()
    if not lower:find("use", 1, true) or not lower:find("potion", 1, true) then
        return nil
    end

    local tierText = normalized:match("(Tier%s+[IVX]+)")
        or normalized:match("(Tier%s+%d+)")

    return {
        Amount = extractQuestNumber(normalized, "[Uu]se"),
        Text = normalized,
        TierText = tierText
    }
end

function extractEarnCoinsQuest(text)
    local normalized = normalizeWhitespace(text)
    if normalized == "" then
        return nil
    end
    local lower = normalized:lower()
    if not lower:find("earn", 1, true) or not lower:find("coin", 1, true) then
        return nil
    end
    return {
        Amount = extractQuestNumber(normalized, "[Ee]arn"),
        Text = normalized
    }
end

function extractOpenGiftsQuest(text)
    local normalized = normalizeWhitespace(text)
    if normalized == "" then
        return nil
    end
    local lower = normalized:lower()
    if not lower:find("open", 1, true) or not lower:find("gift", 1, true) then
        return nil
    end
    return {
        Amount = extractQuestNumber(normalized, "[Oo]pen"),
        Text = normalized
    }
end

function extractRollRNGQuest(text)
    local normalized = normalizeWhitespace(text)
    if normalized == "" then
        return nil
    end
    local lower = normalized:lower()
    if not lower:find("roll", 1, true) or not lower:find("rng", 1, true) then
        return nil
    end
    return {
        Amount = extractQuestNumber(normalized, "[Rr]oll"),
        Text = normalized
    }
end

function extractUseBoostsQuest(text)
    local normalized = normalizeWhitespace(text)
    if normalized == "" then
        return nil
    end
    local lower = normalized:lower()
    if not lower:find("use", 1, true) or not lower:find("boost", 1, true) then
        return nil
    end
    return {
        Amount = extractQuestNumber(normalized, "[Uu]se"),
        Text = normalized
    }
end

function extractCollectLootbagsQuest(text)
    local normalized = normalizeWhitespace(text)
    if normalized == "" then
        return nil
    end
    local lower = normalized:lower()
    if not lower:find("collect", 1, true) or not lower:find("lootbag", 1, true) then
        return nil
    end
    return {
        Amount = extractQuestNumber(normalized, "[Cc]ollect"),
        Text = normalized
    }
end

function extractMakeBestPetsGoldQuest(text)
    local normalized = normalizeWhitespace(text)
    if normalized == "" then
        return nil
    end
    local lower = normalized:lower()
    if not lower:find("make", 1, true) or not lower:find("gold", 1, true) then
        return nil
    end
    return {
        Amount = extractQuestNumber(normalized, "[Mm]ake"),
        Text = normalized
    }
end

function extractMakeBestPetsRainbowQuest(text)
    local normalized = normalizeWhitespace(text)
    if normalized == "" then
        return nil
    end
    local lower = normalized:lower()
    if not lower:find("make", 1, true) or not lower:find("rainbow", 1, true) then
        return nil
    end
    return {
        Amount = extractQuestNumber(normalized, "[Mm]ake"),
        Text = normalized
    }
end

function extractLevelUpPetsQuest(text)
    local normalized = normalizeWhitespace(text)
    if normalized == "" then
        return nil
    end
    local lower = normalized:lower()
    if not lower:find("level", 1, true) or not lower:find("pet", 1, true) then
        return nil
    end
    return {
        Amount = extractQuestNumber(normalized, "[Ll]evel"),
        Text = normalized
    }
end

function extractSendPetsToIndexQuest(text)
    local normalized = normalizeWhitespace(text)
    if normalized == "" then
        return nil
    end
    local lower = normalized:lower()
    if not lower:find("send", 1, true) or not lower:find("index", 1, true) then
        return nil
    end
    return {
        Amount = extractQuestNumber(normalized, "[Ss]end"),
        Text = normalized
    }
end

function extractUpgradeEnchantQuest(text)
    local normalized = normalizeWhitespace(text)
    if normalized == "" then
        return nil
    end
    local lower = normalized:lower()
    if not lower:find("upgrade", 1, true) or not lower:find("enchant", 1, true) then
        return nil
    end
    return {
        Amount = extractQuestNumber(normalized, "[Uu]pgrade"),
        Text = normalized
    }
end

function parseShortNumber(text)
    local cleaned = normalizeWhitespace(tostring(text or "")):gsub(",", "")
    cleaned = cleaned:gsub("[^%w%.%-]", "")
    if cleaned == "" then
        return nil
    end

    local numberText, suffix = cleaned:match("^([%d%.%-]+)([%a]+)$")
    if numberText then
        local base = tonumber(numberText)
        local multiplier = NUMBER_SUFFIXES[(suffix or ""):lower()]
        if base and multiplier then
            return base * multiplier
        end
    end

    local plain = tonumber(cleaned)
    if plain then
        return plain
    end

    local fallback = cleaned:match("([%d%.%-]+)")
    return fallback and tonumber(fallback) or nil
end

function getQuestHolder()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    local goalsSide = playerGui and playerGui:FindFirstChild("GoalsSide")
    local frame = goalsSide and goalsSide:FindFirstChild("Frame")
    local quests = frame and frame:FindFirstChild("Quests")
    local gradient = quests and quests:FindFirstChild("QuestsGradient")
    return gradient and gradient:FindFirstChild("QuestsHolder")
end

function autoQuestDebug(message)
    if getgenv().autoQuestConfig.DEBUG then
        print("[Auto Quest] " .. tostring(message))
    end
end

function getVisibleQuestTitles()
    local titles = {}
    local holder = getQuestHolder()
    if not holder then
        return titles
    end

    for _, difficulty in ipairs(QUEST_DIFFICULTIES) do
        local questFrame = holder:FindFirstChild(difficulty)
        if questFrame and questFrame.Visible ~= false then
            local titleText = getLabelText(questFrame:FindFirstChild("Title"))
            if titleText and titleText ~= "" then
                table.insert(titles, string.format("%s: %s", difficulty, titleText))
            end
        end
    end

    return titles
end

local getLatestUnlockedBestArea

function getQuestProgressData(questFrame, expectedTotal)
    if not questFrame then
        return nil
    end

    local fallbackProgress
    local title = questFrame:FindFirstChild("Title")

    for _, child in ipairs(questFrame:GetChildren()) do
        if child ~= title and (child:IsA("TextLabel") or child:IsA("TextButton")) then
            local text = getLabelText(child)
            if text and text ~= "" then
                local currentText, totalText = text:match("([%d,]+)%s*/%s*([%d,]+)")
                if not currentText then
                    currentText, totalText = text:match("([%d,]+)%s+[Oo][Ff]%s+([%d,]+)")
                end

                local current = currentText and tonumber((currentText:gsub(",", ""))) or nil
                local total = totalText and tonumber((totalText:gsub(",", ""))) or nil
                if current and total and total > 0 and current <= total then
                    local progressData = {
                        Current = current,
                        Total = total,
                        Text = text
                    }

                    if expectedTotal and total == expectedTotal then
                        return progressData
                    end

                    if not fallbackProgress or total > fallbackProgress.Total then
                        fallbackProgress = progressData
                    end
                end
            end
        end
    end

    return fallbackProgress
end

function finalizeQuestTask(task, questFrame)
    local progressData = getQuestProgressData(questFrame, task.Amount)
    task.Frame = questFrame
    task.TotalAmount = task.Amount
    task.CurrentAmount = 0
    task.RemainingAmount = task.Amount

    if progressData then
        task.TotalAmount = progressData.Total
        task.CurrentAmount = progressData.Current
        task.RemainingAmount = math.max(progressData.Total - progressData.Current, 0)
        task.ProgressText = progressData.Text
    end

    return task
end

function buildQuestTask(difficulty, questFrame)
    if not questFrame or questFrame.Visible == false then
        return nil
    end

    local titleText = getLabelText(questFrame:FindFirstChild("Title"))
    if not titleText or titleText == "" then
        return nil
    end

    local amount, text = extractHatchQuestAmount(titleText)
    if amount then
        return finalizeQuestTask({
            Type = QUEST_TYPES.HATCH,
            Difficulty = difficulty,
            Amount = amount,
            Text = text
        }, questFrame)
    end

    local breakTask = extractBreakQuestTask(titleText)
    if breakTask then
        return finalizeQuestTask({
            Type = QUEST_TYPES.BREAK,
            Difficulty = difficulty,
            Amount = breakTask.Amount,
            Text = breakTask.Text,
            TargetText = breakTask.TargetText,
            TargetKey = breakTask.TargetKey,
            InBestArea = breakTask.InBestArea
        }, questFrame)
    end

    local earnDiamondsTask = extractEarnDiamondsQuest(titleText)
    if earnDiamondsTask then
        return finalizeQuestTask({
            Type = QUEST_TYPES.EARN_DIAMONDS,
            Difficulty = difficulty,
            Amount = earnDiamondsTask.Amount,
            Text = earnDiamondsTask.Text
        }, questFrame)
    end

    local collectEnchantsTask = extractCollectEnchantsQuest(titleText)
    if collectEnchantsTask then
        return finalizeQuestTask({
            Type = QUEST_TYPES.COLLECT_ENCHANTS,
            Difficulty = difficulty,
            Amount = collectEnchantsTask.Amount,
            Text = collectEnchantsTask.Text
        }, questFrame)
    end

    local collectPotionsTask = extractCollectPotionsQuest(titleText)
    if collectPotionsTask then
        return finalizeQuestTask({
            Type = QUEST_TYPES.COLLECT_POTIONS,
            Difficulty = difficulty,
            Amount = collectPotionsTask.Amount,
            Text = collectPotionsTask.Text
        }, questFrame)
    end

    local useFruitsTask = extractUseFruitsQuest(titleText)
    if useFruitsTask then
        return finalizeQuestTask({
            Type = QUEST_TYPES.USE_FRUITS,
            Difficulty = difficulty,
            Amount = useFruitsTask.Amount,
            Text = useFruitsTask.Text
        }, questFrame)
    end

    local useFlagsTask = extractUseFlagsQuest(titleText)
    if useFlagsTask then
        return finalizeQuestTask({
            Type = QUEST_TYPES.USE_FLAGS,
            Difficulty = difficulty,
            Amount = useFlagsTask.Amount,
            Text = useFlagsTask.Text
        }, questFrame)
    end

    local usePotionsTask = extractUsePotionsQuest(titleText)
    if usePotionsTask then
        return finalizeQuestTask({
            Type = QUEST_TYPES.USE_POTIONS,
            Difficulty = difficulty,
            Amount = usePotionsTask.Amount,
            Text = usePotionsTask.Text,
            TierText = usePotionsTask.TierText
        }, questFrame)
    end

    local earnCoinsTask = extractEarnCoinsQuest(titleText)
    if earnCoinsTask then
        return finalizeQuestTask({
            Type = QUEST_TYPES.EARN_COINS,
            Difficulty = difficulty,
            Amount = earnCoinsTask.Amount,
            Text = earnCoinsTask.Text
        }, questFrame)
    end

    local openGiftsTask = extractOpenGiftsQuest(titleText)
    if openGiftsTask then
        return finalizeQuestTask({
            Type = QUEST_TYPES.OPEN_GIFTS,
            Difficulty = difficulty,
            Amount = openGiftsTask.Amount,
            Text = openGiftsTask.Text
        }, questFrame)
    end

    local rollRNGTask = extractRollRNGQuest(titleText)
    if rollRNGTask then
        return finalizeQuestTask({
            Type = QUEST_TYPES.ROLL_RNG,
            Difficulty = difficulty,
            Amount = rollRNGTask.Amount,
            Text = rollRNGTask.Text
        }, questFrame)
    end

    local useBoostsTask = extractUseBoostsQuest(titleText)
    if useBoostsTask then
        return finalizeQuestTask({
            Type = QUEST_TYPES.USE_BOOSTS,
            Difficulty = difficulty,
            Amount = useBoostsTask.Amount,
            Text = useBoostsTask.Text
        }, questFrame)
    end

    local collectLootbagsTask = extractCollectLootbagsQuest(titleText)
    if collectLootbagsTask then
        return finalizeQuestTask({
            Type = QUEST_TYPES.COLLECT_LOOTBAGS,
            Difficulty = difficulty,
            Amount = collectLootbagsTask.Amount,
            Text = collectLootbagsTask.Text
        }, questFrame)
    end

    local makeGoldTask = extractMakeBestPetsGoldQuest(titleText)
    if makeGoldTask then
        return finalizeQuestTask({
            Type = QUEST_TYPES.MAKE_GOLD,
            Difficulty = difficulty,
            Amount = makeGoldTask.Amount,
            Text = makeGoldTask.Text
        }, questFrame)
    end

    local makeRainbowTask = extractMakeBestPetsRainbowQuest(titleText)
    if makeRainbowTask then
        return finalizeQuestTask({
            Type = QUEST_TYPES.MAKE_RAINBOW,
            Difficulty = difficulty,
            Amount = makeRainbowTask.Amount,
            Text = makeRainbowTask.Text
        }, questFrame)
    end

    local levelUpPetsTask = extractLevelUpPetsQuest(titleText)
    if levelUpPetsTask then
        return finalizeQuestTask({
            Type = QUEST_TYPES.LEVEL_UP_PETS,
            Difficulty = difficulty,
            Amount = levelUpPetsTask.Amount,
            Text = levelUpPetsTask.Text
        }, questFrame)
    end

    local sendToIndexTask = extractSendPetsToIndexQuest(titleText)
    if sendToIndexTask then
        return finalizeQuestTask({
            Type = QUEST_TYPES.SEND_TO_INDEX,
            Difficulty = difficulty,
            Amount = sendToIndexTask.Amount,
            Text = sendToIndexTask.Text
        }, questFrame)
    end

    local upgradeEnchantTask = extractUpgradeEnchantQuest(titleText)
    if upgradeEnchantTask then
        return finalizeQuestTask({
            Type = QUEST_TYPES.UPGRADE_ENCHANT,
            Difficulty = difficulty,
            Amount = upgradeEnchantTask.Amount,
            Text = upgradeEnchantTask.Text
        }, questFrame)
    end

    return nil
end

function getQuestDifficultyPriority(difficulty)
    if difficulty == "Easy" then
        return 1
    end
    if difficulty == "Medium" then
        return 2
    end
    if difficulty == "Hard" then
        return 3
    end
    if difficulty == "Extreme" then
        return 4
    end
    return 5
end

function getQuestTaskPriority(task)
    if not task then
        return math.huge
    end

    if task.Type == QUEST_TYPES.BREAK and task.InBestArea then
        return 1
    end
    if task.Type == QUEST_TYPES.HATCH then
        return 2
    end
    if task.Type == QUEST_TYPES.EARN_DIAMONDS then
        return 3
    end
    if task.Type == QUEST_TYPES.COLLECT_POTIONS then
        return 4
    end
    if task.Type == QUEST_TYPES.COLLECT_ENCHANTS then
        return 5
    end
    if task.Type == QUEST_TYPES.USE_FRUITS then
        return 6
    end
    if task.Type == QUEST_TYPES.USE_FLAGS then
        return 7
    end
    if task.Type == QUEST_TYPES.USE_POTIONS then
        return 8
    end
    if task.Type == QUEST_TYPES.EARN_COINS then
        return 9
    end
    if task.Type == QUEST_TYPES.COLLECT_LOOTBAGS then
        return 10
    end
    if task.Type == QUEST_TYPES.OPEN_GIFTS then
        return 11
    end
    if task.Type == QUEST_TYPES.ROLL_RNG then
        return 12
    end
    if task.Type == QUEST_TYPES.USE_BOOSTS then
        return 13
    end
    if task.Type == QUEST_TYPES.BREAK then
        return 14
    end
    if task.Type == QUEST_TYPES.MAKE_GOLD then
        return 15
    end
    if task.Type == QUEST_TYPES.MAKE_RAINBOW then
        return 16
    end
    if task.Type == QUEST_TYPES.LEVEL_UP_PETS then
        return 17
    end
    if task.Type == QUEST_TYPES.SEND_TO_INDEX then
        return 18
    end
    if task.Type == QUEST_TYPES.UPGRADE_ENCHANT then
        return 19
    end
    return 20
end

function getQuestTaskSignature(task)
    if not task then
        return ""
    end

    return table.concat({
        tostring(task.Type or ""),
        tostring(task.Difficulty or ""),
        tostring(task.Text or ""),
        tostring(task.TargetKey or ""),
        tostring(task.InBestArea == true)
    }, "|")
end

function formatQuestTaskStatus(task)
    if not task then
        return ""
    end

    if type(task.RemainingAmount) == "number" and type(task.TotalAmount) == "number" then
        return string.format(" (%d left)", math.max(task.RemainingAmount, 0))
    end

    return ""
end

function getParsedQuestTasks()
    local holder = getQuestHolder()
    if not holder then
        return {}, {}, {}
    end

    local tasks = {}
    local visibleTitles = {}
    local unsupportedTitles = {}

    for _, difficulty in ipairs(QUEST_DIFFICULTIES) do
        local questFrame = holder:FindFirstChild(difficulty)
        if questFrame and questFrame.Visible ~= false then
            local titleText = getLabelText(questFrame:FindFirstChild("Title"))
            local visibleTitle
            if titleText and titleText ~= "" then
                visibleTitle = string.format("%s: %s", difficulty, titleText)
                table.insert(visibleTitles, visibleTitle)
            end

            local questTask = buildQuestTask(difficulty, questFrame)
            if questTask then
                table.insert(tasks, questTask)
            elseif visibleTitle then
                table.insert(unsupportedTitles, visibleTitle)
            end
        end
    end

    return tasks, visibleTitles, unsupportedTitles
end

function getActiveQuestTask()
    local tasks, visibleTitles, unsupportedTitles = getParsedQuestTasks()
    if #tasks == 0 then
        return nil, tasks, visibleTitles, unsupportedTitles
    end

    table.sort(tasks, function(a, b)
        local priorityA = getQuestTaskPriority(a)
        local priorityB = getQuestTaskPriority(b)
        if priorityA ~= priorityB then
            return priorityA < priorityB
        end

        local remainingA = tonumber(a.RemainingAmount) or tonumber(a.Amount) or math.huge
        local remainingB = tonumber(b.RemainingAmount) or tonumber(b.Amount) or math.huge
        if remainingA ~= remainingB then
            return remainingA < remainingB
        end

        local difficultyA = getQuestDifficultyPriority(a.Difficulty)
        local difficultyB = getQuestDifficultyPriority(b.Difficulty)
        if difficultyA ~= difficultyB then
            return difficultyA < difficultyB
        end

        return tostring(a.Text or "") < tostring(b.Text or "")
    end)

    return tasks[1], tasks, visibleTitles, unsupportedTitles
end

function getSaveData()
    local clientSave = Library:FindFirstChild("Client") and Library.Client:FindFirstChild("Save")
    if clientSave then
        local ok, saveData = pcall(function()
            return require(clientSave).Get()
        end)
        if ok and type(saveData) == "table" then
            return saveData
        end
    end

    local ok, saveData = pcall(function()
        return require(Library).Save.Get()
    end)
    if ok and type(saveData) == "table" then
        return saveData
    end
    return nil
end

function getInventoryBucket(bucketName)
    local saveData = getSaveData()
    if not saveData then
        return nil
    end

    local inventory = saveData.Inventory
    if type(inventory) == "table" and type(inventory[bucketName]) == "table" then
        return inventory[bucketName]
    end

    if type(saveData[bucketName]) == "table" then
        return saveData[bucketName]
    end

    return nil
end

function collectInventoryItems(bucketNames)
    local items = {}
    for _, bucketName in ipairs(bucketNames) do
        local bucket = getInventoryBucket(bucketName)
        if type(bucket) == "table" then
            for itemUid, itemData in pairs(bucket) do
                if type(itemData) == "table" then
                    table.insert(items, {
                        Uid = itemUid,
                        Data = itemData,
                        Bucket = bucketName
                    })
                end
            end
        end
    end
    return items
end

function getInventoryItemName(itemData)
    if type(itemData) ~= "table" then
        return ""
    end

    return tostring(itemData.id or itemData.ID or itemData.name or itemData.Name or "")
end

function getInventoryItemCount(itemData)
    if type(itemData) ~= "table" then
        return 1
    end

    return tonumber(itemData._am or itemData.am or itemData.Amount or itemData.amount or itemData.Count or itemData.count) or 1
end

function normalizeQuestTierText(tierText)
    return collapseKey((tierText or ""):gsub("%s+", ""))
end

function findInventoryConsumable(bucketNames, matcher)
    for _, item in ipairs(collectInventoryItems(bucketNames)) do
        if matcher(item) then
            return item
        end
    end

    return nil
end

function requireClientModule(moduleName)
    local clientFolder = Library and Library:FindFirstChild("Client")
    local moduleScript = clientFolder and clientFolder:FindFirstChild(moduleName)
    if not moduleScript then
        return nil
    end

    local ok, moduleValue = pcall(require, moduleScript)
    if ok then
        return moduleValue
    end

    return nil
end

function tryInvokeConsumableMethod(target, methodName, argumentsList)
    if type(target) ~= "table" or type(target[methodName]) ~= "function" then
        return false
    end

    for _, arguments in ipairs(argumentsList) do
        local ok, result = pcall(function()
            return target[methodName](unpack(arguments))
        end)
        if not ok then
            ok, result = pcall(function()
                return target[methodName](target, unpack(arguments))
            end)
        end
        if ok and result ~= false then
            return true
        end
    end

    return false
end

function tryUseConsumableRemote(remoteName, argumentsList)
    local remote = Network:FindFirstChild(remoteName)
    if not remote then
        return false
    end

    for _, arguments in ipairs(argumentsList) do
        local ok, result
        if remote:IsA("RemoteFunction") then
            ok, result = pcall(function()
                return remote:InvokeServer(unpack(arguments))
            end)
        else
            ok, result = pcall(function()
                return remote:FireServer(unpack(arguments))
            end)
        end

        if ok and result ~= false then
            return true
        end
    end

    return false
end

function tryUseInventoryConsumable(item, category)
    if not item then
        return false
    end

    local itemUid = item.Uid
    local itemName = getInventoryItemName(item.Data)
    local argumentsList = {
        { itemUid },
        { itemUid, 1 },
        { tostring(itemUid) },
        { tostring(itemUid), 1 },
        { itemName },
        { itemName, 1 }
    }

    local moduleCandidates = {}
    if category == "flag" then
        moduleCandidates = {
            { Name = "FlagCmds", Methods = { "Consume", "Use", "UseFlag" } },
            { Name = "ItemCmds", Methods = { "Consume", "Use", "UseItem" } }
        }
    else
        moduleCandidates = {
            { Name = "PotionCmds", Methods = { "Consume", "Use", "UsePotion" } },
            { Name = "ItemCmds", Methods = { "Consume", "Use", "UseItem" } }
        }
    end

    for _, candidate in ipairs(moduleCandidates) do
        local moduleValue = requireClientModule(candidate.Name)
        if moduleValue then
            for _, methodName in ipairs(candidate.Methods) do
                if tryInvokeConsumableMethod(moduleValue, methodName, argumentsList) then
                    return true
                end
            end
        end
    end

    local remoteCandidates = category == "flag"
        and { "Flags_Consume", "Flag_Consume", "Flags_Use", "Flag_Use", "Items_Consume", "Item_Use" }
        or { "Potions_Consume", "Potion_Consume", "Potions_Use", "Potion_Use", "Items_Consume", "Item_Use" }

    for _, remoteName in ipairs(remoteCandidates) do
        if tryUseConsumableRemote(remoteName, argumentsList) then
            return true
        end
    end

    return false
end

function findFlagConsumable(preferredName)
    local normalizedPreferredName = normalizeWhitespace(preferredName)

    if normalizedPreferredName and normalizedPreferredName ~= "" then
        local matchedFlag = findInventoryConsumable({ "Flags", "Flag" }, function(item)
            return getInventoryItemCount(item.Data) > 0
                and normalizeWhitespace(getInventoryItemName(item.Data)) == normalizedPreferredName
        end)

        if matchedFlag then
            return matchedFlag
        end
    end

    return findInventoryConsumable({ "Flags", "Flag" }, function(item)
        return getInventoryItemCount(item.Data) > 0 and getInventoryItemName(item.Data) ~= ""
    end)
end

function findPotionConsumable(tierText)
    local normalizedTier = normalizeQuestTierText(tierText)

    return findInventoryConsumable({ "Potions", "Potion" }, function(item)
        if getInventoryItemCount(item.Data) <= 0 then
            return false
        end

        if normalizedTier == "" then
            return getInventoryItemName(item.Data) ~= ""
        end

        local itemKey = collapseKey(getInventoryItemName(item.Data))
        return itemKey:find(normalizedTier, 1, true) ~= nil
    end)
end

local GENERIC_CONSUMABLE_BUCKETS = {
    "Items",
    "Item",
    "Misc",
    "Boosts",
    "Boost",
    "Consumables",
    "Consumable",
    "Lootboxes",
    "Lootbox",
    "Boxes",
    "Events",
    "Event"
}
local UTILITY_ITEM_ACTIONS = {
    ["Squeaky Toy"] = { Remote = "SqueakyToy_Consume", Mode = "invoke_noargs" },
    ["Toy Ball"] = { Remote = "ToyBall_Consume", Mode = "invoke_noargs" },
    ["Toy Bone"] = { Remote = "ToyBone_Consume", Mode = "invoke_noargs" }
}
local FRUIT_ACTIONS = {
    ["Rainbow Fruit"] = { Remote = "Fruits: Consume", Mode = "fire_uid_amount", BucketNames = { "Fruit", "Fruits" }, ItemNames = { "Rainbow Fruit" } },
    ["Banana"] = { Remote = "Fruits: Consume", Mode = "fire_uid_amount", BucketNames = { "Fruit", "Fruits" }, ItemNames = { "Banana" } },
    ["Apple"] = { Remote = "Fruits: Consume", Mode = "fire_uid_amount", BucketNames = { "Fruit", "Fruits" }, ItemNames = { "Apple" } },
    ["Orange"] = { Remote = "Fruits: Consume", Mode = "fire_uid_amount", BucketNames = { "Fruit", "Fruits" }, ItemNames = { "Orange" } },
    ["Pineapple"] = { Remote = "Fruits: Consume", Mode = "fire_uid_amount", BucketNames = { "Fruit", "Fruits" }, ItemNames = { "Pineapple" } },
    ["Watermelon"] = { Remote = "Fruits: Consume", Mode = "fire_uid_amount", BucketNames = { "Fruit", "Fruits" }, ItemNames = { "Watermelon" } }
}
local BOOST_ITEM_ACTIONS = {
    ["Lucky Block"] = { Remote = "MiniLuckyBlock_Consume", Mode = "invoke_uid", BucketNames = GENERIC_CONSUMABLE_BUCKETS, ItemNames = { "Lucky Block", "Mini Lucky Block" } },
    ["Giant Coin Jar"] = { Remote = "CoinJar_Spawn", Mode = "invoke_uid", BucketNames = GENERIC_CONSUMABLE_BUCKETS, ItemNames = { "Giant Coin Jar" } },
    ["Party Box"] = { Remote = "PartyBox_Consume", Mode = "invoke_uid", BucketNames = GENERIC_CONSUMABLE_BUCKETS, ItemNames = { "Party Box" } },
    ["Mini Pinata"] = { Remote = "MiniPinata_Consume", Mode = "invoke_uid", BucketNames = GENERIC_CONSUMABLE_BUCKETS, ItemNames = { "Mini Pinata" } },
    ["TNT Crate"] = { Remote = "TNT_Crate_Consume", Mode = "invoke_noargs" },
    ["Comet"] = { Remote = "Comet_Spawn", Mode = "invoke_uid", BucketNames = GENERIC_CONSUMABLE_BUCKETS, ItemNames = { "Comet" } },
    ["Magic Coin Jar"] = { Remote = "CoinJar_Spawn", Mode = "invoke_uid", BucketNames = GENERIC_CONSUMABLE_BUCKETS, ItemNames = { "Magic Coin Jar" } },
    ["Basic Coin Jar"] = { Remote = "CoinJar_Spawn", Mode = "invoke_uid", BucketNames = GENERIC_CONSUMABLE_BUCKETS, ItemNames = { "Basic Coin Jar" } },
    ["TNT"] = { Remote = "TNT_Consume", Mode = "invoke_noargs" }
}

function inventoryItemMatchesNames(itemData, names)
    local itemKey = collapseKey(getInventoryItemName(itemData))
    if itemKey == "" then
        return false
    end

    for _, name in ipairs(names or {}) do
        if itemKey == collapseKey(name) then
            return true
        end
    end

    return false
end

function findInventoryConsumableByNames(bucketNames, names)
    return findInventoryConsumable(bucketNames, function(item)
        return getInventoryItemCount(item.Data) > 0 and inventoryItemMatchesNames(item.Data, names)
    end)
end

function invokeNamedRemote(remoteName, mode, amount, uid)
    local remote = Network:FindFirstChild(remoteName)
    if not remote then
        warn("[Items] Missing remote: " .. tostring(remoteName))
        return false
    end

    local count = math.max(tonumber(amount) or 1, 1)
    if mode == "fire_uid_amount" then
        if not uid then
            return false
        end

        return pcall(function()
            remote:FireServer(uid, count)
        end)
    end

    if mode == "invoke_uid_amount" or mode == "invoke_uid_amount_nil" then
        if not uid or not remote:IsA("RemoteFunction") then
            return false
        end
        local ok, result = pcall(function()
            if mode == "invoke_uid_amount_nil" then
                return remote:InvokeServer(uid, count, nil)
            end
            return remote:InvokeServer(uid, count)
        end)
        return ok and result ~= false
    end

    local usedAny = false
    for _ = 1, count do
        local ok, result
        if mode == "invoke_uid" then
            if not uid then
                return usedAny
            end
            ok, result = pcall(function()
                return remote:InvokeServer(uid)
            end)
        elseif mode == "invoke_noargs" then
            ok, result = pcall(function()
                return remote:InvokeServer()
            end)
        elseif mode == "fire_uid" then
            if not uid then
                return usedAny
            end
            ok, result = pcall(function()
                remote:FireServer(uid)
            end)
        else
            ok, result = pcall(function()
                remote:FireServer()
            end)
        end

        if not ok or result == false then
            return usedAny
        end

        usedAny = true
        task.wait(0.05)
    end

    return usedAny
end

function getNamedConsumableUid(definition)
    if not definition then
        return nil
    end

    local item = findInventoryConsumableByNames(definition.BucketNames or GENERIC_CONSUMABLE_BUCKETS, definition.ItemNames or {})
    if item and item.Uid then
        return tostring(item.Uid)
    end

    return nil
end

function resolveInventoryAction(itemName, category)
    if category == "utility" and UTILITY_ITEM_ACTIONS[itemName] then
        return UTILITY_ITEM_ACTIONS[itemName]
    end
    if category == "fruit" and FRUIT_ACTIONS[itemName] then
        return FRUIT_ACTIONS[itemName]
    end
    if category == "boost" and BOOST_ITEM_ACTIONS[itemName] then
        return BOOST_ITEM_ACTIONS[itemName]
    end

    local buckets = GENERIC_CONSUMABLE_BUCKETS
    if category == "fruit" then
        buckets = { "Fruit", "Fruits" }
    elseif category == "utility" then
        buckets = { "Items", "Item", "Misc", "MiscItems", "Consumables", "Consumable" }
    elseif category == "boost" then
        buckets = { "Boosts", "Boost", "Items", "Item", "Misc", "MiscItems", "Consumables", "Consumable", "Lootboxes", "Lootbox", "Boxes" }
    end

    local item = findInventoryConsumableByNames(buckets, { itemName })
    if not item or not item.Uid then
        return nil
    end

    local candidates = category == "fruit"
        and {
            { Remote = "Fruits: Consume", Mode = "fire_uid_amount" },
            { Remote = "Consumables_Consume", Mode = "invoke_uid_amount" }
        }
        or {
            { Remote = "Consumables_Consume", Mode = "invoke_uid_amount" },
            { Remote = "MiscItems_Consume", Mode = "invoke_uid" },
            { Remote = "Item_Use", Mode = "invoke_uid" },
            { Remote = "Items_Consume", Mode = "invoke_uid" },
            { Remote = "GiftBag_Open", Mode = "invoke_uid" },
            { Remote = "KX_Release", Mode = "invoke_uid_amount_nil" }
        }

    for _, candidate in ipairs(candidates) do
        if Network:FindFirstChild(candidate.Remote) then
            return {
                Remote = candidate.Remote,
                Mode = candidate.Mode,
                ResolvedUid = tostring(item.Uid)
            }
        end
    end

    return nil
end

function tryUseInventoryItem(itemName, amount, category)
    local definition = resolveInventoryAction(itemName, category)
    if not definition then
        notifyFlow("Unsupported Item", tostring(itemName) .. " has no supported action route.", 3)
        return false
    end

    local uid = definition.ResolvedUid
    if not uid and (definition.Mode == "invoke_uid" or definition.Mode == "invoke_uid_amount" or definition.Mode == "invoke_uid_amount_nil" or definition.Mode == "fire_uid" or definition.Mode == "fire_uid_amount") then
        uid = getNamedConsumableUid(definition)
        if not uid then
            warn("[Items] Missing uid for " .. tostring(itemName))
            return false
        end
    end

    return invokeNamedRemote(definition.Remote, definition.Mode, amount, uid)
end

function executeUtilityItemAction(itemName, amount)
    return tryUseInventoryItem(itemName, amount, "utility")
end

function executeFruitAction(fruitName, amount)
    return tryUseInventoryItem(fruitName, amount, "fruit")
end

function executeBoostAction(boostName, amount)
    return tryUseInventoryItem(boostName, amount, "boost")
end

function executeFlagAction(flagName, amount, isRunning)
    local zoneInfo = getSelectedAutoFlagZoneInfo()
    if not zoneInfo then
        warn("[Flags] No best area found.")
        return false
    end

    local usedAny = false
    for _ = 1, math.max(tonumber(amount) or 1, 1) do
        if isRunning and not isRunning() then
            break
        end

        if not useFlagInBreakableZone(flagName, zoneInfo, isRunning) then
            return usedAny
        end

        usedAny = true
        task.wait(0.1)
    end

    return usedAny
end

function redeemFreeGift(giftIndex)
    local redeemGift = Network:FindFirstChild("Redeem Free Gift")
    if not redeemGift or not redeemGift:IsA("RemoteFunction") then
        warn("[Gifts] Redeem Free Gift remote was not found.")
        return false
    end

    local rewardIndex = math.max(tonumber(giftIndex) or 1, 1)
    local ok, result = pcall(function()
        return redeemGift:InvokeServer(rewardIndex)
    end)

    if not ok then
        warn("[Gifts] Failed to redeem gift " .. tostring(rewardIndex) .. ": " .. tostring(result))
        return false
    end

    return result ~= false
end

function claimFreeGifts()
    local claimedAny = false
    local values = #giftRewardValues > 0 and giftRewardValues or {}
    if #values == 0 then
        for i = 1, 12 do
            table.insert(values, tostring(i))
        end
    end

    for _, giftIndex in ipairs(values) do
        if redeemFreeGift(giftIndex) then
            claimedAny = true
        end
        task.wait(0.05)
    end

    return claimedAny
end

function countInventoryPotions(tierText)
    local total = 0
    local normalizedTier = normalizeQuestTierText(tierText)
    for _, item in ipairs(collectInventoryItems({ "Potions", "Potion" })) do
        if normalizedTier == "" then
            total = total + getInventoryItemCount(item.Data)
        else
            local itemKey = collapseKey(getInventoryItemName(item.Data))
            if itemKey:find(normalizedTier, 1, true) then
                total = total + getInventoryItemCount(item.Data)
            end
        end
    end
    return total
end

function parseZoneLabel(rawName)
    local zoneNumber, zoneName = tostring(rawName):match("^(%d+)%s*|%s*(.+)$")
    if zoneNumber and zoneName then
        return tonumber(zoneNumber), trim(zoneName)
    end
    return nil, nil
end

function getAvailableZoneEntries()
    local maps = getCurrentMaps()
    if #maps == 0 then
        return {}
    end

    local entries = {}
    for _, mapEntry in ipairs(maps) do
        for _, zonePath in ipairs(mapEntry.Path:GetChildren()) do
            local zoneNumber, zoneName = parseZoneLabel(zonePath.Name)
            if zoneNumber and zoneName and zonePath:FindFirstChild("PERSISTENT") then
                table.insert(entries, {
                    Number = zoneNumber,
                    Name = zoneName,
                    FullName = zonePath.Name,
                    Path = zonePath,
                    World = mapEntry.Name,
                    Source = "Manual"
                })
            end
        end
    end

    table.sort(entries, function(a, b)
        if a.World ~= b.World then
            return tostring(a.World) < tostring(b.World)
        elseif a.Number == b.Number then
            return a.Name < b.Name
        end
        return a.Number < b.Number
    end)

    return entries
end

function findAvailableZoneEntryByFullName(fullName)
    for _, entry in ipairs(getAvailableZoneEntries()) do
        if entry.FullName == fullName then
            return entry
        end
    end

    return nil
end

function findAvailableZoneEntryByName(zoneName)
    local normalizedTarget = normalizeWhitespace(zoneName)
    for _, entry in ipairs(getAvailableZoneEntries()) do
        if normalizeWhitespace(entry.Name) == normalizedTarget then
            return entry
        end
    end

    return nil
end

function isZoneOwnedByInteract(zonePath)
    if not zonePath then
        return false
    end
    local interact = zonePath:FindFirstChild("INTERACT")
    if not interact then
        return false
    end

    local gate = interact:FindFirstChild("Gate", true)
    if not gate then
        return true
    end

    if gate:IsA("BasePart") then
        if gate.Transparency >= 0.9 or not gate.CanCollide then
            return true
        end
    end

    return false
end

function getOwnedZoneEntries()
    local entries = {}

    for _, entry in ipairs(getAvailableZoneEntries()) do
        if isZoneEntryUnlocked(entry) then
            table.insert(entries, entry)
        end
    end

    return entries
end

function refreshBreakableFarmZoneList()
    table.clear(breakableFarmZoneValues)
    table.insert(breakableFarmZoneValues, BREAKABLE_FARM_RANDOM_ZONE)

    for _, entry in ipairs(getOwnedZoneEntries()) do
        table.insert(breakableFarmZoneValues, entry.FullName)
    end

    if #breakableFarmZoneValues == 1 then
        table.insert(breakableFarmZoneValues, "No zones found")
    end

    if not selectedBreakableFarmZone or not table.find(breakableFarmZoneValues, selectedBreakableFarmZone) then
        selectedBreakableFarmZone = breakableFarmZoneValues[1]
    end

    getgenv().breakableFarmConfig.ZONE = selectedBreakableFarmZone
end

function getSelectedBreakableFarmZoneInfo()
    if selectedBreakableFarmMethod == "Best Area" then
        return getLatestUnlockedBestArea()
    end

    local entries = getOwnedZoneEntries()
    if selectedBreakableFarmZone == BREAKABLE_FARM_RANDOM_ZONE then
        if #entries == 0 then
            return nil
        end
        return entries[BREAKABLE_RANDOM:NextInteger(1, #entries)]
    end

    for _, entry in ipairs(entries) do
        if entry.FullName == selectedBreakableFarmZone then
            return entry
        end
    end

    return nil
end

function refreshAutoFlagZoneList()
    table.clear(autoFlagZoneValues)
    table.insert(autoFlagZoneValues, AUTO_FLAG_BEST_AREA)

    for _, entry in ipairs(getOwnedZoneEntries()) do
        table.insert(autoFlagZoneValues, entry.FullName)
    end

    if not selectedAutoFlagZone or not table.find(autoFlagZoneValues, selectedAutoFlagZone) then
        selectedAutoFlagZone = autoFlagZoneValues[1]
    end

    getgenv().autoFlagsConfig.ZONE = selectedAutoFlagZone
end

function getSelectedAutoFlagZoneInfo()
    if selectedAutoFlagZone == AUTO_FLAG_BEST_AREA then
        return getLatestUnlockedBestArea()
    end

    for _, entry in ipairs(getOwnedZoneEntries()) do
        if entry.FullName == selectedAutoFlagZone then
            return entry
        end
    end

    return nil
end

function addUniqueValue(target, added, value)
    local normalized = normalizeWhitespace(value)
    if normalized ~= "" and not added[normalized] then
        added[normalized] = true
        table.insert(target, normalized)
    end
end

function addInventoryNames(target, added, bucketNames, matcher)
    for _, item in ipairs(collectInventoryItems(bucketNames)) do
        local itemName = normalizeWhitespace(getInventoryItemName(item.Data))
        if getInventoryItemCount(item.Data) > 0 and itemName ~= "" and (not matcher or matcher(itemName)) then
            addUniqueValue(target, added, itemName)
        end
    end
end

function addDirectoryNames(target, added, folderName, matcher, limit)
    for _, entry in ipairs(discoverDirectoryEntries(folderName, limit)) do
        if not matcher or matcher(entry.Name, entry.Path) then
            addUniqueValue(target, added, entry.Name)
        end
    end
end

function refreshAutoFlagNameList()
    local oldSelection = selectedAutoFlagName
    table.clear(autoFlagNameValues)

    local added = {}
    for _, value in ipairs({ "Fortune Flag", "Diamonds Flag", "Hasty Flag", "Coins Flag", "Magnet Flag", "Strength Flag" }) do
        addUniqueValue(autoFlagNameValues, added, value)
    end

    addDirectoryNames(autoFlagNameValues, added, "ZoneFlags", nil, 80)
    addInventoryNames(autoFlagNameValues, added, { "Flags", "Flag" })

    table.sort(autoFlagNameValues)

    if oldSelection and table.find(autoFlagNameValues, oldSelection) then
        selectedAutoFlagName = oldSelection
    else
        selectedAutoFlagName = autoFlagNameValues[1]
    end

    getgenv().autoFlagsConfig.FLAG = selectedAutoFlagName
end

function refreshUtilityItemList()
    local oldSelection = selectedUtilityItemName
    table.clear(utilityItemValues)

    local added = {}
    for name in pairs(UTILITY_ITEM_ACTIONS) do
        addUniqueValue(utilityItemValues, added, name)
    end

    addInventoryNames(utilityItemValues, added, { "Items", "Item", "Misc", "MiscItems", "Consumables", "Consumable" }, function(name)
        return getgenv().pet99DiscoveryConfig.INCLUDE_UNSUPPORTED_ITEMS or resolveInventoryAction(name, "utility") ~= nil
    end)

    table.sort(utilityItemValues)

    if oldSelection and table.find(utilityItemValues, oldSelection) then
        selectedUtilityItemName = oldSelection
    else
        selectedUtilityItemName = utilityItemValues[1]
    end

    getgenv().utilityItemsConfig.ITEM = selectedUtilityItemName
end

function refreshConsumableFruitChoiceList()
    local oldSelection = selectedConsumableFruitName
    table.clear(consumableFruitChoiceValues)

    local added = {}
    for name in pairs(FRUIT_ACTIONS) do
        addUniqueValue(consumableFruitChoiceValues, added, name)
    end

    addDirectoryNames(consumableFruitChoiceValues, added, "Fruits", isSelectableFruitName, 80)
    addInventoryNames(consumableFruitChoiceValues, added, { "Fruit", "Fruits" }, isSelectableFruitName)

    table.sort(consumableFruitChoiceValues)

    if oldSelection and table.find(consumableFruitChoiceValues, oldSelection) then
        selectedConsumableFruitName = oldSelection
    else
        selectedConsumableFruitName = consumableFruitChoiceValues[1]
    end

    getgenv().fruitConsumeConfig.FRUIT = selectedConsumableFruitName
end

function refreshBoostItemList()
    local oldSelection = selectedBoostItemName
    table.clear(boostItemValues)

    local added = {}
    for name in pairs(BOOST_ITEM_ACTIONS) do
        addUniqueValue(boostItemValues, added, name)
    end

    addDirectoryNames(boostItemValues, added, "MiscItems", function(name, path)
        local fullName = path and path:GetFullName() or ""
        return fullName:find("Boosts", 1, true) ~= nil
            or fullName:find("Event", 1, true) ~= nil
            or getgenv().pet99DiscoveryConfig.INCLUDE_UNSUPPORTED_ITEMS
    end, 180)
    addInventoryNames(boostItemValues, added, GENERIC_CONSUMABLE_BUCKETS, function(name)
        return getgenv().pet99DiscoveryConfig.INCLUDE_UNSUPPORTED_ITEMS or resolveInventoryAction(name, "boost") ~= nil
    end)

    table.sort(boostItemValues)

    if oldSelection and table.find(boostItemValues, oldSelection) then
        selectedBoostItemName = oldSelection
    else
        selectedBoostItemName = boostItemValues[1]
    end

    getgenv().boostItemsConfig.ITEM = selectedBoostItemName
end

function isSelectableFruitName(fruitName)
    local fruitKey = collapseKey(fruitName)
    if fruitKey == "" then
        return false
    end

    if fruitKey == "candycane" then
        return false
    end

    return not fruitKey:find("gift", 1, true)
        and not fruitKey:find("bundle", 1, true)
end

function isSelectableBundleName(bundleName)
    local bundleKey = collapseKey(bundleName)
    if bundleKey == "" then
        return false
    end

    return bundleKey:find("bundle", 1, true) ~= nil
        and bundleKey:find("gift", 1, true) == nil
end

function refreshAutoFruitList()
    table.clear(autoFruitValues)
    table.insert(autoFruitValues, AUTO_FRUIT_ALL)

    local added = {}
    local fruitInventory = getInventoryBucket("Fruit") or {}

    for _, itemData in pairs(fruitInventory) do
        local fruitName = normalizeWhitespace(getInventoryItemName(itemData))
        if isSelectableFruitName(fruitName) and not added[fruitName] then
            added[fruitName] = true
            table.insert(autoFruitValues, fruitName)
        end
    end

    table.sort(autoFruitValues, function(a, b)
        if a == AUTO_FRUIT_ALL then
            return true
        end
        if b == AUTO_FRUIT_ALL then
            return false
        end
        return a < b
    end)

    if not selectedAutoFruit or not table.find(autoFruitValues, selectedAutoFruit) then
        selectedAutoFruit = autoFruitValues[1]
    end

    getgenv().autoFruitsConfig.FRUIT = selectedAutoFruit
end

function refreshAutoBundleList()
    table.clear(autoBundleValues)
    table.insert(autoBundleValues, AUTO_BUNDLE_ALL)

    local added = {}
    local fruitInventory = getInventoryBucket("Fruit") or {}

    for _, itemData in pairs(fruitInventory) do
        local bundleName = normalizeWhitespace(getInventoryItemName(itemData))
        if isSelectableBundleName(bundleName) and not added[bundleName] then
            added[bundleName] = true
            table.insert(autoBundleValues, bundleName)
        end
    end

    table.sort(autoBundleValues, function(a, b)
        if a == AUTO_BUNDLE_ALL then
            return true
        end
        if b == AUTO_BUNDLE_ALL then
            return false
        end
        return a < b
    end)

    if not selectedAutoBundle or not table.find(autoBundleValues, selectedAutoBundle) then
        selectedAutoBundle = autoBundleValues[1]
    end

    getgenv().autoBundlesConfig.BUNDLE = selectedAutoBundle
end

function waitForBreakableZoneReady(zonePath, isRunning)
    if not zonePath then
        return false
    end

    if not waitForZoneInteract(zonePath, isRunning) then
        return false
    end

    local breakZones = zonePath.INTERACT and zonePath.INTERACT:FindFirstChild("BREAK_ZONES")
    local deadline = os.clock() + 5

    while isRunning == nil or isRunning() do
        if breakZones and #breakZones:GetChildren() > 0 then
            return true
        end

        if os.clock() >= deadline then
            break
        end

        task.wait(0.1)
        breakZones = zonePath.INTERACT and zonePath.INTERACT:FindFirstChild("BREAK_ZONES")
    end

    return breakZones ~= nil and #breakZones:GetChildren() > 0
end

function moveToBreakableZone(zoneInfo, isRunning)
    if not zoneInfo or not zoneInfo.Path or not zoneInfo.Path:FindFirstChild("PERSISTENT") then
        return false
    end

    if not teleportToBestAreaWithFallbacks(zoneInfo, isRunning) then
        return false
    end

    if not waitForBreakableZoneReady(zoneInfo.Path, isRunning) then
        return false
    end

    local breakZone = getClosestBreakZone(zoneInfo.Path)
    if breakZone then
        getHumanoidRootPart().CFrame = breakZone.CFrame + Vector3.new(0, 10, 0)
    end

    return true
end

function consumeFlexibleFlagItem(flagItem, amount)
    if not flagItem then
        return false
    end

    local flagName = normalizeWhitespace(getInventoryItemName(flagItem.Data))
    local flagUid = tostring(flagItem.Uid or "")
    if flagName == "" or flagUid == "" then
        return false
    end

    local commands = requireClientModule("FlexibleFlagCmds")
    if type(commands) ~= "table" or type(commands.Consume) ~= "function" then
        warn("[Flags] FlexibleFlagCmds.Consume is unavailable for " .. flagName)
        return false
    end

    local count = math.max(math.floor(tonumber(amount) or 1), 1)
    local ok, result = pcall(function()
        return commands.Consume(flagName, flagUid, count)
    end)
    if ok and result ~= false then
        print(string.format("[Flags] Used %s x%d", flagName, count))
        return true
    end
    warn("[Flags] Flag consume failed for " .. flagName .. ": " .. tostring(result))
    return false
end

function useFlagInBreakableZone(preferredFlagName, zoneInfo, isRunning)
    local flagItem = findFlagConsumable(preferredFlagName)
    if not flagItem then
        warn("[Flags] No usable flag found in inventory.")
        return false
    end

    if not moveToBreakableZone(zoneInfo, isRunning) then
        warn("[Flags] Failed to reach a breakable zone for flag placement.")
        return false
    end

    return consumeFlexibleFlagItem(flagItem, 1)
end

function getUnusedFlagQuestZone(usedZones)
    local entries = getOwnedZoneEntries()
    table.sort(entries, function(a, b)
        return a.Number > b.Number
    end)

    for _, entry in ipairs(entries) do
        if entry.FullName and not usedZones[entry.FullName] then
            return entry
        end
    end

    return nil
end

function parseWorkspaceEggName(rawName)
    local eggNumber, eggName = tostring(rawName):match("^(%d+)%s*%-%s*(.+)$")
    if eggNumber and eggName then
        return tonumber(eggNumber), trim(eggName)
    end

    eggNumber, eggName = tostring(rawName):match("^(%d+)%s*|%s*(.+)$")
    if eggNumber and eggName then
        return tonumber(eggNumber), trim(eggName)
    end

    return nil, nil
end

function isEggLocked(eggInstance)
    if not eggInstance then
        return true
    end
    return eggInstance:FindFirstChild("EggLock", true) ~= nil
end

function resolveEggCFrame(eggInstance)
    if not eggInstance then
        return nil
    end

    if eggInstance:IsA("BasePart") then
        return eggInstance.CFrame
    end

    local interact = eggInstance:FindFirstChild("INTERACT", true)
    if interact and interact:IsA("BasePart") then
        return interact.CFrame
    end

    local namedPart = eggInstance:FindFirstChild("Pad", true)
        or eggInstance:FindFirstChild("Root", true)
        or eggInstance:FindFirstChild("Main", true)
        or eggInstance:FindFirstChild("Bottom", true)
        or eggInstance:FindFirstChild("Base", true)
    if namedPart and namedPart:IsA("BasePart") then
        return namedPart.CFrame
    end

    if eggInstance:IsA("Model") then
        local ok, pivot = pcall(function()
            return eggInstance:GetPivot()
        end)
        if ok and pivot then
            return pivot
        end
    end

    local firstPart = eggInstance:FindFirstChildWhichIsA("BasePart", true)
    return firstPart and firstPart.CFrame or nil
end

function getLatestUnlockedEgg()
    local things = Workspace:FindFirstChild("__THINGS")
    local eggsMain = things and things:FindFirstChild("Eggs")
    eggsMain = eggsMain and eggsMain:FindFirstChild("Main")
    local workspaceEntries = {}
    local workspaceByName = {}
    if eggsMain then
        for _, eggInstance in ipairs(eggsMain:GetChildren()) do
            local eggNumber, eggName = parseWorkspaceEggName(eggInstance.Name)
            if eggNumber and eggName then
                local entry = {
                    Number = eggNumber,
                    Name = eggName,
                    FullName = eggInstance.Name,
                    Instance = eggInstance,
                    Locked = isEggLocked(eggInstance)
                }
                table.insert(workspaceEntries, entry)
                workspaceByName[eggName] = entry
            end
        end
    end

    local eggCmds = requireClientModule("EggCmds")
    local highestEggNumber
    if type(eggCmds) == "table" and type(eggCmds.GetHighestEggNumberAvailable) == "function" then
        local ok, result = pcall(eggCmds.GetHighestEggNumberAvailable)
        highestEggNumber = ok and tonumber(result) or nil
    end

    local entries = {}
    local seen = {}
    local eggsFolder = getDirectoryFolder("Eggs")
    local zoneEggs = eggsFolder and eggsFolder:FindFirstChild("Zone Eggs")
    if zoneEggs then
        for _, moduleScript in ipairs(zoneEggs:GetDescendants()) do
            if moduleScript:IsA("ModuleScript") then
                local eggNumber, parsedName = parseEggLabel(moduleScript.Name)
                local ok, definition = pcall(require, moduleScript)
                if ok and type(definition) == "table" then
                    local eggName = parsedName or definition.name or definition.Name or definition._id or definition.id
                    eggNumber = eggNumber or tonumber(definition.eggNumber or definition.EggNumber or definition.number or definition.Number)
                    eggName = normalizeWhitespace(eggName)
                    if eggName ~= "" and eggNumber and (not highestEggNumber or eggNumber <= highestEggNumber) and not seen[eggName] then
                        local available = true
                        local unlocked = true
                        if type(eggCmds) == "table" and type(eggCmds.IsEggAvailable) == "function" then
                            local availableOk, availableResult = pcall(eggCmds.IsEggAvailable, eggName)
                            available = not availableOk or availableResult ~= false
                        end
                        if type(eggCmds) == "table" and type(eggCmds.IsUnlocked) == "function" then
                            local unlockedOk, unlockedResult = pcall(eggCmds.IsUnlocked, eggName)
                            unlocked = not unlockedOk or unlockedResult ~= false
                        end
                        if available then
                            local streamed = workspaceByName[eggName]
                            seen[eggName] = true
                            table.insert(entries, {
                                Number = eggNumber,
                                Name = eggName,
                                FullName = moduleScript.Name,
                                Instance = streamed and streamed.Instance or nil,
                                Locked = not unlocked,
                                DirectoryData = definition
                            })
                        end
                    end
                end
            end
        end
    end

    if #entries == 0 then
        for _, entry in ipairs(workspaceEntries) do
            if not seen[entry.Name] and (not highestEggNumber or entry.Number <= highestEggNumber) then
                entry.DirectoryData = getEggDirectoryData(entry.Name)
                table.insert(entries, entry)
            end
        end
    end

    table.sort(entries, function(a, b)
        return a.Number > b.Number
    end)

    local latestEgg = entries[1]
    for _, entry in ipairs(entries) do
        if not entry.Locked then
            return entry, latestEgg, entries
        end
    end

    return nil, latestEgg, entries
end

function getEggPriceInfo(eggData)
    local definition = eggData and (eggData.DirectoryData or getEggDirectoryData(eggData.Name))
    if type(definition) == "table" then
        local currency = definition.currency or definition.Currency or definition.currencyId or definition.CurrencyId
        local amount = tonumber(definition.overrideCost or definition.cost or definition.Cost or definition.price or definition.Price)
        if currency and amount and amount > 0 then
            return {
                Currency = tostring(currency),
                AmountText = tostring(amount),
                AmountValue = amount
            }
        end
    end

    local eggInstance = eggData and eggData.Instance
    if not eggInstance then
        return nil
    end

    local priceHudRoot = eggInstance:FindFirstChild("PriceHUD", true)
    local priceHud = priceHudRoot and priceHudRoot:FindFirstChild("PriceHUD")
    if not priceHud then
        return nil
    end

    for _, currencyNode in ipairs(priceHud:GetChildren()) do
        local amountNode = currencyNode:FindFirstChild("Amount", true)
        if amountNode and amountNode:IsA("TextLabel") then
            return {
                Currency = currencyNode.Name,
                AmountText = amountNode.Text,
                AmountValue = parseShortNumber(amountNode.Text)
            }
        end
    end

    return nil
end

function getCurrencyAmount(currencyName)
    if not currencyName then
        return nil
    end

    local ok, value = pcall(function()
        return require(Library.Client.CurrencyCmds).Get(currencyName)
    end)
    if ok and type(value) == "number" then
        return value
    end

    local saveOk, saveData = pcall(function()
        return require(Library).Save.Get()
    end)
    if saveOk and type(saveData) == "table" then
        for _, bucketName in ipairs({ "Currency", "Currencies" }) do
            local bucket = saveData[bucketName] or (saveData.Inventory and saveData.Inventory[bucketName])
            if type(bucket) == "table" and type(bucket[currencyName]) == "number" then
                return bucket[currencyName]
            end
        end
    end

    return nil
end

function getTapHeroesEggCandidates()
    return getCachedDiscovery("tapHeroesEggs", 5, false, function()
        local eggsFolder = getDirectoryFolder("Eggs")
        local eventsFolder = eggsFolder and eggsFolder:FindFirstChild("Events")
        local tapHeroesFolder = eventsFolder and eventsFolder:FindFirstChild("TapHeroes")
        local searchRoot = tapHeroesFolder or eventsFolder
        local candidates = {}

        if not searchRoot then
            return candidates
        end

        for _, moduleScript in ipairs(searchRoot:GetDescendants()) do
            if moduleScript:IsA("ModuleScript") then
                local ok, data = pcall(require, moduleScript)
                if ok and type(data) == "table" then
                    local name = tostring(data.name or data.Name or data._id or data.id or "")
                    local tier = tonumber(moduleScript.Name:match("^(%d+)")) or tonumber(name:match("Tier%s+(%d+)$"))
                    if tier and name:find("Tap Heroes Egg Tier", 1, true) == 1 then
                        table.insert(candidates, {
                            Name = name,
                            Tier = tier,
                            Cost = tonumber(data.overrideCost or data.cost or data.Cost),
                            Currency = data.currency or data.Currency,
                            IsCustom = data.isCustomEgg == true,
                            Definition = data
                        })
                    end
                end
            end
        end

        table.sort(candidates, function(a, b)
            return a.Tier < b.Tier
        end)
        return candidates
    end)
end

function getTapHeroesUnlockedEggTier()
    local candidates = getTapHeroesEggCandidates()
    if #candidates == 0 then
        return 0
    end

    local eventUpgradeCmds = requireClientModule("EventUpgradeCmds")
    local directoryModule = Library:FindFirstChild("Directory") and Library.Directory:FindFirstChild("EventUpgrades")
    if type(eventUpgradeCmds) ~= "table" or type(eventUpgradeCmds.GetTier) ~= "function" or not directoryModule then
        return 1
    end

    local okDirectory, definitions = pcall(require, directoryModule)
    local definition = okDirectory and type(definitions) == "table" and definitions.TapHeroesEggUpgrade or nil
    if not definition then
        return 1
    end

    local okTier, tier = pcall(eventUpgradeCmds.GetTier, definition)
    if not okTier then
        return 1
    end

    return math.clamp(math.floor(tonumber(tier) or 0) + 1, 1, #candidates)
end

function getMaximumEggHatchAmount(eggDefinition)
    local eggCmds = requireClientModule("EggCmds")
    if type(eggCmds) == "table" and type(eggCmds.GetMaxHatch) == "function" then
        local ok, amount = pcall(eggCmds.GetMaxHatch, eggDefinition)
        local numericAmount = tonumber(amount)
        if ok and numericAmount then
            return math.max(math.floor(numericAmount), 1)
        end
    end
    return 1
end

function resolveLatestHatchTarget()
    local inTapHeroes = (getCurrentActiveInstanceName and getCurrentActiveInstanceName() == "TapHeroes")
        or (isInstanceActive and isInstanceActive("TapHeroes"))

    if inTapHeroes then
        local candidates = getTapHeroesEggCandidates()
        local unlockedTier = getTapHeroesUnlockedEggTier()
        table.sort(candidates, function(a, b)
            return (tonumber(a.Tier) or 0) > (tonumber(b.Tier) or 0)
        end)
        for _, candidate in ipairs(candidates) do
            if (tonumber(candidate.Tier) or 0) <= unlockedTier then
                local requestedAmount = math.min(eggHatchAmount, getMaximumEggHatchAmount(candidate.Definition))
                local selected, amount = selectLatestAffordableEggCandidate(
                    { candidate },
                    unlockedTier,
                    getCurrencyAmount(candidate.Currency or "MarbleCoins"),
                    requestedAmount
                )
                if selected then
                    return selected, amount
                end
            end
        end
        return nil, 0
    end

    local eggData, _, unlockedEggs = getLatestUnlockedEgg()
    if not eggData then
        return nil, 0
    end

    for _, unlockedEgg in ipairs(unlockedEggs or { eggData }) do
        if not unlockedEgg.Locked then
            local priceInfo = getEggPriceInfo(unlockedEgg)
            local definition = unlockedEgg.DirectoryData or getEggDirectoryData(unlockedEgg.Name)
            local requestedAmount = math.min(eggHatchAmount, getMaximumEggHatchAmount(definition))
            local candidate = {
                Name = unlockedEgg.Name,
                Tier = tonumber(unlockedEgg.Number) or 1,
                Cost = priceInfo and tonumber(priceInfo.AmountValue) or nil,
                Currency = priceInfo and priceInfo.Currency or nil,
                IsCustom = false,
                Instance = unlockedEgg.Instance,
                Definition = definition
            }

            if not candidate.Cost or not candidate.Currency then
                return candidate, requestedAmount
            end

            local selected, amount = selectLatestAffordableEggCandidate(
                { candidate },
                candidate.Tier,
                getCurrencyAmount(candidate.Currency),
                requestedAmount
            )
            if selected then
                return selected, amount
            end
        end
    end
    return nil, 0
end

function getCustomEggHatchTarget(eggName)
    local customEggCmds = requireClientModule("CustomEggsCmds")
    if type(customEggCmds) ~= "table" or type(customEggCmds.All) ~= "function" then
        return nil, nil
    end

    local ok, allEggs = pcall(function()
        return customEggCmds.All()
    end)
    if not ok or type(allEggs) ~= "table" then
        return nil, nil
    end

    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local bestUid, bestEgg, bestDistance
    for uid, customEgg in pairs(allEggs) do
        if type(customEgg) == "table"
            and type(customEgg.Directory) == "function"
            and type(customEgg.IsHatchable) == "function" then
            local directoryOk, directoryData = pcall(function()
                return customEgg:Directory()
            end)
            local hatchableOk, hatchable = pcall(function()
                return customEgg:IsHatchable()
            end)
            local id = directoryOk and directoryData and (directoryData._id or directoryData.name or directoryData.Name or directoryData.id)
            if tostring(id or "") == tostring(eggName) and hatchableOk and hatchable == true then
                local positionOk, position = pcall(function()
                    return customEgg:GetPosition()
                end)
                local distance = positionOk and typeof(position) == "Vector3" and root and (root.Position - position).Magnitude or 0
                if not bestDistance or distance < bestDistance then
                    bestUid = tostring(uid)
                    bestEgg = customEgg
                    bestDistance = distance
                end
            end
        end
    end
    return bestUid, bestEgg
end

function hatchEggByName(eggName, amount)
    if not eggName or eggName == "" then
        return false
    end
    local function canContinue()
        return isAutomationContextCurrent()
    end
    if not canContinue() then
        return false
    end

    local eggData = getEggDirectoryData(eggName)
    local isCustom = eggData and eggData.isCustomEgg == true
    local remote = Network:FindFirstChild(eggData and eggData.isCustomEgg and "CustomEggs_Hatch" or "Eggs_RequestPurchase")
    if not remote then
        getgenv().FlowPS99LastEggHatch = {
            Egg = eggName,
            Failed = true,
            Reason = "Hatch remote is unavailable.",
            Time = os.clock()
        }
        return false
    end

    local hatchAmount = math.min(
        math.max(math.floor(tonumber(amount) or 1), 1),
        getMaximumEggHatchAmount(eggData)
    )
    local requestId = eggName
    local customUid, customEgg
    if isCustom then
        customUid, customEgg = getCustomEggHatchTarget(eggName)
        if not customUid or not customEgg then
            getgenv().FlowPS99LastEggHatch = {
                Egg = eggName,
                Failed = true,
                Reason = "No live hatchable custom egg UID was found.",
                Time = os.clock()
            }
            return false
        end
        requestId = customUid

        local positionOk, position = pcall(function()
            return customEgg:GetPosition()
        end)
        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if positionOk and typeof(position) == "Vector3" and root and (root.Position - position).Magnitude > 38 and canContinue() then
            root.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
            if not waitForRunningDelay(0.15, canContinue) then
                return false
            end
        end
    end

    if not canContinue() then
        return false
    end
    local ok, result, message = pcall(function()
        if remote:IsA("RemoteFunction") then
            return remote:InvokeServer(requestId, hatchAmount)
        end
        remote:FireServer(requestId, hatchAmount)
        return true
    end)

    getgenv().FlowPS99LastEggHatch = {
        Egg = eggName,
        Amount = hatchAmount,
        Remote = remote.Name,
        RequestId = requestId,
        Result = result,
        Reason = message,
        Failed = not ok or result == false,
        Time = os.clock()
    }
    return ok and result ~= false
end

function hatchLatestEggOnce()
    local candidate, amount = resolveLatestHatchTarget()
    if not candidate or amount < 1 then
        return false
    end

    return hatchEggByName(candidate.Name, amount)
end

function getZoneGateTitleText(zonePath)
    local title = zonePath
        and zonePath:FindFirstChild("INTERACT")
        and zonePath.INTERACT:FindFirstChild("Gate")
        and zonePath.INTERACT.Gate:FindFirstChild("GateHUD")
        and zonePath.INTERACT.Gate.GateHUD:FindFirstChild("Title")

    if title and title:IsA("TextLabel") then
        return normalizeWhitespace(title.Text)
    end

    return nil
end

function isZoneUnlockedByText(zonePath)
    if not zonePath or not zonePath:FindFirstChild("INTERACT") then
        return false
    end

    local titleText = getZoneGateTitleText(zonePath)
    if not titleText or titleText == "" then
        return true
    end

    local zoneName = trim(split(zonePath.Name, "|")[2]) or ""
    local lowerTitle = titleText:lower()
    local lowerZoneName = zoneName:lower()

    if lowerZoneName ~= "" and lowerTitle:find(lowerZoneName, 1, true) then
        return true
    end

    if lowerTitle:find("locked", 1, true)
        or lowerTitle:find("unlock", 1, true)
        or lowerTitle:find("purchase", 1, true)
        or lowerTitle:find("buy", 1, true)
        or lowerTitle:find("coins", 1, true)
        or lowerTitle:find("diamonds", 1, true)
        or lowerTitle:find("gems", 1, true) then
        return false
    end

    if titleText:match("%d") then
        return false
    end

    return true
end

function getLatestUnlockedBestArea()
    if #getCurrentMaps() == 0 then
        return nil
    end

    local zoneCmdsOk, zoneCmds = pcall(function()
        return require(Library.Client.ZoneCmds)
    end)

    if zoneCmdsOk and zoneCmds and type(zoneCmds.GetMaxOwnedZone) == "function" then
        local maxOk, zoneName, maxZoneData = pcall(zoneCmds.GetMaxOwnedZone)
        if maxOk and zoneName and maxZoneData and maxZoneData.ZoneNumber then
            local zonePath = findZonePathByData(nil, maxZoneData.ZoneNumber, zoneName)
            local isOwned = (type(zoneCmds.Owns) == "function" and zoneCmds.Owns(zoneName)) or (zonePath and isZoneOwnedByInteract(zonePath))
            if zonePath and zonePath:FindFirstChild("PERSISTENT") and isOwned then
                return {
                    Number = maxZoneData.ZoneNumber,
                    Name = zoneName,
                    FullName = zonePath.Name,
                    Path = zonePath,
                    Source = "ZoneCmds",
                    GateTitle = getZoneGateTitleText(zonePath)
                }
            end

            local fullName = tostring(maxZoneData.ZoneNumber) .. " | " .. tostring(zoneName)
            local entry = findAvailableZoneEntryByFullName(fullName) or findAvailableZoneEntryByName(zoneName)
            if entry and entry.Path and isOwned then
                entry.Source = "ZoneCmds"
                entry.GateTitle = getZoneGateTitleText(entry.Path)
                return entry
            end
        end
    end

    local entries = getAvailableZoneEntries()
    table.sort(entries, function(a, b)
        return a.Number > b.Number
    end)

    for _, entry in ipairs(entries) do
        if isZoneEntryUnlocked(entry) then
            entry.Source = "Interact"
            entry.GateTitle = getZoneGateTitleText(entry.Path)
            return entry
        end
    end

    for _, entry in ipairs(entries) do
        if isZoneUnlockedByText(entry.Path) then
            entry.Source = "GateHUD"
            entry.GateTitle = getZoneGateTitleText(entry.Path)
            return entry
        end
    end

    if #entries > 0 then
        table.sort(entries, function(a, b) return a.Number < b.Number end)
        return entries[1]
    end

    return nil
end

function isZoneEntryUnlocked(entry)
    if not entry then
        return false
    end

    local zoneCmdsOk, zoneCmds = pcall(function()
        return require(Library.Client.ZoneCmds)
    end)
    if zoneCmdsOk and zoneCmds and type(zoneCmds.Owns) == "function" then
        if entry.Name and zoneCmds.Owns(entry.Name) then
            return true
        end
        if entry.FullName and zoneCmds.Owns(entry.FullName) then
            return true
        end
    end

    local saveOk, save = pcall(function()
        return require(Library.Client.Save).Get()
    end)
    if saveOk and save and type(save.UnlockedZones) == "table" then
        if entry.Name and (save.UnlockedZones[entry.Name] == true or save.UnlockedZones[tostring(entry.Name)] == true) then
            return true
        end
    end

    if entry.Path and isZoneOwnedByInteract(entry.Path) then
        return true
    end

    return entry.Path and isZoneUnlockedByText(entry.Path) or false
end

function syncSelectedEggFromQuest(eggData)
    if not eggData then
        return
    end

    selectedEggName = eggData.Name

    local expectedLabel = string.format("%d | %s", eggData.Number, eggData.Name)
    if eggNameLookup[expectedLabel] then
        selectedEggLabel = expectedLabel
        return
    end

    for label, purchaseName in pairs(eggNameLookup) do
        if purchaseName == eggData.Name then
            selectedEggLabel = label
            return
        end
    end
end

function getQuestEggStandCFrame(targetCFrame, spinStep)
    local angle = math.rad((spinStep % 12) * 30)
    local offset = Vector3.new(math.cos(angle) * 7, 3, math.sin(angle) * 7)
    local standPosition = targetCFrame.Position + offset
    return CFrame.lookAt(standPosition, targetCFrame.Position + Vector3.new(0, 2, 0))
end
function teleportToEggWithFallbacks(eggData, isRunning)
    if not eggData then
        return false, nil
    end

    local eggCFrame = resolveEggCFrame(eggData.Instance)
    if not eggCFrame then
        return false, nil
    end

    local hrp = getHumanoidRootPart()
    local eKey = 0x45
    local runningCheck = isRunning or function()
        return autoQuestRunning and isAutomationContextCurrent()
    end

    for attempt = 1, 4 do
        if not runningCheck() then
            return false, eggCFrame
        end
        local standCFrame = getQuestEggStandCFrame(eggCFrame, attempt)

        hrp.CFrame = standCFrame

        if keypress and keyrelease then
            keypress(eKey)
            if not waitForRunningDelay(0.05, runningCheck) then
                pcall(keyrelease, eKey)
                return false, eggCFrame
            end
            keyrelease(eKey)
        end

        if not waitForRunningDelay(getgenv().autoQuestConfig.TELEPORT_RETRY_DELAY, runningCheck) then
            return false, eggCFrame
        end

        if (hrp.Position - eggCFrame.Position).Magnitude <= 20 then
            return true, eggCFrame
        end

        hrp.CFrame = eggCFrame + Vector3.new(0, 6, 0)

        if keypress and keyrelease then
            keypress(eKey)
            if not waitForRunningDelay(0.05, runningCheck) then
                pcall(keyrelease, eKey)
                return false, eggCFrame
            end
            keyrelease(eKey)
        end

        if not waitForRunningDelay(getgenv().autoQuestConfig.TELEPORT_RETRY_DELAY, runningCheck) then
            return false, eggCFrame
        end

        if (hrp.Position - eggCFrame.Position).Magnitude <= 20 then
            return true, eggCFrame
        end
    end

    return false, eggCFrame
end
function getQuestBreakZones(zonePath)
    local breakZones = {}
    local breakZonesFolder = zonePath
        and zonePath:FindFirstChild("INTERACT")
        and zonePath.INTERACT:FindFirstChild("BREAK_ZONES")

    if breakZonesFolder then
        for _, breakZone in ipairs(breakZonesFolder:GetChildren()) do
            if breakZone:IsA("BasePart") then
                table.insert(breakZones, breakZone)
            end
        end
    end

    table.sort(breakZones, function(a, b)
        return a.Name < b.Name
    end)

    return breakZones
end

function getQuestBreakZoneCFrame(zonePath, step)
    local breakZones = getQuestBreakZones(zonePath)
    if #breakZones == 0 then
        return zonePath and zonePath:FindFirstChild("PERSISTENT") and (zonePath.PERSISTENT.Teleport.CFrame + Vector3.new(0, 10, 0)) or nil
    end

    local index = ((math.max(step, 1) - 1) % #breakZones) + 1
    return breakZones[index].CFrame + Vector3.new(0, 10, 0)
end

function teleportToBestAreaWithFallbacks(zoneInfo, isRunning)
    if not zoneInfo or not zoneInfo.Path or not zoneInfo.Path:FindFirstChild("PERSISTENT") then
        return false
    end

    local zonePath = zoneInfo.Path
    local hrp = getHumanoidRootPart()
    local runningCheck = isRunning or function()
        return autoQuestRunning
    end

    for attempt = 1, 4 do
        if not runningCheck() then
            return false
        end
        hrp.CFrame = zonePath.PERSISTENT.Teleport.CFrame + Vector3.new(0, 10, 0)
        if not waitForRunningDelay(getgenv().autoQuestConfig.TELEPORT_RETRY_DELAY, runningCheck) then
            return false
        end

        if waitForZoneInteract(zonePath, function()
            return runningCheck()
        end) then
            local targetCFrame = getQuestBreakZoneCFrame(zonePath, attempt)
            if targetCFrame and runningCheck() then
                hrp.CFrame = targetCFrame
                if not waitForRunningDelay(getgenv().autoQuestConfig.TELEPORT_RETRY_DELAY, runningCheck) then
                    return false
                end
            end
            return runningCheck()
        end
    end

    return false
end

function getBreakableTargetPart(breakable)
    if not breakable then
        return nil
    end

    if breakable:IsA("BasePart") then
        return breakable
    end

    return breakable:FindFirstChild("Top")
        or breakable:FindFirstChild("Bottom")
        or breakable:FindFirstChild("Main")
        or breakable:FindFirstChildWhichIsA("BasePart", true)
end

function getBreakableCFrame(breakable)
    if not breakable then
        return nil
    end

    if breakable:IsA("BasePart") then
        return breakable.CFrame
    end

    local targetPart = getBreakableTargetPart(breakable)
    if targetPart then
        return targetPart.CFrame
    end

    if breakable:IsA("Model") then
        local ok, pivot = pcall(function()
            return breakable:GetPivot()
        end)
        if ok and pivot then
            return pivot
        end

        if breakable.WorldPivot then
            return breakable.WorldPivot
        end
    end

    return nil
end

function breakableMatchesZone(breakable, zoneInfo)
    if not breakable or not zoneInfo then
        return false
    end

    local zoneName = tostring(zoneInfo.Name or "")
    local zoneFullName = tostring(zoneInfo.FullName or "")
    local zoneNumber = tostring(zoneInfo.Number or "")
    local isVipZone = zoneName:lower():find("vip") ~= nil or zoneFullName:lower():find("vip") ~= nil

    local isVipBreakable = breakable:GetAttribute("VIPBreakable") == true or tostring(breakable:GetAttribute("AreaID") or ""):lower() == "vip"
    if isVipBreakable and not isVipZone then
        return false
    end

    local parentId = tostring(breakable:GetAttribute("ParentID") or breakable:GetAttribute("ParentId") or "")
    local parentKey = collapseKey(parentId)
    local candidates = {
        zoneName,
        zoneFullName,
        zoneNumber,
        collapseKey(zoneName),
        collapseKey(zoneFullName),
        collapseKey(zoneNumber)
    }

    if parentKey ~= "" then
        for _, candidate in ipairs(candidates) do
            local candidateKey = collapseKey(candidate)
            if candidateKey ~= "" and (parentKey == candidateKey or candidateKey:find(parentKey, 1, true) or parentKey:find(candidateKey, 1, true)) then
                return true
            end
        end
    end

    for _, attributeName in ipairs({ "ParentID", "ParentId", "Zone", "ZoneName", "Area", "AreaID" }) do
        local attributeValue = breakable:GetAttribute(attributeName)
        if attributeValue ~= nil then
            local value = tostring(attributeValue)
            for _, candidate in ipairs(candidates) do
                local candidateKey = collapseKey(candidate)
                local valueKey = collapseKey(value)
                if value == candidate or (candidateKey ~= "" and (valueKey == candidateKey or candidateKey:find(valueKey, 1, true) or valueKey:find(candidateKey, 1, true))) then
                    return true
                end
            end
        end
    end

    return false
end

function setEquippedPetsTarget(targetId)
    if not targetId then
        return false
    end
    targetId = tostring(targetId)
    if lastPetTargetId == targetId then
        return true
    end

    local petCmdsOk, petCmds = pcall(function()
        return require(Library.Client.PetCmds)
    end)
    local equipped = (petCmdsOk and petCmds and petCmds.GetEquipped and petCmds.GetEquipped()) or {}

    local petBulk = {}
    local bulkTarget = {}
    for euid, _ in pairs(equipped) do
        local euidStr = tostring(euid)
        petBulk[euidStr] = targetId
        bulkTarget[euidStr] = {
            targetId = targetId,
            targetType = "Breakable"
        }
    end

    if next(petBulk) == nil then
        local ok, saveData = pcall(function()
            return require(Library.Client.Save).Get(LocalPlayer)
        end)
        if ok and saveData and saveData.EquippedPets then
            for petId in pairs(saveData.EquippedPets) do
                local pStr = tostring(petId)
                petBulk[pStr] = targetId
                bulkTarget[pStr] = {
                    targetId = targetId,
                    targetType = "Breakable"
                }
            end
        end
    end

    if next(petBulk) ~= nil then
        pcall(function()
            local clientNet = require(Library.Client.Network)
            if clientNet and clientNet.Fire then
                clientNet.Fire("Breakables_JoinPetBulk", petBulk)
                clientNet.Fire("Pets_SetTargetBulk", bulkTarget)
            end
        end)
        pcall(function()
            local remoteJoin = Network:FindFirstChild("Breakables_JoinPetBulk")
            if remoteJoin then
                remoteJoin:FireServer(petBulk)
            end
            local remoteTarget = Network:FindFirstChild("Pets_SetTargetBulk")
            if remoteTarget then
                remoteTarget:FireServer(bulkTarget)
            end
        end)
    end

    lastPetTargetId = targetId
    return true
end

function getBreakableDisplayName(breakable)
    if not breakable then
        return nil
    end

    local rawName = breakable:GetAttribute("BreakableID")
        or breakable:GetAttribute("BreakableId")
        or breakable.Name

    return stripTrailingMode(rawName)
end

function getBreakableTargetId(breakable)
    if not breakable then
        return nil
    end

    if type(breakable) == "string" or type(breakable) == "number" then
        return tostring(breakable)
    end

    local targetId = breakable:GetAttribute("BreakableUID")
        or breakable:GetAttribute("BreakableUid")
        or breakable:GetAttribute("BreakableID")
        or breakable:GetAttribute("BreakableId")

    if targetId ~= nil then
        return tostring(targetId)
    end

    return tostring(breakable.Name)
end

function isNumericBreakableName(breakable)
    local targetId = getBreakableTargetId(breakable)
    return targetId ~= nil and targetId:match("^%d+$") ~= nil
end

function getBreakableParentId(breakable)
    return breakable and (breakable:GetAttribute("ParentID") or breakable:GetAttribute("ParentId"))
end

function getBreakableQuestKey(breakable)
    return normalizeBreakableTarget(getBreakableDisplayName(breakable))
end

function getBreakableFarmKeys(breakable)
    local keys = {}
    local displayKey = collapseKey(getBreakableDisplayName(breakable))
    local parentKey = collapseKey(getBreakableParentId(breakable))

    if displayKey == "" then
        if isNumericBreakableName(breakable) then
            keys.coin = true
        end
        return keys
    end

    if displayKey:find("coin", 1, true) or displayKey:find("bar", 1, true) or displayKey:find("pile", 1, true) then
        keys.coin = true
    end
    if displayKey:find("smallcoin", 1, true) then
        keys.smallcoin = true
    end
    if displayKey:find("mediumcoin", 1, true) then
        keys.mediumcoin = true
    end
    if displayKey:find("largecoin", 1, true) then
        keys.largecoin = true
        keys.bigcoin = true
    end
    if displayKey:find("bigcoin", 1, true) then
        keys.bigcoin = true
        keys.largecoin = true
    end
    if displayKey:find("minichest", 1, true) then
        keys.minichest = true
        keys.chest = true
    end
    if displayKey:find("chest", 1, true) then
        keys.chest = true
    end
    if displayKey:find("safe", 1, true) then
        keys.safe = true
    end
    if displayKey:find("vault", 1, true) then
        keys.vault = true
    end
    if displayKey:find("crate", 1, true) then
        keys.crate = true
    end
    if displayKey:find("diamondpresent", 1, true) then
        keys.diamondpresent = true
        keys.present = true
    elseif displayKey:find("present", 1, true) then
        keys.present = true
    end
    if displayKey:find("diamondpile", 1, true) then
        keys.diamondpile = true
        keys.coin = true
    end
    if displayKey:find("comet", 1, true) then
        keys.comet = true
    end
    if displayKey:find("iceblock", 1, true) then
        keys.iceblock = true
    end
    if displayKey:find("luckyblock", 1, true) or parentKey == "luckyblocks" then
        keys.luckyblock = true
    end
    if isNumericBreakableName(breakable) then
        keys.coin = true
    end

    return keys
end

function breakableMatchesFarmFilters(breakable, filters)
    if not breakable then
        return false
    end

    if not filters or #filters == 0 or table.find(filters, "Any") then
        return true
    end

    local keys = getBreakableFarmKeys(breakable)
    for _, label in ipairs(filters) do
        local key = BREAKABLE_FARM_FILTER_KEYS[label]
        if key and keys[key] then
            return true
        end
    end

    return false
end

function getResolvedBreakableFarmFilters(filters)
    local resolved = cloneArray(filters)
    if #resolved == 0 then
        return { "Any" }
    end
    return resolved
end

function breakableMatchesQuestTarget(breakable, questTask)
    if not breakable or not questTask or not questTask.TargetKey then
        return true
    end

    local targetKey = questTask.TargetKey
    local breakableKey = getBreakableQuestKey(breakable)
    local parentKey = collapseKey(getBreakableParentId(breakable))
    local displayKey = collapseKey(getBreakableDisplayName(breakable))

    if targetKey == "luckyblock" then
        return parentKey == "luckyblocks" or breakableKey == "luckyblock"
    end

    if targetKey == "present" then
        return breakableKey == "present" or breakableKey == "diamondpresent"
    end

    if targetKey == "coin" then
        return breakableKey == "coin" or breakableKey == "diamondpile" or isNumericBreakableName(breakable)
    end

    if targetKey == "diamond" then
        return displayKey:find("diamond", 1, true) ~= nil
    end

    if targetKey == "chest" then
        return breakableKey == "chest"
    end

    if breakableKey == targetKey then
        return true
    end

    return displayKey:find(targetKey, 1, true) ~= nil
end

function ensureLuckyBlocksInstance()
    local things = Workspace:FindFirstChild("__THINGS")
    local activeInstances = things and things:FindFirstChild("__INSTANCE_CONTAINER")
    activeInstances = activeInstances and activeInstances:FindFirstChild("Active")

    if activeInstances and activeInstances:FindFirstChild("LuckyBlocks") then
        return true
    end

    
    if activeInstances and #activeInstances:GetChildren() > 0 then
        autoQuestDebug("Already inside another instance. Skipping LuckyBlocks entry.")
        return false
    end

    pcall(function()
        Network.Instancing_PlayerEnterInstance:InvokeServer("LuckyBlocks")
    end)

    local deadline = os.clock() + 5
    repeat
        if activeInstances and activeInstances:FindFirstChild("LuckyBlocks") then
            return true
        end

        local breakables = things and things:FindFirstChild("Breakables")
        if breakables then
            for _, breakable in ipairs(breakables:GetChildren()) do
                if collapseKey(getBreakableParentId(breakable)) == "luckyblocks" then
                    return true
                end
            end
        end

        task.wait(0.2)
    until os.clock() >= deadline or not autoQuestRunning

    return false
end

function getQuestMatchingBreakables(questTask, zoneInfo)
    local matches = {}
    local things = Workspace:FindFirstChild("__THINGS")
    local breakablesFolder = things and things:FindFirstChild("Breakables")
    if not breakablesFolder then
        return matches
    end

    for _, breakable in ipairs(breakablesFolder:GetChildren()) do
        if breakableMatchesQuestTarget(breakable, questTask) then
            if not zoneInfo or breakableMatchesZone(breakable, zoneInfo) then
                table.insert(matches, breakable)
            end
        end
    end

    return matches
end

function getBreakableFarmMatchingBreakables(zoneInfo, filters)
    local matches = {}
    local things = Workspace:FindFirstChild("__THINGS")
    local breakablesFolder = things and things:FindFirstChild("Breakables")
    if not breakablesFolder then
        return matches
    end

    filters = getResolvedBreakableFarmFilters(filters or selectedBreakableFarmFilters)

    for _, breakable in ipairs(breakablesFolder:GetChildren()) do
        if breakableMatchesZone(breakable, zoneInfo) and breakableMatchesFarmFilters(breakable, filters) then
            table.insert(matches, breakable)
        end
    end

    return matches
end

function getQuestZoneBreakables(questTask, zoneInfo)
    if not zoneInfo then
        return {}
    end

    if questTask and questTask.TargetKey then
        return getQuestMatchingBreakables(questTask, zoneInfo)
    end

    local preferredMatches = getBreakableFarmMatchingBreakables(zoneInfo, selectedBreakableFarmFilters)
    if #preferredMatches > 0 then
        return preferredMatches
    end

    return getBreakableFarmMatchingBreakables(zoneInfo, { "Any" })
end

function findQuestFarmZoneByFilters(filters, preferredZoneName)
    local matchedZones = {}

    for _, entry in ipairs(getAvailableZoneEntries()) do
        if not isZoneEntryUnlocked(entry) then
            continue
        end

        local matches = getBreakableFarmMatchingBreakables(entry, filters)
        if #matches > 0 then
            if preferredZoneName and entry.FullName == preferredZoneName then
                return entry, matches
            end

            table.insert(matchedZones, {
                Zone = entry,
                Matches = matches
            })
        end
    end

    if #matchedZones == 0 then
        return nil, {}
    end

    local selectedZone = matchedZones[BREAKABLE_RANDOM:NextInteger(1, #matchedZones)]
    return selectedZone.Zone, selectedZone.Matches
end

function getGlobalQuestMatchingBreakables(questTask)
    local matches = {}
    local things = Workspace:FindFirstChild("__THINGS")
    local breakablesFolder = things and things:FindFirstChild("Breakables")
    if not breakablesFolder then
        return matches
    end

    for _, breakable in ipairs(breakablesFolder:GetChildren()) do
        if breakableMatchesQuestTarget(breakable, questTask) then
            table.insert(matches, breakable)
        end
    end

    return matches
end

function findQuestZoneByTargetBreakables(questTask, preferredZoneName, isRunning)
    if not questTask then
        return nil, {}
    end

    local entries = getOwnedZoneEntries()
    table.sort(entries, function(a, b)
        return a.Number > b.Number
    end)

    
    local globalMatches = getGlobalQuestMatchingBreakables(questTask)
    if #globalMatches > 0 then
        local zoneMatchCounts = {}
        for _, match in ipairs(globalMatches) do
            for _, entry in ipairs(entries) do
                if breakableMatchesZone(match, entry) then
                    zoneMatchCounts[entry.FullName] = (zoneMatchCounts[entry.FullName] or 0) + 1
                end
            end
        end
        local bestZoneName, bestCount
        for fullName, count in pairs(zoneMatchCounts) do
            if not bestCount or count > bestCount then
                bestCount = count
                bestZoneName = fullName
            end
        end
        if bestZoneName then
            for _, entry in ipairs(entries) do
                if entry.FullName == bestZoneName then
                    return entry, globalMatches
                end
            end
        end
    end

    if preferredZoneName then
        for _, entry in ipairs(entries) do
            if entry.FullName == preferredZoneName then
                local matches = getQuestMatchingBreakables(questTask, entry)
                if #matches > 0 then
                    return entry, matches
                end

                if moveToBreakableZone(entry, isRunning) then
                    task.wait(math.max(getgenv().autoQuestConfig.ACTION_DELAY, 0.15))
                    matches = getQuestMatchingBreakables(questTask, entry)
                    if #matches > 0 then
                        return entry, matches
                    end
                end

                break
            end
        end
    end

    for _, entry in ipairs(entries) do
        if isRunning and not isRunning() then
            break
        end

        if not preferredZoneName or entry.FullName ~= preferredZoneName then
            if moveToBreakableZone(entry, isRunning) then
                task.wait(math.max(getgenv().autoQuestConfig.ACTION_DELAY, 0.15))

                local matches = getQuestMatchingBreakables(questTask, entry)
                if #matches > 0 then
                    return entry, matches
                end
            end
        end
    end

    return nil, {}
end

function getZoneTeleportPosition(zoneInfo)
    local teleportPart = zoneInfo
        and zoneInfo.Path
        and zoneInfo.Path:FindFirstChild("PERSISTENT")
        and zoneInfo.Path.PERSISTENT:FindFirstChild("Teleport")

    return teleportPart and teleportPart.Position or nil
end

function findNearestOwnedZoneEntryToPosition(targetPosition)
    local closestEntry
    local closestDistance = math.huge

    for _, entry in ipairs(getOwnedZoneEntries()) do
        local teleportPosition = getZoneTeleportPosition(entry)
        if teleportPosition then
            local distance = (teleportPosition - targetPosition).Magnitude
            if distance < closestDistance then
                closestDistance = distance
                closestEntry = entry
            end
        end
    end

    return closestEntry
end

function resolveQuestRouteZone(routeStep)
    if routeStep.ZoneName then
        return findAvailableZoneEntryByName(routeStep.ZoneName)
    end

    return findNearestOwnedZoneEntryToPosition(routeStep.Position)
end

function invokeVendingMachineBulk(machineId, purchases, amount, isRunning)
    local function canContinue()
        return isRunning == nil or isRunning()
    end
    if not machineId then
        return false
    end

    local purchaseCount = tonumber(purchases) or 1
    local purchaseAmount = tonumber(amount) or 1
    local success = false

    for _ = 1, purchaseCount do
        if not canContinue() then
            break
        end
        local ok, result = pcall(function()
            return Network.VendingMachines_Purchase:InvokeServer(machineId, purchaseAmount)
        end)
        if ok and result ~= false then
            success = true
        end
        if not waitForRunningDelay(0.1, isRunning) then
            break
        end
    end

    return success
end

function runQuestCollectRoute(routeSteps, isRunning)
    local visitedZone
    local visitedAny = false
    local waitDuration = math.max(getgenv().autoQuestConfig.COLLECT_ROUTE_WAIT, 0.5)

    for _, routeStep in ipairs(routeSteps) do
        if isRunning and not isRunning() then
            break
        end

        local zoneInfo = resolveQuestRouteZone(routeStep)
        if zoneInfo then
            visitedZone = zoneInfo
            teleportToBestAreaWithFallbacks(zoneInfo, isRunning)
        end

        if isRunning and not isRunning() then
            break
        end

        if isRunning and not isRunning() then
            break
        end
        getHumanoidRootPart().CFrame = CFrame.new(routeStep.Position)
        visitedAny = true
        if not waitForRunningDelay(waitDuration, isRunning) then
            break
        end

        if routeStep.MachineId and (not isRunning or isRunning()) then
            invokeVendingMachineBulk(routeStep.MachineId, routeStep.Purchases, routeStep.Amount, isRunning)
        end
    end

    return visitedAny, visitedZone
end

function runCollectEnchantsQuestStep(isRunning)
    local destinations = {
        {
            ZoneName = "Coral Reef",
            Position = Vector3.new(212, -30, 844)
        },
        {
            Position = Vector3.new(368, 17, 89),
            MachineId = "EnchantVendingMachine1",
            Purchases = 6,
            Amount = 1
        },
        {
            Position = Vector3.new(855, 20, 2088),
            MachineId = "RareEnchantsVendingMachine1",
            Purchases = 6,
            Amount = 1
        },
        {
            ZoneName = "Carnival",
            Position = Vector3.new(-129, 17, 4270)
        }
    }

    pcall(function()
        Network.DailyRewards_Redeem:InvokeServer("DailyEnchants1")
    end)

    local visitedAny, visitedZone = runQuestCollectRoute(destinations, isRunning)
    if visitedAny then
        return visitedZone
    end

    return nil
end

function runCollectPotionsQuestStep(isRunning)
    local destinations = {
        {
            Position = Vector3.new(907, 17, -9),
            ZoneName = "Cherry Blossom",
            MachineId = "PotionVendingMachine1",
            Purchases = 6,
            Amount = 1
        },
        {
            Position = Vector3.new(696, 17, 560),
            ZoneName = "Jungle"
        },
        {
            Position = Vector3.new(987, 17, 1319),
            ZoneName = "Safari",
            MachineId = "PotionVendingMachine2",
            Purchases = 6,
            Amount = 1
        },
        {
            Position = Vector3.new(1481, 16, 1925),
            ZoneName = "Underworld Bridge",
            MachineId = "RarePotionsVendingMachine1",
            Purchases = 6,
            Amount = 1
        },
        {
            Position = Vector3.new(1149, 18, 2865),
            ZoneName = "Cotton Candy Forest",
            MachineId = "OPPotionsVendingMachine1",
            Purchases = 6,
            Amount = 1
        },
        {
            Position = Vector3.new(752, 17, 4229),
            ZoneName = "Ice Sculptures"
        }
    }

    local visitedAny, visitedZone = runQuestCollectRoute(destinations, isRunning)
    if visitedAny then
        return visitedZone
    end

    return nil
end

function teleportToBreakable(breakable)
    local targetCFrame = getBreakableCFrame(breakable)
    if not targetCFrame then
        return false
    end

    local hrp = getHumanoidRootPart()
    if hrp then
        hrp.CFrame = targetCFrame + Vector3.new(0, 3, 0)
    end
    return true
end

function firePrimaryClick()
    pcall(function()
        local cam = Workspace.CurrentCamera
        local vp = cam and cam.ViewportSize or Vector2.new(800, 600)
        local cx = math.floor(vp.X / 2)
        local cy = math.floor(vp.Y / 2)
        VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, true, game, 0)
        task.wait(0.015)
        VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, false, game, 0)
    end)
end

function damageBreakable(breakable)
    if not breakable then
        return false
    end

    local targetId = getBreakableTargetId(breakable)
    if not targetId then
        return false
    end

    setEquippedPetsTarget(targetId)

    for _ = 1, 2 do
        pcall(function()
            local clientNet = require(Library.Client.Network)
            if clientNet and clientNet.Fire then
                clientNet.Fire("Breakables_PlayerDealDamage", targetId)
            end
        end)
        pcall(function()
            local remote = Network:FindFirstChild("Breakables_PlayerDealDamage")
            if remote then
                remote:FireServer(targetId)
            end
        end)
    end

    firePrimaryClick()
    return true
end

function damageBreakableByName(breakable)
    if not breakable then
        return false
    end

    local targetName = tostring(breakable.Name or "")
    if targetName == "" then
        return false
    end

    setEquippedPetsTarget(targetName)

    for _ = 1, 2 do
        pcall(function()
            local clientNet = require(Library.Client.Network)
            if clientNet and clientNet.Fire then
                clientNet.Fire("Breakables_PlayerDealDamage", targetName)
            end
        end)
        pcall(function()
            local remote = Network:FindFirstChild("Breakables_PlayerDealDamage")
            if remote then
                remote:FireServer(targetName)
            end
        end)
    end

    firePrimaryClick()
    return true
end

function sweepNearbyOrbs(maxDistance)
    pcall(function()
        local hrp = getHumanoidRootPart()
        if not hrp then return end
        local things = Workspace:FindFirstChild("__THINGS")
        local orbsFolder = things and things:FindFirstChild("Orbs")
        if not orbsFolder then return end

        local charPos = hrp.Position
        local count = 0
        for _, orb in ipairs(orbsFolder:GetChildren()) do
            if orb:IsA("BasePart") then
                local dist = (charPos - orb.Position).Magnitude
                if dist <= (maxDistance or 120) and dist > 15 then
                    hrp.CFrame = orb.CFrame + Vector3.new(0, 1.5, 0)
                    task.wait(0.03)
                    count = count + 1
                    if count >= 6 then break end
                end
            end
        end
    end)
end

function autoBuyAreaUpgrades()
    local ok = pcall(function()
        local upgradeCmds = require(Library.Client.UpgradeCmds)
        local currencyCmds = require(Library.Client.CurrencyCmds)
        local directory = require(Library.Directory)

        local diamonds = currencyCmds.Get("Diamonds") or 0
        if diamonds <= 0 then return end

        local all = upgradeCmds.All()
        if not all or #all == 0 then return end

        local hrp = getHumanoidRootPart()
        if not hrp then return end

        for _, upg in ipairs(all) do
            if upg.Model and upgradeCmds.CanInteractWith(upg.UpgradeID, upg.ZoneID) then
                local dirInfo = directory.Upgrades[upg.UpgradeID]
                local cost = (dirInfo and dirInfo.TierCosts and dirInfo.TierCosts[upg.UpgradeTier]) or 0
                if diamonds >= cost and cost > 0 then
                    local origCFrame = hrp.CFrame
                    local padPivot = upg.Model:GetPivot()
                    hrp.CFrame = padPivot + Vector3.new(0, 3, 0)
                    task.wait(0.25)
                    local bought = upgradeCmds.Purchase(upg.UpgradeID, upg.ZoneID)
                    task.wait(0.15)
                    hrp.CFrame = origCFrame
                    if bought then
                        print(string.format("[Auto Farm] Purchased Upgrade: %s Tier %s in %s (%s Diamonds)", tostring(upg.UpgradeID), tostring(upg.UpgradeTier), tostring(upg.ZoneID), tostring(cost)))
                        notifyFlow("Upgrade Purchased", string.format("%s (%s) in %s", tostring(upg.UpgradeID), tostring(upg.UpgradeTier), tostring(upg.ZoneID)), 3)
                        diamonds = currencyCmds.Get("Diamonds") or 0
                    end
                    task.wait(0.1)
                end
            end
        end
    end)
    return ok
end

function autoUnlockAndHatchZoneEgg()
    local ok = pcall(function()
        local eggCmds = require(Library.Client.EggCmds)
        local eggsUtil = require(Library.Util.EggsUtil)
        local currencyCmds = require(Library.Client.CurrencyCmds)
        local directory = require(Library.Directory)
        local calcEggPrice = require(Library.Balancing.CalcEggPrice)

        local maxEggNum = eggCmds.GetHighestEggNumberAvailable()
        if not maxEggNum or maxEggNum <= 0 then return end

        local eggId = eggsUtil.GetIdByNumber(maxEggNum)
        if not eggId then return end

        local eggData = directory.Eggs[eggId]
        if not eggData then return end

        -- 1. Unlock egg if locked
        if eggCmds.IsEggLocked(eggId) then
            local unlocked = eggCmds.RequestUnlock(eggId)
            if unlocked then
                print(string.format("[Auto Farm] Unlocked Egg #%d (%s)!", maxEggNum, tostring(eggId)))
                notifyFlow("Egg Unlocked", string.format("Unlocked Egg #%d: %s", maxEggNum, tostring(eggId)), 3)
                task.wait(0.3)
            end
        end

        -- 2. Hatch egg if affordable
        if eggCmds.IsUnlocked(eggId) then
            local eggPrice = 0
            pcall(function()
                eggPrice = calcEggPrice(eggData) or 0
            end)

            local currentCoins = currencyCmds.Get("Coins") or 0
            if currentCoins >= eggPrice and eggPrice > 0 then
                local things = Workspace:FindFirstChild("__THINGS")
                local eggsFolder = things and things:FindFirstChild("Eggs") and things.Eggs:FindFirstChild("Main")
                local capsule = eggsFolder and eggsFolder:FindFirstChild(tostring(maxEggNum) .. " - Egg Capsule")

                local hrp = getHumanoidRootPart()
                if hrp and capsule then
                    local origCFrame = hrp.CFrame
                    hrp.CFrame = capsule:GetPivot() + Vector3.new(0, 3, 0)
                    task.wait(0.25)

                    local hatchCount = 1
                    local maxHatch = pcall(function() return eggCmds.GetMaxHatch() end) and eggCmds.GetMaxHatch() or 1
                    if currentCoins >= eggPrice * maxHatch * 3 then
                        hatchCount = maxHatch
                    end

                    local bought = eggCmds.RequestPurchase(eggId, hatchCount)
                    task.wait(0.2)
                    hrp.CFrame = origCFrame
                    if bought then
                        print(string.format("[Auto Farm] Hatched %d x Egg #%d (%s)!", hatchCount, maxEggNum, tostring(eggId)))
                        notifyFlow("Egg Hatched", string.format("Hatched %d x %s", hatchCount, tostring(eggId)), 3)
                    end
                end
            end
        end
    end)
    return ok
end

function teleportToRandomQuestBreakable(questTask, zoneInfo)
    local matches = getQuestMatchingBreakables(questTask, zoneInfo)
    if #matches == 0 and questTask and questTask.TargetKey == "luckyblock" then
        ensureLuckyBlocksInstance()
        matches = getQuestMatchingBreakables(questTask, zoneInfo)
    end

    if #matches == 0 then
        return nil
    end

    local choice = matches[BREAKABLE_RANDOM:NextInteger(1, #matches)]
    if teleportToBreakable(choice) then
        return choice
    end

    return nil
end

function pokeNearestBestAreaBreakable(zoneInfo)
    if not zoneInfo then
        return false
    end

    local things = Workspace:FindFirstChild("__THINGS")
    local breakablesFolder = things and things:FindFirstChild("Breakables")
    if not breakablesFolder then
        return false
    end

    local hrp = getHumanoidRootPart()
    local nearestMatching
    local nearestMatchingDistance = math.huge

    for _, breakable in ipairs(breakablesFolder:GetChildren()) do
        local targetPart = getBreakableTargetPart(breakable)
        if targetPart then
            local distance = (hrp.Position - targetPart.Position).Magnitude
            if breakableMatchesZone(breakable, zoneInfo) and distance <= 300 and distance < nearestMatchingDistance then
                nearestMatching = breakable
                nearestMatchingDistance = distance
            end
        end
    end

    if not nearestMatching then
        return false
    end

    return damageBreakable(nearestMatching)
end

function ensureLootbagCollector()
    if lootbagCollectorInstalled then
        return
    end

    local things = Workspace:WaitForChild("__THINGS")
    local lootbags = things:FindFirstChild("Lootbags")
    if not lootbags or not Network:FindFirstChild("Lootbags_Claim") then
        return
    end
    lootbagCollectorInstalled = true

    for _, lootbag in ipairs(lootbags:GetChildren()) do
        claimLootbag(lootbag)
        task.wait()
    end

    disconnectConnection(lootbagCollectorConnection)
    lootbagCollectorConnection = lootbags.ChildAdded:Connect(function(lootbag)
        task.wait()
        claimLootbag(lootbag)
    end)
end

function ensureOrbCollector()
    if orbCollectorInstalled then
        return
    end

    local things = Workspace:WaitForChild("__THINGS")
    local orbs = things:FindFirstChild("Orbs")
    if not orbs then
        return
    end
    orbCollectorInstalled = true

    disconnectConnection(orbCollectorConnection)
    orbCollectorConnection = orbs.ChildAdded:Connect(function(orb)
        task.wait()
        claimOrb(orb)
    end)
end

function disconnectWorldCollectors()
    disconnectConnection(lootbagCollectorConnection)
    disconnectConnection(orbCollectorConnection)
    lootbagCollectorConnection = nil
    orbCollectorConnection = nil
    lootbagCollectorInstalled = false
    orbCollectorInstalled = false
end

function ensureAntiIdle()
    if antiIdleInstalled then
        getgenv().antiAfkInstalled = true
        return
    end
    antiIdleInstalled = true
    getgenv().antiAfkInstalled = true

    pcall(function()
        local scripts = LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Scripts")
        local core = scripts:WaitForChild("Core")
        local idleTracking = core:FindFirstChild("Idle Tracking")
        if idleTracking then
            antiIdleRestoreState.IdleTracking = idleTracking
            antiIdleRestoreState.IdleTrackingEnabled = idleTracking.Enabled
            idleTracking.Enabled = false
        end
    end)

    if getconnections then
        for _, connection in ipairs(getconnections(LocalPlayer.Idled)) do
            if connection ~= antiIdleConnection and connection.Enabled ~= false and type(connection.Disable) == "function" then
                local ok = pcall(function()
                    connection:Disable()
                end)
                if ok then
                    table.insert(antiIdleRestoreState.DisabledConnections, connection)
                end
            end
        end
    end

    disconnectConnection(antiIdleConnection)
    antiIdleConnection = LocalPlayer.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
    end)
end

function disableAntiIdle()
    disconnectConnection(antiIdleConnection)
    antiIdleConnection = nil

    for _, connection in ipairs(antiIdleRestoreState.DisabledConnections) do
        if connection and type(connection.Enable) == "function" then
            pcall(function()
                connection:Enable()
            end)
        end
    end
    table.clear(antiIdleRestoreState.DisabledConnections)

    local idleTracking = antiIdleRestoreState.IdleTracking
    if idleTracking and idleTracking.Parent and type(antiIdleRestoreState.IdleTrackingEnabled) == "boolean" then
        pcall(function()
            idleTracking.Enabled = antiIdleRestoreState.IdleTrackingEnabled
        end)
    end
    antiIdleRestoreState.IdleTracking = nil
    antiIdleRestoreState.IdleTrackingEnabled = nil
    antiIdleInstalled = false
    getgenv().antiAfkInstalled = false
end

function getRequestFunction()
    local executorEnvironment = getgenv()
    local synApi = rawget(executorEnvironment, "syn")
    local synRequest = type(synApi) == "table" and rawget(synApi, "request") or nil
    return synRequest
        or rawget(executorEnvironment, "http_request")
        or rawget(executorEnvironment, "request")
end

local SERVER_HOP_MODULE_URL = "https://raw.githubusercontent.com/LeoKholYt/roblox/main/lk_serverhop.lua"

function serverHopWithModule()
    if not loadstring or not game.HttpGet then
        return false
    end

    local ok, module = pcall(function()
        return loadstring(game:HttpGet(SERVER_HOP_MODULE_URL, true))()
    end)

    if not ok or type(module) ~= "table" or type(module.Teleport) ~= "function" then
        warn("[ServerHop] Module server hop failed to load.")
        return false
    end

    local teleportOk, result = pcall(function()
        return module:Teleport(game.PlaceId)
    end)

    if not teleportOk or result == false then
        warn("[ServerHop] Module teleport failed: " .. tostring(result))
        return false
    end

    return true
end

function serverHop()
    if serverHopWithModule() then
        return true
    end

    local req = getRequestFunction()
    if not req then
        warn("No supported http request method found. Cannot server hop.")
        return false
    end

    local cursor = ""
    local servers = {}
    local checkedPages = 0

    while checkedPages < 5 do
        checkedPages = checkedPages + 1
        local okRequest, response = pcall(req, {
            Url = string.format(
                "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=2&limit=100&cursor=%s",
                game.PlaceId,
                cursor
            ),
            Method = "GET"
        })

        if not okRequest or not response or response.Success == false or not response.Body then
            break
        end

        local ok, data = pcall(function()
            return HttpService:JSONDecode(response.Body)
        end)
        if not ok or not data or not data.data then
            break
        end

        for _, server in ipairs(data.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                table.insert(servers, server.id)
            end
        end

        if not data.nextPageCursor then
            break
        end
        cursor = data.nextPageCursor
    end

    if #servers == 0 then
        warn("No available servers found.")
        return false
    end

    TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], LocalPlayer)
    return true
end

function waitForAutomationDelay(duration, isRunning, generation)
    local deadline = os.clock() + math.max(tonumber(duration) or 0, 0)
    while os.clock() < deadline do
        if generation ~= automationCancellationGeneration
            or flowSessionGeneration ~= getgenv().FlowPS99Generation
            or (isRunning and not isRunning()) then
            return false
        end
        task.wait(math.min(0.25, math.max(deadline - os.clock(), 0.03)))
    end
    return generation == automationCancellationGeneration
        and flowSessionGeneration == getgenv().FlowPS99Generation
        and (isRunning == nil or isRunning())
end

function waitForRunningDelay(duration, isRunning)
    local generation = automationThreadState.Generations[coroutine.running()]
        or automationCancellationGeneration
    return waitForAutomationDelay(duration, isRunning, generation)
end

function isAutomationContextCurrent()
    if flowSessionGeneration ~= getgenv().FlowPS99Generation then
        return false
    end
    local workerThread = coroutine.running()
    local worker = automationThreadState.Workers[workerThread]
    local generation = automationThreadState.Generations[workerThread]
    local launchSerial = automationThreadState.Serials[workerThread]
    return (generation == nil or generation == automationCancellationGeneration)
        and (worker == nil or worker.Requested)
        and (worker == nil or launchSerial == nil or worker.Serial == launchSerial)
end

function serverHopUntilSuccess(reason, isRunning)
    local attempt = 0
    local retryDelay = 3
    local initialJobId = game.JobId
    local generation = automationCancellationGeneration

    while generation == automationCancellationGeneration
        and flowSessionGeneration == getgenv().FlowPS99Generation
        and (isRunning == nil or isRunning()) do
        attempt = attempt + 1
        print(string.format("[ServerHop] %s attempt #%d", tostring(reason or "Server hop"), attempt))

        local failed = false
        local connection
        connection = TeleportService.TeleportInitFailed:Connect(function(player)
            if player == LocalPlayer then
                failed = true
            end
        end)

        local ok = serverHop()
        if not waitForAutomationDelay(4, isRunning, generation) then
            disconnectConnection(connection)
            return false
        end

        if connection then
            connection:Disconnect()
        end

        if ok and not failed and game.JobId ~= initialJobId then
            return true
        end

        if ok and not failed then
            print("[ServerHop] Teleport requested. Waiting for Roblox to move servers.")
        else
            warn("[ServerHop] Attempt failed. Retrying.")
        end

        if not waitForAutomationDelay(retryDelay, isRunning, generation) then
            return false
        end
    end

    return false
end

function stopPetSimAutomations()
    invalidateAutomationWorkers()
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
    autoTapHeroesRunning = false
    autoSelectedMinigameRunning = false
    lowEndPerformanceRunning = false
    performancePassRunning = false

    getgenv().autoChest = false
    getgenv().autoShinyRelicRunning = false
    getgenv().autoChestRaidRunning = false
    getgenv().autoDigsite = false
    getgenv().autoFishing = false
    getgenv().autoFruits = false
    getgenv().autoBundles = false
    getgenv().autoEgg = false
    getgenv().autoBalloonChest = false
    autoEggHatcherRunning = false
    autoRNGRollRunning = false
    clearOwnedPetTargets()
    disconnectWorldCollectors()
    disableActiveAutoMine()
    restoreVisualState()
    restorePetSpeed()
    restoreCharacterState()
    restorePerformanceState()
    restoreFishingState()
    if TapHeroesAdapter then
        TapHeroesAdapter:Stop()
    end
end

function handleStaffDetected(player)
    if getgenv().STAFF_DETECTED or staffHopPending then
        return
    end

    getgenv().STAFF_DETECTED = true
    staffHopPending = true
    stopPetSimAutomations()

    local waitTime = Random.new():NextInteger(30, 60)
    local staffGeneration = automationCancellationGeneration
    print("[ANTI-STAFF] BIG Games staff (" .. player.Name .. ") detected. Server hopping in " .. tostring(waitTime) .. " seconds.")

    task.spawn(function()
        if not waitForAutomationDelay(waitTime, function()
            return getgenv().STAFF_DETECTED and staffHopPending
        end, staffGeneration) then
            return
        end
        if not serverHop() then
            LocalPlayer:Kick("[ANTI-STAFF] A BIG Games staff member joined and the script could not server hop.")
        end
    end)
end

function ensureAntiStaff()
    if antiStaffInstalled then
        return
    end
    antiStaffInstalled = true

    local function inspectPlayer(player)
        if player == LocalPlayer then
            return
        end

        local ok, isStaff = pcall(function()
            return player:IsInGroup(5060810)
        end)

        if ok and isStaff then
            handleStaffDetected(player)
        elseif not ok then
            warn("[ANTI-STAFF] Failed to inspect player: " .. player.Name)
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        inspectPlayer(player)
    end

    disconnectConnection(antiStaffConnection)
    antiStaffConnection = Players.PlayerAdded:Connect(inspectPlayer)
    print("[ANTI-STAFF] Monitoring enabled")
end

function runAutoWorldFarm()
    ensureAntiStaff()
    ensureLootbagCollector()
    ensureOrbCollector()
    ensurePetSpeed()

    local map = getCurrentMap()
    if not map then
        clearDiscoveryCache("maps")
        task.wait(1)
        map = getCurrentMap()
    end
    local zoneCmds = require(Library.Client.ZoneCmds)
    local rebirthCmds = require(Library.Client.RebirthCmds)
    local currentZoneKey

    if not map then
        warn("Map is not loaded for Auto World.")
        autoWorldFarmRunning = false
        return
    end

    local nextRebirthData = rebirthCmds.GetNextRebirth()
    local rebirthNumber = nextRebirthData and nextRebirthData.RebirthNumber
    local rebirthZone = nextRebirthData and nextRebirthData.ZoneNumberRequired

    local function isRunning()
        return (autoWorldFarmRunning or getgenv().autoWorldFarmRunning) and not getgenv().STAFF_DETECTED
    end

    local function teleportToOwnedZone(forceMove)
        local maxOk, zoneName, maxZoneData = pcall(zoneCmds.GetMaxOwnedZone)
        if not zoneName or not maxZoneData then
            local latestZone = getLatestUnlockedBestArea()
            if latestZone then
                zoneName = latestZone.Name
                maxZoneData = {
                    ZoneNumber = latestZone.Number
                }
            end
        end

        if not maxOk and not maxZoneData then
            return
        end

        local zoneKey = tostring(maxZoneData.ZoneNumber) .. "|" .. zoneName
        if not forceMove and currentZoneKey == zoneKey then
            return
        end
        currentZoneKey = zoneKey

        local zonePath = findZonePathByData(nil, maxZoneData.ZoneNumber, zoneName)
        if not zonePath or not zonePath:FindFirstChild("PERSISTENT") then
            warn("Failed to resolve zone path for " .. tostring(zoneName))
            return
        end

        local hrp = getHumanoidRootPart()
        hrp.CFrame = zonePath.PERSISTENT.Teleport.CFrame + Vector3.new(0, 10, 0)

        if not waitForZoneInteract(zonePath, isRunning) then
            return
        end
        local closestBreakZone = getClosestBreakZone(zonePath)
        if closestBreakZone then
            hrp.CFrame = closestBreakZone.CFrame + Vector3.new(0, 10, 0)
        end
    end

    teleportToOwnedZone(true)

    local lastTeleportAt = 0
    local lastUpgradeCheckAt = 0
    local lastEggCheckAt = 0
    local lastOrbSweepAt = 0

    while isRunning() do
        local maxOk, zoneName, maxZoneData = pcall(zoneCmds.GetMaxOwnedZone)
        if not zoneName or not maxZoneData then
            local latestZone = getLatestUnlockedBestArea()
            if latestZone then
                zoneName = latestZone.Name
                maxZoneData = {
                    ZoneNumber = latestZone.Number
                }
            end
        end

        local zoneLimit = tonumber(getgenv().autoWorldConfig and getgenv().autoWorldConfig.ZONE_TO_REACH) or 999
        if maxZoneData and maxZoneData.ZoneNumber and maxZoneData.ZoneNumber >= zoneLimit then
            print("[Auto Farm To End] Reached target zone: " .. tostring(zoneLimit))
            notifyFlow("Auto Farm To End", "Reached target zone: " .. tostring(zoneLimit), 4)
            break
        end

        local nextZoneName, nextZoneData = zoneCmds.GetNextZone()
        if nextZoneName then
            local purchased = false
            pcall(function()
                local clientNet = require(Library.Client.Network)
                if clientNet and clientNet.Invoke then
                    purchased = clientNet.Invoke("Zones_RequestPurchase", nextZoneName) == true
                else
                    local remote = Network:FindFirstChild("Zones_RequestPurchase")
                    if remote then
                        purchased = remote:InvokeServer(nextZoneName) == true
                    end
                end
            end)

            if purchased then
                print("[Auto Farm To End] Purchased zone: " .. tostring(nextZoneName))
                notifyFlow("Zone Purchased", "Unlocked " .. tostring(nextZoneName), 3)

                if getgenv().autoWorldConfig.AUTO_REBIRTH and rebirthZone and nextZoneData and nextZoneData.ZoneNumber >= rebirthZone then
                    pcall(function()
                        print("[Auto Farm To End] Rebirthing...")
                        local clientNet = require(Library.Client.Network)
                        if clientNet and clientNet.Invoke then
                            clientNet.Invoke("Rebirth_Request", tostring(rebirthNumber))
                        else
                            local remote = Network:FindFirstChild("Rebirth_Request")
                            if remote then
                                remote:InvokeServer(tostring(rebirthNumber))
                            end
                        end
                    end)
                    if not waitForRunningDelay(15, isRunning) then
                        break
                    end

                    nextRebirthData = rebirthCmds.GetNextRebirth()
                    rebirthNumber = nextRebirthData and nextRebirthData.RebirthNumber
                    rebirthZone = nextRebirthData and nextRebirthData.ZoneNumberRequired
                end

                teleportToOwnedZone(true)
                if getgenv().autoWorldConfig.AUTO_BUY_UPGRADES ~= false then
                    autoBuyAreaUpgrades()
                end
                if getgenv().autoWorldConfig.AUTO_HATCH_ZONE_EGG ~= false then
                    autoUnlockAndHatchZoneEgg()
                end
            else
                teleportToOwnedZone(false)
            end
        else
            teleportToOwnedZone(false)
        end

        local now = os.clock()
        if getgenv().autoWorldConfig.AUTO_BUY_UPGRADES ~= false and now - lastUpgradeCheckAt >= 15 then
            lastUpgradeCheckAt = now
            autoBuyAreaUpgrades()
        end
        if getgenv().autoWorldConfig.AUTO_HATCH_ZONE_EGG ~= false and now - lastEggCheckAt >= 15 then
            lastEggCheckAt = now
            autoUnlockAndHatchZoneEgg()
        end
        if getgenv().autoWorldConfig.SWEEP_ORBS ~= false and now - lastOrbSweepAt >= 6 then
            lastOrbSweepAt = now
            sweepNearbyOrbs(100)
        end

        local bestZone = getLatestUnlockedBestArea()
        if bestZone then
            local matches = getBreakableFarmMatchingBreakables(bestZone, { "Any" })
            if #matches > 0 then
                local choice = matches[BREAKABLE_RANDOM:NextInteger(1, #matches)]
                if choice and choice:IsA("Instance") then
                    local id = choice:GetAttribute("BreakableUID") or choice:GetAttribute("BreakableId") or choice.Name
                    setEquippedPetsTarget(id)
                    if getgenv().autoWorldConfig.MOVE_TO_BREAKABLES ~= false and now - lastTeleportAt >= (getgenv().autoWorldConfig.TELEPORT_INTERVAL or 1.2) then
                        teleportToBreakable(choice)
                        lastTeleportAt = now
                    end
                    if getgenv().autoWorldConfig.CLICK_BREAKABLES ~= false then
                        damageBreakable(choice)
                    end
                end
            else
                pokeNearestBestAreaBreakable(bestZone)
            end
        end

        if not waitForRunningDelay(0.2, isRunning) then
            break
        end
    end

    autoWorldFarmRunning = false
end

function runCurrentStageFarm()
    ensureAntiStaff()
    ensureLootbagCollector()
    ensureOrbCollector()
    ensurePetSpeed()

    local map = getCurrentMap()
    local zoneCmds = require(Library.Client.ZoneCmds)
    local _, zoneName, zoneData = pcall(zoneCmds.GetMaxOwnedZone)
    local latestZone = getLatestUnlockedBestArea()

    if latestZone then
        zoneName = latestZone.Name
        zoneData = {
            ZoneNumber = latestZone.Number
        }
    end

    local zonePath = latestZone and latestZone.Path or findZonePathByData(nil, zoneData and zoneData.ZoneNumber, zoneName)
    if not zonePath or not zonePath:FindFirstChild("PERSISTENT") then
        warn("Failed to find stage path for " .. tostring(zoneName))
        autoCurrentStageFarmRunning = false
        return
    end

    print("Auto farming current stage: " .. tostring(zoneName))

    local hrp = getHumanoidRootPart()
    hrp.CFrame = zonePath.PERSISTENT.Teleport.CFrame + Vector3.new(0, 10, 0)
    local closestBreakZone = getClosestBreakZone(zonePath)
    if closestBreakZone then
        hrp.CFrame = closestBreakZone.CFrame + Vector3.new(0, 10, 0)
    end

    local lastTeleportAt = 0
    local lastUpgradeCheckAt = 0
    local lastEggCheckAt = 0
    local lastOrbSweepAt = 0
    while (autoCurrentStageFarmRunning or getgenv().autoCurrentStageFarmRunning) and not getgenv().STAFF_DETECTED do
        local now = os.clock()
        if getgenv().autoWorldConfig.AUTO_BUY_UPGRADES ~= false and now - lastUpgradeCheckAt >= 15 then
            lastUpgradeCheckAt = now
            autoBuyAreaUpgrades()
        end
        if getgenv().autoWorldConfig.AUTO_HATCH_ZONE_EGG ~= false and now - lastEggCheckAt >= 15 then
            lastEggCheckAt = now
            autoUnlockAndHatchZoneEgg()
        end
        if getgenv().autoWorldConfig.SWEEP_ORBS ~= false and now - lastOrbSweepAt >= 6 then
            lastOrbSweepAt = now
            sweepNearbyOrbs(100)
        end

        local activeZone = latestZone or { Name = zoneName, FullName = zonePath.Name, Path = zonePath }
        local matches = getBreakableFarmMatchingBreakables(activeZone, { "Any" })
        if #matches > 0 then
            local choice = matches[BREAKABLE_RANDOM:NextInteger(1, #matches)]
            if choice and choice:IsA("Instance") then
                local id = choice:GetAttribute("BreakableUID") or choice:GetAttribute("BreakableId") or choice.Name
                setEquippedPetsTarget(id)
                if now - lastTeleportAt >= (getgenv().breakableFarmConfig.TELEPORT_INTERVAL or 1.2) then
                    teleportToBreakable(choice)
                    lastTeleportAt = now
                end
                damageBreakable(choice)
            end
        else
            pokeNearestBestAreaBreakable(activeZone)
        end

        task.wait(math.max(getgenv().autoStageFarmConfig.MOVE_DELAY, 0.1))
    end

    autoCurrentStageFarmRunning = false
end

function runAutoShinyRelic()
    ensureAntiStaff()

    local hrp = getHumanoidRootPart()
    local originalPosition = hrp.CFrame
    local activeInstances = Workspace:WaitForChild("__THINGS"):WaitForChild("__INSTANCE_CONTAINER"):WaitForChild("Active")

    local relicLookup = {}
    local relicResponse = {}
    pcall(function()
        relicResponse = Network.Relics_Request:InvokeServer()
    end)

    for relicId, relicData in pairs(relicResponse) do
        if type(relicId) == "number" then
            relicLookup[relicId] = relicData
        end
    end

    local saveData = require(Library).Save.Get()
    for _, collectedRelic in pairs(saveData.ShinyRelics or {}) do
        relicLookup[collectedRelic] = nil
    end

    local sortedRelicIds = {}
    for relicId in pairs(relicLookup) do
        table.insert(sortedRelicIds, relicId)
    end
    table.sort(sortedRelicIds)

    for _, relicId in ipairs(sortedRelicIds) do
        if not getgenv().autoShinyRelicRunning or getgenv().STAFF_DETECTED then
            break
        end

        local relicData = relicLookup[relicId]
        if relicData then
            if relicData.ParentType == 1 then
                local targetCFrame = toCFrame(relicData.Position)
                if targetCFrame then
                    hrp.CFrame = targetCFrame
                end

                repeat
                    task.wait()
                until not getgenv().autoShinyRelicRunning
                    or getgenv().STAFF_DETECTED
                    or Network.Relic_Found:InvokeServer(relicId)

                if not getgenv().autoShinyRelicRunning or getgenv().STAFF_DETECTED then
                    break
                end
                print("Found relic: " .. tostring(relicId))
            elseif relicData.ParentType == 2 then
                local instanceFolder = Workspace.__THINGS.Instances:FindFirstChild(relicData.ParentId)
                local instanceTeleports = instanceFolder and instanceFolder:FindFirstChild("Teleports")
                local enterTeleport = instanceTeleports and instanceTeleports:FindFirstChild("Enter")
                local leaveTeleport = instanceTeleports and instanceTeleports:FindFirstChild("Leave")
                local relicCFrame = toCFrame(relicData.Position)

                if enterTeleport and leaveTeleport and relicCFrame then
                    repeat
                        hrp.CFrame = enterTeleport.CFrame
                        task.wait()
                    until activeInstances:FindFirstChild(relicData.ParentId)
                        or not getgenv().autoShinyRelicRunning
                        or getgenv().STAFF_DETECTED

                    if not getgenv().autoShinyRelicRunning or getgenv().STAFF_DETECTED then
                        break
                    end

                    hrp.CFrame = relicCFrame

                    repeat
                        task.wait()
                    until not getgenv().autoShinyRelicRunning
                        or getgenv().STAFF_DETECTED
                        or Network.Relic_Found:InvokeServer(relicId)

                    print("Found relic " .. tostring(relicId) .. " in instance " .. tostring(relicData.ParentId))

                    repeat
                        hrp.CFrame = leaveTeleport.CFrame
                        task.wait()
                    until not activeInstances:FindFirstChild(relicData.ParentId)
                        or not getgenv().autoShinyRelicRunning
                        or getgenv().STAFF_DETECTED
                end
            end
        end
    end

    hrp.CFrame = originalPosition
    getgenv().autoShinyRelicRunning = false
end

function findDigsiteBlock()
    local digsite = getActiveInstanceFolder("Digsite")
    local important = digsite and digsite:FindFirstChild("Important")
    local activeBlocks = important and important:FindFirstChild("ActiveBlocks")
    if not activeBlocks then
        return nil
    end

    local closestDistance = math.huge
    local closestBlock

    for _, block in ipairs(activeBlocks:GetChildren()) do
        if block:IsA("BasePart") then
            local distance = (getHumanoidRootPart().Position - block.Position).Magnitude
            if distance < closestDistance then
                closestDistance = distance
                closestBlock = block
            end
        end
    end

    return closestBlock
end

function findDigsiteChest()
    local digsite = getActiveInstanceFolder("Digsite")
    local important = digsite and digsite:FindFirstChild("Important")
    local activeChests = important and important:FindFirstChild("ActiveChests")
    if not activeChests then
        return nil
    end

    local closestDistance = math.huge
    local closestChest

    for _, chest in ipairs(activeChests:GetChildren()) do
        local top = chest:IsA("Model") and chest:FindFirstChild("Top")
        if top then
            local distance = (getHumanoidRootPart().Position - top.Position).Magnitude
            if distance < closestDistance then
                closestDistance = distance
                closestChest = chest
            end
        end
    end

    return closestChest
end

function optimizeDigsite()
    pcall(function()
        local digsite = getActiveInstanceFolder("Digsite")
        if not digsite then
            return
        end

        for _, item in ipairs(digsite:GetChildren()) do
            if string.find(item.Name, "hill")
                or string.find(item.Name, "Flower")
                or string.find(item.Name, "rock")
                or string.find(item.Name, "Meshes")
                or string.find(item.Name, "Sign")
                or string.find(item.Name, "Wood")
                or item.Name == "Model" then
                hideVisualTree(item, "Digsite")
            end
        end

        local alwaysRendering = Workspace:FindFirstChild("ALWAYS_RENDERING")
        if alwaysRendering then
            hideVisualTree(alwaysRendering, "Digsite")
        end
    end)
end

function runAutoDigsite()
    if getgenv().antiAfkConfig.ENABLED then
        ensureAntiIdle()
    end
    ensureAntiStaff()

    while autoDigsiteRunning and not getgenv().STAFF_DETECTED do
        if not isInstanceActive("Digsite") then
            enterInstance("Digsite")
            if not waitForRunningDelay(math.max(getgenv().autoInstanceConfig.ENTER_DELAY, 0.5), function()
                return autoDigsiteRunning and not getgenv().STAFF_DETECTED
            end) then
                break
            end
        end

        if isInstanceActive("Digsite") then
            runAutoMineModuleStep("Digsite")
        end

        if not waitForRunningDelay(math.max(getgenv().autoDigsiteConfig.MODULE_DELAY, 0.5), function()
            return autoDigsiteRunning and not getgenv().STAFF_DETECTED
        end) then
            break
        end
    end

    disableActiveAutoMine()
    restoreVisualState("Digsite")

    autoDigsiteRunning = false
    getgenv().autoDigsite = false
end

function clearCharacterVisuals(character, owner)
    for _, descendant in ipairs(character:GetDescendants()) do
        if descendant:IsA("BasePart") or descendant:IsA("Decal") then
            setRestorableProperty(owner, descendant, "Transparency", 1)
        end
    end
end

function hideVisualTree(root, owner)
    if not root then
        return false
    end

    for _, descendant in ipairs(root:GetDescendants()) do
        if descendant:IsA("BasePart") or descendant:IsA("Decal") or descendant:IsA("Texture") then
            setRestorableProperty(owner, descendant, "Transparency", 1)
        elseif descendant:IsA("ParticleEmitter")
            or descendant:IsA("Trail")
            or descendant:IsA("Beam")
            or descendant:IsA("Smoke")
            or descendant:IsA("Fire")
            or descendant:IsA("Sparkles") then
            setRestorableProperty(owner, descendant, "Enabled", false)
        end
    end

    return true
end

function optimizeFishing()
    local advancedFishing = getActiveInstanceFolder("AdvancedFishing")
    if not advancedFishing then
        return false
    end

    pcall(function()
        for _, item in ipairs(advancedFishing:GetChildren()) do
            if string.find(item.Name, "Model")
                or string.find(item.Name, "Water")
                or string.find(item.Name, "Debris") then
                hideVisualTree(item, "FishingWorld")
            end
        end

        local alwaysRendering = Workspace:FindFirstChild("ALWAYS_RENDERING")
        if alwaysRendering then
            hideVisualTree(alwaysRendering, "FishingWorld")
        end
    end)

    if getgenv().autoFishingConfig.HIDE_PLAYER then
        local trackingGeneration = fishingVisualGeneration
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character then
                clearCharacterVisuals(player.Character, "FishingPlayers")
            end
        end

        if not petVisualPlayerConnection then
            local function trackPlayer(player)
                if trackingGeneration ~= fishingVisualGeneration
                    or not getgenv().autoFishingConfig.HIDE_PLAYER then
                    return
                end
                if player.Character then
                    clearCharacterVisuals(player.Character, "FishingPlayers")
                end
                local connection = player.CharacterAdded:Connect(function(character)
                    if trackingGeneration == fishingVisualGeneration
                        and getgenv().autoFishingConfig.HIDE_PLAYER then
                        clearCharacterVisuals(character, "FishingPlayers")
                    end
                end)
                table.insert(fishingCharacterConnections, connection)
            end
            for _, player in ipairs(Players:GetPlayers()) do
                trackPlayer(player)
            end
            petVisualPlayerConnection = Players.PlayerAdded:Connect(trackPlayer)
        end
    else
        restoreFishingPlayerState()
    end

    return true
end

function restoreFishingPlayerState()
    fishingVisualGeneration = fishingVisualGeneration + 1
    disconnectConnection(petVisualPlayerConnection)
    petVisualPlayerConnection = nil
    for _, connection in ipairs(fishingCharacterConnections) do
        disconnectConnection(connection)
    end
    table.clear(fishingCharacterConnections)
    restoreVisualState("FishingPlayers")
end

function restoreFishingState()
    restoreFishingPlayerState()
    restoreVisualState("FishingWorld")
end

function findMatchingBobber(bobbers, castVector)
    for _, bobberModel in ipairs(bobbers:GetChildren()) do
        local bobber = bobberModel:FindFirstChild("Bobber")
        if bobber and math.abs(bobber.Position.X - castVector.X) <= 0.5 and math.abs(bobber.Position.Z - castVector.Z) <= 0.5 then
            return bobber
        end
    end
    return nil
end

function runAutoFishing()
    if getgenv().antiAfkConfig.ENABLED then
        ensureAntiIdle()
    end
    ensureAntiStaff()

    while autoFishingRunning and not getgenv().STAFF_DETECTED do
        local instanceName = table.find(instanceValues, "FishingEvent") and "FishingEvent" or "AdvancedFishing"
        if not isInstanceActive(instanceName) then
            enterInstance(instanceName)
            if not waitForRunningDelay(math.max(getgenv().autoInstanceConfig.ENTER_DELAY, 0.5), function()
                return autoFishingRunning and not getgenv().STAFF_DETECTED
            end) then
                break
            end
        end

        if isInstanceActive(instanceName) then
            if getgenv().autoFishingConfig.OPTIMIZE_GAME and instanceName == "AdvancedFishing" then
                pcall(optimizeFishing)
            end
            runFishingMinigameStep(instanceName)
        end

        if not waitForRunningDelay(math.max(getgenv().autoFishingConfig.MODULE_DELAY, 0.5), function()
            return autoFishingRunning and not getgenv().STAFF_DETECTED
        end) then
            break
        end
    end

    autoFishingRunning = false
    getgenv().autoFishing = false
    restoreFishingState()
end

function getBigChestZones()
    local candidates = {
        "Beach",
        "Underworld",
        "No Path Forest",
        "Heaven Gates",
        "Cuboid Canyon"
    }
    local zones = {}
    for _, zoneName in ipairs(candidates) do
        if findZonePathByName(nil, zoneName) then
            table.insert(zones, zoneName)
        end
    end

    return zones
end

function getActiveInstanceFolder(instanceName)
    local things = Workspace:FindFirstChild("__THINGS")
    local container = things and things:FindFirstChild("__INSTANCE_CONTAINER")
    local active = container and container:FindFirstChild("Active")
    return active and active:FindFirstChild(instanceName)
end

function getCurrentActiveInstanceName()
    local things = Workspace:FindFirstChild("__THINGS")
    local container = things and things:FindFirstChild("__INSTANCE_CONTAINER")
    local active = container and container:FindFirstChild("Active")
    if active then
        local child = active:FindFirstChildWhichIsA("Folder") or active:FindFirstChildWhichIsA("Model")
        if child then
            return child.Name
        end
    end

    local instanceCmds = getInstanceCmds and getInstanceCmds()
    if type(instanceCmds) == "table" and type(instanceCmds.All) == "function" and type(instanceCmds.IsInInstance) == "function" then
        local ok, instances = pcall(instanceCmds.All)
        if ok and type(instances) == "table" then
            for _, instanceName in ipairs(instances) do
                local isOk, activeResult = pcall(function()
                    return instanceCmds.IsInInstance(instanceName)
                end)
                if isOk and activeResult == true then
                    return tostring(instanceName)
                end
            end
        end
    end

    return nil
end

function getInstanceCmds()
    return requireClientModule("InstancingCmds")
end

function isInstanceAvailable(instanceName)
    local things = Workspace:FindFirstChild("__THINGS")
    local instances = things and things:FindFirstChild("Instances")
    if instances and instances:FindFirstChild(instanceName) then
        return true
    end

    local instanceCmds = getInstanceCmds()
    if type(instanceCmds) == "table" and type(instanceCmds.All) == "function" then
        local ok, available = pcall(instanceCmds.All)
        if ok and type(available) == "table" then
            for _, candidate in ipairs(available) do
                if tostring(candidate) == tostring(instanceName) then
                    return true
                end
            end
        end
    end
    return false
end

function isInstanceActive(instanceName)
    if getActiveInstanceFolder(instanceName) then
        return true
    end

    local instanceCmds = getInstanceCmds()
    if type(instanceCmds) == "table" and type(instanceCmds.IsInInstance) == "function" then
        local ok, result = pcall(function()
            return instanceCmds.IsInInstance(instanceName)
        end)
        if ok and result == true then
            return true
        end
    end

    if instanceName == "SoccerEvent" then
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local yeetMain = playerGui and playerGui:FindFirstChild("YeetMain")
        if yeetMain and yeetMain.Enabled == true then
            return true
        end
    end

    return false
end

function waitForInstanceActive(instanceName, timeout)
    local started = os.clock()
    timeout = math.max(tonumber(timeout) or 1, 0.1)
    while os.clock() - started <= timeout do
        if isInstanceActive(instanceName) then
            return true
        end
        task.wait(0.1)
    end
    return false
end

function requestModuleInstanceEnter(instanceName)
    local instanceCmds = getInstanceCmds()
    if type(instanceCmds) ~= "table" or type(instanceCmds.Enter) ~= "function" then
        return false
    end

    local ok, result = pcall(function()
        return instanceCmds.Enter(instanceName)
    end)
    return ok and result ~= false
end

function getInstanceRequirementStatus(instanceName)
    local instanceCmds = getInstanceCmds()
    if type(instanceCmds) ~= "table" or type(instanceCmds.DoesMeetRequirement) ~= "function" then
        return nil
    end

    local ok, result = pcall(function()
        return instanceCmds.DoesMeetRequirement(instanceName)
    end)
    if not ok or type(result) ~= "boolean" then
        return nil
    end

    if result == false and type(instanceCmds.GetRequirementMessage) == "function" then
        local messageOk, message = pcall(function()
            return instanceCmds.GetRequirementMessage(instanceName)
        end)
        if messageOk and message and tostring(message) ~= "" then
            return false, tostring(message)
        end
    end

    return result
end

function touchInstancePortal(instanceName, portalName)
    local things = Workspace:FindFirstChild("__THINGS")
    local instances = things and things:FindFirstChild("Instances")
    local instance = instances and instances:FindFirstChild(instanceName)
    local teleports = instance and instance:FindFirstChild("Teleports")
    if not teleports then
        return false
    end

    local character = LocalPlayer.Character
    local hrp = getHumanoidRootPart()
    local touchParts = {}
    if character then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                table.insert(touchParts, part)
            end
        end
    end

    local portalParts = {}
    local wantedPortal = tostring(portalName or "Enter"):lower()
    for _, part in ipairs(teleports:GetDescendants()) do
        if part:IsA("BasePart") then
            local partName = part.Name:lower()
            local exactName = partName == wantedPortal
            local teleportName = partName == (wantedPortal .. "teleport")
            local prefixedTeleport = partName:sub(1, #wantedPortal) == wantedPortal and partName:find("teleport", 1, true)
            if exactName or teleportName or prefixedTeleport then
                table.insert(portalParts, part)
            end
        end
    end
    table.sort(portalParts, function(a, b)
        return (hrp.Position - a.Position).Magnitude < (hrp.Position - b.Position).Magnitude
    end)

    local touched = false
    for _, part in ipairs(portalParts) do
        hrp.CFrame = part.CFrame + Vector3.new(0, math.max(part.Size.Y * 0.5 + 2, 4), 0)
        task.wait(0.15)
        if firetouchinterest then
            for _, touchPart in ipairs(touchParts) do
                pcall(function()
                    firetouchinterest(touchPart, part, 0)
                    task.wait()
                    firetouchinterest(touchPart, part, 1)
                end)
            end
        end
        if firesignal then
            for _, touchPart in ipairs(touchParts) do
                pcall(function()
                    firesignal(part.Touched, touchPart)
                end)
            end
        end
        pcall(function()
            hrp.CFrame = part.CFrame + Vector3.new(0, math.max(part.Size.Y * 0.5 + 0.5, 1), 0)
        end)
        touched = true
        task.wait(0.35)
        if portalName == "Leave" or isInstanceActive(instanceName) then
            break
        end
    end

    return touched
end

function invokeRemoteAny(remote, argSets)
    if not remote then
        return false
    end

    for _, args in ipairs(argSets) do
        local ok, result
        if remote:IsA("RemoteFunction") then
            ok, result = pcall(function()
                return remote:InvokeServer(unpack(args))
            end)
        else
            ok, result = pcall(function()
                remote:FireServer(unpack(args))
                return true
            end)
        end

        if ok and result ~= false then
            return true, result
        end
    end

    return false
end

function queueInstanceFailureServerHop(entryGeneration)
    if not getgenv().autoInstanceConfig.SERVER_HOP
        or entryGeneration ~= automationCancellationGeneration
        or flowSessionGeneration ~= getgenv().FlowPS99Generation then
        return false
    end

    task.spawn(function()
        if entryGeneration ~= automationCancellationGeneration
            or flowSessionGeneration ~= getgenv().FlowPS99Generation then
            return
        end
        serverHopUntilSuccess("Instance unavailable", function()
            return entryGeneration == automationCancellationGeneration
                and flowSessionGeneration == getgenv().FlowPS99Generation
        end)
    end)
    return true
end

function enterInstance(instanceName)
    local entryGeneration = automationCancellationGeneration
    if not instanceName or instanceName == "" or instanceName == "No instances found" then
        notifyFlow("Instance", "No instance selected.", 2.5)
        return false
    end

    if isInstanceActive(instanceName) then
        notifyFlow("Instance", instanceName .. " is already active.", 2.5)
        return true
    end

    local meetsRequirement, requirementMessage = getInstanceRequirementStatus(instanceName)
    if meetsRequirement == false then
        notifyFlow("Instance", requirementMessage or (tostring(instanceName) .. " is not available right now."), 2.5)
        queueInstanceFailureServerHop(entryGeneration)
        return false
    end

    local requested = requestModuleInstanceEnter(instanceName)

    local entered = invokeRemoteAny(Network:FindFirstChild("Instancing_PlayerEnterInstance"), {
        { instanceName },
        { instanceName, {} }
    })
    requested = requested or entered

    if waitForInstanceActive(instanceName, math.max(getgenv().autoInstanceConfig.ENTER_DELAY, 0.1)) then
        notifyFlow("Instance", "Entered " .. instanceName, 2.5)
        return true
    end

    if touchInstancePortal(instanceName, "Enter")
        and waitForInstanceActive(instanceName, math.max(getgenv().autoInstanceConfig.ENTER_DELAY, 0.25)) then
        notifyFlow("Instance", "Entered " .. instanceName, 2.5)
        return true
    end

    queueInstanceFailureServerHop(entryGeneration)

    if requested then
        getgenv().FlowPS99LastInstanceEntryFailed = {
            Instance = instanceName,
            Requested = true,
            Reason = "Entry request did not activate instance.",
            Time = os.clock()
        }
        notifyFlow("Instance", "Entry did not activate " .. instanceName, 2.5)
    else
        getgenv().FlowPS99LastInstanceEntryFailed = {
            Instance = instanceName,
            Requested = false,
            Reason = "No supported entry route responded.",
            Time = os.clock()
        }
        notifyFlow("Instance", "No entry route for " .. instanceName, 2.5)
    end

    return false
end

function leaveCurrentInstance()
    local instanceName = getCurrentActiveInstanceName() or selectedInstanceName
    local instanceCmds = getInstanceCmds()
    local requested = false

    if type(instanceCmds) == "table" and type(instanceCmds.Leave) == "function" then
        local ok, result = pcall(instanceCmds.Leave)
        requested = ok and result ~= false
    end

    local left = invokeRemoteAny(Network:FindFirstChild("Instancing_PlayerLeaveInstance"), {
        {},
        { instanceName }
    })
    requested = requested or left

    if not requested then
        left = invokeRemoteAny(Network:FindFirstChild("Instancing_ForceLeave"), {
            {},
            { instanceName }
        })
        requested = requested or left
    end

    local started = os.clock()
    while os.clock() - started <= math.max(getgenv().autoInstanceConfig.ENTER_DELAY, 0.5) do
        if not instanceName or instanceName == "" or not isInstanceActive(instanceName) then
            notifyFlow("Instance", "Left instance.", 2.5)
            return true
        end
        task.wait(0.1)
    end

    if instanceName and instanceName ~= "" and touchInstancePortal(instanceName, "Leave") then
        local leftAt = os.clock()
        while os.clock() - leftAt <= math.max(getgenv().autoInstanceConfig.ENTER_DELAY, 0.5) do
            if not isInstanceActive(instanceName) then
                notifyFlow("Instance", "Left instance.", 2.5)
                return true
            end
            task.wait(0.1)
        end
    end

    getgenv().FlowPS99LastInstanceLeaveFailed = {
        Instance = instanceName,
        Requested = requested,
        Reason = requested and "Leave request did not deactivate instance." or "No supported leave route responded.",
        Time = os.clock()
    }
    notifyFlow("Instance", requested and "Leave did not finish." or "No leave route found.", 2.5)
    return false
end

function getOwnedAbstractItem(classModuleName, itemName, tier)
    local itemsFolder = Library:FindFirstChild("Items")
    local classModule = itemsFolder and itemsFolder:FindFirstChild(classModuleName)
    if not classModule then
        return nil
    end
    local okClass, itemClass = pcall(require, classModule)
    if not okClass then
        return nil
    end
    local okQuery, query = pcall(function()
        return itemClass(itemName)
    end)
    if not okQuery or not query or type(query.FindAny) ~= "function" then
        return nil
    end
    if tier and type(query.SetTier) == "function" then
        local tierOk = pcall(function()
            query:SetTier(tier)
        end)
        if not tierOk then
            return nil
        end
    end
    local okFound, found = pcall(function()
        return query:FindAny()
    end)
    return okFound and type(found) == "table" and found[1] or nil
end

function getAbstractItemAmount(item)
    if not item then
        return 0
    end
    if type(item.GetAmount) == "function" then
        local ok, amount = pcall(function()
            return item:GetAmount()
        end)
        local numericAmount = tonumber(amount)
        if ok and numericAmount then
            return math.max(math.floor(numericAmount), 0)
        end
    end
    return math.max(math.floor(tonumber(item._am or item.Amount or item.amount) or 1), 0)
end

function useTapHeroesConsumable(itemName, amount, tier)
    local item = getOwnedAbstractItem("ConsumableItem", itemName, tier)
    local commands = requireClientModule("ConsumableCmds")
    if not item or type(commands) ~= "table" or type(commands.Consume) ~= "function" then
        return false
    end
    local count = math.min(math.max(math.floor(tonumber(amount) or 1), 1), getAbstractItemAmount(item))
    if count <= 0 then
        return false
    end
    local ok, result = pcall(function()
        return commands.Consume(item, count)
    end)
    return ok and result ~= false
end

function openTapHeroesGift(giftName, amount)
    local item = getOwnedAbstractItem("LootboxItem", giftName)
    local commands = requireClientModule("LootboxCmds")
    if not item or type(commands) ~= "table" or type(commands.Open) ~= "function" then
        return false
    end
    local count = math.min(math.max(math.floor(tonumber(amount) or 1), 1), getAbstractItemAmount(item))
    if count <= 0 then
        return false
    end
    local ok, result = pcall(function()
        return commands.Open(item, count)
    end)
    return ok and result ~= false
end

function openMarbleGifts(amount)
    return openTapHeroesGift("Marble Gift", amount)
end

function useSelectedTapHeroesConsumables()
    local selected = getgenv().tapHeroesConfig.CONSUMABLE or selectedTapHeroesConsumable
    local names = selected == TAP_HEROES_CONSUMABLE_ALL and tapHeroesConsumableValues or { selected }
    local used = false
    for _, label in ipairs(names) do
        local definition = tapHeroesConsumableDefinitions[label]
        if definition and useTapHeroesConsumable(
            definition.Name,
            getgenv().tapHeroesConfig.CONSUMABLE_AMOUNT,
            definition.Tier
        ) then
            used = true
            task.wait(0.1)
        end
    end
    return used
end

function openSelectedTapHeroesGift()
    local giftName = getgenv().tapHeroesConfig.GIFT or selectedTapHeroesGift
    return openTapHeroesGift(giftName, getgenv().tapHeroesConfig.GIFT_AMOUNT)
end

TapHeroesAdapter = {
    EnteredByAdapter = false,
    OriginalAutoTapper = nil,
    OriginalAutoAdvance = nil,
    AutoTapperChanged = false,
    AutoAdvanceChanged = false,
    LastAutoAdvance = nil,
    LastPollAt = 0,
    LastUpgradeAt = 0,
    LastPermanentUpgradeAt = 0,
    LastConsumableAt = 0,
    LastGiftAt = 0,
    LastBoostStatusAt = 0,
    CachedBoostStatus = {},
    LastStatusText = nil,
    LastUpgrade = nil,
    LastError = nil,
    BoostDefinitions = {
        { Id = "TapHeroesTapDamage", Name = "Tap Damage I" },
        { Id = "TapHeroesTapDamage2", Name = "Tap Damage II" },
        { Id = "TapHeroesLuck1", Name = "Luck I" },
        { Id = "TapHeroesLuck2", Name = "Luck II" },
        { Id = "TapHeroesLuck3", Name = "Luck III" },
        { Id = "TapHeroesFrenzy", Name = "Frenzy" },
        { Id = "TapHeroesChestLuck1", Name = "Chest Luck I" },
        { Id = "TapHeroesChestLuck2", Name = "Chest Luck II" }
    }
}

function TapHeroesAdapter:IsAvailable()
    local instanceCmds = getInstanceCmds()
    local eggs = getTapHeroesEggCandidates()
    return isInstanceAvailable("TapHeroes")
        and type(instanceCmds) == "table"
        and type(instanceCmds.Get) == "function"
        and #eggs > 0
end

function TapHeroesAdapter:GetInstance()
    local instanceCmds = getInstanceCmds()
    if type(instanceCmds) ~= "table" or type(instanceCmds.Get) ~= "function" then
        return nil
    end

    local ok, instance = pcall(function()
        return instanceCmds.Get()
    end)
    if not ok or type(instance) ~= "table" or instance.instanceID ~= "TapHeroes" then
        return nil
    end

    local active = isInstanceActive("TapHeroes")
    if type(instance.Active) == "function" then
        local activeOk, activeResult = pcall(function()
            return instance:Active()
        end)
        if activeOk and type(activeResult) == "boolean" then
            active = activeResult
        end
    end

    return active and instance or nil
end

function TapHeroesAdapter:FireCustom(command, ...)
    local instance = self:GetInstance()
    if not instance or type(instance.FireCustom) ~= "function" then
        self.LastError = "Tap Heroes is not the active instance."
        return false
    end

    local arguments = { ... }
    local ok, result = pcall(function()
        return instance:FireCustom(command, unpack(arguments))
    end)
    if not ok or result == false then
        self.LastError = ok and (tostring(command) .. " was rejected.") or tostring(result)
        return false
    end

    self.LastError = nil
    return true, result
end

function TapHeroesAdapter:Enter()
    if self:GetInstance() then
        return true
    end
    if not self:IsAvailable() then
        self.LastError = "Tap Heroes is unavailable in this game version."
        return false
    end

    local current = getCurrentActiveInstanceName()
    if current and current ~= "TapHeroes" then
        self.LastError = "Leave " .. tostring(current) .. " before entering Tap Heroes."
        return false
    end

    local instanceCmds = getInstanceCmds()
    if type(instanceCmds) ~= "table" or type(instanceCmds.Enter) ~= "function" then
        self.LastError = "InstancingCmds.Enter is unavailable."
        return false
    end

    if type(instanceCmds.DoesMeetRequirement) == "function" then
        local requirementOk, meetsRequirement = pcall(function()
            return instanceCmds.DoesMeetRequirement("TapHeroes")
        end)
        if requirementOk and meetsRequirement == false then
            self.LastError = "Tap Heroes entry requirement is not met."
            return false
        end
    end

    local requested = pcall(function()
        return instanceCmds.Enter("TapHeroes")
    end)
    if requested and waitForInstanceActive("TapHeroes", math.max(getgenv().autoInstanceConfig.ENTER_DELAY, 0.5)) then
        self.EnteredByAdapter = true
        self.LastError = nil
        return true
    end

    local enterRemote = Network:FindFirstChild("Instancing_PlayerEnterInstance")
    if enterRemote then
        requested = pcall(function()
            if enterRemote:IsA("RemoteFunction") then
                return enterRemote:InvokeServer("TapHeroes")
            end
            enterRemote:FireServer("TapHeroes")
            return true
        end)
        if requested and waitForInstanceActive("TapHeroes", math.max(getgenv().autoInstanceConfig.ENTER_DELAY, 0.5)) then
            self.EnteredByAdapter = true
            self.LastError = nil
            return true
        end
    end

    if touchInstancePortal("TapHeroes", "Enter")
        and waitForInstanceActive("TapHeroes", math.max(getgenv().autoInstanceConfig.ENTER_DELAY, 0.5)) then
        self.EnteredByAdapter = true
        self.LastError = nil
        return true
    end

    self.LastError = "Tap Heroes entry did not activate the instance."
    return false
end

function TapHeroesAdapter:PollState()
    local ok = self:FireCustom("HK_Read")
    if ok then
        self.LastPollAt = os.clock()
    end
    return ok
end

function TapHeroesAdapter:GetNativeAutoAdvanceState()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    local mainLeft = playerGui and playerGui:FindFirstChild("MainLeft")
    local left = mainLeft and mainLeft:FindFirstChild("Left")
    local tools = left and left:FindFirstChild("Tools")
    local button = tools and tools:FindFirstChild("AutoAdvance")
    local statusOn = button and button:FindFirstChild("StatusOn")
    local statusOff = button and button:FindFirstChild("StatusOff")
    if statusOn and statusOff and statusOn.Visible ~= statusOff.Visible then
        return statusOn.Visible == true
    end
    return nil
end

function normalizeTapHeroesProgress(currentZone, maxZone)
    currentZone = tonumber(currentZone)
    if not currentZone or currentZone ~= currentZone then
        currentZone = 0
    else
        currentZone = math.max(math.floor(currentZone), 0)
    end

    maxZone = tonumber(maxZone)
    if not maxZone or maxZone ~= maxZone then
        maxZone = 0
    else
        maxZone = math.max(math.floor(maxZone), 0)
    end

    return currentZone, math.max(maxZone, currentZone)
end

function TapHeroesAdapter:GetState()
    local currentZone = LocalPlayer:GetAttribute("TapHeroes_Zone")
    local maxZone = LocalPlayer:GetAttribute("TapHeroes_MaxZone")
    local rebirths = LocalPlayer:GetAttribute("TapHeroes_Rebirths")
    local autoAdvance = LocalPlayer:GetAttribute("TapHeroes_AutoAdvance")
    local bossFails = LocalPlayer:GetAttribute("TapHeroes_BossFails")
    local staged = LocalPlayer:GetAttribute("TapHeroes_Staged")
    local kills = LocalPlayer:GetAttribute("TapHeroes_Kills")
    local roundSize = LocalPlayer:GetAttribute("TapHeroes_RoundSize")
    local stateSynced = LocalPlayer:GetAttribute("TapHeroes_StateSynced")
    local saveData = getSaveData() or {}
    local eventState = type(saveData.TapHeroes) == "table" and saveData.TapHeroes or {}
    currentZone = tonumber(currentZone) or tonumber(eventState.CurrentZone or eventState.Zone) or 0
    maxZone = tonumber(maxZone) or tonumber(eventState.MaxZone or eventState.HighestZone) or 0
    currentZone, maxZone = normalizeTapHeroesProgress(currentZone, maxZone)
    rebirths = tonumber(rebirths) or tonumber(eventState.Rebirths) or 0
    if type(autoAdvance) ~= "boolean" then
        autoAdvance = eventState.AutoAdvance
    end
    if type(autoAdvance) ~= "boolean" then
        autoAdvance = self:GetNativeAutoAdvanceState()
    end
    if type(autoAdvance) ~= "boolean" then
        autoAdvance = self.LastAutoAdvance
    end

    return {
        CurrentZone = currentZone,
        MaxZone = maxZone,
        Rebirths = rebirths,
        BossFails = tonumber(bossFails) or 0,
        Staged = staged == true,
        Kills = tonumber(kills) or 0,
        RoundSize = tonumber(roundSize) or 0,
        StateSynced = stateSynced == true,
        MarbleCoins = getCurrencyAmount("MarbleCoins"),
        TapTokens = getCurrencyAmount("TapTokens"),
        TranscendTokens = getCurrencyAmount("Tap Rebirth Token"),
        EggTier = getTapHeroesUnlockedEggTier(),
        LatestEggTier = #getTapHeroesEggCandidates(),
        AutoAdvance = autoAdvance,
        AutoTapper = type(saveData.AutoTapper) == "boolean" and saveData.AutoTapper or nil
    }
end

function TapHeroesAdapter:SetAutoAdvance(enabled)
    enabled = enabled == true
    local state = self:GetState()
    if self.OriginalAutoAdvance == nil and type(state.AutoAdvance) == "boolean" then
        self.OriginalAutoAdvance = state.AutoAdvance
    end
    if self.LastAutoAdvance == enabled then
        return true
    end

    local ok = self:FireCustom("NR_Step", enabled)
    if ok then
        if type(self.OriginalAutoAdvance) == "boolean" and self.OriginalAutoAdvance ~= enabled then
            self.AutoAdvanceChanged = true
        end
        self.LastAutoAdvance = enabled
    end
    return ok
end

function TapHeroesAdapter:RestoreAutoAdvance()
    if self.AutoAdvanceChanged and type(self.OriginalAutoAdvance) == "boolean" and self:GetInstance() then
        self:FireCustom("NR_Step", self.OriginalAutoAdvance)
    end
    self.AutoAdvanceChanged = false
    self.OriginalAutoAdvance = nil
    self.LastAutoAdvance = nil
end

function TapHeroesAdapter:EnableAutoTranscend()
    local ok = self:FireCustom("CY_Loop", true)
    if ok then
        notifyFlow("Tap Heroes", "Native Auto Transcend enabled for this event run.", 3)
    else
        notifyFlow("Tap Heroes", self.LastError or "Could not enable Auto Transcend.", 3)
    end
    return ok
end

function TapHeroesAdapter:Transcend()
    local state = self:GetState()
    if state.MaxZone < 180 then
        self.LastError = "Transcend unlocks at Tap Heroes level 180."
        notifyFlow("Tap Heroes", self.LastError, 3)
        return false
    end
    local ok = self:FireCustom("EK_Seal")
    notifyFlow("Tap Heroes", ok and "Transcend requested." or (self.LastError or "Transcend failed."), 3)
    return ok
end

function TapHeroesAdapter:CanUnleashFrenzy()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    local tapperHud = playerGui and playerGui:FindFirstChild("TapperHud")
    local hud = tapperHud and tapperHud:FindFirstChild("HUD")
    local textFrame = hud and hud:FindFirstChild("Text")
    local progressBar = textFrame and textFrame:FindFirstChild("ProgressBar")
    local zone = progressBar and progressBar:FindFirstChild("Zone")
    return zone and zone:IsA("TextLabel") and zone.Text == "TAP TO UNLEASH!"
end

function TapHeroesAdapter:UnleashFrenzy()
    if not self:CanUnleashFrenzy() then
        return false
    end
    return self:FireCustom("WP_Burst")
end

function TapHeroesAdapter:EnterGauntlet()
    local state = self:GetState()
    if state.MaxZone < 180 then
        self.LastError = "Tap Gauntlet unlocks at level 180."
        notifyFlow("Tap Gauntlet", self.LastError, 3)
        return false
    end
    local entered = enterInstance("TapperVault")
    if not entered then
        self.LastError = "Tap Gauntlet entry failed. Check that you own a Marble Key."
        notifyFlow("Tap Gauntlet", self.LastError, 3)
        return false
    end
    self.LastError = nil
    return true
end

function TapHeroesAdapter:EnsureNativeAutoTapper()
    local saveData = getSaveData()
    local current = saveData and saveData.AutoTapper
    if type(current) ~= "boolean" then
        self.LastError = "Native Auto Tapper state is unavailable."
        return false
    end
    if self.OriginalAutoTapper == nil then
        self.OriginalAutoTapper = current
    end
    if current == true then
        return true
    end

    local clientNetwork = requireClientModule("Network")
    if type(clientNetwork) ~= "table" or type(clientNetwork.Invoke) ~= "function" then
        self.LastError = "Native Auto Tapper command is unavailable."
        return false
    end

    local ok, result = pcall(function()
        return clientNetwork.Invoke("AutoTapper_Toggle")
    end)
    if ok and result ~= false then
        self.AutoTapperChanged = true
        self.LastError = nil
        return true
    end

    self.LastError = ok and "Native Auto Tapper rejected the toggle." or tostring(result)
    return false
end

function TapHeroesAdapter:RestoreNativeAutoTapper()
    if not self.AutoTapperChanged or type(self.OriginalAutoTapper) ~= "boolean" then
        self.AutoTapperChanged = false
        self.OriginalAutoTapper = nil
        return
    end

    local saveData = getSaveData()
    local current = saveData and saveData.AutoTapper
    local clientNetwork = requireClientModule("Network")
    if type(current) == "boolean" and current ~= self.OriginalAutoTapper
        and type(clientNetwork) == "table" and type(clientNetwork.Invoke) == "function" then
        pcall(function()
            clientNetwork.Invoke("AutoTapper_Toggle")
        end)
    end
    self.AutoTapperChanged = false
    self.OriginalAutoTapper = nil
end

function TapHeroesAdapter:GetEventUpgradeDefinitions()
    local directory = Library:FindFirstChild("Directory")
    local moduleScript = directory and directory:FindFirstChild("EventUpgrades")
    if not moduleScript then
        return nil
    end
    local ok, definitions = pcall(require, moduleScript)
    return ok and type(definitions) == "table" and definitions or nil
end

function TapHeroesAdapter:ReadCurrencyCost(value, visited)
    if type(value) ~= "table" then
        return nil, nil
    end
    visited = visited or {}
    if visited[value] then
        return nil, nil
    end
    visited[value] = true

    local data = type(value._data) == "table" and value._data or value
    local currency = data.id or data.Id or data.ID or data.Currency or data.CurrencyId
    local amount = tonumber(data._am or data.Amount or data.amount or data.Value)
    if currency and amount and amount > 0 then
        return tostring(currency), amount
    end

    for _, nested in pairs(value) do
        if type(nested) == "table" then
            local nestedCurrency, nestedAmount = self:ReadCurrencyCost(nested, visited)
            if nestedCurrency and nestedAmount then
                return nestedCurrency, nestedAmount
            end
        end
    end
    return nil, nil
end

function TapHeroesAdapter:BuyUpgrade(upgradeId)
    if not self:GetInstance() then
        return false
    end
    local definitions = self:GetEventUpgradeDefinitions()
    local definition = definitions and definitions[upgradeId]
    local commands = requireClientModule("EventUpgradeCmds")
    if not definition or type(commands) ~= "table"
        or type(commands.GetTier) ~= "function" or type(commands.Purchase) ~= "function" then
        return false
    end

    local tierOk, tier = pcall(commands.GetTier, definition)
    tier = tierOk and math.max(math.floor(tonumber(tier) or 0), 0) or nil
    if tier == nil or tier >= #(definition.TierPowers or {}) then
        return false
    end

    local currency, cost = self:ReadCurrencyCost((definition.TierCosts or {})[tier + 1])
    local balance = currency and getCurrencyAmount(currency) or nil
    if not currency or not cost or balance == nil or balance < cost then
        return false
    end

    local ok, result = pcall(commands.Purchase, definition)
    if ok and result ~= false then
        self.LastUpgrade = upgradeId
        return true
    end
    return false
end

function TapHeroesAdapter:BuyUpgrades()
    for _, upgradeId in ipairs({
        "TapHeroesEggUpgrade",
        "TapHeroesCoinBonus",
        "TapHeroesClickDamage",
        "TapHeroesPetDamage"
    }) do
        if self:BuyUpgrade(upgradeId) then
            return true
        end
    end
    return false
end

function TapHeroesAdapter:BuyPermanentUpgrades()
    for _, upgradeId in ipairs({
        "TapHeroesPermPetDamage",
        "TapHeroesPermLuck",
        "TapHeroesFrenzyDamage"
    }) do
        if self:BuyUpgrade(upgradeId) then
            return true
        end
    end
    return false
end

function TapHeroesAdapter:GetBoostStatus()
    local commands = requireClientModule("BoostCmds")
    local status = {}
    for _, definition in ipairs(self.BoostDefinitions) do
        local timer
        if type(commands) == "table" and type(commands.GetTimer) == "function" then
            local timerOk, timerResult = pcall(commands.GetTimer, definition.Id)
            timer = timerOk and tonumber(timerResult) or nil
        end
        if timer and timer > 0 then
            local power
            if type(commands) == "table" and type(commands.GetPower) == "function" then
                local powerOk, powerResult = pcall(commands.GetPower, definition.Id)
                power = powerOk and tonumber(powerResult) or nil
            end
            local powerText = power and power > 0 and (" | x" .. tostring(power)) or ""
            table.insert(status, definition.Name .. " | " .. tostring(math.floor(timer)) .. "s" .. powerText)
        end
    end
    if #status == 0 then
        table.insert(status, "None")
    end
    return status
end

function TapHeroesAdapter:RefreshStatus(force)
    local available = self:IsAvailable()
    local active = self:GetInstance() ~= nil
    local state = self:GetState()
    local text = "Status: " .. (active and "Running" or (available and "Ready to enter" or "Unavailable"))
        .. "\nProgress: Zone " .. tostring(state.CurrentZone) .. "/" .. tostring(state.MaxZone)
        .. " | Egg " .. tostring(state.EggTier) .. "/" .. tostring(state.LatestEggTier)
        .. "\nWallet: " .. tostring(state.MarbleCoins or "?") .. " Marble Coins"
        .. " | " .. tostring(state.TapTokens or "?") .. " Tap Tokens"
        .. " | " .. tostring(state.TranscendTokens or "?") .. " Transcend Tokens"
    if self.LastError then
        text = text .. " | " .. tostring(self.LastError)
    end

    if force or os.clock() - self.LastBoostStatusAt >= 3 or #self.CachedBoostStatus == 0 then
        self.CachedBoostStatus = self:GetBoostStatus()
        self.LastBoostStatusAt = os.clock()
    end
    local boostStatus = self.CachedBoostStatus
    getgenv().FlowPS99TapHeroesStatus = {
        Available = available,
        Active = active,
        State = state,
        Boosts = boostStatus,
        Text = text,
        Time = os.clock()
    }
    local labelText = text .. "\nBoosts: " .. table.concat(boostStatus, ", ")
    pcall(function()
        if TapHeroesStatusLabel and TapHeroesStatusLabel.Parent and TapHeroesStatusLabel.Text ~= labelText then
            TapHeroesStatusLabel.Text = labelText
        end
    end)
    self.LastStatusText = labelText
    return getgenv().FlowPS99TapHeroesStatus
end

function TapHeroesAdapter:RunStep()
    if not self:IsAvailable() then
        self.LastError = "Tap Heroes is unavailable in this game version."
        self:RefreshStatus()
        return false
    end
    if not self:GetInstance() and getgenv().tapHeroesConfig.ENTER then
        self:Enter()
    end
    if not self:GetInstance() then
        self:RefreshStatus()
        return false
    end

    if os.clock() - self.LastPollAt >= 3 then
        self:PollState()
    end
    if getgenv().tapHeroesConfig.NATIVE_AUTO_TAP then
        self:EnsureNativeAutoTapper()
    end
    if getgenv().tapHeroesConfig.AUTO_ADVANCE then
        self:SetAutoAdvance(true)
    end
    if getgenv().tapHeroesConfig.AUTO_UPGRADES
        and os.clock() - self.LastUpgradeAt >= math.max(getgenv().tapHeroesConfig.UPGRADE_DELAY, 1) then
        self.LastUpgradeAt = os.clock()
        self:BuyUpgrades()
    end
    if getgenv().tapHeroesConfig.AUTO_PERMANENT_UPGRADES
        and os.clock() - self.LastPermanentUpgradeAt >= math.max(getgenv().tapHeroesConfig.UPGRADE_DELAY, 1) then
        self.LastPermanentUpgradeAt = os.clock()
        self:BuyPermanentUpgrades()
    end
    if getgenv().tapHeroesConfig.AUTO_HATCH then
        hatchLatestEggOnce()
    end
    if getgenv().tapHeroesConfig.AUTO_FRENZY then
        self:UnleashFrenzy()
    end
    if getgenv().tapHeroesConfig.AUTO_USE_CONSUMABLES
        and os.clock() - self.LastConsumableAt >= math.max(tonumber(getgenv().tapHeroesConfig.CONSUMABLE_DELAY) or 30, 5) then
        self.LastConsumableAt = os.clock()
        useSelectedTapHeroesConsumables()
    end
    if getgenv().tapHeroesConfig.AUTO_OPEN_GIFTS
        and os.clock() - self.LastGiftAt >= math.max(tonumber(getgenv().tapHeroesConfig.GIFT_DELAY) or 30, 5) then
        self.LastGiftAt = os.clock()
        openSelectedTapHeroesGift()
    end
    self:RefreshStatus()
    return true
end

function TapHeroesAdapter:Run()
    while autoTapHeroesRunning do
        local ok, err = pcall(function()
            self:RunStep()
        end)
        if not ok then
            self.LastError = tostring(err)
            self:RefreshStatus()
        end
        if not waitForRunningDelay(math.max(tonumber(getgenv().tapHeroesConfig.DELAY) or 1, 0.25), function()
            return autoTapHeroesRunning
        end) then
            break
        end
    end
end

function TapHeroesAdapter:Stop()
    autoTapHeroesRunning = false
    self:RestoreAutoAdvance()
    self:RestoreNativeAutoTapper()
    self:RefreshStatus()
end

function getInstanceChestClaimArgs(instanceName)
    local args = {}
    local active = getActiveInstanceFolder(instanceName)
    if not active then
        return args
    end

    local seen = {}
    for _, item in ipairs(active:GetDescendants()) do
        local nameKey = item.Name:lower()
        if nameKey:find("chest", 1, true) or nameKey:find("reward", 1, true) then
            for _, attr in ipairs({ "UID", "Uid", "ID", "Id", "ChestId", "ChestID", "RewardId", "RewardID" }) do
                local value = item:GetAttribute(attr)
                if value and not seen[tostring(value)] then
                    seen[tostring(value)] = true
                    table.insert(args, { value })
                    table.insert(args, { tostring(value) })
                end
            end
        end
    end

    return args
end

function claimInstanceChest(instanceName)
    local instanceChestArgs = getInstanceChestClaimArgs(instanceName)
    if #instanceChestArgs > 0 and invokeRemoteAny(Network:FindFirstChild("InstanceChests_Claim"), instanceChestArgs) then
        notifyFlow("Instance Chest", "Requested through InstanceChests_Claim", 2.5)
        return true
    end

    local raidArgSets = {
        { instanceName },
        { tostring(instanceName) },
        { instanceName, 1 },
        { tostring(instanceName), 1 }
    }
    for _, remoteName in ipairs({ "Raids_OpenChest", "Raids_CollectReward" }) do
        if invokeRemoteAny(Network:FindFirstChild(remoteName), raidArgSets) then
            notifyFlow("Instance Chest", "Requested through " .. remoteName, 2.5)
            return true
        end
    end

    local timeTrialArgSets = isInstanceActive(instanceName) and { { instanceName }, {} } or { { instanceName } }
    if invokeRemoteAny(Network:FindFirstChild("TimeTrials_OpenChest"), timeTrialArgSets) then
        notifyFlow("Instance Chest", "Requested through TimeTrials_OpenChest", 2.5)
        return true
    end

    notifyFlow("Instance Chest", "No supported claim route for " .. tostring(instanceName), 2.5)
    return false
end

function claimMinigameReward(instanceName)
    local routes = {
        ChestRush = {
            { Remote = "Raids_OpenChest", Args = { { instanceName }, { instanceName, 1 } } },
            { Remote = "Raids_CollectReward", Args = { { instanceName }, { instanceName, 1 } } }
        },
        BankHeist = {
            { Remote = "Raids_OpenChest", Args = { { instanceName }, { instanceName, 1 } } },
            { Remote = "Raids_CollectReward", Args = { { instanceName }, { instanceName, 1 } } }
        },
        ChestRaid = {
            { Remote = "Raids_OpenChest", Args = { { instanceName }, { instanceName, 1 } } },
            { Remote = "Raids_CollectReward", Args = { { instanceName }, { instanceName, 1 } } }
        },
        GrinchRaid = {
            { Remote = "Raids_OpenChest", Args = { { instanceName }, { instanceName, 1 } } },
            { Remote = "Raids_CollectReward", Args = { { instanceName }, { instanceName, 1 } } }
        },
        TimeTrial = {
            { Remote = "TimeTrials_OpenChest", Args = { { instanceName }, {} } }
        },
        TreasureHideout = {
            { Remote = "TreasureHideout_Unlock", Args = { {}, { instanceName } } }
        }
    }

    for _, route in ipairs(routes[instanceName] or {}) do
        local remote = Network:FindFirstChild(route.Remote)
        if remote and invokeRemoteAny(remote, route.Args) then
            notifyFlow("Minigame Reward", "Requested " .. tostring(instanceName) .. " reward.", 2.5)
            return true
        end
        task.wait(0.04)
    end

    return false
end

function callClientCommand(moduleName, methodName, argSets)
    local moduleValue = requireClientModule(moduleName)
    if type(moduleValue) ~= "table" or type(moduleValue[methodName]) ~= "function" then
        return false
    end

    for _, args in ipairs(argSets or { {} }) do
        local ok, result = pcall(function()
            return moduleValue[methodName](unpack(args))
        end)
        if not ok then
            ok, result = pcall(function()
                return moduleValue[methodName](moduleValue, unpack(args))
            end)
        end
        if ok and result ~= false then
            return true, result
        end
    end

    return false
end

local petDirectoryCache

function getPetDirectory()
    if petDirectoryCache then
        return petDirectoryCache
    end

    local directoryModule = Library:FindFirstChild("Directory") and Library.Directory:FindFirstChild("Pets")
    if not directoryModule then
        return nil
    end

    local ok, directory = pcall(require, directoryModule)
    if ok and type(directory) == "table" then
        petDirectoryCache = directory
        return directory
    end

    return nil
end

function getPetVariantScore(itemData)
    if type(itemData) ~= "table" then
        return 0
    end

    local score = 0
    if itemData.pt == 1 or itemData.g == true or itemData.Golden == true then
        score = score + 100
    elseif itemData.pt == 2 or itemData.r == true or itemData.Rainbow == true then
        score = score + 300
    end
    if itemData.sh == true or itemData.Shiny == true then
        score = score + 500
    end
    if itemData.tn == true or itemData.Titanic == true then
        score = score + 1000
    end

    return score
end

function getPetDamageScore(item)
    local itemName = getInventoryItemName(item.Data)
    local petCmds = requireClientModule("PetCmds")
    if type(petCmds) == "table" and type(petCmds.CalculateDamage) == "function" then
        local attempts = {
            { item.Uid },
            { item.Data },
            { item },
            { itemName }
        }
        for _, args in ipairs(attempts) do
            local ok, value = pcall(function()
                return petCmds.CalculateDamage(unpack(args))
            end)
            if ok and tonumber(value) then
                return tonumber(value)
            end
        end
    end

    local directory = getPetDirectory()
    local petData = directory and directory[itemName]
    if type(petData) == "table" then
        if type(petData.cachedPower) == "table" then
            local best = 0
            for _, value in pairs(petData.cachedPower) do
                best = math.max(best, tonumber(value) or 0)
            end
            if best > 0 then
                return best
            end
        end
        return tonumber(petData.zoneNumber or petData.cachedZoneNumber) or 0
    end

    return 0
end

function getPetRareScore(item)
    local itemName = getInventoryItemName(item.Data)
    local directory = getPetDirectory()
    local petData = directory and directory[itemName]
    local score = 0

    if type(petData) == "table" then
        if petData.gargantuan then
            score = score + 1000000000
        elseif petData.titanic then
            score = score + 500000000
        elseif petData.huge then
            score = score + 250000000
        elseif petData.exclusiveLevel or (petData.rarity and petData.rarity._id == "Exclusive") then
            score = score + 100000000
        end

        if type(petData.rarity) == "table" then
            score = score + ((tonumber(petData.rarity.RarityNumber) or 0) * 100000)
        end

        score = score + ((tonumber(petData.zoneNumber or petData.cachedZoneNumber) or 0) * 1000)
    end

    score = score + getPetVariantScore(item.Data)
    score = score + math.min(getPetDamageScore(item) / 1000000000, 999)
    return score
end

function getMaxEquippedPets()
    local ok, value = callClientCommand("PetCmds", "GetMaxEquipped", { {} })
    if ok and tonumber(value) then
        return tonumber(value)
    end

    local okStatus, equipped = pcall(function()
        return Network.Pets_GetEquipped:InvokeServer()
    end)
    if okStatus and type(equipped) == "table" then
        return math.max(#equipped, 1)
    end

    return 4
end

function equipPetItem(item)
    if not item or not item.Uid then
        return false
    end

    local uid = tostring(item.Uid)
    if callClientCommand("PetCmds", "Equip", {
        { uid },
        { item.Data },
        { item },
        { getInventoryItemName(item.Data) }
    }) then
        return true
    end

    local remote = Network:FindFirstChild("Pets_Equip")
    if invokeRemoteAny(remote, {
        { uid },
        { item.Data },
        { { uid } }
    }) then
        return true
    end

    return false
end

function equipBestPetsOnce(mode)
    local selectedMode = mode or getgenv().autoEquipBestPetsConfig.MODE or AUTO_EQUIP_DAMAGE_MODE
    if selectedMode == AUTO_EQUIP_DAMAGE_MODE then
        if callClientCommand("PetCmds", "EquipBest", { {}, { false }, { true } })
            or invokeRemoteAny(Network:FindFirstChild("Pets_EquipBest"), { {}, { false }, { true } }) then
            notifyFlow("Pets", "Equipped best damage pets.", 2.5)
            return true
        end
    end

    local pets = collectInventoryItems({ "Pet", "Pets" })
    if #pets == 0 then
        notifyFlow("Pets", "No pets found in inventory.", 2.5)
        return false
    end

    table.sort(pets, function(a, b)
        if selectedMode == AUTO_EQUIP_RARE_MODE then
            return getPetRareScore(a) > getPetRareScore(b)
        end
        return getPetDamageScore(a) > getPetDamageScore(b)
    end)

    callClientCommand("PetCmds", "UnequipAll", { {} })
    invokeRemoteAny(Network:FindFirstChild("Pets_LocalUnequipAll"), { {} })

    local equipped = 0
    local limit = math.max(getMaxEquippedPets(), 1)
    for _, item in ipairs(pets) do
        if equipped >= limit then
            break
        end
        if equipPetItem(item) then
            equipped = equipped + 1
            task.wait(0.05)
        end
    end

    notifyFlow("Pets", "Equipped " .. tostring(equipped) .. " pets by " .. tostring(selectedMode) .. ".", 2.5)
    return equipped > 0
end

function runAutoEquipBestPets()
    while autoEquipBestPetsRunning and not getgenv().STAFF_DETECTED do
        equipBestPetsOnce(getgenv().autoEquipBestPetsConfig.MODE)
        if not waitForRunningDelay(math.max(getgenv().autoEquipBestPetsConfig.DELAY, 5), function()
            return autoEquipBestPetsRunning and not getgenv().STAFF_DETECTED
        end) then
            break
        end
    end
    autoEquipBestPetsRunning = false
end

function getPetUids(limit)
    local pets = {}
    for _, item in ipairs(collectInventoryItems({ "Pet", "Pets" })) do
        if item.Uid then
            table.insert(pets, tostring(item.Uid))
            if limit and #pets >= limit then
                break
            end
        end
    end
    return pets
end

function claimDaycareOnce()
    local claimed = false
    if callClientCommand("DaycareCmds", "Claim", { {} }) then
        claimed = true
    elseif invokeRemoteAny(Network:FindFirstChild("Daycare: Claim"), { {} }) then
        claimed = true
    end

    if callClientCommand("ExclusiveDaycareCmds", "Claim", { {} }) then
        claimed = true
    elseif invokeRemoteAny(Network:FindFirstChild("Exclusive Daycare: Claim"), { {} }) then
        claimed = true
    end

    return claimed
end

function enrollDaycareOnce()
    local pets = getPetUids(getgenv().autoDaycareConfig.PET_LIMIT)
    if #pets == 0 then
        return false
    end

    local enrolled = false
    if getgenv().autoDaycareConfig.ENROLL_NORMAL then
        if callClientCommand("DaycareCmds", "Enroll", {
            { pets },
            { pets, 1 },
            { pets, "Default" },
            { pets[1] }
        }) or invokeRemoteAny(Network:FindFirstChild("Daycare: Enroll"), {
            { pets },
            { pets, 1 },
            { pets[1] }
        }) then
            enrolled = true
        end
    end

    if getgenv().autoDaycareConfig.ENROLL_EXCLUSIVE then
        if callClientCommand("ExclusiveDaycareCmds", "Enroll", {
            { pets },
            { pets, 1 },
            { pets[1] }
        }) or invokeRemoteAny(Network:FindFirstChild("Exclusive Daycare: Enroll"), {
            { pets },
            { pets, 1 },
            { pets[1] }
        }) then
            enrolled = true
        end
    end

    return enrolled
end

function runDaycareStep()
    local claimed = claimDaycareOnce()
    local enrolled = enrollDaycareOnce()
    if claimed or enrolled then
        notifyFlow("Auto Daycare", (claimed and "Claimed" or "Checked") .. " / " .. (enrolled and "enrolled pets" or "no enroll"), 2.5)
    end
    return claimed or enrolled
end

function runAutoDaycare()
    while autoDaycareRunning and not getgenv().STAFF_DETECTED do
        runDaycareStep()
        if not waitForRunningDelay(math.max(getgenv().autoDaycareConfig.DELAY, 5), function()
            return autoDaycareRunning and not getgenv().STAFF_DETECTED
        end) then
            break
        end
    end
    autoDaycareRunning = false
end

function getRoamingPetTargets()
    local targets = {}
    local things = Workspace:FindFirstChild("__THINGS")
    local folder = things and things:FindFirstChild("RoamingPets")
    if folder then
        for _, item in ipairs(folder:GetChildren()) do
            table.insert(targets, item.Name)
            for _, attr in ipairs({ "PetId", "PetID", "UID", "Id", "ID" }) do
                local value = item:GetAttribute(attr)
                if value then
                    table.insert(targets, tostring(value))
                end
            end
        end
    end

    local save = getSaveData()
    if save and type(save.RoamingPets) == "table" then
        for key, value in pairs(save.RoamingPets) do
            table.insert(targets, tostring(key))
            if type(value) == "table" then
                table.insert(targets, tostring(value.id or value.ID or value.uid or value.UID or ""))
            else
                table.insert(targets, tostring(value))
            end
        end
    end

    local clean = {}
    local added = {}
    for _, value in ipairs(targets) do
        local id = normalizeWhitespace(value)
        if id ~= "" and not added[id] then
            added[id] = true
            table.insert(clean, id)
        end
    end

    return clean
end

function catchRoamingPetsOnce()
    local caught = false
    for _, id in ipairs(getRoamingPetTargets()) do
        if invokeRemoteAny(Network:FindFirstChild("RoamingPets_CatchPet"), {
            { id },
            { tonumber(id) or id },
            { { id } }
        }) or invokeRemoteAny(Network:FindFirstChild("RoamingPets_CatchTimedPet"), {
            { id },
            { tonumber(id) or id },
            { { id } }
        }) then
            caught = true
        end
    end

    if caught then
        notifyFlow("Roaming Pets", "Catch request sent.", 2.5)
    end

    return caught
end

function runAutoRoamingPets()
    while autoRoamingPetsRunning and not getgenv().STAFF_DETECTED do
        catchRoamingPetsOnce()
        if not waitForRunningDelay(math.max(getgenv().autoRoamingPetsConfig.DELAY, 1), function()
            return autoRoamingPetsRunning and not getgenv().STAFF_DETECTED
        end) then
            break
        end
    end
    autoRoamingPetsRunning = false
end

function claimEventGoalsOnce()
    local remote = Network:FindFirstChild("EventGoals_Claim")
    if not remote then
        return false
    end

    local save = getSaveData()
    local goals = save and save.EventGoals
    if type(goals) ~= "table" then
        return false
    end

    local claimed = false
    local maxGoals = math.max(tonumber(getgenv().autoEventGoalsConfig.MAX_GOALS) or 12, 1)
    local eventGoalCmds = requireClientModule("EventGoalCmds")
    for eventId, eventData in pairs(goals) do
        local argSets = {}
        if type(eventGoalCmds) == "table" then
            local okIndex, setIndex = pcall(function()
                return eventGoalCmds.GetSetIndex(eventId)
            end)
            if okIndex and setIndex then
                local okClaimable, isClaimable = pcall(function()
                    return eventGoalCmds.IsSetClaimable(eventId, setIndex)
                end)
                if okClaimable and isClaimable then
                    table.insert(argSets, { eventId, setIndex })
                    table.insert(argSets, { tostring(eventId), setIndex })
                end
            end
        elseif type(eventData) == "table" and type(eventData.GoalProgress) == "table" then
            for i = 1, maxGoals do
                table.insert(argSets, { eventId, i })
                table.insert(argSets, { tostring(eventId), i })
            end
        end

        if #argSets > 0 and invokeRemoteAny(remote, argSets) then
            claimed = true
        end
    end

    if claimed then
        notifyFlow("Event Goals", "Claim request sent.", 2.5)
    end

    return claimed
end

function runAutoEventGoals()
    while autoEventGoalsRunning and not getgenv().STAFF_DETECTED do
        claimEventGoalsOnce()
        if not waitForRunningDelay(math.max(getgenv().autoEventGoalsConfig.DELAY, 3), function()
            return autoEventGoalsRunning and not getgenv().STAFF_DETECTED
        end) then
            break
        end
    end
    autoEventGoalsRunning = false
end

function refreshSoccerEventLists()
    local discoveredUpgrades = {}
    local eventUpgradeDirectory = Library:FindFirstChild("Directory") and Library.Directory:FindFirstChild("EventUpgrades")
    if eventUpgradeDirectory then
        local ok, definitions = pcall(require, eventUpgradeDirectory)
        if ok and type(definitions) == "table" then
            for upgradeId in pairs(definitions) do
                if tostring(upgradeId):find("Soccer", 1, true) == 1 then
                    table.insert(discoveredUpgrades, tostring(upgradeId))
                end
            end
        end
    end
    table.sort(discoveredUpgrades)
    if #discoveredUpgrades > 0 then
        table.clear(soccerUpgradeValues)
        table.insert(soccerUpgradeValues, SOCCER_UPGRADE_ALL)
        for _, upgradeId in ipairs(discoveredUpgrades) do
            table.insert(soccerUpgradeValues, upgradeId)
        end
    end

    local discoveredEggs = {}
    local seenEggs = {}
    local eggsFolder = getDirectoryFolder("Eggs")
    local eventsFolder = eggsFolder and eggsFolder:FindFirstChild("Events")
    local soccerFolder = eventsFolder and eventsFolder:FindFirstChild("Soccer")
    if soccerFolder then
        for _, moduleScript in ipairs(soccerFolder:GetDescendants()) do
            if moduleScript:IsA("ModuleScript") then
                local _, parsedName = parseEggLabel(moduleScript.Name)
                local ok, definition = pcall(require, moduleScript)
                local eggName = parsedName or (ok and type(definition) == "table" and (definition.name or definition.Name or definition._id or definition.id))
                eggName = normalizeWhitespace(eggName)
                if eggName ~= "" and not seenEggs[eggName] then
                    seenEggs[eggName] = true
                    table.insert(discoveredEggs, eggName)
                end
            end
        end
    end
    table.sort(discoveredEggs, function(a, b)
        local aEgg, aTier = a:match("Soccer Egg%s+(%d+)%s*Tier%s*(%d+)")
        local bEgg, bTier = b:match("Soccer Egg%s+(%d+)%s*Tier%s*(%d+)")
        aEgg = tonumber(aEgg or a:match("Soccer Egg%s+(%d+)")) or 0
        bEgg = tonumber(bEgg or b:match("Soccer Egg%s+(%d+)")) or 0
        aTier = tonumber(aTier) or 0
        bTier = tonumber(bTier) or 0
        if aEgg == bEgg then
            return aTier < bTier
        end
        return aEgg < bEgg
    end)
    if #discoveredEggs > 0 then
        table.clear(soccerEggValues)
        for _, eggName in ipairs(discoveredEggs) do
            table.insert(soccerEggValues, eggName)
        end
    end

    if not table.find(soccerUpgradeValues, selectedSoccerUpgrade) then
        selectedSoccerUpgrade = SOCCER_UPGRADE_ALL
        getgenv().autoSoccerEventConfig.UPGRADE = selectedSoccerUpgrade
    end
    if not table.find(soccerEggValues, selectedSoccerEgg) then
        selectedSoccerEgg = soccerEggValues[#soccerEggValues] or "Soccer Egg 8 Tier 6"
        getgenv().autoSoccerEventConfig.EGG = selectedSoccerEgg
    end
end

function getSelectedSoccerBoostNames()
    if selectedSoccerBoost == SOCCER_BOOST_ALL or getgenv().autoSoccerEventConfig.BOOST == SOCCER_BOOST_ALL then
        return { "Cleats", "Golden Cleats", "Soccer Orb Frenzy" }
    end
    return { getgenv().autoSoccerEventConfig.BOOST or selectedSoccerBoost }
end

function useSoccerBoostsOnce()
    local used = false
    for _, boostName in ipairs(getSelectedSoccerBoostNames()) do
        if boostName and boostName ~= "" and boostName ~= SOCCER_BOOST_ALL then
            if tryUseInventoryItem(boostName, 1, "boost") then
                used = true
                task.wait(0.15)
            end
        end
    end

    if used then
        notifyFlow("Soccer Event", "Soccer boost use requested.", 2.5)
    end
    return used
end

function getSelectedSoccerUpgradeNames()
    if selectedSoccerUpgrade == SOCCER_UPGRADE_ALL or getgenv().autoSoccerEventConfig.UPGRADE == SOCCER_UPGRADE_ALL then
        local names = {}
        for _, upgradeId in ipairs(soccerUpgradeValues) do
            if upgradeId ~= SOCCER_UPGRADE_ALL then
                table.insert(names, upgradeId)
            end
        end
        return names
    end
    return { getgenv().autoSoccerEventConfig.UPGRADE or selectedSoccerUpgrade }
end

function buySoccerUpgrade(upgradeName)
    if not upgradeName or upgradeName == "" or upgradeName == SOCCER_UPGRADE_ALL then
        return false
    end

    local now = os.clock()
    if now - (soccerUpgradeAttemptTimes[upgradeName] or 0) < 30 then
        return false
    end
    soccerUpgradeAttemptTimes[upgradeName] = now

    local directory = Library:FindFirstChild("Directory")
    local moduleScript = directory and directory:FindFirstChild("EventUpgrades")
    local okDefinitions = false
    local definitions
    if moduleScript then
        okDefinitions, definitions = pcall(require, moduleScript)
    end
    local definition = okDefinitions and type(definitions) == "table" and definitions[upgradeName] or nil
    local commands = requireClientModule("EventUpgradeCmds")
    if definition and type(commands) == "table" and type(commands.Purchase) == "function" then
        local ok, result = pcall(commands.Purchase, definition)
        if ok then
            return result ~= false
        end
    end
    return false
end

function buySoccerUpgradesOnce()
    local bought = false
    for _, upgradeName in ipairs(getSelectedSoccerUpgradeNames()) do
        if buySoccerUpgrade(upgradeName) then
            bought = true
            task.wait(0.2)
        end
    end

    if bought then
        notifyFlow("Soccer Event", "Upgrade purchase requested.", 2.5)
    end
    return bought
end

function getSoccerEggCandidates()
    local candidates = {}
    local seen = {}

    local function add(name)
        name = normalizeWhitespace(name)
        if name ~= "" and not seen[name] then
            seen[name] = true
            table.insert(candidates, name)
        end
    end

    add(getgenv().autoSoccerEventConfig.EGG)

    local active = getActiveInstanceFolder("SoccerEvent")
    local interact = active and active:FindFirstChild("INTERACT")
    if interact then
        for _, item in ipairs(interact:GetChildren()) do
            if item.Name:lower():find("egg", 1, true) or item.Name:lower():find("soccer", 1, true) then
                add(item.Name)
            end
        end
    end

    local directory = ReplicatedStorage:FindFirstChild("__DIRECTORY")
    local eggsFolder = directory and directory:FindFirstChild("Eggs")
    local eventsFolder = eggsFolder and eggsFolder:FindFirstChild("Events")
    local soccerFolder = eventsFolder and eventsFolder:FindFirstChild("Soccer")
    if soccerFolder then
        for _, item in ipairs(soccerFolder:GetChildren()) do
            local _, eggName = parseZoneLabel(item.Name)
            add(eggName or item.Name)
        end
    end

    for _, eggName in ipairs(soccerEggValues) do
        add(eggName)
    end
    return candidates
end

function getSoccerEggDirectoryData(eggName)
    local directory = ReplicatedStorage:FindFirstChild("__DIRECTORY")
    local eggsFolder = directory and directory:FindFirstChild("Eggs")
    if not eggsFolder then
        return nil
    end

    for _, item in ipairs(eggsFolder:GetDescendants()) do
        if item:IsA("ModuleScript") then
            local _, parsedName = parseZoneLabel(item.Name)
            if item.Name == eggName or parsedName == eggName then
                local ok, data = pcall(require, item)
                if ok and type(data) == "table" then
                    return data
                end
            end
        end
    end

    return nil
end

function hatchSoccerEggOnce()
    local amount = math.max(tonumber(getgenv().autoSoccerEventConfig.HATCH_AMOUNT) or 1, 1)
    local lastResult
    local lastEgg
    local lastRemote
    local preferredEgg = normalizeWhitespace(getgenv().autoSoccerEventConfig.EGG or "")

    for _, eggName in ipairs(getSoccerEggCandidates()) do
        lastEgg = eggName
        local eggData = getSoccerEggDirectoryData(eggName)
        local currencyName = eggData and eggData.currency
        local cost = tonumber(eggData and eggData.overrideCost)
        if currencyName and cost then
            local owned = getCurrencyAmount(currencyName)
            if owned and owned < cost * amount then
                lastResult = "Need " .. tostring(cost * amount) .. " " .. tostring(currencyName) .. " for " .. tostring(amount) .. "x " .. eggName .. " (owned " .. tostring(owned) .. ")"
                if eggName == preferredEgg then
                    break
                end
                continue
            end
        end

        lastRemote = eggData and eggData.isCustomEgg and "CustomEggs_Hatch" or "Eggs_RequestPurchase"
        local ok = hatchEggByName(eggName, amount)
        local hatchResult = getgenv().FlowPS99LastEggHatch or {}
        lastResult = hatchResult.Reason or hatchResult.Message or hatchResult.Result

        if ok then
            local actualAmount = tonumber(hatchResult.Amount) or amount
            getgenv().autoSoccerEventConfig.EGG = eggName
            getgenv().FlowPS99LastSoccerHatch = {
                Egg = eggName,
                Amount = actualAmount,
                Remote = hatchResult.Remote or lastRemote,
                Result = hatchResult.Result,
                Time = os.clock()
            }
            notifyFlow("Soccer Event", "Hatched " .. eggName .. " x" .. tostring(actualAmount), 2.5)
            return true
        end
    end

    getgenv().FlowPS99LastSoccerHatch = {
        Egg = lastEgg,
        Amount = amount,
        Remote = lastRemote,
        Result = lastResult,
        Reason = lastResult,
        Failed = true,
        Time = os.clock()
    }
    local warnKey = tostring(lastEgg) .. "|" .. tostring(lastResult)
    local now = os.clock()
    if now - (soccerHatchWarnTimes[warnKey] or 0) >= 30 then
        soccerHatchWarnTimes[warnKey] = now
        warn("[Soccer Event] Hatch failed: " .. tostring(lastResult))
    end
    return false
end

function collectExistingOrbsOnce()
    local things = Workspace:FindFirstChild("__THINGS")
    local collected = false
    local soccerOrbClaims = 0

    local active = getActiveInstanceFolder("SoccerEvent")
    local clientModule = active and active:FindFirstChild("ClientModule")
    local yeetOrbsModule = clientModule and clientModule:FindFirstChild("YeetOrbs")
    if yeetOrbsModule then
        local okModule, yeetOrbs = pcall(require, yeetOrbsModule)
        if okModule and type(yeetOrbs) == "table" and type(yeetOrbs.Claim) == "function" and debug and debug.getupvalues then
            local okUpvalues, upvalues = pcall(debug.getupvalues, yeetOrbs.Claim)
            if okUpvalues and type(upvalues) == "table" then
                for _, candidate in pairs(upvalues) do
                    if type(candidate) == "table" then
                        for uid, orbData in pairs(candidate) do
                            if type(orbData) == "table" and (orbData.UID or orbData.Model or orbData.Amount or orbData.Type) then
                                local okClaim = pcall(yeetOrbs.Claim, orbData.UID or uid)
                                if okClaim then
                                    collected = true
                                    soccerOrbClaims = soccerOrbClaims + 1
                                    task.wait()
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    for _, folderName in ipairs({ "Orbs", "MagicOrbs" }) do
        local folder = things and things:FindFirstChild(folderName)
        if folder then
            for _, orb in ipairs(folder:GetChildren()) do
                claimOrb(orb)
                collected = true
                task.wait()
            end
        end
    end

    if soccerOrbClaims > 0 then
        getgenv().FlowPS99LastSoccerOrbCollect = {
            Count = soccerOrbClaims,
            Route = "YeetOrbs.Claim",
            Time = os.clock()
        }
    end

    return collected
end

function getSoccerBreakableFolder()
    local active = getActiveInstanceFolder("SoccerEvent")
    if active then
        local things = active:FindFirstChild("__THINGS") or active:FindFirstChild("THINGS") or active
        local breakables = things:FindFirstChild("Breakables") or active:FindFirstChild("Breakables", true)
        if breakables then
            return breakables
        end
    end

    local instance = Workspace:FindFirstChild("__THINGS")
        and Workspace.__THINGS:FindFirstChild("Instances")
        and Workspace.__THINGS.Instances:FindFirstChild("SoccerEvent")
    return instance and instance:FindFirstChild("BREAKABLE_SPAWNS")
end

function damageSoccerBreakablesOnce()
    local breakables = getSoccerBreakableFolder()
    if not breakables then
        return false
    end

    local didAny = false
    for _, breakable in ipairs(breakables:GetChildren()) do
        local targetId = getBreakableTargetId(breakable) or breakable.Name
        if targetId and setEquippedPetsTarget(tostring(targetId)) then
            didAny = true
            task.wait(0.1)
        end
    end
    return didAny
end

function getSoccerThrowStrengthModule()
    local active = getActiveInstanceFolder("SoccerEvent")
    local clientModule = active and active:FindFirstChild("ClientModule")
    local throwStrength = clientModule and clientModule:FindFirstChild("ThrowStrengthGUI")
    if not throwStrength then
        return nil
    end

    local ok, moduleValue = pcall(require, throwStrength)
    if ok and type(moduleValue) == "table"
        and type(moduleValue.Hold) == "function"
        and type(moduleValue.Release) == "function" then
        return moduleValue
    end

    return nil
end

function normalizeSoccerKickPercent(rawPercent)
    rawPercent = tonumber(rawPercent)
    if not rawPercent then
        return nil
    end
    if rawPercent <= 1 then
        return rawPercent * 100
    end
    if rawPercent <= 4 then
        return (rawPercent / 4) * 100
    end
    return rawPercent
end

function runSoccerThrowStrengthKick(moduleValue)
    moduleValue = moduleValue or getSoccerThrowStrengthModule()
    if not moduleValue then
        return false
    end

    getgenv().FlowPS99LastSoccerKick = nil
    getgenv().FlowPS99LastSoccerKickBlocked = nil

    local target = math.clamp(tonumber(getgenv().autoSoccerEventConfig.PERFECT_KICK_TARGET) or 100, 1, 100)
    local releaseAt = target
    if target >= 99 then
        releaseAt = math.clamp(tonumber(getgenv().autoSoccerEventConfig.PERFECT_KICK_MIN_PERCENT) or 99, 95, target)
    end
    local timeout = math.clamp(tonumber(getgenv().autoSoccerEventConfig.PERFECT_KICK_WINDOW) or 4, 0.25, 8)
    local poll = math.clamp(tonumber(getgenv().autoSoccerEventConfig.PERFECT_KICK_POLL) or 0.03, 0.03, 0.25)
    if type(moduleValue.Reset) == "function" then
        pcall(moduleValue.Reset)
    end
    local okHold = pcall(moduleValue.Hold)
    if not okHold then
        return false
    end

    local started = os.clock()
    local bestPercent
    local bestRaw
    while os.clock() - started <= timeout do
        local okPercent, rawPercent = pcall(moduleValue.GetPercent)
        local percent = okPercent and normalizeSoccerKickPercent(rawPercent) or nil
        if percent then
            if not bestPercent or percent > bestPercent then
                bestPercent = percent
                bestRaw = rawPercent
            end
            if percent >= releaseAt then
                local okRelease, releaseResult = pcall(moduleValue.Release)
                if okRelease then
                    getgenv().FlowPS99LastSoccerKickBlocked = nil
                    getgenv().FlowPS99LastSoccerKick = {
                        Percent = percent,
                        RawPercent = rawPercent,
                        Target = target,
                        ReleaseAt = releaseAt,
                        Perfect = percent >= 99,
                        Route = "ThrowStrengthGUI",
                        Result = releaseResult,
                        Time = os.clock()
                    }
                    return true
                end
                return false
            end
        end
        if not bestPercent and os.clock() - started > math.min(timeout, 0.45) then
            break
        end
        task.wait(poll)
    end

    if bestPercent and bestPercent >= releaseAt then
        local okRelease, releaseResult = pcall(moduleValue.Release)
        if okRelease then
            getgenv().FlowPS99LastSoccerKickBlocked = nil
            getgenv().FlowPS99LastSoccerKick = {
                Percent = bestPercent,
                RawPercent = bestRaw,
                Target = target,
                ReleaseAt = releaseAt,
                Perfect = bestPercent >= 99,
                Route = "ThrowStrengthGUITimeout",
                Result = releaseResult,
                Time = os.clock()
            }
            return true
        end
        return false
    end

    if type(moduleValue.Reset) == "function" then
        pcall(moduleValue.Reset)
    end

    getgenv().FlowPS99LastSoccerKickBlocked = {
        Reason = bestPercent and "Perfect kick window missed before release." or "ThrowStrengthGUI percent was not available.",
        BestPercent = bestPercent,
        RawPercent = bestRaw,
        Target = target,
        ReleaseAt = releaseAt,
        Route = "ThrowStrengthGUI",
        Time = os.clock()
    }
    return false
end

function requestSoccerAutoKickOnce()
    local throwStrength = getSoccerThrowStrengthModule()
    if throwStrength then
        return runSoccerThrowStrengthKick(throwStrength)
    end

    local fired = false
    local invokeRemote = Network:FindFirstChild("Instancing_InvokeCustomFromClient")
    local fireRemote = Network:FindFirstChild("Instancing_FireCustomFromClient")
    local safeActions = {
        { "Auto", true },
        { "ToggleAuto", true },
        { "RequestAuto", true },
        { "Kick" },
        { "Yeet" },
        { "RequestKick" },
        { "RequestYeet" },
        { "SoccerKick" },
        { "SoccerYeet" },
        { "Clicked" },
        { "Click" }
    }

    for _, action in ipairs(safeActions) do
        local actionName = action[1]
        local extra = action[2]
        local args = extra == nil and { "SoccerEvent", actionName } or { "SoccerEvent", actionName, extra }
        if invokeRemote and invokeRemote:IsA("RemoteFunction") then
            local ok, result = pcall(function()
                return invokeRemote:InvokeServer(unpack(args))
            end)
            if ok and result ~= false then
                fired = true
            end
        end

        if fireRemote and fireRemote:IsA("RemoteEvent") then
            local ok = pcall(function()
                fireRemote:FireServer(unpack(args))
            end)
            if ok then
                fired = true
            end
        end
        task.wait(0.03)
    end

    return fired
end

function getGuiText(instance)
    local ok, value = pcall(function()
        return instance.Text
    end)
    return ok and tostring(value or "") or ""
end

function guiNameMatches(instance, patterns)
    local value = (tostring(instance.Name or "") .. " " .. getGuiText(instance)):lower()
    local parent = instance.Parent
    local depth = 0
    while parent and depth < 3 do
        value = value .. " " .. tostring(parent.Name or ""):lower() .. " " .. getGuiText(parent):lower()
        parent = parent.Parent
        depth = depth + 1
    end

    for _, pattern in ipairs(patterns) do
        if value:find(pattern, 1, true) then
            return true
        end
    end

    return false
end

function guiBranchHasText(instance, patterns, maxDepth)
    local current = instance
    local depth = 0
    while current and depth < (maxDepth or 8) do
        local value = (tostring(current.Name or "") .. " " .. getGuiText(current)):lower()
        for _, pattern in ipairs(patterns) do
            if value:find(pattern, 1, true) then
                return true
            end
        end
        current = current.Parent
        depth = depth + 1
    end

    return false
end

function guiBranchIsVisible(instance)
    local current = instance
    local depth = 0
    while current and depth < 10 do
        if current:IsA("ScreenGui") and current.Enabled == false then
            return false
        end
        if current:IsA("GuiObject") and current.Visible == false then
            return false
        end
        current = current.Parent
        depth = depth + 1
    end

    return true
end

local soccerKickAnchorHints = { "hold to kick", "auto kick", "kick", "throw", "yeet" }
local soccerKickDenyHints = { "exclusive", "shop", "chance", "egg", "upgrade", "leaderboard", "changelog", "index", "tax" }
local soccerKickRootCache = {}
local soccerKickRootCacheTime = 0

function getSoccerKickGuiRoots(forceRefresh, directOnly)
    local now = os.clock()
    if not directOnly and not forceRefresh and now - soccerKickRootCacheTime < 1 then
        return soccerKickRootCache
    end

    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then
        if not directOnly then
            soccerKickRootCache = {}
            soccerKickRootCacheTime = now
        end
        return {}
    end

    local roots = {}
    local seen = {}

    local function addRoot(root)
        if root and not seen[root] and guiBranchIsVisible(root) and not guiBranchHasText(root, soccerKickDenyHints, 5) then
            seen[root] = true
            table.insert(roots, root)
        end
    end

    for _, root in ipairs(playerGui:GetChildren()) do
        local name = tostring(root.Name or ""):lower()
        if name:find("yeet", 1, true)
            or name:find("kick", 1, true)
            or name:find("soccer", 1, true)
            or name:find("throw", 1, true) then
            addRoot(root)
        end
    end

    local mainGui = playerGui:FindFirstChild("Main")
    local basketballButton = mainGui and mainGui:FindFirstChild("BasketballButton")
    if basketballButton then
        addRoot(basketballButton)
    end

    local checkedDirect = 0
    for _, gui in ipairs(playerGui:GetDescendants()) do
        checkedDirect = checkedDirect + 1
        if checkedDirect > 300 or #roots >= 6 then
            break
        end
        if gui:IsA("GuiButton") or gui:IsA("TextLabel") then
            local value = (tostring(gui.Name or "") .. " " .. getGuiText(gui)):lower()
            if value:find("auto throw", 1, true)
                or value:find("hold to kick", 1, true)
                or value:find("throw", 1, true)
                or value:find("kick", 1, true)
                or value:find("yeet", 1, true) then
                addRoot(gui:IsA("GuiButton") and gui or gui.Parent)
            end
        end
    end

    if #roots > 0 then
        soccerKickRootCache = roots
        soccerKickRootCacheTime = now
        return roots
    end

    if directOnly then
        return roots
    end

    for _, root in ipairs(playerGui:GetChildren()) do
        if #roots >= 6 then
            break
        end
        if guiBranchIsVisible(root) and not guiBranchHasText(root, soccerKickDenyHints, 3) then
            local checked = 0
            for _, gui in ipairs(root:GetDescendants()) do
                checked = checked + 1
                if checked > 120 then
                    break
                end

                local name = tostring(gui.Name or ""):lower()
                local text = ""
                if gui:IsA("TextLabel") or gui:IsA("TextButton") then
                    text = getGuiText(gui):lower()
                end
                local value = name .. " " .. text
                if value:find("hold to kick", 1, true)
                    or value:find("auto kick", 1, true)
                    or value:find("kick", 1, true)
                    or value:find("yeet", 1, true)
                    or value:find("throw", 1, true) then
                    addRoot(root)
                    break
                end
            end
        end
    end

    soccerKickRootCache = roots
    soccerKickRootCacheTime = now
    return roots
end

function getSoccerKickPercentFromRoots(roots)
    local bestPercent
    for _, root in ipairs(roots or {}) do
        local scan = root:GetDescendants()
        table.insert(scan, root)
        for _, gui in ipairs(scan) do
            if not (gui:IsA("TextLabel") or gui:IsA("TextButton") or gui:IsA("TextBox")) then
                continue
            end
            local percent = tonumber(getGuiText(gui):match("(%d+)%%"))
            if percent and percent >= 0 and percent <= 100 and guiBranchIsVisible(gui) then
                bestPercent = math.max(bestPercent or 0, percent)
            end
        end
    end

    return bestPercent
end

function getSoccerKickPercent(forceRefresh)
    return getSoccerKickPercentFromRoots(getSoccerKickGuiRoots(forceRefresh))
end

function pressGuiButton(button)
    local fired = false

    if type(firesignal) == "function" then
        pcall(function()
            firesignal(button.MouseButton1Down)
            task.wait(0.03)
            firesignal(button.MouseButton1Up)
            firesignal(button.MouseButton1Click)
            firesignal(button.Activated)
        end)
        fired = true
    end

    if not fired and VirtualInputManager then
        local position = button.AbsolutePosition + (button.AbsoluteSize / 2)
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(position.X, position.Y, 0, true, game, 0)
            task.wait(0.03)
            VirtualInputManager:SendMouseButtonEvent(position.X, position.Y, 0, false, game, 0)
        end)
        fired = true
    end

    return fired
end

function pressSoccerKickButtons(roots)
    local didAny = false
    for _, root in ipairs(roots or {}) do
        local scan = root:GetDescendants()
        table.insert(scan, root)
        for _, gui in ipairs(scan) do
            if gui:IsA("GuiButton") and guiBranchIsVisible(gui) then
                if pressGuiButton(gui) then
                    didAny = true
                end
            end
        end
    end

    return didAny
end

function requestSoccerPerfectKickOnce(forceRefresh, roots)
    local target = math.clamp(tonumber(getgenv().autoSoccerEventConfig.PERFECT_KICK_TARGET) or 100, 1, 100)
    local releaseAt = target
    if target >= 99 then
        releaseAt = math.clamp(tonumber(getgenv().autoSoccerEventConfig.PERFECT_KICK_MIN_PERCENT) or 99, 95, target)
    end
    roots = roots or getSoccerKickGuiRoots(forceRefresh)
    local percent = getSoccerKickPercentFromRoots(roots)
    if not percent or percent < releaseAt then
        return false
    end

    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then
        return false
    end

    local didAny = pressSoccerKickButtons(roots)

    if didAny then
        getgenv().FlowPS99LastSoccerKick = {
            Percent = percent,
            Target = target,
            ReleaseAt = releaseAt,
            Perfect = percent >= 99,
            Route = "KickGui",
            Time = os.clock()
        }
    end

    return didAny
end

function runSoccerPerfectKickWindow()
    local timeout = math.clamp(tonumber(getgenv().autoSoccerEventConfig.PERFECT_KICK_WINDOW) or 4, 0.25, 8)
    local poll = math.clamp(tonumber(getgenv().autoSoccerEventConfig.PERFECT_KICK_POLL) or 0.03, 0.03, 0.25)
    local started = os.clock()

    while os.clock() - started <= timeout do
        local roots = getSoccerKickGuiRoots(true, true)
        if #roots == 0 and os.clock() - started > 1 then
            return false
        end
        if requestSoccerPerfectKickOnce(false, roots) then
            return true
        end
        task.wait(poll)
    end

    return false
end

function runSoccerEventStep()
    if not isInstanceAvailable or not isInstanceAvailable("SoccerEvent") then
        getgenv().FlowPS99LastSoccerEventBlocked = {
            Reason = "SoccerEvent is unavailable in this game version.",
            Time = os.clock()
        }
        return false
    end
    local didAny = false
    local soccerActive = isInstanceActive("SoccerEvent")

    if getgenv().autoSoccerEventConfig.ENTER then
        if enterInstance("SoccerEvent") then
            didAny = true
            soccerActive = true
        else
            soccerActive = isInstanceActive("SoccerEvent")
        end
    end

    if not soccerActive then
        getgenv().FlowPS99LastSoccerEventBlocked = {
            Reason = "SoccerEvent is not active; legacy actions were skipped.",
            Time = os.clock()
        }
        return false
    end

    if getgenv().autoSoccerEventConfig.COLLECT_ORBS then
        ensureOrbCollector()
        if collectExistingOrbsOnce() then
            didAny = true
        end
    end

    if soccerActive and damageSoccerBreakablesOnce() then
        didAny = true
    end

    local hasKickUi = #getSoccerKickGuiRoots(false) > 0
    if getgenv().autoSoccerEventConfig.AUTO_KICK and (soccerActive or hasKickUi) then
        local requestedKick = requestSoccerAutoKickOnce()
        if requestedKick then
            didAny = true
        end
        local kickInfo = getgenv().FlowPS99LastSoccerKick
        local usedThrowStrength = kickInfo
            and tostring(kickInfo.Route or ""):find("ThrowStrength", 1, true)
            and os.clock() - (tonumber(kickInfo.Time) or 0) < 2
        if getgenv().autoSoccerEventConfig.PERFECT_KICK and not usedThrowStrength and runSoccerPerfectKickWindow() then
            didAny = true
        end
    elseif getgenv().autoSoccerEventConfig.AUTO_KICK then
        getgenv().FlowPS99LastSoccerKickBlocked = {
            Reason = "SoccerEvent is not active and kick UI is not open.",
            Time = os.clock()
        }
    end

    if getgenv().autoSoccerEventConfig.USE_BOOSTS and useSoccerBoostsOnce() then
        didAny = true
    end

    if getgenv().autoSoccerEventConfig.BUY_UPGRADES and buySoccerUpgradesOnce() then
        didAny = true
    end

    if getgenv().autoSoccerEventConfig.CLAIM_GOALS and claimEventGoalsOnce() then
        didAny = true
    end

    if getgenv().autoSoccerEventConfig.HATCH_EGGS and hatchSoccerEggOnce() then
        didAny = true
    end

    return didAny
end

function runAutoSoccerEvent()
    while autoSoccerEventRunning and not getgenv().STAFF_DETECTED do
        runSoccerEventStep()
        if not waitForRunningDelay(math.max(getgenv().autoSoccerEventConfig.DELAY, 2), function()
            return autoSoccerEventRunning and not getgenv().STAFF_DETECTED
        end) then
            break
        end
    end
    autoSoccerEventRunning = false
end

function getKeyItemUids(matchers)
    local items = {}
    for _, item in ipairs(collectInventoryItems({ "Misc", "MiscItems", "Items", "Item" })) do
        local itemName = getInventoryItemName(item.Data)
        local itemKey = collapseKey(itemName)
        for _, matcher in ipairs(matchers) do
            if itemKey:find(collapseKey(matcher), 1, true) and item.Uid then
                table.insert(items, tostring(item.Uid))
                break
            end
        end
    end
    return items
end

function usePrisonKeysOnce()
    local usedAny = false
    local keyUids = getKeyItemUids({ "Prison Key", "Golden Prison Key" })
    if #keyUids == 0 then
        return false
    end

    local keyRemote = Network:FindFirstChild("PrisonKey_Use")

    if keyRemote then
        for _, uid in ipairs(keyUids) do
            if invokeRemoteAny(keyRemote, {
                { uid },
                { uid, 1 },
                { "Prison Key", uid },
                { "Golden Prison Key", uid }
            }) then
                usedAny = true
            end
        end
    end

    local chestRemote = Network:FindFirstChild("PrisonCell_ChestUnlock")
    if chestRemote then
        for i = 1, math.max(getgenv().autoPrisonKeysConfig.CHEST_SCAN, 1) do
            if invokeRemoteAny(chestRemote, {
                { i },
                { tostring(i) },
                { "Cell" .. tostring(i) },
                { "Chest" .. tostring(i) }
            }) then
                usedAny = true
            end
        end
    end

    if usedAny then
        notifyFlow("Prison Keys", "Use/unlock requests sent.", 2.5)
    end

    return usedAny
end

function runAutoPrisonKeys()
    while autoPrisonKeysRunning and not getgenv().STAFF_DETECTED do
        usePrisonKeysOnce()
        if not waitForRunningDelay(math.max(getgenv().autoPrisonKeysConfig.DELAY, 2), function()
            return autoPrisonKeysRunning and not getgenv().STAFF_DETECTED
        end) then
            break
        end
    end
    autoPrisonKeysRunning = false
end

function runChestRushBankHeistStep()
    local didAny = false
    for _, instanceName in ipairs({ "ChestRush", "BankHeist" }) do
        if enterInstance(instanceName) then
            didAny = true
            task.wait(math.max(getgenv().autoInstanceConfig.CLAIM_CHEST_DELAY, 0.5))
            if claimMinigameReward(instanceName) then
                didAny = true
            end
            if getgenv().autoChestRushBankHeistConfig.LEAVE_AFTER_CLAIM then
                leaveCurrentInstance()
                task.wait(0.5)
            end
        end
    end
    return didAny
end

function runAutoChestRushBankHeist()
    while autoChestRushBankHeistRunning and not getgenv().STAFF_DETECTED do
        runChestRushBankHeistStep()
        if not waitForRunningDelay(math.max(getgenv().autoChestRushBankHeistConfig.DELAY, 5), function()
            return autoChestRushBankHeistRunning and not getgenv().STAFF_DETECTED
        end) then
            break
        end
    end
    autoChestRushBankHeistRunning = false
end

local minigameActionMap = {
    ChestRush = { "Start", "Claim", "OpenChest", "Clicked" },
    BankHeist = { "Start", "Claim", "OpenChest", "Clicked" },
    ChestRoulette = { "Spin", "Roll", "Claim", "Open", "Start", "Play", "Clicked" },
    ClawMachine = { "Start", "Play", "Grab", "Drop", "Claim", "Clicked" },
    DiamondWheelInstance = { "Spin", "WheelSpin", "Roll", "Claim", "Clicked" },
    Digsite = { "Dig", "DigBlock", "DigChest", "Claim", "Clicked" },
    AdvancedDigsite = { "Dig", "DigBlock", "DigChest", "Claim", "Clicked" },
    AdvancedFishing = { "RequestReel", "Clicked", "Claim" },
    Fishing = { "RequestReel", "Clicked", "Claim" },
    FishingEvent = { "RequestReel", "Clicked", "Claim" },
    TimeTrial = { "Start", "Finish", "Claim", "OpenChest", "Clicked" },
    TreasureHideout = { "Start", "Claim", "OpenChest", "Open", "Clicked" },
    LuckyBlocks = { "Start", "Break", "Claim", "OpenChest", "Clicked" },
    ChestRaid = { "Start", "Claim", "OpenChest", "Clicked" },
    GrinchRaid = { "Start", "Claim", "OpenChest", "Clicked" },
    Woodcutting = { "Chop", "Cut", "Claim", "Clicked" },
    BlockParty = { "Start", "Claim", "Finish", "Clicked" },
    FlowerGarden = { "Start", "Collect", "Claim", "Clicked" },
    CrystalKeyCastle = { "Open", "Unlock", "UseKey", "Claim", "Clicked" },
    MillionaireRun = { "Start", "Claim", "OpenChest", "Clicked" },
    Minefield = { "Start", "Claim", "OpenChest", "Clicked" },
    SledRace = { "Start", "Claim", "OpenChest", "Clicked" },
    Atlantis = { "Start", "Claim", "OpenChest", "Clicked" },
    HackerObby = { "Start", "Finish", "Claim", "Clicked" },
    HoverboardTechObby = { "Start", "Finish", "Claim", "Clicked" },
    IceObby = { "Start", "Finish", "Claim", "Clicked" },
    JungleObby = { "Start", "Finish", "Claim", "Clicked" },
    PyramidObby = { "Start", "Finish", "Claim", "Clicked" },
    SpawnObby = { "Start", "Finish", "Claim", "Clicked" },
    StairwayToHeaven = { "Start", "Finish", "Claim", "Clicked" },
    EnchantEmpoweringInstance = { "Start", "Claim", "Empower", "Clicked" }
}

local minigameRemoteMap = {
    ChestRoulette = { "ChestRoulette_Spin", "ChestRoulette_Claim", "Roulette_Spin", "Roulette_Claim" },
    ClawMachine = { "ClawMachine_Play", "ClawMachine_Grab", "ClawMachine_Claim" },
    DiamondWheelInstance = { "DiamondWheel_Spin", "DiamondWheel_Claim", "SpinnyWheel_Spin", "Wheel_Spin", "Spinny Wheel: Request Spin", "Spinny Wheel: Request Ticket", "Spinny Wheel: Request Wheels" },
    TimeTrial = { "TimeTrials_Start", "TimeTrials_OpenChest", "TimeTrials_Claim", "TimeTrial_Multipliers_Request" },
    TreasureHideout = { "TreasureHideout_OpenChest", "TreasureHideout_Claim", "TreasureHideout_Unlock", "TreasureHideout_Combine" },
    LuckyBlocks = { "LuckyBlocks_Start", "LuckyBlocks_Claim" },
    FishingEvent = { "FishingEvent_ToggleAutofish", "FishingEvent_Cast", "FishingEvent_Fish", "FishingEvent_Uncast", "FishingEvent_Sell" },
    Woodcutting = { "Woodcutting_Chop", "Woodcutting_Claim" },
    FlowerGarden = { "FlowerGarden_Collect", "FlowerGarden_Claim" },
    BlockParty = { "BlockParty_Start", "BlockParty_Claim" },
    EnchantEmpoweringInstance = { "EnchantEmpowering_Empower", "EnchantEmpowering_Claim" }
}

local minigameAliasMap = {
    AdvancedFishing = { "advancedfishing", "fishing" },
    FishingEvent = { "fishingevent", "fishing" },
    ChestRoulette = { "chestroulette", "roulette" },
    ClawMachine = { "clawmachine", "claw" },
    DiamondWheelInstance = { "diamondwheelinstance", "diamondwheel", "wheel" },
    TimeTrial = { "timetrial", "timetrials" },
    TreasureHideout = { "treasurehideout", "treasure" },
    LuckyBlocks = { "luckyblocks", "luckyblock" },
    GrinchRaid = { "grinchraid", "grinch", "raid" },
    CrystalKeyCastle = { "crystalkeycastle", "crystalkey" },
    MillionaireRun = { "millionairerun", "millionaire" },
    HoverboardTechObby = { "hoverboardtechobby", "techobby", "obby" },
    EnchantEmpoweringInstance = { "enchantempoweringinstance", "enchantempowering", "empowering" }
}

local minigameRemoteActionHints = {
    "claim",
    "open",
    "chest",
    "spin",
    "roll",
    "play",
    "start",
    "reward",
    "finish",
    "complete",
    "completion",
    "goal",
    "win",
    "end",
    "collect",
    "dig",
    "fish",
    "reel",
    "cast",
    "chop",
    "cut",
    "unlock",
    "key"
}

local minigameRemoteDenyHints = {
    "animate",
    "update",
    "changed",
    "discovered",
    "success",
    "replicate",
    "broadcast",
    "notify",
    "sound",
    "effect",
    "visual",
    "merchant",
    "purchase",
    "inspect"
}

local minigameStructuredRemoteDenyPrefixes = {
    "customeggs",
    "daycare",
    "eggs",
    "eventgoals",
    "exclusive",
    "farming",
    "fishingevent",
    "gift",
    "instancechests",
    "keybinds",
    "prison",
    "secret",
    "summergift"
}

local minigameInteractableHints = {
    "claim",
    "reward",
    "chest",
    "open",
    "start",
    "play",
    "spin",
    "roll",
    "wheel",
    "button",
    "prompt",
    "finish",
    "finishline",
    "complete",
    "completion",
    "goal",
    "win",
    "end",
    "dig",
    "fish",
    "reel",
    "cast",
    "claw",
    "grab",
    "drop",
    "chop",
    "cut",
    "unlock",
    "key"
}

function normalizeRemoteToken(value)
    return tostring(value or ""):lower():gsub("[^%w]", "")
end

function getMinigameAliases(instanceName)
    local aliases = {}
    local primary = normalizeRemoteToken(instanceName)
    if primary ~= "" then
        table.insert(aliases, primary)
    end

    for _, alias in ipairs(minigameAliasMap[instanceName] or {}) do
        alias = normalizeRemoteToken(alias)
        if alias ~= "" and not table.find(aliases, alias) then
            table.insert(aliases, alias)
        end
    end

    return aliases
end

function remoteLooksLikeMinigameAction(remoteName, aliases)
    local normalizedName = normalizeRemoteToken(remoteName)
    for _, prefix in ipairs(minigameStructuredRemoteDenyPrefixes) do
        if normalizedName:sub(1, #prefix) == prefix then
            return false
        end
    end

    for _, hint in ipairs(minigameRemoteDenyHints) do
        if string.find(normalizedName, hint, 1, true) then
            return false
        end
    end

    local matchesAlias = false
    for _, alias in ipairs(aliases) do
        if alias ~= "" and string.find(normalizedName, alias, 1, true) then
            matchesAlias = true
            break
        end
    end

    if not matchesAlias then
        return false
    end

    for _, hint in ipairs(minigameRemoteActionHints) do
        if string.find(normalizedName, hint, 1, true) then
            return true
        end
    end

    return false
end

function getDiscoveredMinigameRemoteNames(instanceName, limit)
    local aliases = getMinigameAliases(instanceName)
    local names = {}
    if #aliases == 0 then
        return names
    end

    local maxCount = math.max(tonumber(limit) or 20, 1)
    for _, remote in ipairs(Network:GetChildren()) do
        if #names >= maxCount then
            break
        end

        if (remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction")) and remoteLooksLikeMinigameAction(remote.Name, aliases) then
            table.insert(names, remote.Name)
        end
    end

    return names
end

function nameMatchesAnyHint(value, hints)
    local normalizedName = normalizeRemoteToken(value)
    if normalizedName == "" then
        return false
    end

    for _, hint in ipairs(hints) do
        if string.find(normalizedName, hint, 1, true) then
            return true
        end
    end

    return false
end

function interactableLooksActionable(item)
    local name = item.Name
    local parent = item.Parent

    if item:IsA("TouchTransmitter") and parent then
        name = parent.Name .. " " .. (parent.Parent and parent.Parent.Name or "")
    else
        name = name .. " " .. (parent and parent.Name or "")
    end

    return nameMatchesAnyHint(name, minigameInteractableHints)
end

function countInstanceInteractables(instanceName, limit)
    local roots = getInstanceSearchRoots(instanceName)
    local count = 0
    local maxCount = math.max(tonumber(limit) or 200, 1)

    for _, root in ipairs(roots) do
        for _, item in ipairs(root:GetDescendants()) do
            if count >= maxCount then
                return count, true
            end

            if interactableLooksActionable(item)
                and (item:IsA("ClickDetector")
                    or item:IsA("ProximityPrompt")
                    or item:IsA("TouchTransmitter")
                    or item:IsA("BasePart")) then
                count = count + 1
            end
        end
    end

    return count, false
end

function getInstanceSearchRoots(instanceName)
    local roots = {}
    local things = Workspace:FindFirstChild("__THINGS")
    local active = things and things:FindFirstChild("__INSTANCE_CONTAINER") and things.__INSTANCE_CONTAINER:FindFirstChild("Active")
    local instances = things and things:FindFirstChild("Instances")

    local activeInstance = active and active:FindFirstChild(instanceName)
    if activeInstance then
        table.insert(roots, activeInstance)
    end

    local portalInstance = instances and instances:FindFirstChild(instanceName)
    if portalInstance then
        table.insert(roots, portalInstance)
    end

    return roots
end

function getActionPartFromInteractable(instance)
    if instance:IsA("BasePart") then
        return instance
    end

    local parent = instance.Parent
    while parent and parent ~= Workspace do
        if parent:IsA("BasePart") then
            return parent
        end
        parent = parent.Parent
    end

    return nil
end

function activateInstanceInteractables(instanceName)
    local roots = getInstanceSearchRoots(instanceName)
    if #roots == 0 then
        return false
    end

    local hrp = getHumanoidRootPart()
    local didAny = false
    local count = 0
    local maxCount = math.max(tonumber(getgenv().autoMinigameConfig.MAX_INTERACTABLES) or 10, 1)

    for _, root in ipairs(roots) do
        for _, item in ipairs(root:GetDescendants()) do
            if count >= maxCount then
                return didAny
            end

            if interactableLooksActionable(item) then
                if item:IsA("ClickDetector") and type(fireclickdetector) == "function" then
                    local ok = pcall(function()
                        fireclickdetector(item)
                    end)
                    if ok then
                        didAny = true
                        count = count + 1
                        task.wait(0.05)
                    end
                elseif item:IsA("ProximityPrompt") and type(fireproximityprompt) == "function" then
                    local part = getActionPartFromInteractable(item)
                    if part then
                        hrp.CFrame = part.CFrame + Vector3.new(0, 4, 0)
                    end
                    local ok = pcall(function()
                        fireproximityprompt(item)
                    end)
                    if ok then
                        didAny = true
                        count = count + 1
                        task.wait(0.05)
                    end
                elseif item:IsA("TouchTransmitter") and type(firetouchinterest) == "function" then
                    local part = getActionPartFromInteractable(item)
                    if part then
                        local ok = pcall(function()
                            hrp.CFrame = part.CFrame + Vector3.new(0, 4, 0)
                            firetouchinterest(hrp, part, 0)
                            task.wait(0.05)
                            firetouchinterest(hrp, part, 1)
                        end)
                        if ok then
                            didAny = true
                            count = count + 1
                            task.wait(0.05)
                        end
                    end
                elseif item:IsA("BasePart") and type(firetouchinterest) == "function" then
                    local ok = pcall(function()
                        hrp.CFrame = item.CFrame + Vector3.new(0, 4, 0)
                        firetouchinterest(hrp, item, 0)
                        task.wait(0.05)
                        firetouchinterest(hrp, item, 1)
                    end)
                    if ok then
                        didAny = true
                        count = count + 1
                        task.wait(0.05)
                    end
                end
            end
        end
    end

    return didAny
end

function fireInstanceCustomAction(instanceName, actionName, extra)
    local fired = false
    local invokeRemote = Network:FindFirstChild("Instancing_InvokeCustomFromClient")
    local fireRemote = Network:FindFirstChild("Instancing_FireCustomFromClient")
    local args = { instanceName, actionName }

    if extra ~= nil then
        table.insert(args, extra)
    end

    if invokeRemote and invokeRemote:IsA("RemoteFunction") then
        local ok, result = pcall(function()
            return invokeRemote:InvokeServer(unpack(args))
        end)
        if ok and result ~= false then
            fired = true
        end
    end

    if fireRemote and fireRemote:IsA("RemoteEvent") then
        local ok = pcall(function()
            fireRemote:FireServer(unpack(args))
        end)
        if ok then
            fired = true
        end
    end

    return fired
end

function runKnownMinigameRemotes(instanceName)
    local remoteNames = minigameRemoteMap[instanceName]
    if not remoteNames then
        return false
    end

    local didAny = false
    for _, remoteName in ipairs(remoteNames) do
        local remote = Network:FindFirstChild(remoteName)
        if remote and invokeRemoteAny(remote, {
            {},
            { instanceName },
            { tostring(instanceName) },
            { 1 },
            { instanceName, 1 }
        }) then
            didAny = true
            task.wait(0.05)
        end
    end

    return didAny
end

function runDiscoveredMinigameRemotes(instanceName)
    local remoteNames = getDiscoveredMinigameRemoteNames(instanceName, getgenv().autoMinigameConfig.MAX_REMOTE_ATTEMPTS)
    if #remoteNames == 0 then
        return false
    end

    local didAny = false
    for _, remoteName in ipairs(remoteNames) do
        local remote = Network:FindFirstChild(remoteName)
        if remote and invokeRemoteAny(remote, {
            {},
            { instanceName },
            { tostring(instanceName) },
            { 1 },
            { instanceName, 1 }
        }) then
            didAny = true
        end
        task.wait(0.04)
    end

    return didAny
end

function damageInstanceBreakablesOnce(instanceName, limit)
    local things = Workspace:FindFirstChild("__THINGS")
    local breakables = things and things:FindFirstChild("Breakables")
    if not breakables then
        return false
    end

    local didAny = false
    local count = 0
    for _, breakable in ipairs(breakables:GetChildren()) do
        if count >= (limit or 8) then
            break
        end

        local parentId = breakable:GetAttribute("ParentID")
        if tostring(parentId) == tostring(instanceName) then
            teleportToBreakable(breakable)
            if damageBreakableByName(breakable) then
                didAny = true
                count = count + 1
            end
            task.wait(0.05)
        end
    end

    return didAny
end

function runMinigameCustomActions(instanceName)
    local actions = minigameActionMap[instanceName]
    if not actions then
        return false
    end

    local didAny = false
    for _, actionName in ipairs(actions) do
        if fireInstanceCustomAction(instanceName, actionName) then
            didAny = true
        end
        task.wait(0.04)
    end

    return didAny
end

function runFishingEventModuleStep()
    local moduleValue = requireClientModule("EventFishingCmds")
    if type(moduleValue) ~= "table" then
        return false
    end

    local state = {
        Module = "EventFishingCmds",
        IsLocalFishing = false,
        IsOnWater = nil,
        RegionReady = false,
        Action = nil,
        Returned = false
    }

    local function call(methodName, argSets)
        local method = moduleValue[methodName]
        if type(method) ~= "function" then
            return false
        end

        for _, args in ipairs(argSets or { {} }) do
            local ok, result = pcall(function()
                return method(unpack(args))
            end)
            if not ok then
                ok, result = pcall(function()
                    return method(moduleValue, unpack(args))
                end)
            end
            if ok and result ~= false then
                state.Action = methodName
                state.Returned = true
                return true
            end
        end

        return false
    end

    local isFishing = false
    if type(moduleValue.IsLocalFishing) == "function" then
        local ok, result = pcall(moduleValue.IsLocalFishing)
        isFishing = ok and result == true
    end
    state.IsLocalFishing = isFishing

    if type(moduleValue.IsOnWater) == "function" then
        local ok, result = pcall(moduleValue.IsOnWater)
        if ok then
            state.IsOnWater = result == true
        end
    end

    if type(moduleValue.FindRegion) == "function" then
        local hrp = getHumanoidRootPart()
        local okRegion, region = pcall(function()
            return moduleValue.FindRegion(hrp.CFrame)
        end)
        state.RegionReady = okRegion and region ~= nil

        if not state.RegionReady then
            local active = getActiveInstanceFolder("FishingEvent")
            if active then
                for _, part in ipairs(active:GetDescendants()) do
                    if part:IsA("BasePart") and (part.Size.X > 40 or part.Size.Z > 40) then
                        local targetCFrame = CFrame.new(part.Position + Vector3.new(0, 6, 0))
                        okRegion, region = pcall(function()
                            return moduleValue.FindRegion(targetCFrame)
                        end)
                        if okRegion and region ~= nil then
                            hrp.CFrame = targetCFrame
                            task.wait(0.2)
                            state.RegionReady = true
                            break
                        end
                    end
                end
            end
        end
    end

    if not isFishing then
        local didAny = call("Equip") or call("Cast") or call("LocalCast")
        getgenv().FlowPS99LastFishingResult = state
        return didAny
    end

    local didAny = call("Hook") or call("Fish") or call("Unhook")
    getgenv().FlowPS99LastFishingResult = state
    return didAny
end

function runFishingCallbackModuleStep()
    local state = {
        Module = "FishingCallbacks",
        Action = nil,
        Returned = false
    }

    for _, moduleName in ipairs({ "CastFishing", "CatchFish", "SellFish" }) do
        local moduleValue = requireClientModule(moduleName)
        if type(moduleValue) == "table" and type(moduleValue.Callback) == "function" then
            local ok, result = pcall(moduleValue.Callback)
            if ok and result ~= false then
                state.Action = moduleName
                state.Returned = true
                getgenv().FlowPS99LastFishingResult = state
                return true
            end
        end
    end

    getgenv().FlowPS99LastFishingResult = state
    return false
end

function runFishingMinigameStep(instanceName)
    if instanceName == "FishingEvent" then
        return runFishingEventModuleStep() or runFishingCallbackModuleStep()
    end

    return runFishingCallbackModuleStep()
end

function runAutoMineModuleStep(instanceName)
    local moduleValue = requireClientModule("AutoMineCmds")
    if type(moduleValue) ~= "table" or type(moduleValue.Enable) ~= "function" then
        return false
    end

    local ok, result = pcall(moduleValue.Enable)
    getgenv().FlowPS99LastAutoMineResult = {
        Instance = instanceName,
        Enabled = ok and result ~= false,
        Error = not ok and tostring(result) or nil,
        Time = os.clock()
    }
    autoMineActive = ok and result ~= false
    return ok and result ~= false
end

function disableActiveAutoMine()
    if not autoMineActive then
        return
    end
    local moduleValue = requireClientModule("AutoMineCmds")
    if type(moduleValue) == "table" and type(moduleValue.Disable) == "function" then
        pcall(moduleValue.Disable)
    end
    autoMineActive = false
end

function runSpinnyWheelModuleStep()
    local moduleValue = requireClientModule("SpinnyWheelCmds")
    if type(moduleValue) ~= "table" then
        return false
    end

    local wheels = {}
    if type(moduleValue.GetPhysicalWheels) == "function" then
        local ok, result = pcall(moduleValue.GetPhysicalWheels)
        if ok and type(result) == "table" then
            for key, wheel in pairs(result) do
                table.insert(wheels, {
                    Key = key,
                    Value = wheel
                })
            end
        end
    end

    if #wheels == 0 then
        return false
    end

    local requestSpin = moduleValue.RequestSpin
    if type(requestSpin) ~= "function" then
        return false
    end

    for _, wheel in ipairs(wheels) do
        local ok, result = pcall(function()
            return requestSpin(wheel.Key)
        end)
        if not ok then
            ok, result = pcall(function()
                return requestSpin(wheel.Value)
            end)
        end
        if ok and result ~= false then
            return true
        end
    end

    return false
end

function runSelectedMinigameStep(instanceName)
    if not instanceName or instanceName == "" or instanceName == "No instances found" then
        notifyFlow("Minigame", "No minigame selected.", 2.5)
        return false
    end

    local meetsRequirement, requirementMessage = getInstanceRequirementStatus(instanceName)
    if meetsRequirement == false then
        getgenv().FlowPS99LastMinigameResult = {
            Instance = instanceName,
            Returned = false,
            Status = "Unavailable",
            Reason = requirementMessage or "Live requirement check failed.",
            Time = os.clock()
        }
        notifyFlow("Minigame", requirementMessage or (tostring(instanceName) .. " is not available right now."), 2.5)
        return false
    end

    local didAny = false

    if getgenv().autoMinigameConfig.AUTO_ENTER then
        didAny = enterInstance(instanceName) or didAny
        task.wait(math.max(getgenv().autoInstanceConfig.ENTER_DELAY, 0.1))
    end

    local activeNow = isInstanceActive(instanceName)
    if getgenv().autoMinigameConfig.REQUIRE_ACTIVE_FOR_ACTIONS and not activeNow then
        if getgenv().autoMinigameConfig.TRY_INTERACTABLES then
            didAny = activateInstanceInteractables(instanceName) or didAny
        end
        notifyFlow("Minigame", didAny and "Entry requested for " .. tostring(instanceName) or "Could not enter " .. tostring(instanceName), 2.5)
        return didAny
    end

    if instanceName == "LuckyBlocks" or instanceName == "ChestRaid" then
        didAny = damageInstanceBreakablesOnce(instanceName, 10) or didAny
    end

    if getgenv().autoMinigameConfig.AUTO_CLAIM then
        didAny = claimMinigameReward(instanceName) or didAny
    end

    if getgenv().autoMinigameConfig.TRY_ACTIONS then
        if instanceName == "FishingEvent" or instanceName == "Fishing" or instanceName == "AdvancedFishing" then
            didAny = runFishingMinigameStep(instanceName) or didAny
        elseif instanceName == "Digsite" or instanceName == "AdvancedDigsite" then
            didAny = runAutoMineModuleStep(instanceName) or didAny
        elseif instanceName == "DiamondWheelInstance" then
            didAny = runSpinnyWheelModuleStep() or didAny
        else
            didAny = runKnownMinigameRemotes(instanceName) or didAny
            didAny = runMinigameCustomActions(instanceName) or didAny
            if getgenv().autoMinigameConfig.TRY_DISCOVERED_REMOTES then
                didAny = runDiscoveredMinigameRemotes(instanceName) or didAny
            end
        end
        if getgenv().autoMinigameConfig.TRY_INTERACTABLES then
            didAny = activateInstanceInteractables(instanceName) or didAny
        end
    end

    if getgenv().autoMinigameConfig.LEAVE_AFTER_STEP then
        leaveCurrentInstance()
    end

    if didAny then
        notifyFlow("Minigame", "Ran " .. tostring(instanceName) .. ".", 2.5)
    else
        notifyFlow("Minigame", "No working route found for " .. tostring(instanceName) .. ".", 2.5)
    end

    return didAny
end

function safeRunSelectedMinigameStep(instanceName)
    local startedActive = isInstanceActive(instanceName)
    local ok, result = pcall(function()
        return runSelectedMinigameStep(instanceName)
    end)
    local endedActive = isInstanceActive(instanceName)
    local previousResult = getgenv().FlowPS99LastMinigameResult
    local previousUnavailable = previousResult
        and previousResult.Instance == instanceName
        and previousResult.Status == "Unavailable"
        and os.clock() - (tonumber(previousResult.Time) or 0) < 2

    getgenv().FlowPS99LastMinigameResult = {
        Instance = instanceName,
        StartedActive = startedActive,
        EndedActive = endedActive,
        VerifiedActive = startedActive or endedActive,
        Returned = ok and result == true,
        Status = previousUnavailable and "Unavailable" or ((startedActive or endedActive) and "ActiveVerified" or (ok and result == true and "EntryRequested" or "NoRoute")),
        Reason = previousUnavailable and previousResult.Reason or nil,
        Error = not ok and tostring(result) or nil,
        Time = os.clock()
    }

    if not ok then
        warn("[HipHub Minigame] " .. tostring(instanceName) .. " failed: " .. tostring(result))
        notifyFlow("Minigame Error", tostring(instanceName) .. " failed. Check console.", 3)
        return false
    end

    return result == true
end

function getRunnableMinigameNames()
    local values = {}
    for _, name in ipairs(minigameAutoValues) do
        if name ~= MINIGAME_AUTO_ALL and name ~= "No instances found" then
            table.insert(values, name)
        end
    end
    return values
end

function runAllMinigamesStep(shouldContinue)
    local didAny = false
    for _, instanceName in ipairs(getRunnableMinigameNames()) do
        if shouldContinue and not shouldContinue() then
            break
        end
        didAny = safeRunSelectedMinigameStep(instanceName) or didAny
        if not waitForRunningDelay(math.max(getgenv().autoMinigameConfig.DELAY * 0.25, 1), shouldContinue) then
            break
        end
    end
    return didAny
end

function runAutoSelectedMinigame()
    while autoSelectedMinigameRunning and not getgenv().STAFF_DETECTED do
        if selectedMinigameAuto == MINIGAME_AUTO_ALL then
            runAllMinigamesStep(function()
                return autoSelectedMinigameRunning and not getgenv().STAFF_DETECTED
            end)
        else
            safeRunSelectedMinigameStep(selectedMinigameAuto)
        end
        if not waitForRunningDelay(math.max(getgenv().autoMinigameConfig.DELAY, 3), function()
            return autoSelectedMinigameRunning and not getgenv().STAFF_DETECTED
        end) then
            break
        end
    end
    autoSelectedMinigameRunning = false
end

function runFlowReleaseDiagnostics()
    clearDiscoveryCache()
    pcall(refreshInstanceList, true)
    pcall(refreshDirectorySummaryList, true)
    pcall(refreshEggList)

    local maps = getCurrentMaps(true)
    local worlds = discoverDirectoryEntries("Worlds", nil, true)
    local zones = discoverDirectoryEntries("Zones", nil, true)
    local instances = discoverInstances(true)
    local selected = selectedMinigameAuto ~= MINIGAME_AUTO_ALL and selectedMinigameAuto or (minigameAutoValues[2] or instances[1])
    local remoteNames = {}
    local interactableCount = 0
    local interactableCapped = false

    if selected and selected ~= "No instances found" then
        remoteNames = getDiscoveredMinigameRemoteNames(selected, 20)
        interactableCount, interactableCapped = countInstanceInteractables(selected, 250)
    end

    local summary = {
        "HipHub PS99 Release Check",
        "World maps loaded: " .. tostring(#maps),
        "World directories: " .. tostring(#worlds),
        "Zone directories: " .. tostring(#zones),
        "Instances found: " .. tostring(#instances),
        "Minigame options: " .. tostring(#minigameAutoValues),
        "Selected minigame: " .. tostring(selected),
        "Remote candidates: " .. tostring(#remoteNames),
        "Interactables: " .. tostring(interactableCount) .. (interactableCapped and "+" or ""),
        "FPS boost saved: " .. tostring(getgenv().performanceConfig.ENABLED == true),
        "Effects disabled: " .. tostring(getgenv().performanceConfig.DISABLE_EFFECTS == true),
        "Smooth parts: " .. tostring(getgenv().performanceConfig.SIMPLIFY_PARTS == true),
        "Hide pets: " .. tostring(getgenv().performanceConfig.HIDE_OTHER_PETS == true),
        "Hide drops: " .. tostring(getgenv().performanceConfig.HIDE_DROPS == true),
        "3D render off: " .. tostring(getgenv().performanceConfig.DISABLE_RENDER == true)
    }

    for _, line in ipairs(summary) do
        print("[HipHub Diagnostics] " .. line)
    end

    if #remoteNames > 0 then
        print("[HipHub Diagnostics] Remote list: " .. table.concat(remoteNames, ", "))
    end
    if #minigameAutoValues > 0 then
        local preview = {}
        for i = 1, math.min(#minigameAutoValues, 12) do
            table.insert(preview, minigameAutoValues[i])
        end
        print("[HipHub Diagnostics] Minigame list: " .. table.concat(preview, ", "))
    end

    notifyFlow("Release Check", "Instances " .. tostring(#instances) .. " | Zones " .. tostring(#zones) .. " | Remotes " .. tostring(#remoteNames), 4)
    return {
        Maps = #maps,
        Worlds = #worlds,
        Zones = #zones,
        Instances = #instances,
        Minigames = #minigameAutoValues,
        Selected = selected,
        RemoteCandidates = #remoteNames,
        Interactables = interactableCount
    }
end


local performanceDescendantConnection
local performanceDropFolders = {
    Orbs = true,
    MagicOrbs = true,
    Lootbags = true,
    Lootboxes = true,
    Lootables = true,
    PetCubes = true
}

function isDropVisualDescendant(descendant)
    local things = Workspace:FindFirstChild("__THINGS")
    local current = descendant
    while current and current ~= Workspace do
        if current.Parent == things and performanceDropFolders[current.Name] then
            return true
        end
        current = current.Parent
    end

    return false
end

function optimizeVisualDescendant(descendant)
    local config = getgenv().performanceConfig

    if config.HIDE_DROPS and isDropVisualDescendant(descendant) then
        if descendant:IsA("BasePart") or descendant:IsA("Decal") or descendant:IsA("Texture") then
            setRestorableProperty("PerformanceDrops", descendant, "Transparency", 1)
        elseif descendant:IsA("ParticleEmitter")
            or descendant:IsA("Trail")
            or descendant:IsA("Beam")
            or descendant:IsA("Smoke")
            or descendant:IsA("Fire")
            or descendant:IsA("Sparkles") then
            setRestorableProperty("PerformanceDrops", descendant, "Enabled", false)
        end
    end

    if config.DISABLE_EFFECTS and (descendant:IsA("ParticleEmitter")
        or descendant:IsA("Trail")
        or descendant:IsA("Beam")
        or descendant:IsA("Smoke")
        or descendant:IsA("Fire")
        or descendant:IsA("Sparkles")) then
        setRestorableProperty("PerformanceEffects", descendant, "Enabled", false)
    end

    if config.SIMPLIFY_PARTS and descendant:IsA("BasePart") then
        setRestorableProperty("PerformanceParts", descendant, "CastShadow", false)
        setRestorableProperty("PerformanceParts", descendant, "Reflectance", 0)
        setRestorableProperty("PerformanceParts", descendant, "Material", Enum.Material.SmoothPlastic)
    end
end

function installPerformanceDescendantOptimizer()
    if performanceDescendantConnection then
        return
    end

    performanceDescendantConnection = Workspace.DescendantAdded:Connect(function(descendant)
        if not lowEndPerformanceRunning and not getgenv().performanceConfig.ENABLED then
            return
        end
        local visualGeneration = performanceVisualGeneration
        task.defer(function()
            if visualGeneration ~= performanceVisualGeneration
                or (not lowEndPerformanceRunning and not getgenv().performanceConfig.ENABLED) then
                return
            end
            optimizeVisualDescendant(descendant)
        end)
    end)
end

function uninstallPerformanceDescendantOptimizer()
    if performanceDescendantConnection then
        performanceDescendantConnection:Disconnect()
        performanceDescendantConnection = nil
    end
end

function hidePetVisualsOnce()
    if not getgenv().performanceConfig.HIDE_OTHER_PETS then
        return false
    end

    local things = Workspace:FindFirstChild("__THINGS")
    local pets = things and things:FindFirstChild("Pets")
    if not pets then
        return false
    end

    for _, descendant in ipairs(pets:GetDescendants()) do
        if descendant:IsA("BasePart") or descendant:IsA("Decal") or descendant:IsA("Texture") then
            setRestorableProperty("PerformancePets", descendant, "Transparency", 1)
        elseif descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") or descendant:IsA("Beam") then
            setRestorableProperty("PerformancePets", descendant, "Enabled", false)
        end
    end

    return true
end

function hideWorldDropVisualsOnce()
    if not getgenv().performanceConfig.HIDE_DROPS then
        return false
    end

    local things = Workspace:FindFirstChild("__THINGS")
    if not things then
        return false
    end

    local didAny = false
    for folderName in pairs(performanceDropFolders) do
        local folder = things:FindFirstChild(folderName)
        if folder then
            didAny = true
            for _, descendant in ipairs(folder:GetDescendants()) do
                if descendant:IsA("BasePart") or descendant:IsA("Decal") or descendant:IsA("Texture") then
                    setRestorableProperty("PerformanceDrops", descendant, "Transparency", 1)
                elseif descendant:IsA("ParticleEmitter")
                    or descendant:IsA("Trail")
                    or descendant:IsA("Beam")
                    or descendant:IsA("Smoke")
                    or descendant:IsA("Fire")
                    or descendant:IsA("Sparkles") then
                    setRestorableProperty("PerformanceDrops", descendant, "Enabled", false)
                end
            end
        end
    end

    return didAny
end

function setFlowFpsCap(value)
    if type(setfpscap) ~= "function" then
        return false
    end

    local targetCap = math.max(tonumber(value) or 240, 30)
    if not performanceRestoreState.FpsCaptured and type(getfpscap) == "function" then
        local readOk, currentCap = pcall(getfpscap)
        if readOk and tonumber(currentCap) then
            performanceRestoreState.FpsCaptured = true
            performanceRestoreState.FpsCap = tonumber(currentCap)
        end
    end

    local setOk = pcall(setfpscap, targetCap)
    if setOk then
        performanceRestoreState.FpsApplied = targetCap
    end
    return setOk
end

function setFlowRenderingDisabled(disabled)
    local runService = game:GetService("RunService")
    if disabled == true then
        local ok = pcall(function()
            runService:Set3dRenderingEnabled(false)
        end)
        if ok then
            performanceRestoreState.RenderingOwned = true
        end
        return ok
    end

    if not performanceRestoreState.RenderingOwned then
        return true
    end
    local ok = pcall(function()
        runService:Set3dRenderingEnabled(true)
    end)
    if ok then
        performanceRestoreState.RenderingOwned = false
    end
    return ok
end

function applyLowEndPerformanceSettings()
    local config = getgenv().performanceConfig
    local lighting = game:GetService("Lighting")
    local terrain = Workspace:FindFirstChildOfClass("Terrain")

    setRestorableProperty("PerformanceSettings", lighting, "GlobalShadows", false)
    setRestorableProperty("PerformanceSettings", lighting, "FogEnd", 1000000)
    setRestorableProperty("PerformanceSettings", lighting, "EnvironmentDiffuseScale", 0)
    setRestorableProperty("PerformanceSettings", lighting, "EnvironmentSpecularScale", 0)

    if terrain then
        setRestorableProperty("PerformanceSettings", terrain, "WaterWaveSize", 0)
        setRestorableProperty("PerformanceSettings", terrain, "WaterWaveSpeed", 0)
        setRestorableProperty("PerformanceSettings", terrain, "WaterReflectance", 0)
        setRestorableProperty("PerformanceSettings", terrain, "WaterTransparency", 1)
    end

    pcall(function()
        setRestorableProperty("PerformanceSettings", settings().Rendering, "QualityLevel", Enum.QualityLevel.Level01)
    end)

    setFlowFpsCap(config.FPS_CAP)
    if config.DISABLE_RENDER == true then
        setFlowRenderingDisabled(true)
    end
end

function applyLowEndPerformanceOnce(showNotification, scanWorkspace, isRunning, generation)
    local automationGeneration = generation or automationCancellationGeneration
    local visualGeneration = performanceVisualGeneration
    local function canContinue()
        return automationGeneration == automationCancellationGeneration
            and visualGeneration == performanceVisualGeneration
            and flowSessionGeneration == getgenv().FlowPS99Generation
            and (isRunning == nil or isRunning())
    end

    if not canContinue() then
        return false
    end
    performanceRestoreState.VisualApplied = true
    applyLowEndPerformanceSettings()

    if scanWorkspace ~= false then
        local scanned = 0
        for _, descendant in ipairs(Workspace:GetDescendants()) do
            if not canContinue() then
                return false
            end
            optimizeVisualDescendant(descendant)
            scanned = scanned + 1
            if scanned % 500 == 0 then
                task.wait()
                if not canContinue() then
                    return false
                end
            end
        end
    end

    if not canContinue() then
        return false
    end
    hidePetVisualsOnce()
    hideWorldDropVisualsOnce()
    if showNotification then
        notifyFlow("Performance", "Low-end performance pass applied.", 2.5)
    end
    return true
end

function restorePerformanceState()
    performanceVisualGeneration = performanceVisualGeneration + 1
    lowEndPerformanceRunning = false
    performancePassRunning = false
    uninstallPerformanceDescendantOptimizer()
    for _, owner in ipairs({
        "PerformanceSettings",
        "PerformanceEffects",
        "PerformanceParts",
        "PerformancePets",
        "PerformanceDrops"
    }) do
        restoreVisualState(owner)
    end
    if performanceRestoreState.FpsCaptured and performanceRestoreState.FpsCap and type(setfpscap) == "function" then
        local shouldRestore = true
        if performanceRestoreState.FpsApplied and type(getfpscap) == "function" then
            local readOk, currentCap = pcall(getfpscap)
            if readOk and tonumber(currentCap) then
                shouldRestore = math.abs(tonumber(currentCap) - performanceRestoreState.FpsApplied) < 0.5
            end
        end
        if shouldRestore then
            pcall(setfpscap, performanceRestoreState.FpsCap)
        end
    end
    setFlowRenderingDisabled(false)
    performanceRestoreState.FpsCaptured = false
    performanceRestoreState.FpsCap = nil
    performanceRestoreState.FpsApplied = nil
    performanceRestoreState.VisualApplied = false
end

function runLowEndPerformanceLoop()
    local generation = automationCancellationGeneration
    local isRunning = function()
        return lowEndPerformanceRunning
    end
    installPerformanceDescendantOptimizer()
    pcall(function()
        applyLowEndPerformanceOnce(false, true, isRunning, generation)
    end)

    while lowEndPerformanceRunning and generation == automationCancellationGeneration do
        local ok, err = pcall(function()
            applyLowEndPerformanceOnce(false, false, isRunning, generation)
        end)
        if not ok then
            warn("[HipHub Performance] FPS boost failed: " .. tostring(err))
        end
        if not waitForAutomationDelay(
            math.max(getgenv().performanceConfig.APPLY_INTERVAL, 5),
            isRunning,
            generation
        ) then
            break
        end
    end

    restorePerformanceState()
end

function setLowEndPerformanceRunning(value)
    lowEndPerformanceRunning = value == true
end

function setPerformancePassRunning(value)
    performancePassRunning = value == true
end

function refreshPerformanceVisuals(showNotification)
    startAutomationWorker("PerformancePass", setPerformancePassRunning, function()
        local generation = automationCancellationGeneration
        applyLowEndPerformanceOnce(showNotification == true, true, function()
            return performancePassRunning
        end, generation)
    end, false)
end

function setPerformanceVisualOption(owner, enabled)
    if not enabled then
        restoreVisualState(owner)
        return
    end
    if lowEndPerformanceRunning or performanceRestoreState.VisualApplied then
        refreshPerformanceVisuals(false)
    end
end

function countDictionary(tbl)
    local count = 0
    if type(tbl) == "table" then
        for _ in pairs(tbl) do
            count = count + 1
        end
    end
    return count
end

function getFarmingClientPlot()
    local plotCmds = Library:FindFirstChild("Client")
        and Library.Client:FindFirstChild("PlotCmds")
        and Library.Client.PlotCmds:FindFirstChild("ClientPlot")
    if not plotCmds then
        return nil
    end

    local ok, clientPlot = pcall(require, plotCmds)
    if not ok or type(clientPlot) ~= "table" or type(clientPlot.GetLocal) ~= "function" then
        return nil
    end

    local gotPlot, plot = pcall(clientPlot.GetLocal)
    if not gotPlot or not plot then
        return nil
    end

    local gotDir, dirId = pcall(function()
        return plot:GetDirectory()._id
    end)
    if gotDir and dirId == "FarmingWorld" then
        return plot
    end

    return nil
end

function getFarmingPlotModel()
    local plot = getFarmingClientPlot()
    if not plot then
        return nil
    end

    local ok, model = pcall(function()
        return plot:GetModel()
    end)
    if ok then
        return model
    end

    return nil
end

function getFarmingEggFloor()
    local model = getFarmingPlotModel()
    local interactable = model and model:FindFirstChild("Interactable")
    return interactable and interactable:FindFirstChild("EggFloor")
end

function moveToFarmingPlot()
    local model = getFarmingPlotModel()
    if not model then
        return false
    end

    local floor = getFarmingEggFloor()
    local spawnPosition = model:FindFirstChild("SpawnPosition")
    local target = spawnPosition or floor
    if not target then
        return false
    end

    getHumanoidRootPart().CFrame = target.CFrame + Vector3.new(0, 6, 0)
    return true
end

function ensureFarmingWorldReady(isRunning)
    local function canContinue()
        return isRunning == nil or isRunning()
    end
    if not canContinue() then
        return false
    end
    if getFarmingClientPlot() and getFarmingEggFloor() then
        return canContinue() and moveToFarmingPlot()
    end

    if getgenv().autoFarmingWorldConfig.ENTER and canContinue() then
        enterInstance("FarmingWorld")
    end

    local deadline = os.clock() + 8
    repeat
        if not canContinue() then
            return false
        end
        if getFarmingClientPlot() and getFarmingEggFloor() then
            return canContinue() and moveToFarmingPlot()
        end
        if not waitForRunningDelay(0.25, isRunning) then
            return false
        end
    until os.clock() >= deadline

    notifyFlow("Farming World", "Farm plot is not loaded.", 2.5)
    return false
end

function getFarmingPlacementPosition(index)
    local floor = getFarmingEggFloor()
    if not floor then
        return nil
    end

    local spacing = math.max(tonumber(getgenv().autoFarmingWorldConfig.GRID_SPACING) or 11, 6)
    local xSlots = math.max(math.floor((floor.Size.X - 10) / spacing), 1)
    local zSlots = math.max(math.floor((floor.Size.Z - 10) / spacing), 1)
    local slot = ((math.max(tonumber(index) or 1, 1) - 1) % (xSlots * zSlots))
    local x = (slot % xSlots) * spacing - ((xSlots - 1) * spacing / 2)
    local z = math.floor(slot / xSlots) * spacing - ((zSlots - 1) * spacing / 2)
    return (floor.CFrame * CFrame.new(x, floor.Size.Y / 2 + 0.2, z)).Position
end

function getFarmingPlacedCount()
    local save = getSaveData() or {}
    return countDictionary(save.FarmingWorldEggs)
        + countDictionary(save.FarmingWorldPets)
        + countDictionary(save.FarmingWorldSprinklers)
end

function getFarmingPlacedIds(bucketName)
    local ids = {}
    local save = getSaveData() or {}
    local bucket = save[bucketName]
    if type(bucket) == "table" then
        for uid, data in pairs(bucket) do
            table.insert(ids, tostring(uid))
            if type(data) == "table" then
                for _, key in ipairs({ "UID", "Uid", "uid", "_uid", "id", "Id" }) do
                    if data[key] then
                        table.insert(ids, tostring(data[key]))
                    end
                end
            end
        end
    end

    return ids
end

function getFarmingInventoryItems(bucketNames, matcher)
    local items = {}
    for _, item in ipairs(collectInventoryItems(bucketNames)) do
        local itemName = getInventoryItemName(item.Data)
        if getInventoryItemCount(item.Data) > 0 and (not matcher or matcher(itemName, item)) then
            table.insert(items, item)
        end
    end
    return items
end

function harvestFarmingEggsOnce(isRunning)
    local function canContinue()
        return isRunning == nil or isRunning()
    end
    local remote = Network:FindFirstChild("Farming_Harvest")
    if not remote then
        return false
    end

    local ids = getFarmingPlacedIds("FarmingWorldEggs")
    local didAny = false
    for _, uid in ipairs(ids) do
        if not canContinue() then
            break
        end
        if invokeRemoteAny(remote, {
            { uid },
            { tostring(uid) }
        }) then
            didAny = true
        end
    end

    if #ids == 0 then
        local farmEggs = Workspace:FindFirstChild("__THINGS") and Workspace.__THINGS:FindFirstChild("FarmEggs")
        if farmEggs then
            for _, egg in ipairs(farmEggs:GetChildren()) do
                if not canContinue() then
                    break
                end
                if egg:GetAttribute("OwnerId") == LocalPlayer.UserId then
                    for _, key in ipairs({ "UID", "Uid", "uid", "EggUID", "EggUid", "Id", "ID" }) do
                        if not canContinue() then
                            break
                        end
                        local value = egg:GetAttribute(key)
                        if value and invokeRemoteAny(remote, { { tostring(value) }, { value } }) then
                            didAny = true
                        end
                    end
                end
            end
        end
    end

    return didAny
end

function getFarmingStorageItemCount(isRunning)
    local remote = Network:FindFirstChild("Farming_GetStorage")
    if not remote then
        return nil
    end

    local done = false
    local ok, storage
    task.spawn(function()
        ok, storage = pcall(function()
            return remote:InvokeServer()
        end)
        done = true
    end)

    local deadline = os.clock() + 3
    repeat
        if isRunning and not isRunning() then
            return nil
        end
        if done then
            break
        end
        if not waitForRunningDelay(0.05, isRunning) then
            return nil
        end
    until os.clock() >= deadline

    if not done then
        return nil
    end

    if not ok or type(storage) ~= "table" then
        return nil
    end

    local total = 0
    for _, bucket in pairs(storage) do
        if type(bucket) == "table" then
            for _, itemData in pairs(bucket) do
                total = total + getInventoryItemCount(itemData)
            end
        end
    end

    return total
end

function claimFarmingStorageOnce(isRunning)
    local function canContinue()
        return isRunning == nil or isRunning()
    end
    if not Network:FindFirstChild("Farming_ClaimStorage") then
        return false
    end

    local stored = getFarmingStorageItemCount(isRunning)
    if not canContinue() or not stored or stored == 0 then
        return false
    end

    return invokeRemoteAny(Network.Farming_ClaimStorage, { {} }) == true
end

function plantFarmingEggsOnce(isRunning)
    local function canContinue()
        return isRunning == nil or isRunning()
    end
    local remote = Network:FindFirstChild("Farming_Plant")
    if not remote then
        return 0
    end

    local planted = 0
    local maxPlants = math.max(tonumber(getgenv().autoFarmingWorldConfig.MAX_PLANTS_PER_STEP) or 3, 1)
    local slot = getFarmingPlacedCount() + 1
    for _, item in ipairs(getFarmingInventoryItems({ "EggFarm", "EggFarmItem", "EggFarmItems" })) do
        if not canContinue() then
            break
        end
        local count = math.min(getInventoryItemCount(item.Data), maxPlants - planted)
        for _ = 1, count do
            if not canContinue() then
                return planted
            end
            local position = getFarmingPlacementPosition(slot)
            if not position then
                return planted
            end

            if invokeRemoteAny(remote, { { position, tostring(item.Uid) } }) then
                planted = planted + 1
                slot = slot + 1
                if not waitForRunningDelay(0.2, isRunning) then
                    return planted
                end
            else
                return planted
            end

            if planted >= maxPlants then
                return planted
            end
        end
    end

    return planted
end

function placeFarmingWorkersOnce(isRunning)
    local function canContinue()
        return isRunning == nil or isRunning()
    end
    local remote = Network:FindFirstChild("Farming_PlacePet")
    if not remote then
        return 0
    end

    local placed = 0
    local maxWorkers = math.max(tonumber(getgenv().autoFarmingWorldConfig.MAX_WORKERS_PER_STEP) or 2, 1)
    local slot = getFarmingPlacedCount() + 1
    for _, item in ipairs(getFarmingInventoryItems({ "Worker", "Workers", "WorkerItem", "WorkerItems" })) do
        if not canContinue() then
            break
        end
        local position = getFarmingPlacementPosition(slot)
        if not position then
            return placed
        end

        if invokeRemoteAny(remote, { { tostring(item.Uid), position } }) then
            placed = placed + 1
            slot = slot + 1
            if not waitForRunningDelay(0.2, isRunning) then
                return placed
            end
        end

        if placed >= maxWorkers then
            return placed
        end
    end

    return placed
end

function placeFarmingSprinklersOnce(isRunning)
    local function canContinue()
        return isRunning == nil or isRunning()
    end
    local remote = Network:FindFirstChild("Farming_PlaceSprinkler")
    if not remote then
        return 0
    end

    local placed = 0
    local maxSprinklers = math.max(tonumber(getgenv().autoFarmingWorldConfig.MAX_SPRINKLERS_PER_STEP) or 1, 1)
    local slot = getFarmingPlacedCount() + 1
    for _, item in ipairs(getFarmingInventoryItems({ "Misc", "MiscItems", "Items", "Item" }, function(itemName)
        return collapseKey(itemName):find("farmingsprinkler", 1, true) ~= nil
    end)) do
        if not canContinue() then
            break
        end
        local position = getFarmingPlacementPosition(slot)
        if not position then
            return placed
        end

        if invokeRemoteAny(remote, { { getInventoryItemName(item.Data), position } }) then
            placed = placed + 1
            slot = slot + 1
            if not waitForRunningDelay(0.2, isRunning) then
                return placed
            end
        end

        if placed >= maxSprinklers then
            return placed
        end
    end

    return placed
end

function getFarmingFoodItem()
    local priority = {
        "Pixel Burger",
        "Pixel Cookie",
        "Pixel Corn",
        "Pixel Potato",
        "Pixel Carrot"
    }

    for _, foodName in ipairs(priority) do
        local found = findInventoryConsumableByNames({ "Misc", "MiscItems", "Items", "Item" }, { foodName })
        if found then
            return found
        end
    end

    return nil
end

function feedFarmingPetsOnce(isRunning)
    local function canContinue()
        return isRunning == nil or isRunning()
    end
    local remote = Network:FindFirstChild("Farming_Feed")
    if not remote then
        return 0
    end

    local food = getFarmingFoodItem()
    if not food then
        return 0
    end

    local fed = 0
    local amount = math.max(tonumber(getgenv().autoFarmingWorldConfig.FOOD_AMOUNT) or 1, 1)
    for _, petUid in ipairs(getFarmingPlacedIds("FarmingWorldPets")) do
        if not canContinue() then
            break
        end
        if invokeRemoteAny(remote, { { petUid, tostring(food.Uid), amount } }) then
            fed = fed + 1
            if not waitForRunningDelay(0.2, isRunning) then
                break
            end
        end
    end

    return fed
end

function runFarmingWorldStep(isRunning)
    local function canContinue()
        return isRunning == nil or isRunning()
    end
    if not ensureFarmingWorldReady(isRunning) or not canContinue() then
        return false
    end

    local didAny = false
    local planted = 0
    local workers = 0
    local sprinklers = 0
    local fed = 0

    if canContinue() and getgenv().autoFarmingWorldConfig.CLAIM_STORAGE and claimFarmingStorageOnce(isRunning) then
        didAny = true
    end

    if canContinue() and getgenv().autoFarmingWorldConfig.HARVEST and harvestFarmingEggsOnce(isRunning) then
        didAny = true
    end

    if canContinue() and getgenv().autoFarmingWorldConfig.PLANT_EGGS then
        planted = plantFarmingEggsOnce(isRunning)
        didAny = didAny or planted > 0
    end

    if canContinue() and getgenv().autoFarmingWorldConfig.PLACE_WORKERS then
        workers = placeFarmingWorkersOnce(isRunning)
        didAny = didAny or workers > 0
    end

    if canContinue() and getgenv().autoFarmingWorldConfig.PLACE_SPRINKLERS then
        sprinklers = placeFarmingSprinklersOnce(isRunning)
        didAny = didAny or sprinklers > 0
    end

    if canContinue() and getgenv().autoFarmingWorldConfig.FEED_PETS then
        fed = feedFarmingPetsOnce(isRunning)
        didAny = didAny or fed > 0
    end

    if didAny then
        notifyFlow("Farming World", string.format("Planted %d / workers %d / sprinklers %d / fed %d", planted, workers, sprinklers, fed), 2.5)
    end

    return didAny
end

function runAutoFarmingWorld()
    local function isRunning()
        return autoFarmingWorldRunning and not getgenv().STAFF_DETECTED
    end
    while autoFarmingWorldRunning and not getgenv().STAFF_DETECTED do
        runFarmingWorldStep(isRunning)
        if not waitForRunningDelay(math.max(getgenv().autoFarmingWorldConfig.DELAY, 5), isRunning) then
            break
        end
    end
    autoFarmingWorldRunning = false
end

local KEY_HELPER_DEFINITIONS = {
    ["Crystal Key"] = { Combine = "CrystalKey_Combine", Unlock = "CrystalKey_Unlock" },
    ["Tech Key"] = { Combine = "TechKey_Combine", Unlock = "TechKey_Unlock" },
    ["Void Key"] = { Combine = "VoidKey_Combine", Unlock = "VoidKey_Unlock" },
    ["Prison Key"] = { Unlock = "PrisonKey_Use" },
    ["Hacker Key"] = { Unlock = "HackerKey_Unlock" },
    ["Fantasy Key"] = { Combine = "FantasyKey_Combine", Unlock = "FantasyKey_Unlock" },
    ["Secret Key"] = { Combine = "SecretKey_Combine", Unlock = "SecretRoom_Unlock" },
    ["MVP Key"] = { Combine = "MVPKey_Combine", Unlock = "MVPKey_Unlock" }
}

function runKeyHelperAction(actionName, amount)
    local definition = KEY_HELPER_DEFINITIONS[selectedKeyHelper]
    local remoteName = definition and definition[actionName]
    if not remoteName then
        notifyFlow("Keys", tostring(selectedKeyHelper) .. " does not support " .. tostring(actionName):lower() .. ".", 2.5)
        return false
    end

    local remote = Network:FindFirstChild(remoteName)
    if not remote then
        notifyFlow("Keys", "Missing remote: " .. remoteName, 2.5)
        return false
    end

    local usedAny = false
    local keyUids = getKeyItemUids({ selectedKeyHelper })
    local keyName = selectedKeyHelper:gsub("%s+", "")
    for _ = 1, math.max(tonumber(amount) or 1, 1) do
        local argSets = {}
        if actionName == "Unlock" then
            for _, uid in ipairs(keyUids) do
                table.insert(argSets, { uid })
                table.insert(argSets, { selectedKeyHelper, uid })
                table.insert(argSets, { keyName, uid })
            end
            if #argSets == 0 then
                notifyFlow("Keys", "No " .. tostring(selectedKeyHelper) .. " found.", 2.5)
                return false
            end
        else
            argSets = {
                {},
                { selectedKeyHelper },
                { keyName }
            }
        end

        local used = invokeRemoteAny(remote, argSets)
        if not used then
            break
        end
        usedAny = true
        task.wait(0.1)
    end

    notifyFlow("Keys", usedAny and "Requested " .. actionName:lower() .. " for " .. selectedKeyHelper or "Key action failed.", 2.5)
    return usedAny
end

function teleportToZoneName(mapPath, selectedZone)
    local zonePath = findZonePathByName(mapPath, selectedZone)
    if zonePath and zonePath:FindFirstChild("PERSISTENT") then
        getHumanoidRootPart().CFrame = zonePath.PERSISTENT.Teleport.CFrame
    end
    return zonePath
end

function waitForZoneBreakables(zonePath)
    if not waitForZoneInteract(zonePath, function()
        return autoBalloonChestRunning or getgenv().autoChest
    end) then
        return false
    end

    local breakZonesFolder = zonePath.INTERACT:FindFirstChild("BREAK_ZONES")
    if not breakZonesFolder then
        return false
    end

    local function getBreakZoneCount()
        local count = 0
        for _ in ipairs(breakZonesFolder:GetChildren()) do
            count = count + 1
        end
        return count
    end

    if getBreakZoneCount() >= 2 then
        return true
    end

    local loaded = false
    local connection = breakZonesFolder.ChildAdded:Connect(function()
        if getBreakZoneCount() >= 2 then
            loaded = true
        end
    end)

    repeat
        task.wait()
    until loaded or getBreakZoneCount() >= 2 or (not autoBalloonChestRunning and not getgenv().autoChest)

    connection:Disconnect()
    return getBreakZoneCount() >= 2
end

function moveToChestScanPosition(zonePath)
    if not zonePath or not zonePath:FindFirstChild("INTERACT") then
        return false
    end

    local bossSpawn = zonePath.INTERACT:FindFirstChild("BREAKABLE_SPAWNS")
    bossSpawn = bossSpawn and bossSpawn:FindFirstChild("Boss")
    if bossSpawn and bossSpawn:IsA("BasePart") then
        getHumanoidRootPart().CFrame = bossSpawn.CFrame + Vector3.new(0, 6, 0)
        return true
    end

    local closestBreakZone = getClosestBreakZone(zonePath)
    if closestBreakZone then
        getHumanoidRootPart().CFrame = closestBreakZone.CFrame + Vector3.new(0, 8, 0)
        return true
    end

    if zonePath:FindFirstChild("PERSISTENT") then
        getHumanoidRootPart().CFrame = zonePath.PERSISTENT.Teleport.CFrame + Vector3.new(0, 10, 0)
        return true
    end

    return false
end

function isWithinRange(part)
    local targetPosition
    if part:IsA("Model") then
        targetPosition = part:GetPivot().Position
    elseif part:IsA("BasePart") then
        targetPosition = part.Position
    end

    if not targetPosition then
        return false
    end

    return (getHumanoidRootPart().Position - targetPosition).Magnitude <= 300
end

function breakBigChest(zonePath, zoneName)
    local client = Library:FindFirstChild("Client")
    if not client then
        return false
    end
    local function isRunning()
        return (autoBalloonChestRunning or getgenv().autoChest) and not getgenv().STAFF_DETECTED
    end
    local chest

    while isRunning() and not chest do
        for chestId in require(client.BreakableCmds).AllByZoneAndClass(zoneName, "Chest") do
            chest = chestId
            break
        end
        task.wait()
    end

    if not chest or not isRunning() then
        return false
    end

    if getgenv().autoChestConfig.SEND_PETS and isRunning() then
        setEquippedPetsTarget(chest)
    end

    local brokeChest = false
    local connection = Workspace.__THINGS.Breakables.ChildRemoved:Connect(function(breakable)
        if breakable.Name == chest then
            brokeChest = true
        end
    end)

    local breakOk, breakError = pcall(function()
        local bossSpawn = zonePath.INTERACT:FindFirstChild("BREAKABLE_SPAWNS")
        bossSpawn = bossSpawn and bossSpawn:FindFirstChild("Boss")
        if bossSpawn and isRunning() then
            getHumanoidRootPart().CFrame = bossSpawn.CFrame
        end

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
                local remote = Network:FindFirstChild("Breakables_PlayerDealDamage")
                if remote then
                    remote:FireServer(chest)
                end
            end)
            task.wait()
        until brokeChest or not isRunning()
    end)

    disconnectConnection(connection)
    if not breakOk then
        warn("[Chest] Break failed and listener was cleaned up: " .. tostring(breakError))
        return false
    end
    return brokeChest
end

function isOwnedBalloonBreakable(breakable)
    if not breakable then
        return false
    end

    local ownerUsername = tostring(breakable:GetAttribute("OwnerUsername") or "")
    local ownerUserId = tostring(
        breakable:GetAttribute("OwnerUserId")
            or breakable:GetAttribute("OwnerUserID")
            or breakable:GetAttribute("OwnerId")
            or ""
    )
    local displayKey = collapseKey(getBreakableDisplayName(breakable))

    if displayKey == "" then
        return false
    end

    if ownerUsername ~= LocalPlayer.Name and ownerUserId ~= tostring(LocalPlayer.UserId) then
        return false
    end

    return displayKey:find("smallballoongift", 1, true) ~= nil
        or displayKey:find("balloongift", 1, true) ~= nil
end

function getOwnedBalloonBreakables()
    local breakablesFolder = Workspace:FindFirstChild("__THINGS") and Workspace.__THINGS:FindFirstChild("Breakables")
    local ownedBalloonBreakables = {}

    if breakablesFolder then
        for _, breakable in ipairs(breakablesFolder:GetChildren()) do
            if isOwnedBalloonBreakable(breakable) then
                table.insert(ownedBalloonBreakables, breakable)
            end
        end
    end

    table.sort(ownedBalloonBreakables, function(a, b)
        return tostring(getBreakableTargetId(a) or a.Name) < tostring(getBreakableTargetId(b) or b.Name)
    end)

    return ownedBalloonBreakables, breakablesFolder
end

function getBalloonReloadScanZones()
    local scanZones = {}
    local seen = {}
    local firstZone

    for _, zoneInfo in ipairs(getAvailableZoneEntries()) do
        if isZoneEntryUnlocked(zoneInfo) then
            firstZone = zoneInfo
            break
        end
    end

    local bestZone = getLatestUnlockedBestArea()

    for _, zoneInfo in ipairs({ firstZone, bestZone }) do
        if zoneInfo and zoneInfo.FullName and not seen[zoneInfo.FullName] then
            seen[zoneInfo.FullName] = true
            table.insert(scanZones, zoneInfo)
        end
    end

    return scanZones
end

function scanBreakableZonesForOwnedBalloons(isRunning)
    local ownedBalloonBreakables, breakablesFolder = getOwnedBalloonBreakables()
    local hrp = getHumanoidRootPart()
    local originalPosition = hrp.CFrame

    if #ownedBalloonBreakables > 0 then
        return ownedBalloonBreakables, breakablesFolder, originalPosition
    end

    print("[Balloon] Reloading breakable areas at first zone and best area for owned balloon drops")

    for _, zoneInfo in ipairs(getBalloonReloadScanZones()) do
        if isRunning and not isRunning() then
            break
        end

        if moveToBreakableZone(zoneInfo, isRunning) then
            print("[Balloon] Checking " .. tostring(zoneInfo.FullName) .. " for owned giftboxes")
            if not waitForRunningDelay(math.max(getgenv().autoBalloonChestConfig.BALLOON_DELAY, 0.2), isRunning) then
                break
            end

            if isRunning and not isRunning() then
                break
            end
            ownedBalloonBreakables, breakablesFolder = getOwnedBalloonBreakables()
            if #ownedBalloonBreakables > 0 then
                print("[Balloon] Detected owned balloon drop in " .. tostring(zoneInfo.FullName))
                return ownedBalloonBreakables, breakablesFolder, originalPosition
            end
        end
    end

    if (not isRunning or isRunning()) and hrp.Parent then
        hrp.CFrame = originalPosition
    end
    return {}, breakablesFolder, nil
end

function popOwnedBalloonBreakables(ownedBalloonBreakables, breakablesFolder, returnPosition)
    if #ownedBalloonBreakables == 0 then
        return false
    end

    local hrp = getHumanoidRootPart()
    local balloonGeneration = automationThreadState.Generations[coroutine.running()]
        or automationCancellationGeneration
    local function isRunning()
        return balloonGeneration == automationCancellationGeneration
            and flowSessionGeneration == getgenv().FlowPS99Generation
            and autoBalloonChestRunning
            and not getgenv().STAFF_DETECTED
    end

    for _, breakable in ipairs(ownedBalloonBreakables) do
        if not isRunning() then
            break
        end

        local targetId = tostring(getBreakableTargetId(breakable) or breakable.Name)
        print(string.format(
            "[Balloon] Popping owned %s (%s)",
            tostring(getBreakableDisplayName(breakable) or "Balloon Gift"),
            targetId
        ))

        local removed = false
        local connection
        if breakablesFolder then
            connection = breakablesFolder.ChildRemoved:Connect(function(child)
                if child == breakable or tostring(getBreakableTargetId(child) or child.Name) == targetId then
                    removed = true
                end
            end)
        end

        local popOk, popError = pcall(function()
            if not waitForRunningDelay(2, isRunning) then
                return
            end

            for _ = 1, 25 do
                if removed or breakable.Parent == nil or not isRunning() then
                    break
                end

                teleportToBreakable(breakable)
                if not isRunning() then
                    break
                end
                damageBreakableByName(breakable)
                if not isRunning() then
                    break
                end
                firePrimaryClick()
                if not waitForRunningDelay(math.max(getgenv().autoBalloonChestConfig.BALLOON_DELAY, 0.1), isRunning) then
                    break
                end
            end
        end)

        disconnectConnection(connection)
        if not popOk then
            warn("[Balloon] Owned drop failed and listener was cleaned up: " .. tostring(popError))
        end
    end

    if returnPosition and isRunning() and hrp.Parent then
        hrp.CFrame = returnPosition
    end

    return true
end

function popAllBalloons()
    local balloonGeneration = automationThreadState.Generations[coroutine.running()]
        or automationCancellationGeneration
    local runningCheck = function()
        return balloonGeneration == automationCancellationGeneration
            and flowSessionGeneration == getgenv().FlowPS99Generation
            and autoBalloonChestRunning
            and not getgenv().STAFF_DETECTED
    end
    local ownedBalloonBreakables, breakablesFolder, ownedReturnPosition = scanBreakableZonesForOwnedBalloons(runningCheck)
    local poppedOwnedBalloons = popOwnedBalloonBreakables(ownedBalloonBreakables, breakablesFolder, ownedReturnPosition)

    if not runningCheck() then
        return
    end

    local activeBalloons = {}
    pcall(function()
        activeBalloons = Network.BalloonGifts_GetActiveBalloons:InvokeServer()
    end)
    if not runningCheck() then
        return false
    end

    local pendingBalloons = {}
    for balloonId, balloonData in pairs(activeBalloons) do
        if balloonData and not balloonData.Popped then
            pendingBalloons[balloonId] = balloonData
        end
    end

    if next(pendingBalloons) == nil then
        if not poppedOwnedBalloons then
            print("No balloons detected")
        end
        return
    end

    local hrp = getHumanoidRootPart()
    local originalPosition = hrp.CFrame
    local ownedPosition = originalPosition
    local slingshotOwned = false
    setRootAnchored(true, "Balloon")

    local actionOk, actionError = pcall(function()
        for balloonId, balloonData in pairs(pendingBalloons) do
            if not autoBalloonChestRunning or getgenv().STAFF_DETECTED then
                break
            end

            local balloonPosition = balloonData.Position
            print("Popping balloon in " .. tostring(balloonData.ZoneId))

            Network.Slingshot_Toggle:InvokeServer()
            slingshotOwned = true
            if not waitForRunningDelay(0.03, runningCheck) then
                return
            end

            hrp.CFrame = CFrame.new(balloonPosition.X, balloonPosition.Y + 30, balloonPosition.Z)
            ownedPosition = hrp.CFrame
            if not waitForRunningDelay(0.03, runningCheck) then
                return
            end

            if not runningCheck() then
                return
            end
            Network.Slingshot_FireProjectile:InvokeServer(
                Vector3.new(balloonPosition.X, balloonPosition.Y + 25, balloonPosition.Z),
                0.5794160315249014,
                -0.8331117721691044,
                200
            )

            if not waitForRunningDelay(0.1, runningCheck) then
                return
            end
            if not runningCheck() then
                return
            end
            Network.BalloonGifts_BalloonHit:FireServer(balloonId)
            if not runningCheck() then
                return
            end
            firePrimaryClick()
            if not waitForRunningDelay(0.03, runningCheck) then
                return
            end
            Network.Slingshot_Unequip:InvokeServer()
            slingshotOwned = false

            if not waitForRunningDelay(getgenv().autoBalloonChestConfig.BALLOON_DELAY, runningCheck) then
                return
            end
        end
    end)

    local ownsCleanup = flowSessionGeneration == getgenv().FlowPS99Generation
        and hrp.Parent ~= nil
        and (ownedPosition == nil or hrp.CFrame == ownedPosition)
    if ownsCleanup then
        if slingshotOwned then
            pcall(function()
                local unequip = Network:FindFirstChild("Slingshot_Unequip")
                if unequip then
                    unequip:InvokeServer()
                end
            end)
        end
        pcall(function()
            hrp.CFrame = originalPosition
        end)
    end
    restoreRootAnchored("Balloon")

    if not actionOk then
        warn("[Balloon] Action failed and was cleaned up: " .. tostring(actionError))
        return false
    end

    if not runningCheck() then
        return
    end

    ownedBalloonBreakables, breakablesFolder, ownedReturnPosition = scanBreakableZonesForOwnedBalloons(runningCheck)
    popOwnedBalloonBreakables(ownedBalloonBreakables, breakablesFolder, ownedReturnPosition)
    return true
end

function runAutoBalloonChestBody()
    ensureAntiStaff()
    ensurePetSpeed()
    local function isRunning()
        return autoBalloonChestRunning and not getgenv().STAFF_DETECTED
    end

    local mapPath = getCurrentMap()
    local chestZones = getBigChestZones()

    if not mapPath or next(chestZones) == nil then
        warn("No chest route available in this world.")
        autoBalloonChestRunning = false
        getgenv().autoBalloonChest = false
        autoBalloonChestLoopActive = false
        return
    end

    local sortedKeys = {}
    for key in pairs(chestZones) do
        table.insert(sortedKeys, key)
    end
    table.sort(sortedKeys)

    if not waitForRunningDelay(getgenv().autoBalloonChestConfig.START_DELAY, isRunning) then
        return false
    end

    while autoBalloonChestRunning and not getgenv().STAFF_DETECTED do
        popAllBalloons()

        if not autoBalloonChestRunning or getgenv().STAFF_DETECTED then
            break
        end

        if not waitForRunningDelay(getgenv().autoBalloonChestConfig.SWITCH_DELAY, isRunning) then
            break
        end

        for _, key in ipairs(sortedKeys) do
            if not autoBalloonChestRunning or getgenv().STAFF_DETECTED then
                break
            end

            local zoneName = chestZones[key]
            local zonePath = teleportToZoneName(mapPath, zoneName)
            if not zonePath or not waitForZoneBreakables(zonePath) then
                continue
            end

            local timerFound = false
            local scanDeadline = os.clock() + math.max(getgenv().autoBalloonChestConfig.TIMER_SEARCH_TIMEOUT, getgenv().autoBalloonChestConfig.TIMER_SEARCH_DELAY)
            moveToChestScanPosition(zonePath)

            while autoBalloonChestRunning and not timerFound and not getgenv().STAFF_DETECTED do
                for _, host in ipairs(Workspace.__DEBRIS:GetChildren()) do
                    local timer
                    local ok = pcall(function()
                        timer = host.ChestTimer.Timer.Text
                    end)

                    if host.Name == "host" and ok and isWithinRange(host) then
                        timerFound = true
                        if timer == "00:00" then
                            breakBigChest(zonePath, zoneName)
                        end
                        break
                    end
                end

                if timerFound then
                    break
                end

                if os.clock() >= scanDeadline then
                    warn(string.format("[Balloon] Timed out scanning %s chest host. Moving to the next zone.", tostring(zoneName)))
                    break
                end

                moveToChestScanPosition(zonePath)
                if not waitForRunningDelay(getgenv().autoBalloonChestConfig.TIMER_SEARCH_DELAY, isRunning) then
                    break
                end
            end

            if not waitForRunningDelay(getgenv().autoBalloonChestConfig.CHEST_BREAK_DELAY, isRunning) then
                break
            end
        end

        if not autoBalloonChestRunning or getgenv().STAFF_DETECTED then
            break
        end

        print("[Balloon] Route finished. Restarting the loop.")
        if not waitForRunningDelay(getgenv().autoBalloonChestConfig.SERVER_HOP_DELAY, isRunning) then
            break
        end

        if not autoBalloonChestRunning or getgenv().STAFF_DETECTED then
            break
        end

        if serverHop() then
            autoBalloonChestLoopActive = false
            return
        end

        warn("[Balloon] Server hop failed. Restarting in the current server.")
    end

    autoBalloonChestLoopActive = false
    autoBalloonChestRunning = false
    getgenv().autoBalloonChest = false
    return true
end

function setAutoBalloonChestRunning(value)
    autoBalloonChestRunning = value == true
    getgenv().autoBalloonChest = value == true
end

function runAutoBalloonChest()
    if autoBalloonChestLoopActive then
        return false
    end

    autoBalloonChestLoopActive = true
    local ok, result = pcall(runAutoBalloonChestBody)
    restoreRootAnchored("Balloon")
    clearOwnedPetTargets()
    autoBalloonChestLoopActive = false
    setAutoBalloonChestRunning(false)

    if not ok then
        warn("[Balloon] Automation failed and was cleaned up: " .. tostring(result))
        return false
    end
    return result ~= false
end

function syncAutoFruits()
    refreshAutoFruitList()

    local fruitsModule = require(Library.Client.FruitCmds)
    local fruitInventory = getInventoryBucket("Fruit") or {}
    local fruitIds = {}
    local neededFruits = {}
    local selectedFruitName = normalizeWhitespace(selectedAutoFruit)

    for itemId, itemData in pairs(fruitInventory) do
        local fruitName = normalizeWhitespace(getInventoryItemName(itemData))
        if isSelectableFruitName(fruitName) then
            fruitIds[fruitName] = itemId
            if selectedFruitName == AUTO_FRUIT_ALL or selectedFruitName == fruitName then
                neededFruits[fruitName] = true
            end
        end
    end

    for fruitName, fruitData in pairs(fruitsModule.GetActiveFruits()) do
        local normalizedFruitName = normalizeWhitespace(fruitName)
        local fruitItemId = fruitIds[normalizedFruitName]
        if fruitItemId then
            local amountToUse = 20 - #fruitData
            if amountToUse > 0 then
                fruitsModule.Consume(fruitItemId, amountToUse)
                task.wait(0.15)
            end
        end
        neededFruits[normalizedFruitName] = nil
    end

    for fruitName in pairs(neededFruits) do
        local fruitItemId = fruitIds[fruitName]
        if fruitItemId then
            fruitsModule.Consume(fruitItemId, 20)
            task.wait(0.15)
        end
    end
end

function useAvailableFruitForQuest()
    local fruitItems = {}
    local seenFruitIds = {}

    for _, bucketName in ipairs({ "Fruit", "Fruits" }) do
        local fruitInventory = getInventoryBucket(bucketName) or {}
        for itemId, itemData in pairs(fruitInventory) do
            local fruitId = tostring(itemId)
            local fruitName = normalizeWhitespace(getInventoryItemName(itemData))
            if not seenFruitIds[fruitId] and isSelectableFruitName(fruitName) and getInventoryItemCount(itemData) > 0 then
                seenFruitIds[fruitId] = true
                table.insert(fruitItems, {
                    Id = fruitId,
                    Name = fruitName
                })
            end
        end
    end

    if #fruitItems == 0 then
        return false
    end

    local fruitItem = fruitItems[BREAKABLE_RANDOM:NextInteger(1, #fruitItems)]
    local usedFruit = invokeNamedRemote("Fruits: Consume", "fire_uid_amount", 1, fruitItem.Id)
    if usedFruit then
        print("[Auto Quest] Used random fruit: " .. tostring(fruitItem.Name))
        return true, fruitItem.Name
    end

    return false, fruitItem.Name
end

function syncAutoBundles()
    refreshAutoBundleList()

    local fruitsModule = require(Library.Client.FruitCmds)
    local fruitInventory = getInventoryBucket("Fruit") or {}
    local selectedBundleName = normalizeWhitespace(selectedAutoBundle)

    for itemId, itemData in pairs(fruitInventory) do
        local bundleName = normalizeWhitespace(getInventoryItemName(itemData))
        if isSelectableBundleName(bundleName) then
            if selectedBundleName == AUTO_BUNDLE_ALL or selectedBundleName == bundleName then
                local amount = getInventoryItemCount(itemData)
                if amount > 0 then
                    fruitsModule.Consume(itemId, 1)
                    task.wait(0.15)
                end
            end
        end
    end
end

function runAutoFruits()
    ensureAntiStaff()

    while autoFruitRunning and not getgenv().STAFF_DETECTED do
        executeFruitAction(selectedConsumableFruitName, fruitConsumeAmount)
        task.wait(1)
    end
end

function runAutoBundles()
    ensureAntiStaff()
    syncAutoBundles()

    if bundleUpdateConnection then
        disconnectConnection(bundleUpdateConnection)
        bundleUpdateConnection = nil
    end

    bundleUpdateConnection = require(Library.Client.Network).Fired("Fruits: Update"):Connect(function()
        if not autoBundleRunning or getgenv().STAFF_DETECTED then
            return
        end
        task.spawn(syncAutoBundles)
    end)

    while autoBundleRunning and not getgenv().STAFF_DETECTED do
        syncAutoBundles()
        task.wait(1)
    end

    if bundleUpdateConnection then
        disconnectConnection(bundleUpdateConnection)
        bundleUpdateConnection = nil
    end
end

function runAutoFlags()
    ensureAntiStaff()

    while autoFlagsRunning and not getgenv().STAFF_DETECTED do
        executeFlagAction(selectedAutoFlagName, flagUseAmount, function()
            return autoFlagsRunning and not getgenv().STAFF_DETECTED
        end)

        if not autoFlagsRunning or getgenv().STAFF_DETECTED then
            break
        end

        if not waitForRunningDelay(math.max(getgenv().autoFlagsConfig.USE_DELAY, 1), function()
            return autoFlagsRunning and not getgenv().STAFF_DETECTED
        end) then
            break
        end
    end

    autoFlagsRunning = false
end

function runAutoItems()
    ensureAntiStaff()

    while autoItemRunning and not getgenv().STAFF_DETECTED do
        executeUtilityItemAction(selectedUtilityItemName, itemUseAmount)
        task.wait(1)
    end

    autoItemRunning = false
end

function runAutoBoosts()
    ensureAntiStaff()

    while autoBoostRunning and not getgenv().STAFF_DETECTED do
        executeBoostAction(selectedBoostItemName, boostUseAmount)
        task.wait(1)
    end

    autoBoostRunning = false
end

local diamondCost = {
    [1] = 150,
    [2] = 300,
    [3] = 600,
    [4] = 900,
    [5] = 1350,
    [6] = 1800,
    [7] = 2400,
    [8] = 3000,
    [9] = 3600,
    [10] = 4200,
    [13] = 10600,
    [15] = 13600,
    [17] = 16600,
    [19] = 20100,
    [21] = 23700,
    [23] = 27300,
    [25] = 30900,
    [27] = 34500,
    [29] = 38500,
    [31] = 42700,
    [34] = 72000,
    [35] = 26100,
    [38] = 85500,
    [41] = 96300,
    [44] = 107000,
    [47] = 117000,
    [50] = 128000,
    [53] = 750000,
    [56] = 1200000,
    [59] = 1650000,
    [62] = 2100000,
    [65] = 2550000,
    [68] = 3000000,
    [69] = 1100000,
    [70] = 1150000,
    [71] = 1200000,
    [72] = 1250000,
    [73] = 1250000,
    [74] = 1300000,
    [75] = 1350000
}

function getNextEggSlotUpgrade(currentEggs, maxPurchasable)
    local current = math.max(math.floor(tonumber(currentEggs) or 0), 0)
    local limit = math.max(math.floor(tonumber(maxPurchasable) or current), current)
    local nextSlot
    for slot in pairs(diamondCost) do
        if slot > current and slot <= limit and (not nextSlot or slot < nextSlot) then
            nextSlot = slot
        end
    end
    return nextSlot
end

function teleportToEggMachine()
    local backyard = findZonePathByName(nil, "Backyard")
    if not backyard or not backyard:FindFirstChild("PERSISTENT") then
        return false
    end

    getHumanoidRootPart().CFrame = backyard.PERSISTENT.Teleport.CFrame
    task.wait()

    if not waitForZoneInteract(backyard, function()
        return autoEggRunning
    end) then
        return false
    end

    local machinePad = backyard.INTERACT
        and backyard.INTERACT:FindFirstChild("Machines")
        and backyard.INTERACT.Machines:FindFirstChild("EggSlotsMachine")
        and backyard.INTERACT.Machines.EggSlotsMachine:FindFirstChild("PadGlow")

    if not machinePad then
        return false
    end

    getHumanoidRootPart().CFrame = machinePad.CFrame
    return true
end

function runAutoEggSlots()
    ensureAntiStaff()

    local saveModule = require(Library.Client.Save)
    local rankCmds = require(Library.Client.RankCmds)
    local currencyCmds = require(Library.Client.CurrencyCmds)
    local function isRunning()
        return autoEggRunning and not getgenv().STAFF_DETECTED
    end

    while autoEggRunning and not getgenv().STAFF_DETECTED do
        local currentEggs = saveModule.Get().EggSlotsPurchased
        local maxPurchasable = rankCmds.GetMaxPurchasableEggSlots()
        local nextSlot = getNextEggSlotUpgrade(currentEggs, maxPurchasable)
        local nextCost = nextSlot and diamondCost[nextSlot] or nil

        if currentEggs >= maxPurchasable then
            while autoEggRunning and not getgenv().STAFF_DETECTED and maxPurchasable == rankCmds.GetMaxPurchasableEggSlots() do
                if not waitForRunningDelay(getgenv().autoEggConfig.RANK_WAIT_DELAY, isRunning) then
                    break
                end
            end
        elseif not nextSlot or not nextCost then
            if not waitForRunningDelay(getgenv().autoEggConfig.RANK_WAIT_DELAY, isRunning) then
                break
            end
        else
            while autoEggRunning and not getgenv().STAFF_DETECTED and currencyCmds.Get("Diamonds") < nextCost do
                if not waitForRunningDelay(getgenv().autoEggConfig.GEM_WAIT_DELAY, isRunning) then
                    break
                end
            end

            if not autoEggRunning or getgenv().STAFF_DETECTED then
                break
            end

            local originalPosition = getHumanoidRootPart().CFrame
            if teleportToEggMachine() then
                Network.EggHatchSlotsMachine_RequestPurchase:InvokeServer(nextSlot)
                print("Purchased egg slot " .. tostring(nextSlot))
            end
            getHumanoidRootPart().CFrame = originalPosition
        end
    end

    autoEggRunning = false
    getgenv().autoEgg = false
end

function hatchSelectedEgg()
    ensureAntiStaff()

    if not selectedEggName then
        warn("No egg selected")
        return false
    end

    return hatchEggByName(selectedEggName, eggHatchAmount)
end

function runAutoEggHatcher()
    ensureAntiStaff()

    while autoEggHatcherRunning and not getgenv().STAFF_DETECTED do
        if selectedHatchMode == HATCH_MODE_LATEST then
            hatchLatestEggOnce()
        else
            hatchSelectedEgg()
        end
        task.wait(eggHatchDelay)
    end

    autoEggHatcherRunning = false
end

function runAutoRNGRoll()
    ensureAntiStaff()

    if not isRngEventAvailable() then
        autoRNGRollRunning = false
        getgenv().FlowPS99LastRNGBlocked = {
            Reason = "The RNG event transports are unavailable in this game version.",
            Time = os.clock()
        }
        notifyFlow("RNG Event", "This legacy event is not active in the current update.", 3)
        return
    end

    while autoRNGRollRunning and not getgenv().STAFF_DETECTED do
        rollRNGOnce()
        task.wait(rngRollDelay)
    end

    autoRNGRollRunning = false
end

function claimRankReward(rewardIndex)
    rewardIndex = math.max(tonumber(rewardIndex) or 1, 1)
    local save = getSaveData()
    if save then
        local currentRank = tonumber(save.Rank) or 0
        local redeemed = type(save.RedeemedRankRewards) == "table"
            and (save.RedeemedRankRewards[rewardIndex] == true or save.RedeemedRankRewards[tostring(rewardIndex)] == true)
        if rewardIndex > currentRank or redeemed then
            return false
        end
    end

    local ok, result = pcall(function()
        return Network.Ranks_ClaimReward:FireServer(rewardIndex)
    end)

    if not ok then
        warn("Rank reward claim failed for #" .. tostring(rewardIndex) .. ": " .. tostring(result))
        return false
    end

    print("Requested rank reward #" .. tostring(rewardIndex))
    return true
end

function getMaxRankRewardIndex()
    local saveData = getSaveData()
    local currentRank = saveData and math.floor(tonumber(saveData.Rank) or 0) or 0
    if currentRank > 0 then
        return currentRank
    end

    local discoveredMax = 0
    for _, entry in ipairs(discoverDirectoryEntries("Ranks")) do
        discoveredMax = math.max(discoveredMax, tonumber(entry.Number) or 0)
    end
    return math.max(discoveredMax, 1)
end

function runAutoRankRewards()
    ensureAntiStaff()
    local function isRunning()
        return autoRankRewardsRunning and not getgenv().STAFF_DETECTED
    end

    while autoRankRewardsRunning and not getgenv().STAFF_DETECTED do
        for rewardIndex = 1, getMaxRankRewardIndex() do
            if not autoRankRewardsRunning or getgenv().STAFF_DETECTED then
                break
            end

            claimRankReward(rewardIndex)
            if not waitForRunningDelay(getgenv().autoRankRewardsConfig.CLAIM_DELAY, isRunning) then
                break
            end
        end

        if autoRankRewardsRunning and not getgenv().STAFF_DETECTED then
            if not waitForRunningDelay(getgenv().autoRankRewardsConfig.SWEEP_DELAY, isRunning) then
                break
            end
        end
    end

    autoRankRewardsRunning = false
end

function tryUnlockEgg(eggData)
    if not eggData or not eggData.Name then
        return false
    end

    local ok = pcall(function()
        Network.Eggs_RequestUnlock:InvokeServer(eggData.Name)
    end)

    return ok and not isEggLocked(eggData.Instance)
end

function farmBestAreaCurrencyStep(zoneInfo)
    if not zoneInfo then
        return false
    end

    if not teleportToBestAreaWithFallbacks(zoneInfo) then
        return false
    end

    local coinMatches = getQuestMatchingBreakables({
        TargetKey = "coin"
    }, zoneInfo)

    if #coinMatches > 0 then
        return damageBreakable(coinMatches[BREAKABLE_RANDOM:NextInteger(1, #coinMatches)])
    end

    if not pokeNearestBestAreaBreakable(zoneInfo) then
        task.wait(0.1)
        return pokeNearestBestAreaBreakable(zoneInfo)
    end

    return true
end

function runAutoBreakableFarm()
    ensureAntiStaff()
    ensureLootbagCollector()
    ensureOrbCollector()
    ensurePetSpeed()

    local repositionCounter = 0
    local lastTeleportAt = 0
    local activeZoneName

    while (autoBreakableFarmRunning or getgenv().autoBreakableFarmRunning) and not getgenv().STAFF_DETECTED do
        local zoneInfo
        if selectedBreakableFarmMethod == "Selected Zone"
            and selectedBreakableFarmZone == BREAKABLE_FARM_RANDOM_ZONE
            and activeZoneName
            and repositionCounter < getgenv().breakableFarmConfig.REPOSITION_INTERVAL then
            zoneInfo = findAvailableZoneEntryByFullName(activeZoneName)
        end

        zoneInfo = zoneInfo or getSelectedBreakableFarmZoneInfo()
        if not zoneInfo then
            task.wait(0.5)
            continue
        end

        if activeZoneName ~= zoneInfo.FullName or repositionCounter >= getgenv().breakableFarmConfig.REPOSITION_INTERVAL then
            if not teleportToBestAreaWithFallbacks(zoneInfo, function()
                return autoBreakableFarmRunning
            end) then
                task.wait(0.5)
                continue
            end

            activeZoneName = zoneInfo.FullName
            repositionCounter = 0
            lastTeleportAt = 0
            print(string.format(
                "[Breakable Farm] Farming %s in %s",
                table.concat(selectedBreakableFarmFilters, ", "),
                zoneInfo.FullName
            ))
        end

        local now = os.clock()
        if getgenv().autoWorldConfig.AUTO_BUY_UPGRADES ~= false and now - lastTeleportAt >= 15 then
            autoBuyAreaUpgrades()
        end
        if getgenv().autoWorldConfig.AUTO_HATCH_ZONE_EGG ~= false and now - lastTeleportAt >= 15 then
            autoUnlockAndHatchZoneEgg()
        end
        if getgenv().breakableFarmConfig.SWEEP_ORBS ~= false and now - lastTeleportAt >= 6 then
            sweepNearbyOrbs(100)
        end

        local matches = getBreakableFarmMatchingBreakables(zoneInfo, selectedBreakableFarmFilters)
        if #matches > 0 then
            if now - lastTeleportAt >= (getgenv().breakableFarmConfig.TELEPORT_INTERVAL or 1.2) then
                teleportToBreakable(matches[BREAKABLE_RANDOM:NextInteger(1, #matches)])
                lastTeleportAt = now
            end

            damageBreakable(matches[BREAKABLE_RANDOM:NextInteger(1, #matches)])
        elseif table.find(selectedBreakableFarmFilters, "Any") then
            pokeNearestBestAreaBreakable(zoneInfo)
        else
            task.wait(0.25)
        end

        repositionCounter = repositionCounter + 1
        task.wait(math.max(getgenv().autoStageFarmConfig.MOVE_DELAY, 0.1))
    end

    autoBreakableFarmRunning = false
end

local QuestExecuters = {}

function runAutoQuest()
    ensureAntiStaff()
    ensureLootbagCollector()
    ensureOrbCollector()
    ensurePetSpeed()
    resetAutoQuestNotifications()
    local function isRunning()
        return autoQuestRunning and not getgenv().STAFF_DETECTED
    end

    local state = {
        spinStep = 0,
        breakZoneStep = 0,
        repositionCounter = 0,
        activeQuestType = nil,
        activeQuestSignature = nil,
        activeEggName = nil,
        activeEggCFrame = nil,
        activeZoneName = nil,
        lastBreakableTeleportAt = 0,
        lastUnlockAttemptAt = 0,
        lastUnlockEggName = nil,
        lastCollectEnchantAt = 0,
        lastCollectPotionAt = 0,
        lastUnsupportedQuestLogAt = 0,
        lastUnsupportedQuestSignature = nil,
        lastQuestCometSpawnAt = 0,
        stuckQuestSignature = nil,
        stuckQuestStartedAt = 0,
        flagQuestSignature = nil,
        flagQuestUsedZones = {},
        questSignature = nil
    }

    while autoQuestRunning and not getgenv().STAFF_DETECTED do
        local questTask, parsedQuestTasks, visibleQuestTitles, unsupportedQuestTitles = getActiveQuestTask()
        notifyAutoQuestVisibleQuests(visibleQuestTitles, questTask)
        notifyAutoQuestUnsupportedQuests(unsupportedQuestTitles)
        if not questTask then
            local unsupportedSignature = table.concat(unsupportedQuestTitles or visibleQuestTitles, " | ")

            if unsupportedSignature ~= "" then
                if unsupportedSignature ~= state.lastUnsupportedQuestSignature
                    or os.clock() - state.lastUnsupportedQuestLogAt >= getgenv().autoQuestConfig.UNSUPPORTED_LOG_DELAY then
                    warn("[Auto Quest] Unsupported quest text: " .. unsupportedSignature)
                    notifyAutoQuestProgress("unsupported-" .. unsupportedSignature, "Unsupported visible quests: " .. unsupportedSignature, 4, "Auto Quest")
                    autoQuestDebug("Supported quests: hatch best eggs, break breakables, earn diamonds/coins, collect enchants/potions/lootbags, use fruits/flags/potions/boosts, open gifts, roll RNG, make gold/rainbow pets, level up pets, send to index, upgrade enchants.")
                    state.lastUnsupportedQuestLogAt = os.clock()
                    state.lastUnsupportedQuestSignature = unsupportedSignature
                end
            elseif os.clock() - state.lastUnsupportedQuestLogAt >= getgenv().autoQuestConfig.UNSUPPORTED_LOG_DELAY then
                autoQuestDebug("Quest UI not ready yet. Waiting for a visible quest title.")
                state.lastUnsupportedQuestLogAt = os.clock()
                state.lastUnsupportedQuestSignature = nil
            end

            state.activeQuestType = nil
            state.activeQuestSignature = nil
            state.activeEggName = nil
            state.activeEggCFrame = nil
            state.activeZoneName = nil
            state.stuckQuestSignature = nil
            state.stuckQuestStartedAt = 0
            state.flagQuestSignature = nil
            state.flagQuestUsedZones = {}
            resetAutoQuestProgressNotification()
            if not waitForRunningDelay(getgenv().autoQuestConfig.SCAN_DELAY, isRunning) then
                break
            end
            continue
        end

        state.lastUnsupportedQuestSignature = nil

        local questSignature = getQuestTaskSignature(questTask)
        state.questSignature = questSignature
        if state.activeQuestSignature ~= questSignature
            or state.activeQuestType == QUEST_TYPES.BREAK and state.activeZoneName ~= nil and questTask.InBestArea == false then
            state.repositionCounter = 0
            state.spinStep = 0
            state.breakZoneStep = 0
            state.activeEggName = nil
            state.activeEggCFrame = nil
            state.activeZoneName = nil
            state.activeQuestType = questTask.Type
            state.activeQuestSignature = questSignature
            state.lastBreakableTeleportAt = 0
            state.flagQuestSignature = nil
            state.flagQuestUsedZones = {}
            notifyAutoQuestProgress(
                "selected-" .. questSignature,
                string.format("Doing %s%s", questTask.Text, formatQuestTaskStatus(questTask)),
                3.5,
                "Auto Quest"
            )
        end

        if state.stuckQuestSignature ~= questSignature then
            state.stuckQuestSignature = questSignature
            state.stuckQuestStartedAt = os.clock()
        elseif getgenv().autoQuestConfig.STUCK_HOP_ENABLED
            and state.stuckQuestStartedAt > 0
            and os.clock() - state.stuckQuestStartedAt >= getgenv().autoQuestConfig.STUCK_HOP_DELAY then
            warn("[Auto Quest] Quest timed out with no progress. Server hopping.")
            serverHopUntilSuccess("Auto Quest stuck hop", function()
                return autoQuestRunning and not getgenv().STAFF_DETECTED
            end)
            autoQuestRunning = false
            break
        end

        local currentRemaining = questTask.RemainingAmount
        if type(currentRemaining) == "number" and currentRemaining > 0 then
            local trackerKey = "lastRemaining_" .. questSignature
            local lastRemaining = getgenv()[trackerKey]
            if lastRemaining and currentRemaining >= lastRemaining then
                
            else
                
                state.stuckQuestStartedAt = os.clock()
            end
            getgenv()[trackerKey] = currentRemaining
        end

        local handler = QuestExecuters[questTask.Type]
        if handler then
            local ok, err = pcall(handler, questTask, state)
            if not ok then
                warn("[Auto Quest] Handler error for " .. tostring(questTask.Type) .. ": " .. tostring(err))
                if not waitForRunningDelay(getgenv().autoQuestConfig.ACTION_DELAY, isRunning) then
                    break
                end
            end
        else
            warn("[Auto Quest] Unsupported parsed quest type: " .. tostring(questTask.Type))
            if not waitForRunningDelay(getgenv().autoQuestConfig.SCAN_DELAY, isRunning) then
                break
            end
        end
    end

    autoQuestRunning = false
    resetAutoQuestNotifications()
end

QuestExecuters[QUEST_TYPES.HATCH] = function(questTask, state)
    local function isRunning()
        return autoQuestRunning
            and not getgenv().STAFF_DETECTED
            and isAutomationContextCurrent()
    end
    if not isRunning() then
        return
    end
    local unlockedEgg, latestEgg = getLatestUnlockedEgg()
    local eggData = unlockedEgg or latestEgg
    if not eggData then
        warn("[Auto Quest] Failed to resolve an egg for the hatch quest.")
        waitForRunningDelay(math.max(getgenv().autoQuestConfig.ACTION_DELAY, 1), isRunning)
        return
    end
    syncSelectedEggFromQuest(eggData)
    if isEggLocked(eggData.Instance) then
        state.activeEggName = nil
        state.activeEggCFrame = nil
        local priceInfo = getEggPriceInfo(eggData)
        local currentCurrency = priceInfo and getCurrencyAmount(priceInfo.Currency) or nil
        if priceInfo and currentCurrency and priceInfo.AmountValue and currentCurrency < priceInfo.AmountValue then
            local zoneInfo = getLatestUnlockedBestArea()
            if zoneInfo then
                state.activeZoneName = zoneInfo.FullName
                farmBestAreaCurrencyStep(zoneInfo)
                print(string.format("[Auto Quest] Farming %s for %s (%s / %s)", tostring(priceInfo.Currency), eggData.FullName, tostring(currentCurrency), tostring(priceInfo.AmountText)))
            else
                warn("[Auto Quest] Egg is locked and no best area was found to farm the unlock currency.")
            end
            waitForRunningDelay(math.max(getgenv().autoStageFarmConfig.MOVE_DELAY, getgenv().autoQuestConfig.ACTION_DELAY), isRunning)
            return
        end
        if isRunning() and (state.lastUnlockEggName ~= eggData.FullName or os.clock() - state.lastUnlockAttemptAt >= getgenv().autoQuestConfig.EGG_UNLOCK_RETRY_DELAY) then
            state.lastUnlockAttemptAt = os.clock()
            state.lastUnlockEggName = eggData.FullName
            tryUnlockEgg(eggData)
        end
        if isEggLocked(eggData.Instance) then
            waitForRunningDelay(getgenv().autoQuestConfig.EGG_UNLOCK_RETRY_DELAY, isRunning)
            return
        end
    end
    if state.activeEggName ~= eggData.FullName or not state.activeEggCFrame or state.repositionCounter >= getgenv().autoQuestConfig.REPOSITION_INTERVAL then
        local teleported, eggCFrame = teleportToEggWithFallbacks(eggData, isRunning)
        if not teleported then
            warn("[Auto Quest] Failed to reach egg: " .. tostring(eggData.FullName))
            waitForRunningDelay(math.max(getgenv().autoQuestConfig.ACTION_DELAY, 0.5), isRunning)
            return
        end
        state.activeEggName = eggData.FullName
        state.activeEggCFrame = eggCFrame
        state.activeZoneName = nil
        state.repositionCounter = 0
        reportAutoQuestStatus("hatch-" .. tostring(eggData.FullName) .. "|" .. state.questSignature, string.format("Working on %s%s at %s", questTask.Text, formatQuestTaskStatus(questTask), eggData.FullName), 3.4)
    end
    state.spinStep = state.spinStep + 1
    state.repositionCounter = state.repositionCounter + 1
    if state.activeEggCFrame and isRunning() then
        getHumanoidRootPart().CFrame = getQuestEggStandCFrame(state.activeEggCFrame, state.spinStep)
    end
    if not isRunning() then
        return
    end
    local hatched = hatchSelectedEgg()
    if not hatched then
        if not waitForRunningDelay(math.max(getgenv().autoQuestConfig.ACTION_DELAY, 0.1), isRunning) then
            return
        end
        if state.activeEggCFrame and isRunning() then
            getHumanoidRootPart().CFrame = getQuestEggStandCFrame(state.activeEggCFrame, state.spinStep + 1)
        end
        if isRunning() then
            hatchSelectedEgg()
        end
    end
    waitForRunningDelay(math.max(eggHatchDelay, 0.05), isRunning)
end

QuestExecuters[QUEST_TYPES.BREAK] = function(questTask, state)
    if questTask.InBestArea then
        local zoneInfo = getLatestUnlockedBestArea()
        if not zoneInfo then
            warn("[Auto Quest] Failed to resolve the latest unlocked best area.")
            task.wait(math.max(getgenv().autoQuestConfig.ACTION_DELAY, 1))
            return
        end
        if state.activeZoneName ~= zoneInfo.FullName or state.repositionCounter >= getgenv().autoQuestConfig.REPOSITION_INTERVAL then
            if not teleportToBestAreaWithFallbacks(zoneInfo) then
                warn("[Auto Quest] Failed to reach best area: " .. tostring(zoneInfo.FullName))
                task.wait(math.max(getgenv().autoQuestConfig.ACTION_DELAY, 0.5))
                return
            end
            state.activeZoneName = zoneInfo.FullName
            state.activeEggName = nil
            state.activeEggCFrame = nil
            state.breakZoneStep = 0
            state.repositionCounter = 0
            reportAutoQuestStatus("break-best-" .. tostring(zoneInfo.FullName) .. "|" .. state.questSignature, zoneInfo.Source == "GateHUD" and string.format("Working on %s%s in %s using GateHUD fallback", questTask.Text, formatQuestTaskStatus(questTask), zoneInfo.FullName) or string.format("Working on %s%s in %s", questTask.Text, formatQuestTaskStatus(questTask), zoneInfo.FullName), 3.4)
        end
        state.breakZoneStep = state.breakZoneStep + 1
        state.repositionCounter = state.repositionCounter + 1
        local breakZoneCFrame = getQuestBreakZoneCFrame(zoneInfo.Path, state.breakZoneStep)
        if breakZoneCFrame then
            getHumanoidRootPart().CFrame = breakZoneCFrame
        end
        local matchingBreakables = getQuestZoneBreakables(questTask, zoneInfo)
        if questTask.TargetKey == "comet" and #matchingBreakables == 0 and os.clock() - state.lastQuestCometSpawnAt >= math.max(getgenv().autoQuestConfig.ACTION_DELAY, 1) then
            if executeBoostAction("Comet", 1) then
                state.lastQuestCometSpawnAt = os.clock()
                reportAutoQuestStatus("quest-comet-" .. tostring(zoneInfo.FullName) .. "|" .. state.questSignature, string.format("Spawning comet in %s for %s%s", zoneInfo.FullName, questTask.Text, formatQuestTaskStatus(questTask)), 3.2)
                task.wait(0.2)
                matchingBreakables = getQuestZoneBreakables(questTask, zoneInfo)
            end
        end
        if #matchingBreakables > 0 then
            local now = os.clock()
            if not questTask.TargetKey and now - state.lastBreakableTeleportAt >= getgenv().breakableFarmConfig.TELEPORT_INTERVAL then
                teleportToBreakable(matchingBreakables[BREAKABLE_RANDOM:NextInteger(1, #matchingBreakables)])
                state.lastBreakableTeleportAt = now
            end
            damageBreakable(matchingBreakables[BREAKABLE_RANDOM:NextInteger(1, #matchingBreakables)])
        elseif not pokeNearestBestAreaBreakable(zoneInfo) then
            task.wait(math.max(getgenv().autoQuestConfig.ACTION_DELAY, 0.1))
            pokeNearestBestAreaBreakable(zoneInfo)
        end
        task.wait(math.max(getgenv().autoStageFarmConfig.MOVE_DELAY, getgenv().autoQuestConfig.ACTION_DELAY))
    else
        local zoneInfo = getLatestUnlockedBestArea()
        local matchingBreakables
        local now = os.clock()
        if questTask.TargetKey == "luckyblock" then
            ensureLuckyBlocksInstance()
        end
        if questTask.TargetKey == "diamond" then
            zoneInfo, matchingBreakables = findQuestZoneByTargetBreakables(questTask, state.activeZoneName, function() return autoQuestRunning and not getgenv().STAFF_DETECTED end)
            if zoneInfo and #matchingBreakables > 0 then
                state.activeZoneName = zoneInfo.FullName
                state.activeEggName = nil
                state.activeEggCFrame = nil
                state.repositionCounter = 0
                reportAutoQuestStatus("break-diamond-" .. tostring(zoneInfo.FullName) .. "|" .. state.questSignature, string.format("Working on %s%s in %s", questTask.Text, formatQuestTaskStatus(questTask), zoneInfo.FullName), 3.2)
                damageBreakable(matchingBreakables[BREAKABLE_RANDOM:NextInteger(1, #matchingBreakables)])
            else
                state.activeZoneName = nil
                autoQuestDebug("No loaded owned zone has diamond breakables yet for " .. tostring(questTask.Text))
                task.wait(math.max(getgenv().autoQuestConfig.ACTION_DELAY, 0.25))
            end
            task.wait(math.max(getgenv().autoStageFarmConfig.MOVE_DELAY, getgenv().autoQuestConfig.ACTION_DELAY))
            return
        end
        if now - state.lastBreakableTeleportAt >= getgenv().autoQuestConfig.RANDOM_BREAKABLE_TELEPORT_INTERVAL then
            local targetBreakable = teleportToRandomQuestBreakable(questTask, zoneInfo)
            state.lastBreakableTeleportAt = now
            if targetBreakable then
                reportAutoQuestStatus("break-target-" .. tostring(getBreakableDisplayName(targetBreakable)) .. "|" .. state.questSignature, string.format("Working on %s%s with %s", questTask.Text, formatQuestTaskStatus(questTask), tostring(getBreakableDisplayName(targetBreakable))), 3.2)
                damageBreakable(targetBreakable)
            end
        end
        local matches = getQuestMatchingBreakables(questTask, zoneInfo)
        if #matches > 0 then
            damageBreakable(matches[BREAKABLE_RANDOM:NextInteger(1, #matches)])
        else
            autoQuestDebug("No matching breakables found yet for " .. tostring(questTask.Text))
            task.wait(math.max(getgenv().autoQuestConfig.ACTION_DELAY, 0.25))
        end
        task.wait(math.max(getgenv().autoStageFarmConfig.MOVE_DELAY, getgenv().autoQuestConfig.ACTION_DELAY))
    end
end

QuestExecuters[QUEST_TYPES.EARN_DIAMONDS] = function(questTask, state)
    local zoneInfo, matchingBreakables = findQuestFarmZoneByFilters({"Diamond Pile"}, state.activeZoneName)
    if not zoneInfo then
        autoQuestDebug("No diamond pile zone found for quest: " .. tostring(questTask.Text))
        task.wait(math.max(getgenv().autoQuestConfig.ACTION_DELAY, 0.25))
        return
    end
    if state.activeZoneName ~= zoneInfo.FullName or state.repositionCounter >= getgenv().autoQuestConfig.REPOSITION_INTERVAL then
        if not teleportToBestAreaWithFallbacks(zoneInfo, function() return autoQuestRunning end) then
            warn("[Auto Quest] Failed to reach diamond zone: " .. tostring(zoneInfo.FullName))
            task.wait(math.max(getgenv().autoQuestConfig.ACTION_DELAY, 0.5))
            return
        end
        state.activeZoneName = zoneInfo.FullName
        state.activeEggName = nil
        state.activeEggCFrame = nil
        state.breakZoneStep = 0
        state.repositionCounter = 0
        reportAutoQuestStatus("diamonds-" .. tostring(zoneInfo.FullName) .. "|" .. state.questSignature, string.format("Working on %s%s in %s", questTask.Text, formatQuestTaskStatus(questTask), zoneInfo.FullName), 3.4)
    end
    if #matchingBreakables > 0 then
        local now = os.clock()
        if now - state.lastBreakableTeleportAt >= getgenv().breakableFarmConfig.TELEPORT_INTERVAL then
            teleportToBreakable(matchingBreakables[BREAKABLE_RANDOM:NextInteger(1, #matchingBreakables)])
            state.lastBreakableTeleportAt = now
        end
        damageBreakable(matchingBreakables[BREAKABLE_RANDOM:NextInteger(1, #matchingBreakables)])
    else
        autoQuestDebug("Diamond quest found no matching breakables in " .. tostring(zoneInfo.FullName))
        task.wait(math.max(getgenv().autoQuestConfig.ACTION_DELAY, 0.25))
    end
    state.repositionCounter = state.repositionCounter + 1
    task.wait(math.max(getgenv().autoStageFarmConfig.MOVE_DELAY, getgenv().autoQuestConfig.ACTION_DELAY))
end

QuestExecuters[QUEST_TYPES.COLLECT_ENCHANTS] = function(questTask, state)
    if os.clock() - state.lastCollectEnchantAt >= 2 then
        local zoneInfo = runCollectEnchantsQuestStep(function() return autoQuestRunning end)
        state.lastCollectEnchantAt = os.clock()
        if zoneInfo then
            state.activeZoneName = zoneInfo.FullName
            state.activeEggName = nil
            state.activeEggCFrame = nil
            state.repositionCounter = 0
            reportAutoQuestStatus("enchants-" .. tostring(zoneInfo.FullName) .. "|" .. state.questSignature, string.format("Working on %s%s in %s", questTask.Text, formatQuestTaskStatus(questTask), zoneInfo.FullName), 3.4)
        else
            warn("[Auto Quest] Collect enchants fallback failed. Supported route zones include Coral Reef and Carnival.")
            task.wait(math.max(getgenv().autoQuestConfig.ACTION_DELAY, 0.5))
        end
    else
        task.wait(math.max(getgenv().autoQuestConfig.ACTION_DELAY, 0.2))
    end
end

QuestExecuters[QUEST_TYPES.COLLECT_POTIONS] = function(questTask, state)
    local potionCount = countInventoryPotions()
    if potionCount < questTask.Amount and os.clock() - state.lastCollectPotionAt >= 2 then
        local zoneInfo = runCollectPotionsQuestStep(function() return autoQuestRunning end)
        state.lastCollectPotionAt = os.clock()
        if zoneInfo then
            state.activeZoneName = zoneInfo.FullName
            state.activeEggName = nil
            state.activeEggCFrame = nil
            state.repositionCounter = 0
            reportAutoQuestStatus("potions-" .. tostring(zoneInfo.FullName) .. "|" .. state.questSignature, string.format("Collecting potions for quest: %s (%d / %d) in %s", questTask.Text, potionCount, questTask.Amount, zoneInfo.FullName), 3.4)
        else
            warn("[Auto Quest] Collect potions fallback failed. Supported route zones include Cherry Blossom, Jungle, Safari, Underworld Bridge, Ice Sculptures, Cotton Candy Forest.")
            task.wait(math.max(getgenv().autoQuestConfig.ACTION_DELAY, 0.5))
        end
    else
        autoQuestDebug("Potion inventory already meets quest amount: " .. tostring(potionCount))
    end
    task.wait(math.max(getgenv().autoQuestConfig.ACTION_DELAY, 0.5))
end

QuestExecuters[QUEST_TYPES.USE_FRUITS] = function(questTask, state)
    local usedFruit, fruitName = useAvailableFruitForQuest()
    if usedFruit then
        reportAutoQuestStatus("use-fruit-" .. tostring(fruitName) .. "|" .. state.questSignature, string.format("Used fruit %s for quest: %s%s", tostring(fruitName), questTask.Text, formatQuestTaskStatus(questTask)), 3)
    else
        warn("[Auto Quest] No usable fruit found for quest: " .. tostring(questTask.Text))
    end
    task.wait(math.max(getgenv().autoQuestConfig.ACTION_DELAY, 0.5))
end

QuestExecuters[QUEST_TYPES.USE_FLAGS] = function(questTask, state)
    if state.flagQuestSignature ~= state.questSignature then
        state.flagQuestSignature = state.questSignature
        state.flagQuestUsedZones = {}
    end
    local zoneInfo = getUnusedFlagQuestZone(state.flagQuestUsedZones)
    if not zoneInfo then
        warn("[Auto Quest] No unused owned zones left for flag quest: " .. tostring(questTask.Text))
        task.wait(math.max(getgenv().autoQuestConfig.ACTION_DELAY, 0.5))
        return
    end
    if useFlagInBreakableZone(selectedAutoFlagName, zoneInfo, function() return autoQuestRunning and not getgenv().STAFF_DETECTED end) then
        state.activeZoneName = zoneInfo.FullName
        state.activeEggName = nil
        state.activeEggCFrame = nil
        state.flagQuestUsedZones[zoneInfo.FullName] = true
        reportAutoQuestStatus("flags-" .. tostring(zoneInfo.FullName) .. "|" .. state.questSignature, string.format("Used flag for quest: %s in %s", questTask.Text, zoneInfo.FullName), 3)
    else
        warn("[Auto Quest] Failed to use a flag for quest: " .. tostring(questTask.Text))
    end
    task.wait(math.max(getgenv().autoQuestConfig.ACTION_DELAY, 0.5))
end

QuestExecuters[QUEST_TYPES.USE_POTIONS] = function(questTask, state)
    local potionItem = findPotionConsumable(questTask.TierText)
    if not potionItem then
        warn("[Auto Quest] No usable potion matched quest: " .. tostring(questTask.Text))
        task.wait(math.max(getgenv().autoQuestConfig.ACTION_DELAY, 0.5))
        return
    end
    if tryUseInventoryConsumable(potionItem, "potion") then
        reportAutoQuestStatus("use-potion-" .. tostring(getInventoryItemName(potionItem.Data)) .. "|" .. state.questSignature, string.format("Used potion %s for quest: %s", tostring(getInventoryItemName(potionItem.Data)), questTask.Text), 3)
    else
        warn("[Auto Quest] Failed to use potion for quest: " .. tostring(questTask.Text))
    end
    task.wait(math.max(getgenv().autoQuestConfig.ACTION_DELAY, 0.5))
end


QuestExecuters["EarnCoins"] = function(questTask, state)
    local zoneInfo = getLatestUnlockedBestArea()
    if not zoneInfo then
        autoQuestDebug("No best area found for coin farming.")
        task.wait(math.max(getgenv().autoQuestConfig.ACTION_DELAY, 0.5))
        return
    end
    if state.activeZoneName ~= zoneInfo.FullName or state.repositionCounter >= getgenv().autoQuestConfig.REPOSITION_INTERVAL then
        if not teleportToBestAreaWithFallbacks(zoneInfo, function() return autoQuestRunning end) then
            warn("[Auto Quest] Failed to reach coin farm zone.")
            task.wait(math.max(getgenv().autoQuestConfig.ACTION_DELAY, 0.5))
            return
        end
        state.activeZoneName = zoneInfo.FullName
        state.repositionCounter = 0
    end
    pokeNearestBestAreaBreakable(zoneInfo)
    state.repositionCounter = state.repositionCounter + 1
    task.wait(math.max(getgenv().autoStageFarmConfig.MOVE_DELAY, getgenv().autoQuestConfig.ACTION_DELAY))
end

QuestExecuters["OpenGifts"] = function(questTask, state)
    for i = 1, 12 do
        if not autoQuestRunning or getgenv().STAFF_DETECTED then break end
        redeemFreeGift(tostring(i))
        task.wait(0.2)
    end
    task.wait(math.max(getgenv().autoQuestConfig.ACTION_DELAY, 0.5))
end

QuestExecuters["RollRNG"] = function(questTask, state)
    rollRNGOnce()
    task.wait(math.max(rngRollDelay, 0.05))
end

QuestExecuters["UseBoosts"] = function(questTask, state)
    local boostNames = {"Lucky Block", "Giant Coin Jar", "Party Box", "Mini Pinata", "TNT Crate", "Comet", "Magic Coin Jar", "Basic Coin Jar", "TNT"}
    local randomBoost = boostNames[BREAKABLE_RANDOM:NextInteger(1, #boostNames)]
    executeBoostAction(randomBoost, 1)
    task.wait(math.max(getgenv().autoQuestConfig.ACTION_DELAY, 0.5))
end

QuestExecuters["CollectLootbags"] = function(questTask, state)
    local zoneInfo = getLatestUnlockedBestArea()
    if not zoneInfo then
        task.wait(math.max(getgenv().autoQuestConfig.ACTION_DELAY, 0.5))
        return
    end
    if state.activeZoneName ~= zoneInfo.FullName or state.repositionCounter >= getgenv().autoQuestConfig.REPOSITION_INTERVAL then
        teleportToBestAreaWithFallbacks(zoneInfo, function() return autoQuestRunning end)
        state.activeZoneName = zoneInfo.FullName
        state.repositionCounter = 0
    end
    pokeNearestBestAreaBreakable(zoneInfo)
    state.repositionCounter = state.repositionCounter + 1
    task.wait(math.max(getgenv().autoStageFarmConfig.MOVE_DELAY, getgenv().autoQuestConfig.ACTION_DELAY))
end

function getInventoryUids(bucketNames, limit)
    local uids = {}
    for _, item in ipairs(collectInventoryItems(bucketNames)) do
        if item.Uid and getInventoryItemCount(item.Data) > 0 then
            table.insert(uids, tostring(item.Uid))
            if limit and #uids >= limit then
                break
            end
        end
    end
    return uids
end

function activateMachineWithInventory(remoteName, bucketNames, limit)
    local remote = Network:FindFirstChild(remoteName)
    if not remote then
        return false
    end

    local uids = getInventoryUids(bucketNames, limit or 6)
    if #uids == 0 then
        return false
    end

    return invokeRemoteAny(remote, {
        { uids },
        { uids, false },
        { uids, true },
        { uids[1] },
        { { uids[1] } }
    })
end

function farmQuestFallback(state)
    local zoneInfo = getLatestUnlockedBestArea()
    if zoneInfo then
        state.activeZoneName = zoneInfo.FullName
        teleportToBestAreaWithFallbacks(zoneInfo, function()
            return autoQuestRunning and not getgenv().STAFF_DETECTED
        end)
        pokeNearestBestAreaBreakable(zoneInfo)
    end
end

QuestExecuters["MakeBestPetsGold"] = function(questTask, state)
    if activateMachineWithInventory("GoldMachine_Activate", { "Pets", "Pet" }, 6) then
        reportAutoQuestStatus("make-gold-" .. state.questSignature, "Requested gold machine for " .. questTask.Text, 3)
    else
        autoQuestDebug("Gold machine route failed. Farming best area as fallback.")
        farmQuestFallback(state)
    end
    task.wait(math.max(getgenv().autoQuestConfig.ACTION_DELAY, 1))
end

QuestExecuters["MakeBestPetsRainbow"] = function(questTask, state)
    if activateMachineWithInventory("RainbowMachine_Activate", { "Pets", "Pet" }, 6) then
        reportAutoQuestStatus("make-rainbow-" .. state.questSignature, "Requested rainbow machine for " .. questTask.Text, 3)
    else
        autoQuestDebug("Rainbow machine route failed. Farming best area as fallback.")
        farmQuestFallback(state)
    end
    task.wait(math.max(getgenv().autoQuestConfig.ACTION_DELAY, 1))
end

QuestExecuters["LevelUpPets"] = function(questTask, state)
    local usedToken = false
    if resolveInventoryAction("Pet Token Boost", "boost") then
        usedToken = tryUseInventoryItem("Pet Token Boost", 1, "boost")
    end
    if not usedToken and resolveInventoryAction("Ultra Pet Token Boost", "boost") then
        usedToken = tryUseInventoryItem("Ultra Pet Token Boost", 1, "boost")
    end

    if usedToken then
        reportAutoQuestStatus("level-pets-" .. state.questSignature, "Used pet token boost for " .. questTask.Text, 3)
    else
        farmQuestFallback(state)
    end
    task.wait(math.max(getgenv().autoQuestConfig.ACTION_DELAY, 1))
end

QuestExecuters["SendPetsToIndex"] = function(questTask, state)
    local remote = Network:FindFirstChild("Index: Request Hatch Count")
    if remote and invokeRemoteAny(remote, { {}, { LocalPlayer.UserId } }) then
        reportAutoQuestStatus("send-index-" .. state.questSignature, "Requested index sync for " .. questTask.Text, 3)
    else
        autoQuestDebug("Index sync route failed. Farming best area as fallback.")
        farmQuestFallback(state)
    end
    task.wait(math.max(getgenv().autoQuestConfig.ACTION_DELAY, 1))
end

QuestExecuters["UpgradeEnchant"] = function(questTask, state)
    if activateMachineWithInventory("EnchantUpgrade_Use", { "Enchants", "Enchant" }, 1) then
        reportAutoQuestStatus("upgrade-enchant-" .. state.questSignature, "Requested enchant upgrade for " .. questTask.Text, 3)
    else
        autoQuestDebug("Enchant upgrade route failed. Farming best area as fallback.")
        farmQuestFallback(state)
    end
    task.wait(math.max(getgenv().autoQuestConfig.ACTION_DELAY, 1))
end

function queueStartupRefresh(name, fn)
    local ok, err = pcall(fn)
    if not ok then
        warn("[Startup Refresh] " .. tostring(name) .. " failed: " .. tostring(err))
    end
end




local STARTUP_REFRESHES = {
    {"Eggs", refreshEggList},
    {"Flags", refreshAutoFlagNameList},
    {"Breakable Zones", refreshBreakableFarmZoneList},
    {"Flag Zones", refreshAutoFlagZoneList},
    {"Utility Items", refreshUtilityItemList},
    {"Fruits", refreshConsumableFruitChoiceList},
    {"Boosts", refreshBoostItemList},
    {"Auto Fruits", refreshAutoFruitList},
    {"Bundles", refreshAutoBundleList},
    {"Instances", refreshInstanceList},
    {"Directories", refreshDirectorySummaryList},
    {"Machines / Merchants", refreshMachineMerchantLists},
    {"Soccer", refreshSoccerEventLists},
}
for refreshIndex, refreshEntry in ipairs(STARTUP_REFRESHES) do
    task.spawn(function()
        
        local myGen = flowSessionGeneration
        task.wait((refreshIndex - 1) * 0.15)
        if myGen ~= flowSessionGeneration then return end
        local ok, err = pcall(refreshEntry[2])
        if not ok then
            warn("[Startup Refresh] " .. tostring(refreshEntry[1]) .. " failed: " .. tostring(err))
        end
    end)
end

if not table.find(breakableFarmMethodValues, selectedBreakableFarmMethod) then
    selectedBreakableFarmMethod = breakableFarmMethodValues[1]
    getgenv().breakableFarmConfig.METHOD = selectedBreakableFarmMethod
end

if #selectedBreakableFarmFilters == 0 then
    selectedBreakableFarmFilters = { "Any" }
    getgenv().breakableFarmConfig.FILTERS = cloneArray(selectedBreakableFarmFilters)
end

if not table.find(breakableFarmFilterValues, selectedBreakableFarmFilters[1]) then
    selectedBreakableFarmFilters = { "Any" }
    getgenv().breakableFarmConfig.FILTERS = cloneArray(selectedBreakableFarmFilters)
end

if not table.find(autoFlagNameValues, selectedAutoFlagName) then
    selectedAutoFlagName = autoFlagNameValues[1]
    getgenv().autoFlagsConfig.FLAG = selectedAutoFlagName
end

if not table.find(autoFruitValues, selectedAutoFruit) then
    selectedAutoFruit = autoFruitValues[1] or AUTO_FRUIT_ALL
    getgenv().autoFruitsConfig.FRUIT = selectedAutoFruit
end

if not table.find(autoBundleValues, selectedAutoBundle) then
    selectedAutoBundle = autoBundleValues[1] or AUTO_BUNDLE_ALL
    getgenv().autoBundlesConfig.BUNDLE = selectedAutoBundle
end

if not table.find(utilityItemValues, selectedUtilityItemName) then
    selectedUtilityItemName = utilityItemValues[1]
    getgenv().utilityItemsConfig.ITEM = selectedUtilityItemName
end

if not table.find(consumableFruitChoiceValues, selectedConsumableFruitName) then
    selectedConsumableFruitName = consumableFruitChoiceValues[1]
    getgenv().fruitConsumeConfig.FRUIT = selectedConsumableFruitName
end

if not table.find(boostItemValues, selectedBoostItemName) then
    selectedBoostItemName = boostItemValues[1]
    getgenv().boostItemsConfig.ITEM = selectedBoostItemName
end

if not table.find(instanceValues, selectedInstanceName) then
    selectedInstanceName = instanceValues[1]
    getgenv().autoInstanceConfig.INSTANCE = selectedInstanceName
end

if not table.find(minigameAutoValues, selectedMinigameAuto) then
    selectedMinigameAuto = minigameAutoValues[1]
    getgenv().autoMinigameConfig.INSTANCE = selectedMinigameAuto
end

if not table.find(keyHelperValues, selectedKeyHelper) then
    selectedKeyHelper = keyHelperValues[1]
    getgenv().keyHelperConfig.KEY = selectedKeyHelper
end

if not table.find(giftRewardValues, selectedGiftReward) then
    selectedGiftReward = giftRewardValues[1]
    getgenv().giftRedeemConfig.INDEX = tonumber(selectedGiftReward) or 1
end



if setthreadidentity then
    pcall(setthreadidentity, 8)
end