-- ==============================================================================
-- HipHub | Jump To Steal Soccer Players Automation & Features Module
-- ==============================================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Features = {}
Features.State = {
    AutoCollectLuckyBlock = false,
    FilterRarity = "All",
    FilterMutation = "All",
    AutoCollectEarnings = false,
    AutoPlaceOpenLuckyBlock = false,
    AutoPickupAllPlayers = false,
    AutoUpgradePlayers = false,
    AutoBuySpeedUpgrade = false,
    AutoRebirth = false,
    AutoSellBackpack = false,
    MoveSpeedMultiplier = 1, -- 1-10 input, capped at 3x for safety
    LuckyBlockESP = false,
    StandESP = false,
    PlayerESP = false
}

-- Safe maximum walkspeed multiplier
local MAX_SAFE_SPEED_MULTIPLIER = 3
local DEFAULT_WALKSPEED = 16

-- Remote references
local Remotes = ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Network"):WaitForChild("Remotes")
local CollectEarningsRemote = Remotes:WaitForChild("Collect Earnings")
local BuySpeedRemote = Remotes:WaitForChild("Buy Speed Upgrade")
local RebirthRemote = Remotes:WaitForChild("Rebirth")
local SellAllRemote = Remotes:WaitForChild("Sell All Slimes")
local SellItemRemote = Remotes:WaitForChild("Sell Slime From Inventory")
local OpenLuckyBlockRemote = Remotes:WaitForChild("Open Lucky Block")
local PlaceSlimeRemote = Remotes:WaitForChild("Place Slime")
local PickupSlimeRemote = Remotes:WaitForChild("Pickup Slime")
local UpgradeSlimeRemote = Remotes:WaitForChild("Upgrade Slime")
local StealSlimeRemote = Remotes:FindFirstChild("Steal Rainbow Slime")

-- Database references
local SharedModules = ReplicatedStorage:WaitForChild("SharedModules")
local Database = require(SharedModules:WaitForChild("Database"))
local SharedVariables = require(SharedModules:WaitForChild("Shared"):WaitForChild("SharedVariables"))
local SoccerGameCatalog = require(SharedModules:WaitForChild("SoccerGameCatalog"))

-- ------------------------------------------------------------------------------
-- Helper: Get Local Player's Plot
-- ------------------------------------------------------------------------------
function Features.GetMyPlot()
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return nil end
    for _, plot in ipairs(plots:GetChildren()) do
        local ownerVal = plot:FindFirstChild("owner") or plot:FindFirstChild("Owner")
        if ownerVal and (ownerVal.Value == LocalPlayer.Name or ownerVal.Value == tostring(LocalPlayer.UserId)) then
            return plot
        end
        if plot:GetAttribute("Owner") == LocalPlayer.Name or plot:GetAttribute("OwnerUserId") == LocalPlayer.UserId then
            return plot
        end
    end
    if _G.MyPlot then return _G.MyPlot end
    return nil
end

function Features.GetPlotPosition(plot)
    if not plot then return nil end
    if plot:IsA("Model") and plot.PrimaryPart then
        return plot.PrimaryPart.Position
    end
    if plot:IsA("Model") then
        local ok, cf = pcall(function() return plot:GetPivot() end)
        if ok and cf then return cf.Position end
    end
    local base = plot:FindFirstChild("Base") or plot:FindFirstChildWhichIsA("BasePart", true)
    if base then
        return base.Position
    end
    return nil
end

-- ------------------------------------------------------------------------------
-- Helper: Get Player Data
-- ------------------------------------------------------------------------------
function Features.GetPlayerData()
    local ok, clientRuntime = pcall(function()
        return require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("ClientRuntime")):AwaitReady()
    end)
    if ok and clientRuntime and clientRuntime.PlayerState then
        return clientRuntime.PlayerState:Get()
    end
    if _G._Lib and _G._Lib.Data then
        return _G._Lib.Data:Get()
    end
    return nil
end

-- ------------------------------------------------------------------------------
-- Helper: Get Current Backpack Count & Max Capacity
-- ------------------------------------------------------------------------------
function Features.GetBackpackCount()
    local count = 0
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") and (item:GetAttribute("slimeUID") ~= nil or item:GetAttribute("slimeID") ~= nil or item.Name:lower():find("lucky block")) and not item:GetAttribute("CoilGear") then
                count = count + 1
            end
        end
    end
    local char = LocalPlayer.Character
    if char then
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") and (item:GetAttribute("slimeUID") ~= nil or item:GetAttribute("slimeID") ~= nil or item.Name:lower():find("lucky block")) and not item:GetAttribute("CoilGear") then
                count = count + 1
            end
        end
    end
    return count
end

function Features.GetMaxBackpackLimit()
    local data = Features.GetPlayerData()
    if data and data.BackpackLevel then
        return 20 + (tonumber(data.BackpackLevel) or 0) * 20
    end
    return 110
end

function Features.GetCarriedCount()
    local count = 0
    local char = LocalPlayer.Character
    if char then
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") and (item:GetAttribute("slimeUID") ~= nil or item:GetAttribute("slimeID") ~= nil or item.Name:lower():find("lucky block")) and not item:GetAttribute("CoilGear") then
                count = count + 1
            end
        end
    end
    return count
end

function Features.GetMaxCarryLimit()
    local data = Features.GetPlayerData()
    if data and data.CarryLevel then
        return tonumber(data.CarryLevel) or 3
    end
    return 3
end

-- ------------------------------------------------------------------------------
-- Helper: Resolve Lucky Block Rarity and Mutation
-- ------------------------------------------------------------------------------
function Features.ResolveBlockRarity(block)
    if not block then return "Common" end
    local sId = block:GetAttribute("SlimeId") or block:GetAttribute("slimeID") or block:GetAttribute("slimeId")
    if sId and Database and Database.Slimes and Database.Slimes[tostring(sId)] then
        local r = Database.Slimes[tostring(sId)].Rarity
        if r then
            if r == "Slime God" then return "Soccer God" end
            return r
        end
    end

    local cleanName = block.Name:gsub(" Lucky Block", ""):gsub("Lucky Block", ""):gsub("^%s*(.-)%s*$", "%1")
    if cleanName == "Slime God" or cleanName == "Soccer God" then
        return "Soccer God"
    end

    local knownRarities = { "LIMITED", "Japan", "Icons", "Spain", "Champions", "OG", "Exclusive", "Divine", "Soccer God", "Secret", "Mythic", "Legendary", "Epic", "Rare", "Common" }
    for _, r in ipairs(knownRarities) do
        if cleanName:lower() == r:lower() or block.Name:lower():find(r:lower()) then
            return r
        end
    end

    if Database and Database.Slimes then
        for _, slime in pairs(Database.Slimes) do
            if block.Name:find(slime.Name) or slime.Name:find(block.Name) then
                local r = slime.Rarity or "Common"
                if r == "Slime God" then return "Soccer God" end
                return r
            end
        end
    end
    return "Common"
end

function Features.ResolveMutation(model)
    local mut = model:GetAttribute("Mutation") or model:GetAttribute("mutation") or model:GetAttribute("Variant")
    if mut and mut ~= "" and mut ~= "Default" then
        return tostring(mut)
    end
    if model:FindFirstChild("RainbowEffect") or model.Name:lower():find("rainbow") then
        return "Rainbow"
    end
    if model.Name:lower():find("gold") then
        return "Gold"
    end
    if model.Name:lower():find("volcanic") then
        return "Volcanic"
    end
    if model.Name:lower():find("cursed") then
        return "Cursed"
    end
    if model.Name:lower():find("ghost") then
        return "Ghost"
    end
    return "None"
end

-- ------------------------------------------------------------------------------
-- Helper: Check if Stand Slot is Bought / Unlocked
-- ------------------------------------------------------------------------------
function Features.IsStandBought(stand, index)
    if not stand then return false end

    -- Check direct attributes
    local isBoughtAttr = stand:GetAttribute("Bought")
    if isBoughtAttr ~= nil then return isBoughtAttr == true end
    local isUnlockedAttr = stand:GetAttribute("Unlocked")
    if isUnlockedAttr ~= nil then return isUnlockedAttr == true end
    local isOwnedAttr = stand:GetAttribute("Owned")
    if isOwnedAttr ~= nil then return isOwnedAttr == true end
    if stand:GetAttribute("Locked") == true then return false end

    -- Check if it contains a buy prompt or buy pad
    local buyPrompt = stand:FindFirstChildWhichIsA("ProximityPrompt", true)
    if buyPrompt and (buyPrompt.ActionText:lower():find("buy") or buyPrompt.ObjectText:lower():find("buy") or buyPrompt.Name:lower():find("buy")) then
        return false
    end
    if stand:FindFirstChild("BuyPad") or stand:FindFirstChild("BuyPart") or stand:FindFirstChild("PurchasePad") or stand:FindFirstChild("Locked") or stand:FindFirstChild("BuyPrompt") then
        return false
    end

    -- Check price display GUI
    for _, gui in ipairs(stand:GetDescendants()) do
        if gui:IsA("BillboardGui") or gui:IsA("SurfaceGui") then
            local n = gui.Name:lower()
            if n:find("buy") or n:find("price") or n:find("cost") or n:find("purchase") or n:find("unlock") then
                return false
            end
        end
    end

    -- Check player runtime data
    local data = Features.GetPlayerData()
    if data then
        if typeof(data.Stands) == "number" and index > data.Stands then
            return false
        elseif typeof(data.Stands) == "table" then
            if data.Stands[tostring(index)] == nil and data.Stands[index] == nil and #data.Stands > 0 and index > #data.Stands then
                return false
            end
        end
        if typeof(data.UnlockedStands) == "number" and index > data.UnlockedStands then
            return false
        end
        if typeof(data.MaxStands) == "number" and index > data.MaxStands then
            return false
        end
        if typeof(data.OwnedStands) == "number" and index > data.OwnedStands then
            return false
        end
    end

    return true
end

-- ------------------------------------------------------------------------------
-- Helper: Find Next Available Empty Bought Stand Slot on Plot
-- ------------------------------------------------------------------------------
function Features.FindEmptyStandSlot()
    local myPlot = Features.GetMyPlot()
    if not myPlot or not myPlot:FindFirstChild("Stands") then return nil end
    local playerSlimes = Workspace:FindFirstChild("Live") and Workspace.Live:FindFirstChild("PlayerSlimes")
    local mySlimesFolder = playerSlimes and playerSlimes:FindFirstChild(LocalPlayer.Name)

    local standsFolder = myPlot.Stands
    local children = standsFolder:GetChildren()

    for i = 1, #children do
        local slotName = tostring(i)
        local standObj = standsFolder:FindFirstChild(slotName) or children[i]
        local actualIndex = tonumber(standObj and standObj.Name) or i
        local targetSlotName = tostring(actualIndex)

        if Features.IsStandBought(standObj, actualIndex) then
            local occupied = mySlimesFolder and (mySlimesFolder:FindFirstChild(targetSlotName) or mySlimesFolder:FindFirstChild(slotName))
            if not occupied then
                return targetSlotName
            end
        end
    end
    return nil
end

-- ------------------------------------------------------------------------------
-- Helper: Deposit & Open All Carried Lucky Blocks onto Empty Bought Stands
-- ------------------------------------------------------------------------------
function Features.DepositAndOpenCarriedLuckyBlocks()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not hum or not backpack then return end

    local myPlot = Features.GetMyPlot()
    local plotPos = Features.GetPlotPosition(myPlot)
    local root = char:FindFirstChild("HumanoidRootPart")

    local maxAttempts = 20
    local attempts = 0

    while attempts < maxAttempts do
        attempts = attempts + 1

        -- Find next lucky block tool
        local lbTool = nil
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and (tool:GetAttribute("slimeUID") ~= nil or tool.Name:lower():find("lucky block")) then
                lbTool = tool
                break
            end
        end
        if not lbTool and char then
            for _, tool in ipairs(char:GetChildren()) do
                if tool:IsA("Tool") and (tool:GetAttribute("slimeUID") ~= nil or tool.Name:lower():find("lucky block")) then
                    lbTool = tool
                    break
                end
            end
        end

        if not lbTool then
            -- All lucky blocks deposited and opened!
            break
        end

        local emptySlot = Features.FindEmptyStandSlot()
        if not emptySlot then
            -- No empty bought stands available on plot!
            if Features.State.AutoSellBackpack then
                Features.SellFromBackpackStep()
                task.wait(0.3)
            end
            break
        end

        -- Bring player to base plot before placing
        if plotPos and root and (root.Position - plotPos).Magnitude > 25 then
            root.CFrame = CFrame.new(plotPos + Vector3.new(0, 3, 0))
            task.wait(0.25)
        end

        local uid = lbTool:GetAttribute("slimeUID")
        if lbTool.Parent == backpack then
            hum:EquipTool(lbTool)
            task.wait(0.12)
        end
        PlaceSlimeRemote:FireServer(emptySlot, uid)
        task.wait(0.18)
        OpenLuckyBlockRemote:FireServer(emptySlot)
        task.wait(0.25)
    end
end

-- ------------------------------------------------------------------------------
-- Feature 1: Auto Collect Lucky Block (With Carry Limit Check & Rarity/Mutation Filters)
-- ------------------------------------------------------------------------------
local isCollectingLB = false
function Features.CollectLuckyBlocksStep()
    if isCollectingLB then return end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- If auto place or auto sell is enabled, process carried blocks when inventory gets full
    if Features.State.AutoPlaceOpenLuckyBlock then
        local backpackCount = Features.GetBackpackCount()
        local maxBackpack = Features.GetMaxBackpackLimit()
        if backpackCount >= maxBackpack then
            isCollectingLB = true
            task.spawn(function()
                Features.DepositAndOpenCarriedLuckyBlocks()
                task.wait(0.3)
                isCollectingLB = false
            end)
            return
        end
    elseif Features.State.AutoSellBackpack then
        local backpackCount = Features.GetBackpackCount()
        local maxBackpack = Features.GetMaxBackpackLimit()
        if backpackCount >= maxBackpack then
            Features.SellFromBackpackStep()
            task.wait(0.3)
        end
    end

    local slimesFolder = Workspace:FindFirstChild("Live") and Workspace.Live:FindFirstChild("Slimes")
    local candidates = {}

    local selectedRarity = Features.State.FilterRarity
    local selectedMutation = Features.State.FilterMutation

    local function isRarityAll(val)
        if not val or val == "All" then return true end
        if typeof(val) == "table" then
            if #val == 0 and not next(val) then return true end
            if val["All"] or table.find(val, "All") then return true end
        end
        return false
    end

    local function isMutationAll(val)
        if not val or val == "All" then return true end
        if typeof(val) == "table" then
            if #val == 0 and not next(val) then return true end
            if val["All"] or table.find(val, "All") then return true end
        end
        return false
    end

    local function matchesFilter(block)
        local blockRarity = Features.ResolveBlockRarity(block)
        local blockRarityLower = string.lower(blockRarity)
        local blockMutation = Features.ResolveMutation(block)
        local blockMutationLower = string.lower(blockMutation)

        -- Check Rarity
        local rarityMatch = false
        if isRarityAll(selectedRarity) then
            rarityMatch = true
        elseif typeof(selectedRarity) == "string" then
            if selectedRarity == "Soccer God" or selectedRarity == "Slime God" then
                rarityMatch = (blockRarityLower == "soccer god" or blockRarityLower == "slime god")
            else
                rarityMatch = (string.lower(selectedRarity) == blockRarityLower)
            end
        elseif typeof(selectedRarity) == "table" then
            for _, r in ipairs(selectedRarity) do
                local rLower = string.lower(tostring(r))
                if (rLower == "soccer god" or rLower == "slime god") and (blockRarityLower == "soccer god" or blockRarityLower == "slime god") then
                    rarityMatch = true
                    break
                elseif rLower == blockRarityLower then
                    rarityMatch = true
                    break
                end
            end
            if not rarityMatch then
                for k, v in pairs(selectedRarity) do
                    if v == true then
                        local kLower = string.lower(tostring(k))
                        if (kLower == "soccer god" or kLower == "slime god") and (blockRarityLower == "soccer god" or blockRarityLower == "slime god") then
                            rarityMatch = true
                            break
                        elseif kLower == blockRarityLower then
                            rarityMatch = true
                            break
                        end
                    end
                end
            end
        end

        -- Check Mutation
        local mutationMatch = false
        if isMutationAll(selectedMutation) then
            mutationMatch = true
        elseif typeof(selectedMutation) == "string" then
            local selMutLower = string.lower(selectedMutation)
            if selMutLower == "gold" or selMutLower == "golden" then
                mutationMatch = (blockMutationLower == "gold" or blockMutationLower == "golden")
            else
                mutationMatch = (selMutLower == blockMutationLower)
            end
        elseif typeof(selectedMutation) == "table" then
            for _, m in ipairs(selectedMutation) do
                local mLower = string.lower(tostring(m))
                if (mLower == "gold" or mLower == "golden") and (blockMutationLower == "gold" or blockMutationLower == "golden") then
                    mutationMatch = true
                    break
                elseif mLower == blockMutationLower then
                    mutationMatch = true
                    break
                end
            end
            if not mutationMatch then
                for k, v in pairs(selectedMutation) do
                    if v == true then
                        local kLower = string.lower(tostring(k))
                        if (kLower == "gold" or kLower == "golden") and (blockMutationLower == "gold" or blockMutationLower == "golden") then
                            mutationMatch = true
                            break
                        elseif kLower == blockMutationLower then
                            mutationMatch = true
                            break
                        end
                    end
                end
            end
        end

        return rarityMatch and mutationMatch
    end

    local candidateList = {}
    local function checkContainer(container)
        if not container then return end
        for _, block in ipairs(container:GetChildren()) do
            if block:IsA("Model") and matchesFilter(block) then
                local prompt = block:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt and (prompt.Name == "StealPrompt" or prompt.ActionText:lower():find("collect")) then
                    local part = prompt.Parent:IsA("BasePart") and prompt.Parent or block.PrimaryPart or block:FindFirstChild("RootPart")
                    if part and not table.find(candidateList, prompt) then
                        table.insert(candidateList, prompt)
                        table.insert(candidates, { prompt = prompt, part = part, distance = (root.Position - part.Position).Magnitude })
                    end
                end
            end
        end
    end

    checkContainer(Workspace:FindFirstChild("Live") and Workspace.Live:FindFirstChild("Slimes"))
    checkContainer(Workspace:FindFirstChild("Slimes"))

    -- Also search workspace if filters are broad or no candidates found yet
    if #candidates == 0 or (isRarityAll(selectedRarity) and isMutationAll(selectedMutation)) then
        for _, prompt in ipairs(Workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") and (prompt.Name == "StealPrompt" or prompt.ActionText:lower():find("collect")) then
                local model = prompt:FindFirstAncestorOfClass("Model")
                if (not model or matchesFilter(model)) and not table.find(candidateList, prompt) then
                    local part = prompt.Parent:IsA("BasePart") and prompt.Parent or (model and model.PrimaryPart)
                    if part then
                        table.insert(candidateList, prompt)
                        table.insert(candidates, { prompt = prompt, part = part, distance = (root.Position - part.Position).Magnitude })
                    end
                end
            end
        end
    end

    if #candidates == 0 then return end

    -- Sort closest first
    table.sort(candidates, function(a, b) return a.distance < b.distance end)

    isCollectingLB = true
    task.spawn(function()
        pcall(function()
            local target = candidates[1]
            local myPlot = Features.GetMyPlot()
            local plotPos = Features.GetPlotPosition(myPlot)
            local returnPos = plotPos and (plotPos + Vector3.new(0, 3, 0)) or (root and root.Position)

            if target and target.prompt and target.prompt.Parent and root and root.Parent then
                local initialCount = Features.GetBackpackCount()
                local promptHold = target.prompt.HoldDuration or 0.5

                -- Teleport stably to lucky block and freeze physics velocity
                root.CFrame = target.part.CFrame + Vector3.new(0, 1.2, 0)
                pcall(function()
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                end)
                task.wait(0.06)

                -- Actively trigger prompt until block is collected or short timeout
                local timeout = os.clock() + math.max(promptHold + 0.25, 0.6)
                while os.clock() < timeout and target.prompt and target.prompt.Parent and root and root.Parent do
                    if Features.GetBackpackCount() > initialCount then
                        break
                    end
                    pcall(function()
                        if fireproximityprompt then
                            fireproximityprompt(target.prompt, promptHold)
                            fireproximityprompt(target.prompt, 0)
                            fireproximityprompt(target.prompt)
                        end
                    end)
                    task.wait(0.08)
                end

                task.wait(0.06)

                -- If AutoPlaceOpenLuckyBlock is enabled, deposit to empty stands
                if Features.State.AutoPlaceOpenLuckyBlock then
                    Features.DepositAndOpenCarriedLuckyBlocks()
                elseif returnPos and root and root.Parent then
                    root.CFrame = CFrame.new(returnPos)
                end
            end
        end)
        task.wait(0.2)
        isCollectingLB = false
    end)
end

-- ------------------------------------------------------------------------------
-- Feature 2: Auto Collect Earnings
-- ------------------------------------------------------------------------------
function Features.CollectEarningsStep()
    local myPlot = Features.GetMyPlot()
    if myPlot and myPlot:FindFirstChild("CollectPads") then
        for _, pad in ipairs(myPlot.CollectPads:GetChildren()) do
            CollectEarningsRemote:FireServer(pad.Name)
        end
    else
        for i = 1, 100 do
            CollectEarningsRemote:FireServer(tostring(i))
        end
    end
end

-- ------------------------------------------------------------------------------
-- Feature 3: Auto Place & Open Lucky Block
-- ------------------------------------------------------------------------------
function Features.PlaceAndOpenLuckyBlockStep()
    Features.DepositAndOpenCarriedLuckyBlocks()
end

-- ------------------------------------------------------------------------------
-- Feature 4: Auto Pick Up All Soccer Players
-- ------------------------------------------------------------------------------
function Features.PickupAllSoccerPlayersStep()
    local myPlot = Features.GetMyPlot()
    local playerSlimes = Workspace:FindFirstChild("Live") and Workspace.Live:FindFirstChild("PlayerSlimes")
    local mySlimesFolder = playerSlimes and playerSlimes:FindFirstChild(LocalPlayer.Name)

    if mySlimesFolder then
        for _, standModel in ipairs(mySlimesFolder:GetChildren()) do
            if standModel:IsA("Model") then
                PickupSlimeRemote:FireServer(standModel.Name)
            end
        end
    elseif myPlot and myPlot:FindFirstChild("Stands") then
        for _, stand in ipairs(myPlot.Stands:GetChildren()) do
            PickupSlimeRemote:FireServer(stand.Name)
        end
    end
end

-- ------------------------------------------------------------------------------
-- Feature 5: Auto Upgrade Soccer Players
-- ------------------------------------------------------------------------------
function Features.UpgradeSoccerPlayersStep()
    local myPlot = Features.GetMyPlot()
    local playerSlimes = Workspace:FindFirstChild("Live") and Workspace.Live:FindFirstChild("PlayerSlimes")
    local mySlimesFolder = playerSlimes and playerSlimes:FindFirstChild(LocalPlayer.Name)

    if mySlimesFolder then
        for _, slime in ipairs(mySlimesFolder:GetChildren()) do
            if slime:IsA("Model") then
                UpgradeSlimeRemote:FireServer(slime.Name)
            end
        end
    elseif myPlot and myPlot:FindFirstChild("Stands") then
        for i = 1, 100 do
            UpgradeSlimeRemote:FireServer(tostring(i))
        end
    end
end

-- ------------------------------------------------------------------------------
-- Feature 6: Auto Buy Speed Upgrade
-- ------------------------------------------------------------------------------
function Features.BuySpeedUpgradeStep()
    for tier = 1, 10 do
        BuySpeedRemote:FireServer(tier)
    end
end

-- ------------------------------------------------------------------------------
-- Feature 7: Auto Rebirth
-- ------------------------------------------------------------------------------
function Features.AutoRebirthStep()
    local data = Features.GetPlayerData()
    if data and data.Rebirth ~= nil and data.Jump ~= nil then
        local nextRebirthIndex = (data.Rebirth or 0) + 1
        local rebData = Database.Rebirths and Database.Rebirths[nextRebirthIndex]
        if rebData and data.Jump >= (rebData.JumpRequirement or 0) then
            RebirthRemote:FireServer()
        end
    else
        RebirthRemote:FireServer()
    end
end

-- ------------------------------------------------------------------------------
-- Feature 8: Auto Sell From Backpack
-- ------------------------------------------------------------------------------
function Features.SellFromBackpackStep()
    SellAllRemote:FireServer()
end

-- ------------------------------------------------------------------------------
-- Feature 9: Move Speed Multiplier (1-10 input, auto-capped at 3x for safety)
-- ------------------------------------------------------------------------------
function Features.ApplyMoveSpeed()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    if hum then
        local rawMultiplier = tonumber(Features.State.MoveSpeedMultiplier) or 1
        local safeMultiplier = math.clamp(rawMultiplier, 1, MAX_SAFE_SPEED_MULTIPLIER)
        hum.WalkSpeed = DEFAULT_WALKSPEED * safeMultiplier
    end
end

-- ------------------------------------------------------------------------------
-- Feature 10: Mutation display on Egg / Lucky Block ESP (Gold / Rainbow / None)
-- ------------------------------------------------------------------------------
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "HipHub_ESP_Cache"
ESPFolder.Parent = Workspace

local ActiveESP = {}

local MUTATION_COLORS = {
    ["Gold"] = Color3.fromRGB(250, 176, 38),
    ["Golden"] = Color3.fromRGB(250, 176, 38),
    ["Rainbow"] = Color3.fromRGB(255, 105, 180),
    ["Diamond"] = Color3.fromRGB(0, 227, 255),
    ["Shiny"] = Color3.fromRGB(255, 109, 126),
    ["Volcanic"] = Color3.fromRGB(255, 69, 0),
    ["Cursed"] = Color3.fromRGB(179, 0, 250),
    ["Neon"] = Color3.fromRGB(4, 250, 0),
    ["None"] = Color3.fromRGB(0, 200, 255)
}

function Features.CreateESPBillboard(target, labelText, mutationText, color)
    local adorneePart = target:IsA("BasePart") and target or target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")
    if not adorneePart then return nil end

    local bb = Instance.new("BillboardGui")
    bb.Name = "HipHubESP_" .. target.Name
    bb.Adornee = adorneePart
    bb.Size = UDim2.new(0, 180, 0, 50)
    bb.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
    bb.AlwaysOnTop = true
    bb.ResetOnSpawn = false

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 0.3
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    frame.BorderSizePixel = 0
    frame.Parent = bb

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = 1.5
    stroke.Parent = frame

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0.5, 0)
    title.Position = UDim2.new(0, 0, 0, 2)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 12
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Text = labelText
    title.Parent = frame

    local mutLabel = Instance.new("TextLabel")
    mutLabel.Name = "Mutation"
    mutLabel.Size = UDim2.new(1, 0, 0.45, 0)
    mutLabel.Position = UDim2.new(0, 0, 0.5, 0)
    mutLabel.BackgroundTransparency = 1
    mutLabel.Font = Enum.Font.GothamBlack
    mutLabel.TextSize = 11
    mutLabel.TextColor3 = color
    mutLabel.Text = "[" .. string.upper(mutationText) .. "]"
    mutLabel.Parent = frame

    bb.Parent = ESPFolder
    return bb
end

function Features.UpdateESP()
    if not Features.State.LuckyBlockESP then
        for _, esp in pairs(ActiveESP) do
            if esp and esp.Parent then esp:Destroy() end
        end
        table.clear(ActiveESP)
        return
    end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local slimesFolder = Workspace:FindFirstChild("Live") and Workspace.Live:FindFirstChild("Slimes")

    if slimesFolder then
        for _, block in ipairs(slimesFolder:GetChildren()) do
            if block:IsA("Model") then
                local id = block:GetDebugId()
                local mutation = Features.ResolveMutation(block)
                local color = MUTATION_COLORS[mutation] or Color3.fromRGB(255, 255, 255)
                local dist = root and math.floor((root.Position - (block:GetPivot().Position)).Magnitude) or 0
                local displayName = block.Name:gsub(" Lucky Block", "") .. " [" .. dist .. "m]"

                if not ActiveESP[id] or not ActiveESP[id].Parent then
                    ActiveESP[id] = Features.CreateESPBillboard(block, displayName, mutation, color)
                else
                    local frame = ActiveESP[id]:FindFirstChild("Frame")
                    if frame then
                        local t = frame:FindFirstChild("Title")
                        local m = frame:FindFirstChild("Mutation")
                        if t then t.Text = displayName end
                        if m then
                            m.Text = "[" .. string.upper(mutation) .. "]"
                            m.TextColor3 = color
                        end
                        local s = frame:FindFirstChildWhichIsA("UIStroke")
                        if s then s.Color = color end
                    end
                end
            end
        end
    end
end

-- ------------------------------------------------------------------------------
-- Main Automation Loop
-- ------------------------------------------------------------------------------
local lastCollectLB = 0
local lastCollectEarn = 0
local lastPlaceOpen = 0
local lastPickup = 0
local lastUpgrade = 0
local lastBuySpeed = 0
local lastRebirth = 0
local lastSell = 0
local lastESP = 0

function Features.Init()
    if _G.HipHubRenderConn then
        pcall(function() _G.HipHubRenderConn:Disconnect() end)
        _G.HipHubRenderConn = nil
    end
    if _G.HipHubHeartbeatConn then
        pcall(function() _G.HipHubHeartbeatConn:Disconnect() end)
        _G.HipHubHeartbeatConn = nil
    end

    -- Fast RenderStepped hook for Speed Multiplier
    _G.HipHubRenderConn = RunService.RenderStepped:Connect(function()
        if Features.State.MoveSpeedMultiplier and Features.State.MoveSpeedMultiplier > 1 then
            Features.ApplyMoveSpeed()
        end
    end)

    -- Heartbeat automation loop
    _G.HipHubHeartbeatConn = RunService.Heartbeat:Connect(function()
        local now = os.clock()

        -- Auto Collect Lucky Block
        if Features.State.AutoCollectLuckyBlock and (now - lastCollectLB >= 0.8) then
            lastCollectLB = now
            Features.CollectLuckyBlocksStep()
        end

        -- Auto Collect Earnings
        if Features.State.AutoCollectEarnings and (now - lastCollectEarn >= 1.0) then
            lastCollectEarn = now
            Features.CollectEarningsStep()
        end

        -- Auto Place & Open Lucky Block
        if Features.State.AutoPlaceOpenLuckyBlock and (now - lastPlaceOpen >= 1.5) then
            lastPlaceOpen = now
            Features.PlaceAndOpenLuckyBlockStep()
        end

        -- Auto Pick Up All Players
        if Features.State.AutoPickupAllPlayers and (now - lastPickup >= 2.0) then
            lastPickup = now
            Features.PickupAllSoccerPlayersStep()
        end

        -- Auto Upgrade Soccer Players
        if Features.State.AutoUpgradePlayers and (now - lastUpgrade >= 1.0) then
            lastUpgrade = now
            Features.UpgradeSoccerPlayersStep()
        end

        -- Auto Buy Speed Upgrade
        if Features.State.AutoBuySpeedUpgrade and (now - lastBuySpeed >= 1.2) then
            lastBuySpeed = now
            Features.BuySpeedUpgradeStep()
        end

        -- Auto Rebirth
        if Features.State.AutoRebirth and (now - lastRebirth >= 2.0) then
            lastRebirth = now
            Features.AutoRebirthStep()
        end

        -- Auto Sell From Backpack
        if Features.State.AutoSellBackpack and (now - lastSell >= 2.5) then
            lastSell = now
            Features.SellFromBackpackStep()
        end

        -- ESP Update
        if now - lastESP >= 0.5 then
            lastESP = now
            Features.UpdateESP()
        end
    end)

    _G.HipHubFeatures = Features
    return Features
end

Features.Init()
