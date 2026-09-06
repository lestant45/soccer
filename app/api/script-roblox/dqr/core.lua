-- ⚔️ HipHub DQR — Core (Bootstrap + UI Helpers + Tab System)
-- Game: [Odin Reincarnation] Dungeon Quest Reborn | PlaceId: 77649408247578

repeat task.wait() until game:IsLoaded()
if setthreadidentity then pcall(setthreadidentity, 8) end

if getgenv then
	if getgenv().DQR_Unload then
		local prev = getgenv().DQR_Unload
		getgenv().DQR_Unload = nil
		task.spawn(function() pcall(prev) end)
	end
	getgenv().DQR_LoadedAt = os.clock()
end

-- ═══ SERVICES ═══
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local Lighting          = game:GetService("Lighting")
local HttpService       = game:GetService("HttpService")
local StarterGui        = game:GetService("StarterGui")

local player = Players.LocalPlayer
while not player do task.wait(0.5); player = Players.LocalPlayer end
player:WaitForChild("PlayerGui")

-- ═══ REMOTES ═══
local remotes = ReplicatedStorage:WaitForChild("remotes", 15)
local function getRemote(name)  return remotes and remotes:FindFirstChild(name) end
local function getRemoteF(name) return remotes and remotes:FindFirstChild(name) end

-- ═══ COMBAT & ENEMY HELPERS ═══
local function getWeaponRemote()
	local char = player.Character
	if not char then return nil end
	for _, child in ipairs(char:GetChildren()) do
		if (child:IsA("Accessory") and child:FindFirstChild("Weapon")) or child:IsA("Tool") then
			local r = child:FindFirstChild("swing") or child:FindFirstChildOfClass("RemoteEvent")
			if r then return r end
			for _, desc in ipairs(child:GetDescendants()) do
				if desc:IsA("RemoteEvent") and desc.Name:lower():find("swing") then
					return desc
				end
			end
		end
	end
	return nil
end

local function getAllEnemies()
	local list = {}
	local seen = {}
	local char = player.Character

	local function checkModel(m)
		if not m or not m:IsA("Model") or seen[m] then return end
		if m == char or Players:GetPlayerFromCharacter(m) then return end
		local hum = m:FindFirstChildOfClass("Humanoid")
		local root = m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("Torso") or m:FindFirstChild("UpperTorso") or m.PrimaryPart
		if hum and hum.Health > 0 and root then
			seen[m] = true
			table.insert(list, {
				model = m,
				humanoid = hum,
				rootPart = root,
				name = m.Name,
				hp = hum.Health,
				maxHp = hum.MaxHealth
			})
		end
	end

	-- 1. Scan workspace.dungeon
	local dungeon = Workspace:FindFirstChild("dungeon")
	if dungeon then
		for _, desc in ipairs(dungeon:GetDescendants()) do
			if desc:IsA("Humanoid") and desc.Parent then
				checkModel(desc.Parent)
			end
		end
	end

	-- 2. Scan workspace.enemies & any enemyFolder
	for _, desc in ipairs(Workspace:GetChildren()) do
		if desc:IsA("Folder") and (desc.Name == "enemies" or desc.Name == "enemyFolder" or desc.Name == "enemyPool") then
			for _, d in ipairs(desc:GetDescendants()) do
				if d:IsA("Humanoid") and d.Parent then
					checkModel(d.Parent)
				end
			end
		end
	end

	-- 3. Fallback scan for any enemyFolder descendant in Workspace
	if #list == 0 then
		for _, desc in ipairs(Workspace:GetDescendants()) do
			if desc:IsA("Humanoid") and desc.Parent and desc.Health > 0 then
				local p = desc.Parent
				if p:FindFirstAncestor("enemyFolder") or p:FindFirstAncestor("enemies") or p:FindFirstAncestor("dungeon") then
					checkModel(p)
				end
			end
		end
	end

	return list
end

local function getNearestEnemy()
	local enemies = getAllEnemies()
	if #enemies == 0 then return nil end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return enemies[1] end
	table.sort(enemies, function(a, b)
		if not a.rootPart or not b.rootPart then return false end
		local distA = (a.rootPart.Position - hrp.Position).Magnitude
		local distB = (b.rootPart.Position - hrp.Position).Magnitude
		return distA < distB
	end)
	return enemies[1]
end

local function stopFarmFly()
	pcall(function()
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local bv = hrp and hrp:FindFirstChild("HipHubFarmFly")
		if bv then bv:Destroy() end
		if char then
			for _, p in ipairs(char:GetDescendants()) do
				if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
					p.CanCollide = true
				end
			end
		end
	end)
end

local function attackTarget(enemyData)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not char or not hrp or not enemyData or not enemyData.rootPart then return end

	local ePos = enemyData.rootPart.Position
	local hoverHeight = tonumber(CFG.farmHoverHeight) or 7.5

	-- Position player hovering above enemy outside melee reach
	if CFG.farmTeleport then
		-- Noclip character to prevent physics snagging on doors/walls
		for _, p in ipairs(char:GetDescendants()) do
			if p:IsA("BasePart") and p.CanCollide then
				p.CanCollide = false
			end
		end

		local bv = hrp:FindFirstChild("HipHubFarmFly")
		if not bv then
			bv = Instance.new("BodyVelocity")
			bv.Name = "HipHubFarmFly"
			bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
			bv.Velocity = Vector3.zero
			bv.Parent = hrp
		end

		local targetPos = ePos + Vector3.new(0, hoverHeight, 0)
		local targetCF = CFrame.lookAt(targetPos, ePos)
		hrp.CFrame = targetCF
		pcall(function() char:PivotTo(targetCF) end)
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
	end

	-- Find weapon
	local wep = nil
	for _, child in ipairs(char:GetChildren()) do
		if (child:IsA("Accessory") and child:FindFirstChild("Weapon")) or child:IsA("Tool") then
			wep = child
			break
		end
	end
	local hitBox = wep and wep:FindFirstChild("hitBox")

	-- Fire weapon swing
	local wRemote = getWeaponRemote()
	if wRemote then
		pcall(function() wRemote:FireServer() end)
	end
	local wu = getRemote("weaponUsed")
	if wu then
		pcall(function() wu:FireServer() end)
	end

	-- Fire touch interest if supported
	if hitBox and enemyData.rootPart and firetouchinterest then
		pcall(function()
			firetouchinterest(hitBox, enemyData.rootPart, 0)
			firetouchinterest(hitBox, enemyData.rootPart, 1)
		end)
	end

	-- Trigger ability spells from Backpack
	pcall(function()
		local bp = player:FindFirstChild("Backpack")
		if bp then
			for _, tool in ipairs(bp:GetChildren()) do
				if tool:IsA("Tool") then
					local slot = tool:FindFirstChild("abilitySlot")
					local cd = tool:FindFirstChild("cooldown")
					if slot and (not cd or cd.Value <= 0) then
						local le = tool:FindFirstChild("localEvent")
						if le then le:Fire() end
						local au = getRemote("abilityUsed")
						if au then au:FireServer(slot.Value, tool) end
					end
				end
			end
		end
	end)
end


-- ═══ CONFIG ═══
local CONFIG_PATH = "HipHub/dqr/config.json"
local CFG = {
	autoFarm = false, autoFarmDelay = 0.15, farmTeleport = true, farmHoverHeight = 7.5,
	autoBoss = false, bossTier = 1, bossAutoReady = true, bossAutoReplay = true,
	autoSell = false, autoSellDelay = 30,
	speedEnabled = false, speedValue = 50,
	jumpEnabled = false, jumpValue = 100,
	noclipEnabled = false, infJump = false,
	playerESP = false, enemyESP = false, espDistance = 500,
	antiAfk = true, fpsBooster = false,
	autoReplay = false, chatBypass = false, dropNotif = false,
}

local function saveConfig()
	pcall(function()
		if writefile then
			pcall(function() if not isfolder("HipHub/dqr") then makefolder("HipHub/dqr") end end)
			writefile(CONFIG_PATH, HttpService:JSONEncode(CFG))
		end
	end)
end
local function loadConfig()
	pcall(function()
		if isfile and readfile and isfile(CONFIG_PATH) then
			local d = HttpService:JSONDecode(readfile(CONFIG_PATH))
			for k, v in pairs(d) do CFG[k] = v end
		end
	end)
end
loadConfig()

-- ═══ STATS ═══
local STATS = { enemiesKilled = 0, bossesKilled = 0, itemsSold = 0 }

-- ═══ UNLOAD ═══
local _connections = {}
local _espObjects  = {}
local function addConn(c) if c then table.insert(_connections, c) end end
local function cleanup()
	for _, c in pairs(_connections) do pcall(function() c:Disconnect() end) end
	for _, e in pairs(_espObjects)  do pcall(function() e:Destroy()    end) end
	_connections, _espObjects = {}, {}
	stopFarmFly()
	for _, k in ipairs({"autoFarm","autoSell","speedEnabled","jumpEnabled","noclipEnabled","infJump","playerESP","enemyESP","fpsBooster","antiAfk","bossAutoReady","autoReplay"}) do
		CFG[k] = false
	end
end
if getgenv then getgenv().DQR_Unload = cleanup end

-- ═══ DESIGN TOKENS ═══
local C = {
	glassPrimary  = Color3.fromRGB(10,12,24),  glassSurface = Color3.fromRGB(16,20,36),
	glassCard     = Color3.fromRGB(20,24,44),  glassHover   = Color3.fromRGB(28,34,58),
	glassActive   = Color3.fromRGB(34,40,68),
	accentCyan    = Color3.fromRGB(0,200,255),  accentViolet = Color3.fromRGB(140,120,255),
	accentBlend   = Color3.fromRGB(80,160,255),
	toggleOn      = Color3.fromRGB(0,180,230),  toggleOff    = Color3.fromRGB(40,46,70),
	textPrimary   = Color3.fromRGB(225,235,255), textSecondary = Color3.fromRGB(140,155,185),
	textMuted     = Color3.fromRGB(90,105,135),  textWhite    = Color3.fromRGB(255,255,255),
	borderGlass   = Color3.fromRGB(50,65,110),   borderGlow   = Color3.fromRGB(0,180,255),
	shadow        = Color3.fromRGB(2,3,8),
	green         = Color3.fromRGB(40,220,130),  red          = Color3.fromRGB(255,70,70),
	yellow        = Color3.fromRGB(255,200,50),
}
local TR = { glassMain=0.02, glassSurface=0.05, glassCard=0.08, glassSidebar=0.04, glassTopBar=0.03, border=0.55, borderGlow=0.35 }
local CR = { large=UDim.new(0,14), medium=UDim.new(0,10), small=UDim.new(0,6), pill=UDim.new(1,0) }

-- ═══ UI HELPERS ═══
local function applyGlass(f, o)
	o = o or {}
	local corner = Instance.new("UICorner"); corner.CornerRadius = o.corner or CR.medium; corner.Parent = f
	if o.stroke then
		local s = Instance.new("UIStroke"); s.Color = o.strokeColor or C.borderGlass
		s.Thickness = o.strokeThickness or 1; s.Transparency = o.strokeTransparency or TR.border
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = f
		if o.returnStroke then return s end
	end
	if o.gradient then
		local g = Instance.new("UIGradient")
		g.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,255,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(180,190,220))})
		g.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.05),NumberSequenceKeypoint.new(0.5,0.12),NumberSequenceKeypoint.new(1,0.03)})
		g.Rotation = o.gradientRotation or 135; g.Parent = f
	end
end

local function applyPadding(p, l, r, t, b)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft=UDim.new(0,l or 0); pad.PaddingRight=UDim.new(0,r or 0)
	pad.PaddingTop=UDim.new(0,t or 0); pad.PaddingBottom=UDim.new(0,b or 0)
	pad.Parent = p
end

local function applyList(p, padding, sortOrder)
	local l = Instance.new("UIListLayout")
	l.SortOrder = sortOrder or Enum.SortOrder.LayoutOrder
	l.Padding = UDim.new(0, padding or 4); l.Parent = p; return l
end

-- Toggle widget
local function createToggle(parent, label, lo)
	local card = Instance.new("Frame"); card.Size=UDim2.new(1,0,0,34); card.BackgroundColor3=C.glassCard
	card.BackgroundTransparency=TR.glassCard; card.BorderSizePixel=0; card.LayoutOrder=lo or 0; card.ZIndex=2; card.Parent=parent
	applyGlass(card,{corner=CR.small,stroke=true,strokeColor=C.borderGlass,strokeThickness=1,strokeTransparency=0.75})

	local title=Instance.new("TextLabel"); title.Size=UDim2.new(0.72,0,1,0); title.Position=UDim2.new(0,12,0,0)
	title.BackgroundTransparency=1; title.Text=label; title.TextColor3=C.textPrimary; title.Font=Enum.Font.GothamMedium
	title.TextSize=12; title.TextXAlignment=Enum.TextXAlignment.Left; title.ZIndex=3; title.Parent=card

	local track=Instance.new("TextButton"); track.Size=UDim2.new(0,36,0,18); track.Position=UDim2.new(1,-46,0.5,-9)
	track.BackgroundColor3=C.toggleOff; track.BackgroundTransparency=0.15; track.BorderSizePixel=0
	track.Text=""; track.ZIndex=3; track.Active=true; track.Parent=card
	Instance.new("UICorner",track).CornerRadius=CR.pill

	local thumb=Instance.new("Frame"); thumb.Size=UDim2.new(0,14,0,14); thumb.Position=UDim2.new(0,2,0.5,-7)
	thumb.BackgroundColor3=C.textWhite; thumb.BorderSizePixel=0; thumb.ZIndex=4; thumb.Parent=track
	Instance.new("UICorner",thumb).CornerRadius=CR.pill

	local stroke=Instance.new("UIStroke"); stroke.Color=C.accentCyan; stroke.Thickness=1; stroke.Transparency=0.5; stroke.Parent=track
	return card, track, thumb
end

-- Input row
local function createInput(parent, label, placeholder, defaultVal, lo, onChange)
	local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,34); row.BackgroundColor3=C.glassCard
	row.BackgroundTransparency=TR.glassCard; row.BorderSizePixel=0; row.LayoutOrder=lo or 0; row.ZIndex=2; row.Parent=parent
	applyGlass(row,{corner=CR.small,stroke=true,strokeColor=C.borderGlass,strokeThickness=1,strokeTransparency=0.75})

	local title=Instance.new("TextLabel"); title.Size=UDim2.new(0.6,0,1,0); title.Position=UDim2.new(0,12,0,0)
	title.BackgroundTransparency=1; title.Text=label; title.TextColor3=C.textPrimary
	title.Font=Enum.Font.GothamMedium; title.TextSize=12; title.TextXAlignment=Enum.TextXAlignment.Left
	title.ZIndex=3; title.Parent=row

	local box=Instance.new("TextBox"); box.Size=UDim2.new(0,70,0,24); box.Position=UDim2.new(1,-80,0.5,-12)
	box.BackgroundColor3=C.glassSurface; box.BackgroundTransparency=0.25; box.BorderSizePixel=0
	box.Text=tostring(defaultVal or ""); box.PlaceholderText=placeholder or ""; box.PlaceholderColor3=C.textMuted
	box.TextColor3=C.accentCyan; box.Font=Enum.Font.GothamBold; box.TextSize=12
	box.TextXAlignment=Enum.TextXAlignment.Center; box.ZIndex=4; box.Parent=row
	applyGlass(box,{corner=CR.small,stroke=true,strokeColor=C.borderGlass,strokeThickness=1,strokeTransparency=0.85})
	if onChange then box.FocusLost:Connect(function() onChange(box.Text) end) end
	return row, box
end

-- Action button
local function createButton(parent, label, color, lo, onClick)
	local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,34); row.BackgroundColor3=C.glassCard
	row.BackgroundTransparency=TR.glassCard; row.BorderSizePixel=0; row.LayoutOrder=lo or 0; row.Parent=parent
	applyGlass(row,{corner=CR.small,stroke=true,strokeColor=color or C.accentCyan,strokeThickness=1,strokeTransparency=0.4})

	local btn=Instance.new("TextButton"); btn.Size=UDim2.new(1,-20,0,24); btn.Position=UDim2.new(0,10,0.5,-12)
	btn.BackgroundColor3=color or C.accentCyan; btn.BackgroundTransparency=0.65; btn.BorderSizePixel=0
	btn.Text="  "..label; btn.TextColor3=C.textWhite; btn.Font=Enum.Font.GothamBold; btn.TextSize=12
	btn.TextXAlignment=Enum.TextXAlignment.Left; btn.ZIndex=3; btn.Parent=row
	Instance.new("UICorner",btn).CornerRadius=CR.small
	if onClick then btn.MouseButton1Click:Connect(onClick) end
	pcall(function()
		btn.MouseEnter:Connect(function() TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundTransparency=0.4}):Play() end)
		btn.MouseLeave:Connect(function() TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundTransparency=0.65}):Play() end)
	end)
	return row, btn
end

-- Collapsible section
local function createSection(parent, title, lo, defaultExpanded)
	local header=Instance.new("TextButton"); header.Size=UDim2.new(1,0,0,32)
	header.BackgroundColor3=Color3.fromRGB(24,28,52); header.BackgroundTransparency=0.08
	header.BorderSizePixel=0; header.Text=""; header.LayoutOrder=lo; header.Parent=parent
	applyGlass(header,{corner=UDim.new(0,8),stroke=true,strokeColor=C.borderGlass,strokeThickness=1,strokeTransparency=0.55})

	local bar=Instance.new("Frame"); bar.Size=UDim2.new(0,3,0,16); bar.Position=UDim2.new(0,6,0.5,-8)
	bar.BackgroundColor3=C.accentCyan; bar.BorderSizePixel=0; bar.Parent=header
	Instance.new("UICorner",bar).CornerRadius=UDim.new(0,2)

	local hT=Instance.new("TextLabel"); hT.Size=UDim2.new(1,-50,1,0); hT.Position=UDim2.new(0,18,0,0)
	hT.BackgroundTransparency=1; hT.Text=title; hT.TextColor3=C.textWhite
	hT.Font=Enum.Font.GothamBold; hT.TextSize=12; hT.TextXAlignment=Enum.TextXAlignment.Left; hT.Parent=header

	local arrow=Instance.new("TextLabel"); arrow.Size=UDim2.new(0,24,0,24)
	arrow.Position=UDim2.new(1,-24,0.5,0); arrow.AnchorPoint=Vector2.new(0.5,0.5)
	arrow.BackgroundTransparency=1; arrow.Text=">"; arrow.TextColor3=C.accentCyan
	arrow.Font=Enum.Font.GothamBold; arrow.TextSize=12
	arrow.TextXAlignment=Enum.TextXAlignment.Center; arrow.TextYAlignment=Enum.TextYAlignment.Center; arrow.Parent=header

	local collapsed = not (defaultExpanded==true)
	if not collapsed then arrow.Rotation=90 end

	local container=Instance.new("Frame"); container.Size=UDim2.new(1,0,0,0); container.BackgroundTransparency=1
	container.LayoutOrder=lo+1; container.ClipsDescendants=true; container.Visible=not collapsed; container.Parent=parent

	local content=Instance.new("Frame"); content.Size=UDim2.new(1,0,0,0); content.BackgroundTransparency=1
	content.Visible=not collapsed; content.Parent=container

	local cLayout=Instance.new("UIListLayout"); cLayout.SortOrder=Enum.SortOrder.LayoutOrder
	cLayout.Padding=UDim.new(0,5); cLayout.Parent=content
	applyPadding(content,0,0,5,5)

	header.MouseButton1Click:Connect(function()
		collapsed=not collapsed; container.Visible=true; content.Visible=true
		TweenService:Create(arrow,TweenInfo.new(0.25,Enum.EasingStyle.Quad),{Rotation=collapsed and 0 or 90}):Play()
		local th=collapsed and 0 or cLayout.AbsoluteContentSize.Y+14
		local tw=TweenService:Create(container,TweenInfo.new(0.25,Enum.EasingStyle.Quad),{Size=UDim2.new(1,0,0,th)})
		tw.Completed:Connect(function() if collapsed then container.Visible=false; content.Visible=false end end)
		tw:Play()
	end)
	cLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		if not collapsed then container.Size=UDim2.new(1,0,0,cLayout.AbsoluteContentSize.Y+14) end
	end)
	task.spawn(function()
		task.wait(0.1)
		if not collapsed then container.Size=UDim2.new(1,0,0,cLayout.AbsoluteContentSize.Y+14) end
	end)
	return {Header=header,Container=container,Content=content,Layout=cLayout}
end

-- Toggle logic
local function setupToggle(track, thumb, cfgKey, onEnable, onDisable)
	local isOn = CFG[cfgKey] or false
	local function updateVisual()
		if isOn then
			TweenService:Create(track,TweenInfo.new(0.2),{BackgroundColor3=C.toggleOn}):Play()
			TweenService:Create(thumb,TweenInfo.new(0.2),{Position=UDim2.new(0,20,0.5,-7)}):Play()
		else
			TweenService:Create(track,TweenInfo.new(0.2),{BackgroundColor3=C.toggleOff}):Play()
			TweenService:Create(thumb,TweenInfo.new(0.2),{Position=UDim2.new(0,2,0.5,-7)}):Play()
		end
	end
	updateVisual()
	if isOn and onEnable then task.spawn(onEnable) end
	track.MouseButton1Click:Connect(function()
		isOn=not isOn; CFG[cfgKey]=isOn; updateVisual(); saveConfig()
		if isOn then if onEnable then task.spawn(onEnable) end
		else if onDisable then task.spawn(onDisable) end end
	end)
	return function() return isOn end
end

-- ═══ BUILD MAIN WINDOW ═══
local oldGui = player.PlayerGui:FindFirstChild("HipHub")
if oldGui then oldGui:Destroy() end
local oldBlur = Lighting:FindFirstChild("HipHubBlur")
if oldBlur then oldBlur:Destroy() end

local gui = Instance.new("ScreenGui"); gui.Name="HipHub"; gui.ResetOnSpawn=false
gui.DisplayOrder=2147483647; pcall(function() gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling end)
gui.Parent = player.PlayerGui

local shadowFrame=Instance.new("Frame"); shadowFrame.Size=UDim2.new(0,580,0,410)
shadowFrame.Position=UDim2.new(0.5,-290,0.5,-205); shadowFrame.BackgroundColor3=C.shadow
shadowFrame.BackgroundTransparency=0.45; shadowFrame.BorderSizePixel=0; shadowFrame.ZIndex=0; shadowFrame.Parent=gui
Instance.new("UICorner",shadowFrame).CornerRadius=UDim.new(0,18)

local mainFrame=Instance.new("Frame"); mainFrame.Size=UDim2.new(0,568,0,398)
mainFrame.Position=UDim2.new(0.5,-284,0.5,-199); mainFrame.BackgroundColor3=C.glassPrimary
mainFrame.BackgroundTransparency=TR.glassMain; mainFrame.BorderSizePixel=0
mainFrame.ClipsDescendants=true; mainFrame.Parent=gui
applyGlass(mainFrame,{corner=CR.large,stroke=true,strokeColor=C.borderGlow,strokeThickness=1.5,strokeTransparency=TR.borderGlow,gradient=true,gradientRotation=145})

local function syncShadow()
	shadowFrame.Position=UDim2.new(mainFrame.Position.X.Scale,mainFrame.Position.X.Offset-6,mainFrame.Position.Y.Scale,mainFrame.Position.Y.Offset-6)
	shadowFrame.Size=UDim2.new(mainFrame.Size.X.Scale,mainFrame.Size.X.Offset+12,mainFrame.Size.Y.Scale,mainFrame.Size.Y.Offset+12)
end
syncShadow()

local mainStroke=mainFrame:FindFirstChildOfClass("UIStroke")
if mainStroke then
	task.spawn(function()
		while mainFrame and mainFrame.Parent do
			TweenService:Create(mainStroke,TweenInfo.new(2.5,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Color=C.accentViolet}):Play(); task.wait(2.5)
			TweenService:Create(mainStroke,TweenInfo.new(2.5,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Color=C.accentCyan}):Play(); task.wait(2.5)
		end
	end)
end

local hl=Instance.new("Frame"); hl.Size=UDim2.new(1,0,0,60); hl.BackgroundColor3=Color3.fromRGB(255,255,255)
hl.BackgroundTransparency=0.96; hl.BorderSizePixel=0; hl.ZIndex=0; hl.Parent=mainFrame
local hg=Instance.new("UIGradient"); hg.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.90),NumberSequenceKeypoint.new(1,1)}); hg.Rotation=180; hg.Parent=hl

-- TOP BAR
local topBar=Instance.new("Frame"); topBar.Size=UDim2.new(1,0,0,42); topBar.BackgroundColor3=C.glassSurface
topBar.BackgroundTransparency=TR.glassTopBar; topBar.BorderSizePixel=0; topBar.ZIndex=2; topBar.Parent=mainFrame
applyGlass(topBar,{corner=CR.large})
local tbC=Instance.new("Frame"); tbC.Size=UDim2.new(1,0,0,14); tbC.Position=UDim2.new(0,0,1,-14)
tbC.BackgroundColor3=C.glassSurface; tbC.BackgroundTransparency=TR.glassTopBar; tbC.BorderSizePixel=0; tbC.ZIndex=2; tbC.Parent=topBar
local al=Instance.new("Frame"); al.Size=UDim2.new(1,0,0,1); al.Position=UDim2.new(0,0,1,-1)
al.BackgroundColor3=C.accentCyan; al.BackgroundTransparency=0.7; al.BorderSizePixel=0; al.ZIndex=3; al.Parent=topBar
do local ag=Instance.new("UIGradient"); ag.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,C.accentCyan),ColorSequenceKeypoint.new(0.5,C.accentViolet),ColorSequenceKeypoint.new(1,C.accentCyan)})
ag.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.8),NumberSequenceKeypoint.new(0.3,0.2),NumberSequenceKeypoint.new(0.7,0.2),NumberSequenceKeypoint.new(1,0.8)}); ag.Parent=al end

local tl=Instance.new("TextLabel"); tl.Size=UDim2.new(0,85,1,0); tl.Position=UDim2.new(0,14,0,0)
tl.BackgroundTransparency=1; tl.Text="⚔ HipHub"; tl.TextColor3=C.textWhite
tl.Font=Enum.Font.GothamBold; tl.TextSize=15; tl.TextXAlignment=Enum.TextXAlignment.Left; tl.ZIndex=3; tl.Parent=topBar

local badge=Instance.new("TextLabel"); badge.Size=UDim2.new(0,176,0,22); badge.Position=UDim2.new(0,104,0.5,-11)
badge.BackgroundColor3=C.accentViolet; badge.BackgroundTransparency=0.25; badge.Text="Dungeon Quest Reborn"
badge.TextColor3=C.textWhite; badge.Font=Enum.Font.GothamBold; badge.TextSize=9; badge.ZIndex=3; badge.Parent=topBar
applyGlass(badge,{corner=CR.pill,stroke=true,strokeColor=C.accentViolet,strokeThickness=1,strokeTransparency=0.5})

local closeBtn=Instance.new("TextButton"); closeBtn.Size=UDim2.new(0,30,0,30); closeBtn.Position=UDim2.new(1,-38,0.5,-15)
closeBtn.BackgroundTransparency=1; closeBtn.Text="x"; closeBtn.TextColor3=C.textSecondary
closeBtn.Font=Enum.Font.GothamBold; closeBtn.TextSize=18; closeBtn.ZIndex=3; closeBtn.Parent=topBar
closeBtn.MouseButton1Click:Connect(function() cleanup(); gui:Destroy() end)
closeBtn.MouseEnter:Connect(function() TweenService:Create(closeBtn,TweenInfo.new(0.15),{TextColor3=C.red}):Play() end)
closeBtn.MouseLeave:Connect(function() TweenService:Create(closeBtn,TweenInfo.new(0.15),{TextColor3=C.textSecondary}):Play() end)

local minBtn=Instance.new("TextButton"); minBtn.Size=UDim2.new(0,30,0,30); minBtn.Position=UDim2.new(1,-70,0.5,-15)
minBtn.BackgroundTransparency=1; minBtn.Text="-"; minBtn.TextColor3=C.textSecondary
minBtn.Font=Enum.Font.GothamBold; minBtn.TextSize=18; minBtn.ZIndex=3; minBtn.Parent=topBar
local isMin=false
minBtn.MouseButton1Click:Connect(function()
	isMin=not isMin
	TweenService:Create(mainFrame,TweenInfo.new(0.3,Enum.EasingStyle.Quad),{Size=UDim2.new(0,568,0,isMin and 42 or 398)}):Play()
	task.delay(0.3,syncShadow)
end)
minBtn.MouseEnter:Connect(function() TweenService:Create(minBtn,TweenInfo.new(0.15),{TextColor3=C.accentCyan}):Play() end)
minBtn.MouseLeave:Connect(function() TweenService:Create(minBtn,TweenInfo.new(0.15),{TextColor3=C.textSecondary}):Play() end)

do
	local dragging,startM,startF
	topBar.InputBegan:Connect(function(inp)
		if inp.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; startM=inp.Position; startF=mainFrame.Position end
	end)
	UserInputService.InputChanged:Connect(function(inp)
		if dragging and inp.UserInputType==Enum.UserInputType.MouseMovement then
			local d=inp.Position-startM
			mainFrame.Position=UDim2.new(startF.X.Scale,startF.X.Offset+d.X,startF.Y.Scale,startF.Y.Offset+d.Y)
			syncShadow()
		end
	end)
	UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
	end)
end

-- SIDEBAR
local sidebar=Instance.new("Frame"); sidebar.Size=UDim2.new(0,155,1,-42); sidebar.Position=UDim2.new(0,0,0,42)
sidebar.BackgroundColor3=C.glassSurface; sidebar.BackgroundTransparency=TR.glassSidebar
sidebar.BorderSizePixel=0; sidebar.ZIndex=1; sidebar.Parent=mainFrame
applyGlass(sidebar,{corner=CR.large})
local sbC=Instance.new("Frame"); sbC.Size=UDim2.new(0,14,1,0); sbC.Position=UDim2.new(1,-14,0,0)
sbC.BackgroundColor3=C.glassSurface; sbC.BackgroundTransparency=TR.glassSidebar; sbC.BorderSizePixel=0; sbC.ZIndex=1; sbC.Parent=sidebar
do local sg=Instance.new("Frame"); sg.Size=UDim2.new(0,1,1,-20); sg.Position=UDim2.new(1,-1,0,10)
sg.BackgroundColor3=C.accentCyan; sg.BackgroundTransparency=0.78; sg.BorderSizePixel=0; sg.ZIndex=2; sg.Parent=sidebar
local sgg=Instance.new("UIGradient"); sgg.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.2,0.5),NumberSequenceKeypoint.new(0.8,0.5),NumberSequenceKeypoint.new(1,1)}); sgg.Rotation=90; sgg.Parent=sg end

local tabContainer=Instance.new("Frame"); tabContainer.Size=UDim2.new(1,0,1,-60)
tabContainer.BackgroundTransparency=1; tabContainer.ZIndex=2; tabContainer.Parent=sidebar
applyList(tabContainer,3); applyPadding(tabContainer,8,8,12,0)

local profileCard=Instance.new("Frame"); profileCard.Size=UDim2.new(1,-16,0,44); profileCard.Position=UDim2.new(0,8,1,-52)
profileCard.BackgroundColor3=C.glassCard; profileCard.BackgroundTransparency=TR.glassCard
profileCard.BorderSizePixel=0; profileCard.ZIndex=2; profileCard.Parent=sidebar
applyGlass(profileCard,{corner=CR.small,stroke=true,strokeColor=C.borderGlass,strokeThickness=1,strokeTransparency=0.7})
local uLbl=Instance.new("TextLabel"); uLbl.Size=UDim2.new(1,-10,1,0); uLbl.Position=UDim2.new(0,10,0,0)
uLbl.BackgroundTransparency=1; uLbl.Text="Sword "..player.DisplayName; uLbl.TextColor3=C.textPrimary
uLbl.Font=Enum.Font.GothamMedium; uLbl.TextSize=11; uLbl.TextXAlignment=Enum.TextXAlignment.Left
uLbl.TextTruncate=Enum.TextTruncate.AtEnd; uLbl.ZIndex=3; uLbl.Parent=profileCard

-- CONTENT AREA
local contentArea=Instance.new("Frame"); contentArea.Size=UDim2.new(1,-155,1,-42)
contentArea.Position=UDim2.new(0,155,0,42); contentArea.BackgroundTransparency=1
contentArea.ZIndex=1; contentArea.Parent=mainFrame

-- TAB SYSTEM
local tabs={};local activeTab=nil

local function createTabFrame()
	local f=Instance.new("ScrollingFrame"); f.Size=UDim2.new(1,0,1,0); f.BackgroundTransparency=1; f.BorderSizePixel=0
	pcall(function() f.ScrollBarThickness=3; f.ScrollBarImageColor3=C.accentCyan; f.ScrollBarImageTransparency=0.4 end)
	f.CanvasSize=UDim2.new(0,0,0,0); f.AutomaticCanvasSize=Enum.AutomaticSize.Y
	f.ClipsDescendants=true; f.Visible=false; f.ZIndex=2; f.Parent=contentArea
	applyPadding(f,14,14,14,14); return f
end

local function selectTab(name)
	for n,data in pairs(tabs) do
		if n==name then
			data.Frame.Visible=true
			TweenService:Create(data.Button,TweenInfo.new(0.2,Enum.EasingStyle.Quad),{BackgroundColor3=C.glassActive,BackgroundTransparency=0.15}):Play()
			pcall(function() data.Button.TextColor3=C.textWhite end)
			if data.Ind then data.Ind.Visible=true; TweenService:Create(data.Ind,TweenInfo.new(0.25),{BackgroundTransparency=0}):Play() end
		else
			data.Frame.Visible=false
			TweenService:Create(data.Button,TweenInfo.new(0.2,Enum.EasingStyle.Quad),{BackgroundColor3=C.glassSurface,BackgroundTransparency=1}):Play()
			pcall(function() data.Button.TextColor3=C.textSecondary end)
			if data.Ind then TweenService:Create(data.Ind,TweenInfo.new(0.15),{BackgroundTransparency=1}):Play()
			task.delay(0.15,function() if data.Ind then data.Ind.Visible=false end end) end
		end
	end
	activeTab=name
end

local function addTab(name,icon,lo)
	local btn=Instance.new("TextButton"); btn.Size=UDim2.new(1,0,0,30); btn.BackgroundColor3=C.glassSurface
	btn.BackgroundTransparency=1; btn.BorderSizePixel=0; btn.ZIndex=3
	pcall(function() btn.Text="  "..(icon~="" and icon.." " or "")..name end)
	if btn.Text=="" then btn.Text="  "..name end
	btn.TextColor3=C.textSecondary; btn.Font=Enum.Font.GothamMedium; btn.TextSize=12
	btn.TextXAlignment=Enum.TextXAlignment.Left; btn.LayoutOrder=lo; btn.Parent=tabContainer
	applyGlass(btn,{corner=CR.small})
	local ind=Instance.new("Frame"); ind.Size=UDim2.new(0,3,0,16); ind.Position=UDim2.new(0,2,0.5,-8)
	ind.BackgroundColor3=C.accentCyan; ind.BackgroundTransparency=1; ind.BorderSizePixel=0
	ind.Visible=false; ind.ZIndex=4; ind.Parent=btn
	Instance.new("UICorner",ind).CornerRadius=UDim.new(0,2)
	local frame=createTabFrame(); tabs[name]={Frame=frame,Button=btn,Ind=ind}
	btn.MouseButton1Click:Connect(function() selectTab(name) end)
	pcall(function()
		btn.MouseEnter:Connect(function() if activeTab~=name then TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=C.glassHover,BackgroundTransparency=0.5}):Play() end end)
		btn.MouseLeave:Connect(function() if activeTab~=name then TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=C.glassSurface,BackgroundTransparency=1}):Play() end end)
	end)
	return frame
end

local tabFrames = {
	Info  = addTab("Info",  "Chart", 1),
	Farm  = addTab("Farm",  "Sword",  2),
	Boss  = addTab("Boss",  "Boss",  3),
	ESP   = addTab("ESP",   "Eye",   4),
	Move  = addTab("Move",  "Run",   5),
	Sell  = addTab("Sell",  "Gold",  6),
	Misc  = addTab("Misc",  "Gear",  7),
}
