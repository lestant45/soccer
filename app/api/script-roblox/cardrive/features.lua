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
    -- Fallback default plot check
    if _G.MyPlot then return _G.MyPlot end
    return nil
end

-- ------------------------------------------------------------------------------
-- Helper: Get Player Data
-- ------------------------------------------------------------------------------
function Features.GetPlayerData()
    local ok, clientRuntime = pcall(function()
        return require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("ClientRuntime"))
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
-- Feature 1: Auto Collect Lucky Block
-- ------------------------------------------------------------------------------
local isCollectingLB = false
function Features.CollectLuckyBlocksStep()
    if isCollectingLB then return end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local slimesFolder = Workspace:FindFirstChild("Live") and Workspace.Live:FindFirstChild("Slimes")
    local candidates = {}

    if slimesFolder then
        for _, block in ipairs(slimesFolder:GetChildren()) do
            local prompt = block:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt and (prompt.Name == "StealPrompt" or prompt.ActionText:lower():find("collect")) then
                local part = prompt.Parent:IsA("BasePart") and prompt.Parent or block.PrimaryPart or block:FindFirstChild("RootPart")
                if part then
                    table.insert(candidates, { prompt = prompt, part = part, distance = (root.Position - part.Position).Magnitude })
                end
            end
        end
    end

    -- Also check general workspace prompts
    for _, prompt in ipairs(Workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and prompt.Name == "StealPrompt" and prompt.ActionText:lower():find("collect") then
            local part = prompt.Parent:IsA("BasePart") and prompt.Parent or prompt.Parent.Parent:FindFirstChild("RootPart")
            if part and not table.find(candidates, prompt) then
                table.insert(candidates, { prompt = prompt, part = part, distance = (root.Position - part.Position).Magnitude })
            end
        end
    end

    if #candidates == 0 then return end

    -- Sort closest first
    table.sort(candidates, function(a, b) return a.distance < b.distance end)

    isCollectingLB = true
    task.spawn(function()
        local target = candidates[1]
        if target and target.prompt and target.prompt.Parent and root and root.Parent then
            local originalCF = root.CFrame
            -- Teleport to lucky block
            root.CFrame = target.part.CFrame + Vector3.new(0, 2, 0)
            task.wait(0.12)
            pcall(function()
                if fireproximityprompt then
                    fireproximityprompt(target.prompt, 0)
                end
            end)
            task.wait(0.15)
            if root and root.Parent then
                root.CFrame = originalCF
            end
        end
        task.wait(0.3)
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
        -- Fallback loop 1-100
        for i = 1, 100 do
            CollectEarningsRemote:FireServer(tostring(i))
        end
    end
end

-- ------------------------------------------------------------------------------
-- Feature 3: Auto Place & Open Lucky Block
-- ------------------------------------------------------------------------------
function Features.PlaceAndOpenLuckyBlockStep()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not hum or not backpack then return end

    local myPlot = Features.GetMyPlot()
    if not myPlot or not myPlot:FindFirstChild("Stands") then return end

    -- Find a Lucky Block tool in backpack or character
    local lbTool = nil
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and tool:GetAttribute("slimeUID") then
            local sId = tool:GetAttribute("slimeID")
            local info = sId and Database.Slimes[sId]
            if info and info.Type == "Lucky Block" or tool.Name:lower():find("lucky block") then
                lbTool = tool
                break
            end
        end
    end

    if not lbTool and char then
        local equipped = char:FindFirstChildWhichIsA("Tool")
        if equipped and equipped:GetAttribute("slimeUID") then
            local sId = equipped:GetAttribute("slimeID")
            local info = sId and Database.Slimes[sId]
            if info and info.Type == "Lucky Block" or equipped.Name:lower():find("lucky block") then
                lbTool = equipped
            end
        end
    end

    if not lbTool then return end

    -- Find an empty stand slot
    local playerSlimes = Workspace:FindFirstChild("Live") and Workspace.Live:FindFirstChild("PlayerSlimes")
    local mySlimesFolder = playerSlimes and playerSlimes:FindFirstChild(LocalPlayer.Name)

    local emptySlot = nil
    for i = 1, 100 do
        local slotName = tostring(i)
        local standObj = myPlot.Stands:FindFirstChild(slotName)
        if standObj then
            local occupied = mySlimesFolder and mySlimesFolder:FindFirstChild(slotName)
            if not occupied then
                emptySlot = slotName
                break
            end
        end
    end

    if emptySlot and lbTool then
        local uid = lbTool:GetAttribute("slimeUID")
        if lbTool.Parent == backpack then
            hum:EquipTool(lbTool)
            task.wait(0.1)
        end
        PlaceSlimeRemote:FireServer(emptySlot, uid)
        task.wait(0.2)
        OpenLuckyBlockRemote:FireServer(emptySlot)
    end
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
    local data = Features.GetPlayerData()
    local cash = data and data.Cash or (LocalPlayer:FindFirstChild("leaderstats") and LocalPlayer.leaderstats:FindFirstChild("Cash") and LocalPlayer.leaderstats.Cash.Value or 0)
    
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
        -- Fallback fire
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
    -- Fast RenderStepped hook for Speed Multiplier
    RunService.RenderStepped:Connect(function()
        if Features.State.MoveSpeedMultiplier and Features.State.MoveSpeedMultiplier > 1 then
            Features.ApplyMoveSpeed()
        end
    end)

    -- Heartbeat automation loop
    RunService.Heartbeat:Connect(function()
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
return Features
