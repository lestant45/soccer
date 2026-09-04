-- ==============================================================================
-- 🐾 HipHub — Liquid Glass Futuristic UI Base Engine (Pet Simulator 99)
-- Theme: Glassmorphism / Liquid Glass with Cyan-Violet Neon Accents
-- Pure Luau Implementation — 100% Self-Contained, Zero External Dependencies
-- ==============================================================================

if not game:IsLoaded() then
	pcall(function() game.Loaded:Wait() end)
end

local Players = game:GetService("Players")
local player = Players.LocalPlayer
while not player do
	task.wait(0.5)
	player = Players.LocalPlayer
end

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

------------------------------------------------
-- 🎨 DESIGN TOKENS (Liquid Glass Palette)
------------------------------------------------
local COLORS = {
	glassPrimary  = Color3.fromRGB(10, 12, 24),
	glassSurface  = Color3.fromRGB(16, 20, 36),
	glassCard     = Color3.fromRGB(20, 24, 44),
	glassHover    = Color3.fromRGB(28, 34, 58),
	glassActive   = Color3.fromRGB(34, 40, 68),
	accentCyan    = Color3.fromRGB(0, 200, 255),
	accentViolet  = Color3.fromRGB(140, 120, 255),
	accentBlend   = Color3.fromRGB(80, 160, 255),
	accentGlow    = Color3.fromRGB(60, 180, 255),
	accentMuted   = Color3.fromRGB(50, 60, 100),
	toggleOn      = Color3.fromRGB(0, 180, 230),
	toggleOff     = Color3.fromRGB(40, 46, 70),
	textPrimary   = Color3.fromRGB(225, 235, 255),
	textSecondary = Color3.fromRGB(140, 155, 185),
	textMuted     = Color3.fromRGB(90, 105, 135),
	textWhite     = Color3.fromRGB(255, 255, 255),
	borderGlass   = Color3.fromRGB(50, 65, 110),
	borderGlow    = Color3.fromRGB(0, 180, 255),
	shadow        = Color3.fromRGB(2, 3, 8),
	successGreen  = Color3.fromRGB(46, 204, 113),
	warningYellow = Color3.fromRGB(241, 196, 15),
	dangerRed     = Color3.fromRGB(231, 76, 60),
}

local TRANSPARENCY = {
	glassMain    = 0.03,
	glassSurface = 0.06,
	glassCard    = 0.10,
	glassSidebar = 0.05,
	glassTopBar  = 0.04,
	border       = 0.55,
	borderGlow   = 0.35,
}

local CORNER = {
	large  = UDim.new(0, 14),
	medium = UDim.new(0, 10),
	small  = UDim.new(0, 6),
	pill   = UDim.new(1, 0),
}

------------------------------------------------
-- 🛠️ STYLING HELPERS
------------------------------------------------
local function applyGlass(frame, opts)
	opts = opts or {}
	local corner = Instance.new("UICorner")
	corner.CornerRadius = opts.corner or CORNER.medium
	corner.Parent = frame

	if opts.stroke then
		local stroke = Instance.new("UIStroke")
		stroke.Color = opts.strokeColor or COLORS.borderGlass
		stroke.Thickness = opts.strokeThickness or 1
		stroke.Transparency = opts.strokeTransparency or TRANSPARENCY.border
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = frame
	end

	if opts.gradient then
		local grad = Instance.new("UIGradient")
		grad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 190, 220)),
		})
		grad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.04),
			NumberSequenceKeypoint.new(0.5, 0.12),
			NumberSequenceKeypoint.new(1, 0.04),
		})
		grad.Rotation = opts.gradientRotation or 135
		grad.Parent = frame
	end
end

local function applyPadding(parent, l, r, t, b)
	local p = Instance.new("UIPadding")
	p.PaddingLeft = UDim.new(0, l or 0)
	p.PaddingRight = UDim.new(0, r or 0)
	p.PaddingTop = UDim.new(0, t or 0)
	p.PaddingBottom = UDim.new(0, b or 0)
	p.Parent = parent
	return p
end

local function applyListLayout(parent, padding, sortOrder)
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = sortOrder or Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, padding or 6)
	layout.Parent = parent
	return layout
end

local function getGuiHost()
	local host = nil
	if gethui then
		pcall(function() host = gethui() end)
	end
	if not host then
		local coreGui = game:GetService("CoreGui")
		local ok = pcall(function()
			local test = Instance.new("Folder")
			test.Parent = coreGui
			test:Destroy()
		end)
		if ok then
			host = coreGui
		else
			host = player:WaitForChild("PlayerGui")
		end
	end
	return host
end

------------------------------------------------
-- 🌐 FLOW LIBRARY (HIPHUB IMPLEMENTATION)
------------------------------------------------
local FlowLibrary = {}

function FlowLibrary.new(cfg)
	cfg = cfg or {}
	local titleText = cfg.Title or "Pet Simulator 99"
	local windowSize = cfg.SizeUi or UDim2.fromOffset(660, 480)

	-- Cleanup existing instances
	local guiHost = getGuiHost()
	pcall(function()
		for _, g in ipairs(guiHost:GetChildren()) do
			if g:IsA("ScreenGui") and (g.Name == "HipHub_PS99" or g.Name == "HipHub") then
				g:Destroy()
			end
		end
		if player:FindFirstChild("PlayerGui") then
			for _, g in ipairs(player.PlayerGui:GetChildren()) do
				if g:IsA("ScreenGui") and (g.Name == "HipHub_PS99" or g.Name == "HipHub") then
					g:Destroy()
				end
			end
		end
	end)

	-- Root ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = "HipHub_PS99"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 2147483647
	pcall(function() gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling end)
	gui.Parent = guiHost

	-- Shadow Backing
	local shadowFrame = Instance.new("Frame")
	shadowFrame.Size = UDim2.new(0, windowSize.X.Offset + 16, 0, windowSize.Y.Offset + 16)
	shadowFrame.Position = UDim2.new(0.5, -math.floor(windowSize.X.Offset / 2) - 8, 0.5, -math.floor(windowSize.Y.Offset / 2) - 8)
	shadowFrame.BackgroundColor3 = COLORS.shadow
	shadowFrame.BackgroundTransparency = 0.45
	shadowFrame.BorderSizePixel = 0
	shadowFrame.ZIndex = 0
	shadowFrame.Parent = gui

	local shadowCorner = Instance.new("UICorner")
	shadowCorner.CornerRadius = UDim.new(0, 18)
	shadowCorner.Parent = shadowFrame

	-- Main Panel
	local mainFrame = Instance.new("Frame")
	mainFrame.Size = windowSize
	mainFrame.Position = UDim2.new(0.5, -math.floor(windowSize.X.Offset / 2), 0.5, -math.floor(windowSize.Y.Offset / 2))
	mainFrame.BackgroundColor3 = COLORS.glassPrimary
	mainFrame.BackgroundTransparency = TRANSPARENCY.glassMain
	mainFrame.BorderSizePixel = 0
	mainFrame.ClipsDescendants = true
	mainFrame.Parent = gui

	applyGlass(mainFrame, {
		corner = CORNER.large,
		stroke = true,
		strokeColor = COLORS.borderGlow,
		strokeThickness = 1.5,
		strokeTransparency = TRANSPARENCY.borderGlow,
		gradient = true,
		gradientRotation = 145,
	})

	-- Dynamic glowing border animation
	local mainStroke = mainFrame:FindFirstChildOfClass("UIStroke")
	if mainStroke then
		task.spawn(function()
			while mainFrame and mainFrame.Parent do
				TweenService:Create(mainStroke, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
					Color = COLORS.accentViolet
				}):Play()
				task.wait(3)
				TweenService:Create(mainStroke, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
					Color = COLORS.accentCyan
				}):Play()
				task.wait(3)
			end
		end)
	end

	-- Top liquid glass highlight reflection
	local glassHighlight = Instance.new("Frame")
	glassHighlight.Size = UDim2.new(1, 0, 0, 50)
	glassHighlight.Position = UDim2.new(0, 0, 0, 0)
	glassHighlight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	glassHighlight.BackgroundTransparency = 0.96
	glassHighlight.BorderSizePixel = 0
	glassHighlight.ZIndex = 0
	glassHighlight.Parent = mainFrame

	local highlightGrad = Instance.new("UIGradient")
	highlightGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.90),
		NumberSequenceKeypoint.new(1, 1),
	})
	highlightGrad.Rotation = 180
	highlightGrad.Parent = glassHighlight

	local function syncShadow()
		if not shadowFrame or not mainFrame then return end
		shadowFrame.Position = UDim2.new(
			mainFrame.Position.X.Scale, mainFrame.Position.X.Offset - 8,
			mainFrame.Position.Y.Scale, mainFrame.Position.Y.Offset - 8
		)
		shadowFrame.Size = UDim2.new(
			mainFrame.Size.X.Scale, mainFrame.Size.X.Offset + 16,
			mainFrame.Size.Y.Scale, mainFrame.Size.Y.Offset + 16
		)
		shadowFrame.Visible = mainFrame.Visible
	end

	------------------------------------------------
	-- 📌 TOP BAR (Title, Badge, Dragging, Controls)
	------------------------------------------------
	local topBar = Instance.new("Frame")
	topBar.Size = UDim2.new(1, 0, 0, 42)
	topBar.BackgroundColor3 = COLORS.glassSurface
	topBar.BackgroundTransparency = TRANSPARENCY.glassTopBar
	topBar.BorderSizePixel = 0
	topBar.ZIndex = 3
	topBar.Parent = mainFrame

	applyGlass(topBar, { corner = CORNER.large })

	local topBarCover = Instance.new("Frame")
	topBarCover.Size = UDim2.new(1, 0, 0, 14)
	topBarCover.Position = UDim2.new(0, 0, 1, -14)
	topBarCover.BackgroundColor3 = COLORS.glassSurface
	topBarCover.BackgroundTransparency = TRANSPARENCY.glassTopBar
	topBarCover.BorderSizePixel = 0
	topBarCover.ZIndex = 3
	topBarCover.Parent = topBar

	-- Glowing accent underline
	local topBarAccent = Instance.new("Frame")
	topBarAccent.Size = UDim2.new(1, 0, 0, 1)
	topBarAccent.Position = UDim2.new(0, 0, 1, -1)
	topBarAccent.BackgroundColor3 = COLORS.accentCyan
	topBarAccent.BackgroundTransparency = 0.65
	topBarAccent.BorderSizePixel = 0
	topBarAccent.ZIndex = 4
	topBarAccent.Parent = topBar

	local accentGrad = Instance.new("UIGradient")
	accentGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, COLORS.accentCyan),
		ColorSequenceKeypoint.new(0.5, COLORS.accentViolet),
		ColorSequenceKeypoint.new(1, COLORS.accentCyan),
	})
	accentGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(0.3, 0.15),
		NumberSequenceKeypoint.new(0.7, 0.15),
		NumberSequenceKeypoint.new(1, 0.8),
	})
	accentGrad.Parent = topBarAccent

	-- Logo / Title Icon
	local hubTitle = Instance.new("TextLabel")
	hubTitle.Size = UDim2.new(0, 80, 1, 0)
	hubTitle.Position = UDim2.new(0, 16, 0, 0)
	hubTitle.BackgroundTransparency = 1
	hubTitle.Text = "🐾 HipHub"
	hubTitle.TextColor3 = COLORS.textWhite
	hubTitle.Font = Enum.Font.GothamBold
	hubTitle.TextSize = 15
	hubTitle.TextXAlignment = Enum.TextXAlignment.Left
	hubTitle.ZIndex = 4
	hubTitle.Parent = topBar

	-- Game Subtitle Badge
	local badge = Instance.new("TextLabel")
	badge.Size = UDim2.new(0, 130, 0, 22)
	badge.Position = UDim2.new(0, 102, 0.5, -11)
	badge.BackgroundColor3 = COLORS.accentViolet
	badge.BackgroundTransparency = 0.3
	badge.Text = "Pet Simulator 99"
	badge.TextColor3 = COLORS.textWhite
	badge.Font = Enum.Font.GothamBold
	badge.TextSize = 10
	badge.ZIndex = 4
	badge.Parent = topBar

	applyGlass(badge, {
		corner = CORNER.pill,
		stroke = true,
		strokeColor = COLORS.accentViolet,
		strokeThickness = 1,
		strokeTransparency = 0.5
	})

	-- TopBar Controls (Close, Fullscreen, Minimize)
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 30, 0, 30)
	closeButton.Position = UDim2.new(1, -38, 0.5, -15)
	closeButton.BackgroundTransparency = 1
	closeButton.Text = "✕"
	closeButton.TextColor3 = COLORS.textSecondary
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextSize = 13
	closeButton.ZIndex = 4
	closeButton.Parent = topBar

	closeButton.MouseEnter:Connect(function()
		TweenService:Create(closeButton, TweenInfo.new(0.15), { TextColor3 = COLORS.dangerRed }):Play()
	end)
	closeButton.MouseLeave:Connect(function()
		TweenService:Create(closeButton, TweenInfo.new(0.15), { TextColor3 = COLORS.textSecondary }):Play()
	end)

	local fullscreenButton = Instance.new("TextButton")
	fullscreenButton.Size = UDim2.new(0, 30, 0, 30)
	fullscreenButton.Position = UDim2.new(1, -70, 0.5, -15)
	fullscreenButton.BackgroundTransparency = 1
	fullscreenButton.Text = "□"
	fullscreenButton.TextColor3 = COLORS.textSecondary
	fullscreenButton.Font = Enum.Font.GothamBold
	fullscreenButton.TextSize = 14
	fullscreenButton.ZIndex = 4
	fullscreenButton.Parent = topBar

	fullscreenButton.MouseEnter:Connect(function()
		TweenService:Create(fullscreenButton, TweenInfo.new(0.15), { TextColor3 = COLORS.accentCyan }):Play()
	end)
	fullscreenButton.MouseLeave:Connect(function()
		TweenService:Create(fullscreenButton, TweenInfo.new(0.15), { TextColor3 = COLORS.textSecondary }):Play()
	end)

	local minimizeButton = Instance.new("TextButton")
	minimizeButton.Size = UDim2.new(0, 30, 0, 30)
	minimizeButton.Position = UDim2.new(1, -102, 0.5, -15)
	minimizeButton.BackgroundTransparency = 1
	minimizeButton.Text = "−"
	minimizeButton.TextColor3 = COLORS.textSecondary
	minimizeButton.Font = Enum.Font.GothamBold
	minimizeButton.TextSize = 18
	minimizeButton.ZIndex = 4
	minimizeButton.Parent = topBar

	minimizeButton.MouseEnter:Connect(function()
		TweenService:Create(minimizeButton, TweenInfo.new(0.15), { TextColor3 = COLORS.accentCyan }):Play()
	end)
	minimizeButton.MouseLeave:Connect(function()
		TweenService:Create(minimizeButton, TweenInfo.new(0.15), { TextColor3 = COLORS.textSecondary }):Play()
	end)

	------------------------------------------------
	-- 📂 SIDEBAR (Tabs & Profile Card)
	------------------------------------------------
	local sidebar = Instance.new("Frame")
	sidebar.Size = UDim2.new(0, 145, 1, -42)
	sidebar.Position = UDim2.new(0, 0, 0, 42)
	sidebar.BackgroundColor3 = COLORS.glassSurface
	sidebar.BackgroundTransparency = TRANSPARENCY.glassSidebar
	sidebar.BorderSizePixel = 0
	sidebar.ZIndex = 2
	sidebar.Parent = mainFrame

	applyGlass(sidebar, { corner = CORNER.large })

	local sidebarCover = Instance.new("Frame")
	sidebarCover.Size = UDim2.new(0, 14, 1, 0)
	sidebarCover.Position = UDim2.new(1, -14, 0, 0)
	sidebarCover.BackgroundColor3 = COLORS.glassSurface
	sidebarCover.BackgroundTransparency = TRANSPARENCY.glassSidebar
	sidebarCover.BorderSizePixel = 0
	sidebarCover.ZIndex = 2
	sidebarCover.Parent = sidebar

	-- Sidebar right glow divider
	local sidebarGlow = Instance.new("Frame")
	sidebarGlow.Size = UDim2.new(0, 1, 1, -20)
	sidebarGlow.Position = UDim2.new(1, -1, 0, 10)
	sidebarGlow.BackgroundColor3 = COLORS.accentCyan
	sidebarGlow.BackgroundTransparency = 0.75
	sidebarGlow.BorderSizePixel = 0
	sidebarGlow.ZIndex = 3
	sidebarGlow.Parent = sidebar

	local sidebarGlowGrad = Instance.new("UIGradient")
	sidebarGlowGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0.4),
		NumberSequenceKeypoint.new(0.8, 0.4),
		NumberSequenceKeypoint.new(1, 1),
	})
	sidebarGlowGrad.Rotation = 90
	sidebarGlowGrad.Parent = sidebarGlow

	-- Tab Buttons Container (Scrollable)
	local tabScroll = Instance.new("ScrollingFrame")
	tabScroll.Size = UDim2.new(1, 0, 1, -56)
	tabScroll.Position = UDim2.new(0, 0, 0, 0)
	tabScroll.BackgroundTransparency = 1
	tabScroll.BorderSizePixel = 0
	tabScroll.ScrollBarThickness = 2
	tabScroll.ScrollBarImageColor3 = COLORS.accentCyan
	tabScroll.ScrollBarImageTransparency = 0.5
	tabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	tabScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	tabScroll.ZIndex = 3
	tabScroll.Parent = sidebar

	applyPadding(tabScroll, 8, 8, 10, 8)
	applyListLayout(tabScroll, 4)

	-- Profile Card at Bottom of Sidebar
	local profileCard = Instance.new("Frame")
	profileCard.Size = UDim2.new(1, -16, 0, 44)
	profileCard.Position = UDim2.new(0, 8, 1, -50)
	profileCard.BackgroundColor3 = COLORS.glassCard
	profileCard.BackgroundTransparency = TRANSPARENCY.glassCard
	profileCard.BorderSizePixel = 0
	profileCard.ZIndex = 3
	profileCard.Parent = sidebar

	applyGlass(profileCard, {
		corner = CORNER.small,
		stroke = true,
		strokeColor = COLORS.borderGlass,
		strokeThickness = 1,
		strokeTransparency = 0.7
	})

	local avatarLabel = Instance.new("ImageLabel")
	avatarLabel.Size = UDim2.new(0, 28, 0, 28)
	avatarLabel.Position = UDim2.new(0, 8, 0.5, -14)
	avatarLabel.BackgroundColor3 = COLORS.glassHover
	avatarLabel.BorderSizePixel = 0
	avatarLabel.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(player.UserId) .. "&w=150&h=150"
	avatarLabel.ZIndex = 4
	avatarLabel.Parent = profileCard

	local avatarCorner = Instance.new("UICorner")
	avatarCorner.CornerRadius = CORNER.pill
	avatarCorner.Parent = avatarLabel

	local avatarStroke = Instance.new("UIStroke")
	avatarStroke.Color = COLORS.accentCyan
	avatarStroke.Thickness = 1
	avatarStroke.Transparency = 0.4
	avatarStroke.Parent = avatarLabel

	local usernameLabel = Instance.new("TextLabel")
	usernameLabel.Size = UDim2.new(1, -48, 0, 16)
	usernameLabel.Position = UDim2.new(0, 42, 0.5, -8)
	usernameLabel.BackgroundTransparency = 1
	usernameLabel.Text = player.DisplayName or player.Name
	usernameLabel.TextColor3 = COLORS.textPrimary
	usernameLabel.Font = Enum.Font.GothamBold
	usernameLabel.TextSize = 11
	usernameLabel.TextXAlignment = Enum.TextXAlignment.Left
	usernameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	usernameLabel.ZIndex = 4
	usernameLabel.Parent = profileCard

	------------------------------------------------
	-- 🖥️ CONTENT AREA
	------------------------------------------------
	local contentArea = Instance.new("Frame")
	contentArea.Size = UDim2.new(1, -145, 1, -42)
	contentArea.Position = UDim2.new(0, 145, 0, 42)
	contentArea.BackgroundTransparency = 1
	contentArea.ZIndex = 2
	contentArea.Parent = mainFrame

	------------------------------------------------
	-- 🔔 NOTIFICATION SYSTEM
	------------------------------------------------
	local notifContainer = Instance.new("Frame")
	notifContainer.Size = UDim2.new(0, 280, 1, -40)
	notifContainer.Position = UDim2.new(1, -290, 0, 20)
	notifContainer.BackgroundTransparency = 1
	notifContainer.ZIndex = 20
	notifContainer.Parent = gui

	local notifLayout = applyListLayout(notifContainer, 8, Enum.SortOrder.LayoutOrder)
	notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom

	local function showNotification(opts)
		opts = opts or {}
		local nTitle = tostring(opts.Title or "HipHub")
		local nDesc = tostring(opts.Description or opts.Content or "")
		local nDuration = tonumber(opts.Duration or opts.Time) or 3

		local notifFrame = Instance.new("Frame")
		notifFrame.Size = UDim2.new(1, 0, 0, 56)
		notifFrame.BackgroundColor3 = COLORS.glassPrimary
		notifFrame.BackgroundTransparency = 0.1
		notifFrame.BorderSizePixel = 0
		notifFrame.ZIndex = 21
		notifFrame.Parent = notifContainer

		applyGlass(notifFrame, {
			corner = CORNER.medium,
			stroke = true,
			strokeColor = COLORS.accentCyan,
			strokeThickness = 1.2,
			strokeTransparency = 0.3
		})

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Size = UDim2.new(1, -20, 0, 20)
		titleLabel.Position = UDim2.new(0, 10, 0, 6)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = "🐾 " .. nTitle
		titleLabel.TextColor3 = COLORS.accentCyan
		titleLabel.Font = Enum.Font.GothamBold
		titleLabel.TextSize = 12
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.ZIndex = 22
		titleLabel.Parent = notifFrame

		local descLabel = Instance.new("TextLabel")
		descLabel.Size = UDim2.new(1, -20, 0, 26)
		descLabel.Position = UDim2.new(0, 10, 0, 26)
		descLabel.BackgroundTransparency = 1
		descLabel.Text = nDesc
		descLabel.TextColor3 = COLORS.textPrimary
		descLabel.Font = Enum.Font.GothamMedium
		descLabel.TextSize = 11
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextWrapped = true
		descLabel.ZIndex = 22
		descLabel.Parent = notifFrame

		task.delay(nDuration, function()
			if notifFrame and notifFrame.Parent then
				TweenService:Create(notifFrame, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
				task.wait(0.35)
				if notifFrame and notifFrame.Parent then
					notifFrame:Destroy()
				end
			end
		end)
	end

	------------------------------------------------
	-- 🪟 WINDOW DRAGGING & CONTROLS
	------------------------------------------------
	local dragging, dragInput, dragStart, startPos

	local function updateDrag(input)
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
			updateDrag(input)
		end
	end)

	local isMinimized = false
	minimizeButton.MouseButton1Click:Connect(function()
		isMinimized = not isMinimized
		if isMinimized then
			sidebar.Visible = false
			contentArea.Visible = false
			TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { Size = UDim2.new(mainFrame.Size.X.Scale, mainFrame.Size.X.Offset, 0, 42) }):Play()
		else
			sidebar.Visible = true
			contentArea.Visible = true
			TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { Size = windowSize }):Play()
		end
		task.delay(0.26, syncShadow)
	end)

	local isFullscreen = false
	local prevSize = windowSize
	local prevPos = mainFrame.Position
	fullscreenButton.MouseButton1Click:Connect(function()
		isFullscreen = not isFullscreen
		if isFullscreen then
			prevSize = mainFrame.Size
			prevPos = mainFrame.Position
			TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
				Size = UDim2.new(0.92, 0, 0.90, 0),
				Position = UDim2.new(0.04, 0, 0.05, 0)
			}):Play()
		else
			TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
				Size = prevSize,
				Position = prevPos
			}):Play()
		end
		task.delay(0.26, syncShadow)
	end)

	closeButton.MouseButton1Click:Connect(function()
		mainFrame.Visible = false
		shadowFrame.Visible = false
	end)

	------------------------------------------------
	-- 📑 TAB MANAGEMENT
	------------------------------------------------
	local tabs = {}
	local activeTabName = nil
	local firstTabName = nil

	local function selectTab(tabName)
		for name, data in pairs(tabs) do
			if name == tabName then
				data.Frame.Visible = true
				if data.Button then
					TweenService:Create(data.Button, TweenInfo.new(0.2), {
						BackgroundColor3 = COLORS.glassActive,
						BackgroundTransparency = 0.2
					}):Play()
					data.Button.TextColor3 = COLORS.textWhite
				end
				if data.Indicator then
					data.Indicator.Visible = true
					TweenService:Create(data.Indicator, TweenInfo.new(0.2), { BackgroundTransparency = 0 }):Play()
				end
			else
				data.Frame.Visible = false
				if data.Button then
					TweenService:Create(data.Button, TweenInfo.new(0.2), {
						BackgroundColor3 = COLORS.glassSurface,
						BackgroundTransparency = 1
					}):Play()
					data.Button.TextColor3 = COLORS.textSecondary
				end
				if data.Indicator then
					TweenService:Create(data.Indicator, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
					task.delay(0.2, function()
						if activeTabName ~= name and data.Indicator then
							data.Indicator.Visible = false
						end
					end)
				end
			end
		end
		activeTabName = tabName
	end

	------------------------------------------------
	-- 📦 COMPONENT CREATORS (TOGGLE, SLIDER, DROPDOWN, ETC.)
	------------------------------------------------
	local function createSectionCard(parent, groupTitle)
		local header = Instance.new("TextButton")
		header.Size = UDim2.new(1, 0, 0, 36)
		header.BackgroundColor3 = COLORS.glassSurface
		header.BackgroundTransparency = 0.15
		header.BorderSizePixel = 0
		header.Text = ""
		header.Parent = parent

		local hCorner = Instance.new("UICorner")
		hCorner.CornerRadius = CORNER.small
		hCorner.Parent = header

		local hStroke = Instance.new("UIStroke")
		hStroke.Color = COLORS.borderGlass
		hStroke.Thickness = 1
		hStroke.Transparency = 0.7
		hStroke.Parent = header

		local accentBar = Instance.new("Frame")
		accentBar.Size = UDim2.new(0, 3, 0, 18)
		accentBar.Position = UDim2.new(0, 8, 0.5, -9)
		accentBar.BackgroundColor3 = COLORS.accentCyan
		accentBar.BorderSizePixel = 0
		accentBar.Parent = header

		local accentCorner = Instance.new("UICorner")
		accentCorner.CornerRadius = UDim.new(0, 2)
		accentCorner.Parent = accentBar

		local hTitle = Instance.new("TextLabel")
		hTitle.Size = UDim2.new(1, -50, 1, 0)
		hTitle.Position = UDim2.new(0, 20, 0, 0)
		hTitle.BackgroundTransparency = 1
		hTitle.Text = groupTitle or "Group"
		hTitle.TextColor3 = COLORS.textWhite
		hTitle.Font = Enum.Font.GothamBold
		hTitle.TextSize = 13
		hTitle.TextXAlignment = Enum.TextXAlignment.Left
		hTitle.Parent = header

		local arrow = Instance.new("TextLabel")
		arrow.Size = UDim2.new(0, 24, 0, 24)
		arrow.Position = UDim2.new(1, -28, 0.5, -12)
		arrow.BackgroundTransparency = 1
		arrow.Text = "▼"
		arrow.TextColor3 = COLORS.accentCyan
		arrow.Font = Enum.Font.GothamBold
		arrow.TextSize = 10
		arrow.Parent = header

		local container = Instance.new("Frame")
		container.Size = UDim2.new(1, 0, 0, 0)
		container.BackgroundTransparency = 1
		container.ClipsDescendants = true
		container.Visible = true
		container.Parent = parent

		local content = Instance.new("Frame")
		content.Size = UDim2.new(1, 0, 0, 0)
		content.BackgroundTransparency = 1
		content.Parent = container

		applyPadding(content, 4, 4, 4, 4)
		local contentLayout = applyListLayout(content, 6)

		local isCollapsed = false

		local function updateContainerHeight()
			if not isCollapsed then
				local h = contentLayout.AbsoluteContentSize.Y + 8
				container.Size = UDim2.new(1, 0, 0, h)
			end
		end

		contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateContainerHeight)

		header.MouseButton1Click:Connect(function()
			isCollapsed = not isCollapsed
			arrow.Text = isCollapsed and "▶" or "▼"
			if isCollapsed then
				TweenService:Create(container, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { Size = UDim2.new(1, 0, 0, 0) }):Play()
				task.delay(0.2, function()
					if isCollapsed then container.Visible = false end
				end)
			else
				container.Visible = true
				local targetH = contentLayout.AbsoluteContentSize.Y + 8
				TweenService:Create(container, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { Size = UDim2.new(1, 0, 0, targetH) }):Play()
			end
		end)

		header.MouseEnter:Connect(function()
			TweenService:Create(header, TweenInfo.new(0.15), { BackgroundColor3 = COLORS.glassHover }):Play()
		end)
		header.MouseLeave:Connect(function()
			TweenService:Create(header, TweenInfo.new(0.15), { BackgroundColor3 = COLORS.glassSurface }):Play()
		end)

		return content
	end

	------------------------------------------------
	-- 🏗️ RETURNED WINDOW OBJECT
	------------------------------------------------
	local W = {}

	function W:SetToggleKey(k)
		k = k or Enum.KeyCode.RightAlt
		UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then return end
			if input.KeyCode == k then
				mainFrame.Visible = not mainFrame.Visible
				syncShadow()
			end
		end)
	end

	function W:Destroy()
		pcall(function()
			if gui and gui.Parent then
				gui:Destroy()
			end
		end)
	end
	W.Close = W.Destroy
	W.Unload = W.Destroy

	function W:Notify(o)
		pcall(showNotification, o)
	end

	function W:CreateSection(sectionOpts)
		local S = {}

		function S:AddTab(tabOpts)
			tabOpts = tabOpts or {}
			local tabName = tabOpts.Name or "Tab"
			local tabIcon = tabOpts.Icon or ""

			-- Sidebar Tab Button
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, 0, 0, 32)
			btn.BackgroundColor3 = COLORS.glassSurface
			btn.BackgroundTransparency = 1
			btn.BorderSizePixel = 0
			btn.Text = "   " .. tabName
			btn.TextColor3 = COLORS.textSecondary
			btn.Font = Enum.Font.GothamMedium
			btn.TextSize = 11
			btn.TextXAlignment = Enum.TextXAlignment.Left
			btn.ZIndex = 4
			btn.Parent = tabScroll

			applyGlass(btn, { corner = CORNER.small })

			local indicator = Instance.new("Frame")
			indicator.Size = UDim2.new(0, 3, 0, 16)
			indicator.Position = UDim2.new(0, 2, 0.5, -8)
			indicator.BackgroundColor3 = COLORS.accentCyan
			indicator.BackgroundTransparency = 1
			indicator.BorderSizePixel = 0
			indicator.Visible = false
			indicator.ZIndex = 5
			indicator.Parent = btn

			local indicatorCorner = Instance.new("UICorner")
			indicatorCorner.CornerRadius = UDim.new(0, 2)
			indicatorCorner.Parent = indicator

			-- Tab Content ScrollingFrame
			local tabFrame = Instance.new("ScrollingFrame")
			tabFrame.Size = UDim2.new(1, 0, 1, 0)
			tabFrame.BackgroundTransparency = 1
			tabFrame.BorderSizePixel = 0
			tabFrame.ScrollBarThickness = 3
			tabFrame.ScrollBarImageColor3 = COLORS.accentCyan
			tabFrame.ScrollBarImageTransparency = 0.4
			tabFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
			tabFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
			tabFrame.Visible = false
			tabFrame.ZIndex = 3
			tabFrame.Parent = contentArea

			applyPadding(tabFrame, 14, 14, 14, 14)
			applyListLayout(tabFrame, 10)

			tabs[tabName] = {
				Frame = tabFrame,
				Button = btn,
				Indicator = indicator
			}

			btn.MouseButton1Click:Connect(function()
				selectTab(tabName)
			end)

			btn.MouseEnter:Connect(function()
				if activeTabName ~= tabName then
					TweenService:Create(btn, TweenInfo.new(0.15), {
						BackgroundColor3 = COLORS.glassHover,
						BackgroundTransparency = 0.5
					}):Play()
				end
			end)
			btn.MouseLeave:Connect(function()
				if activeTabName ~= tabName then
					TweenService:Create(btn, TweenInfo.new(0.15), {
						BackgroundColor3 = COLORS.glassSurface,
						BackgroundTransparency = 1
					}):Play()
				end
			end)

			if not firstTabName then
				firstTabName = tabName
				task.defer(function()
					selectTab(firstTabName)
				end)
			end

			-- Tab Object
			local TB = {}

			function TB:AddGroup(groupOpts)
				groupOpts = groupOpts or {}
				local groupName = groupOpts.Name or "Group"
				local groupContent = createSectionCard(tabFrame, groupName)

				local G = {}

				-- AddToggle
				function G:AddToggle(c)
					c = c or {}
					local labelText = c.Name or c.Title or "Toggle"
					local defaultValue = c.Default and true or false
					local callback = c.Callback

					local card = Instance.new("Frame")
					card.Size = UDim2.new(1, 0, 0, 34)
					card.BackgroundColor3 = COLORS.glassCard
					card.BackgroundTransparency = TRANSPARENCY.glassCard
					card.BorderSizePixel = 0
					card.ZIndex = 3
					card.Parent = groupContent

					applyGlass(card, {
						corner = CORNER.small,
						stroke = true,
						strokeColor = COLORS.borderGlass,
						strokeThickness = 1,
						strokeTransparency = 0.75
					})

					local title = Instance.new("TextLabel")
					title.Size = UDim2.new(1, -60, 1, 0)
					title.Position = UDim2.new(0, 10, 0, 0)
					title.BackgroundTransparency = 1
					title.Text = labelText
					title.TextColor3 = COLORS.textPrimary
					title.Font = Enum.Font.GothamMedium
					title.TextSize = 11
					title.TextXAlignment = Enum.TextXAlignment.Left
					title.TextTruncate = Enum.TextTruncate.AtEnd
					title.ZIndex = 4
					title.Parent = card

					local track = Instance.new("TextButton")
					track.Size = UDim2.new(0, 36, 0, 18)
					track.Position = UDim2.new(1, -46, 0.5, -9)
					track.BackgroundColor3 = defaultValue and COLORS.toggleOn or COLORS.toggleOff
					track.BorderSizePixel = 0
					track.Text = ""
					track.ZIndex = 4
					track.Parent = card

					local trackCorner = Instance.new("UICorner")
					trackCorner.CornerRadius = CORNER.pill
					trackCorner.Parent = track

					local thumb = Instance.new("Frame")
					thumb.Size = UDim2.new(0, 14, 0, 14)
					thumb.Position = defaultValue and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
					thumb.BackgroundColor3 = COLORS.textWhite
					thumb.BorderSizePixel = 0
					thumb.ZIndex = 5
					thumb.Parent = track

					local thumbCorner = Instance.new("UICorner")
					thumbCorner.CornerRadius = CORNER.pill
					thumbCorner.Parent = thumb

					local state = defaultValue

					local function setState(newState, skipCallback)
						state = newState
						local targetColor = state and COLORS.toggleOn or COLORS.toggleOff
						local targetPos = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)

						TweenService:Create(track, TweenInfo.new(0.2), { BackgroundColor3 = targetColor }):Play()
						TweenService:Create(thumb, TweenInfo.new(0.2), { Position = targetPos }):Play()

						if not skipCallback and callback then
							task.spawn(callback, state)
						end
					end

					track.MouseButton1Click:Connect(function()
						setState(not state)
					end)

					local clickOverlay = Instance.new("TextButton")
					clickOverlay.Size = UDim2.new(1, -50, 1, 0)
					clickOverlay.BackgroundTransparency = 1
					clickOverlay.Text = ""
					clickOverlay.ZIndex = 4
					clickOverlay.Parent = card
					clickOverlay.MouseButton1Click:Connect(function()
						setState(not state)
					end)

					return {
						Frame = card,
						Set = setState,
						Get = function() return state end
					}
				end

				-- AddSlider
				function G:AddSlider(c)
					c = c or {}
					local labelText = c.Name or c.Title or "Slider"
					local minVal = tonumber(c.Min) or 0
					local maxVal = tonumber(c.Max) or 100
					local increment = tonumber(c.Increment) or 1
					local defaultVal = tonumber(c.Default) or minVal
					local callback = c.Callback

					local card = Instance.new("Frame")
					card.Size = UDim2.new(1, 0, 0, 44)
					card.BackgroundColor3 = COLORS.glassCard
					card.BackgroundTransparency = TRANSPARENCY.glassCard
					card.BorderSizePixel = 0
					card.ZIndex = 3
					card.Parent = groupContent

					applyGlass(card, {
						corner = CORNER.small,
						stroke = true,
						strokeColor = COLORS.borderGlass,
						strokeThickness = 1,
						strokeTransparency = 0.75
					})

					local title = Instance.new("TextLabel")
					title.Size = UDim2.new(1, -70, 0, 20)
					title.Position = UDim2.new(0, 10, 0, 4)
					title.BackgroundTransparency = 1
					title.Text = labelText
					title.TextColor3 = COLORS.textPrimary
					title.Font = Enum.Font.GothamMedium
					title.TextSize = 11
					title.TextXAlignment = Enum.TextXAlignment.Left
					title.TextTruncate = Enum.TextTruncate.AtEnd
					title.ZIndex = 4
					title.Parent = card

					local valLabel = Instance.new("TextLabel")
					valLabel.Size = UDim2.new(0, 60, 0, 20)
					valLabel.Position = UDim2.new(1, -70, 0, 4)
					valLabel.BackgroundTransparency = 1
					valLabel.Text = tostring(defaultVal)
					valLabel.TextColor3 = COLORS.accentCyan
					valLabel.Font = Enum.Font.GothamBold
					valLabel.TextSize = 11
					valLabel.TextXAlignment = Enum.TextXAlignment.Right
					valLabel.ZIndex = 4
					valLabel.Parent = card

					local barBg = Instance.new("TextButton")
					barBg.Size = UDim2.new(1, -20, 0, 8)
					barBg.Position = UDim2.new(0, 10, 0, 28)
					barBg.BackgroundColor3 = Color3.fromRGB(24, 28, 48)
					barBg.BorderSizePixel = 0
					barBg.Text = ""
					barBg.ZIndex = 4
					barBg.Parent = card

					local barCorner = Instance.new("UICorner")
					barCorner.CornerRadius = CORNER.pill
					barCorner.Parent = barBg

					local fill = Instance.new("Frame")
					local initPct = math.clamp((defaultVal - minVal) / math.max(maxVal - minVal, 1), 0, 1)
					fill.Size = UDim2.new(initPct, 0, 1, 0)
					fill.BackgroundColor3 = COLORS.accentCyan
					fill.BorderSizePixel = 0
					fill.ZIndex = 5
					fill.Parent = barBg

					local fillCorner = Instance.new("UICorner")
					fillCorner.CornerRadius = CORNER.pill
					fillCorner.Parent = fill

					local fillGrad = Instance.new("UIGradient")
					fillGrad.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, COLORS.accentCyan),
						ColorSequenceKeypoint.new(1, COLORS.accentViolet)
					})
					fillGrad.Parent = fill

					local currentVal = defaultVal
					local sliding = false

					local function updateSlider(input)
						local absPos = barBg.AbsolutePosition.X
						local absSize = barBg.AbsoluteSize.X
						local relX = math.clamp((input.Position.X - absPos) / absSize, 0, 1)
						local rawVal = minVal + (maxVal - minVal) * relX
						local steppedVal = math.floor((rawVal - minVal) / increment + 0.5) * increment + minVal
						steppedVal = math.clamp(steppedVal, minVal, maxVal)

						if steppedVal ~= currentVal then
							currentVal = steppedVal
							fill.Size = UDim2.new((steppedVal - minVal) / math.max(maxVal - minVal, 1), 0, 1, 0)
							valLabel.Text = tostring(steppedVal)
							if callback then
								task.spawn(callback, steppedVal)
							end
						end
					end

					barBg.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
							sliding = true
							updateSlider(input)
						end
					end)

					UserInputService.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
							sliding = false
						end
					end)

					UserInputService.InputChanged:Connect(function(input)
						if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
							updateSlider(input)
						end
					end)

					return {
						Frame = card,
						Set = function(val)
							val = math.clamp(tonumber(val) or minVal, minVal, maxVal)
							currentVal = val
							fill.Size = UDim2.new((val - minVal) / math.max(maxVal - minVal, 1), 0, 1, 0)
							valLabel.Text = tostring(val)
							if callback then task.spawn(callback, val) end
						end,
						Get = function() return currentVal end
					}
				end

				-- AddDropdown
				function G:AddDropdown(c)
					c = c or {}
					local labelText = c.Name or c.Title or "Dropdown"
					local options = c.Options or {}
					local defaultVal = c.Default
					local callback = c.Callback

					local card = Instance.new("Frame")
					card.Size = UDim2.new(1, 0, 0, 34)
					card.BackgroundColor3 = COLORS.glassCard
					card.BackgroundTransparency = TRANSPARENCY.glassCard
					card.BorderSizePixel = 0
					card.ClipsDescendants = true
					card.ZIndex = 3
					card.Parent = groupContent

					applyGlass(card, {
						corner = CORNER.small,
						stroke = true,
						strokeColor = COLORS.borderGlass,
						strokeThickness = 1,
						strokeTransparency = 0.75
					})

					local title = Instance.new("TextLabel")
					title.Size = UDim2.new(0.46, 0, 0, 34)
					title.Position = UDim2.new(0, 10, 0, 0)
					title.BackgroundTransparency = 1
					title.Text = labelText
					title.TextColor3 = COLORS.textPrimary
					title.Font = Enum.Font.GothamMedium
					title.TextSize = 11
					title.TextXAlignment = Enum.TextXAlignment.Left
					title.TextTruncate = Enum.TextTruncate.AtEnd
					title.ZIndex = 4
					title.Parent = card

					local selectBtn = Instance.new("TextButton")
					selectBtn.Size = UDim2.new(0.50, 0, 0, 24)
					selectBtn.Position = UDim2.new(0.48, 0, 0, 5)
					selectBtn.BackgroundColor3 = Color3.fromRGB(24, 28, 48)
					selectBtn.BorderSizePixel = 0
					selectBtn.TextColor3 = COLORS.accentCyan
					selectBtn.Font = Enum.Font.GothamBold
					selectBtn.TextSize = 10
					selectBtn.TextTruncate = Enum.TextTruncate.AtEnd
					selectBtn.ZIndex = 4
					selectBtn.Parent = card

					applyGlass(selectBtn, { corner = CORNER.small })

					local optScroll = Instance.new("ScrollingFrame")
					optScroll.Size = UDim2.new(1, -20, 0, 120)
					optScroll.Position = UDim2.new(0, 10, 0, 38)
					optScroll.BackgroundTransparency = 1
					optScroll.BorderSizePixel = 0
					optScroll.ScrollBarThickness = 2
					optScroll.ScrollBarImageColor3 = COLORS.accentCyan
					optScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
					optScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
					optScroll.ZIndex = 5
					optScroll.Parent = card

					applyListLayout(optScroll, 3)

					local selected = defaultVal or (options[1] or "Select...")
					selectBtn.Text = tostring(selected) .. "  ▼"

					local isOpen = false

					local function refreshOptions(newOptions)
						options = newOptions or {}
						for _, child in ipairs(optScroll:GetChildren()) do
							if child:IsA("TextButton") then
								child:Destroy()
							end
						end

						for _, opt in ipairs(options) do
							local itemBtn = Instance.new("TextButton")
							itemBtn.Size = UDim2.new(1, -4, 0, 22)
							itemBtn.BackgroundColor3 = (opt == selected) and COLORS.glassActive or COLORS.glassHover
							itemBtn.BackgroundTransparency = 0.3
							itemBtn.BorderSizePixel = 0
							itemBtn.Text = "  " .. tostring(opt)
							itemBtn.TextColor3 = (opt == selected) and COLORS.accentCyan or COLORS.textSecondary
							itemBtn.Font = Enum.Font.GothamMedium
							itemBtn.TextSize = 10
							itemBtn.TextXAlignment = Enum.TextXAlignment.Left
							itemBtn.ZIndex = 6
							itemBtn.Parent = optScroll

							applyGlass(itemBtn, { corner = CORNER.small })

							itemBtn.MouseButton1Click:Connect(function()
								selected = opt
								selectBtn.Text = tostring(selected) .. "  ▼"
								isOpen = false
								TweenService:Create(card, TweenInfo.new(0.2), { Size = UDim2.new(1, 0, 0, 34) }):Play()
								if callback then
									task.spawn(callback, selected)
								end
							end)
						end
					end

					refreshOptions(options)

					selectBtn.MouseButton1Click:Connect(function()
						isOpen = not isOpen
						local targetH = isOpen and (42 + math.min(#options * 25 + 8, 140)) or 34
						selectBtn.Text = tostring(selected) .. (isOpen and "  ▲" or "  ▼")
						TweenService:Create(card, TweenInfo.new(0.2), { Size = UDim2.new(1, 0, 0, targetH) }):Play()
					end)

					local dropdownHandle = {
						Frame = card,
						Set = function(val)
							selected = val
							selectBtn.Text = tostring(val) .. "  ▼"
							if callback then task.spawn(callback, val) end
						end,
						Get = function() return selected end,
						Refresh = refreshOptions
					}

					-- AutoRefresh support if OptionsProvider is given
					if c.OptionsProvider and c.AutoRefresh then
						local interval = tonumber(c.RefreshInterval) or 2
						task.spawn(function()
							local lastSig = ""
							while gui and gui.Parent do
								task.wait(interval)
								local ok, res = pcall(c.OptionsProvider)
								if ok and type(res) == "table" then
									local sig = table.concat(res, "\1")
									if sig ~= lastSig then
										lastSig = sig
										refreshOptions(res)
									end
								end
							end
						end)
					end

					return dropdownHandle
				end

				-- AddButton
				function G:AddButton(c)
					c = c or {}
					local labelText = c.Name or c.Title or "Button"
					local callback = c.Callback

					local btn = Instance.new("TextButton")
					btn.Size = UDim2.new(1, 0, 0, 32)
					btn.BackgroundColor3 = COLORS.glassCard
					btn.BackgroundTransparency = TRANSPARENCY.glassCard
					btn.BorderSizePixel = 0
					btn.Text = labelText
					btn.TextColor3 = COLORS.textWhite
					btn.Font = Enum.Font.GothamBold
					btn.TextSize = 11
					btn.ZIndex = 4
					btn.Parent = groupContent

					applyGlass(btn, {
						corner = CORNER.small,
						stroke = true,
						strokeColor = COLORS.accentCyan,
						strokeThickness = 1,
						strokeTransparency = 0.6
					})

					btn.MouseEnter:Connect(function()
						TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = COLORS.glassHover }):Play()
					end)
					btn.MouseLeave:Connect(function()
						TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = COLORS.glassCard }):Play()
					end)

					btn.MouseButton1Click:Connect(function()
						TweenService:Create(btn, TweenInfo.new(0.08), { TextSize = 9 }):Play()
						task.delay(0.08, function()
							TweenService:Create(btn, TweenInfo.new(0.08), { TextSize = 11 }):Play()
						end)
						if callback then
							task.spawn(callback)
						end
					end)

					return btn
				end

				-- AddLabel / AddParagraph
				function G:AddLabel(c)
					c = c or {}
					local labelText = tostring(c.Text or c.Name or c.Title or "")

					local lbl = Instance.new("TextLabel")
					lbl.Size = UDim2.new(1, 0, 0, 24)
					lbl.BackgroundTransparency = 1
					lbl.Text = labelText
					lbl.TextColor3 = COLORS.textSecondary
					lbl.Font = Enum.Font.Gotham
					lbl.TextSize = 11
					lbl.TextXAlignment = Enum.TextXAlignment.Left
					lbl.TextWrapped = true
					lbl.ZIndex = 4
					lbl.Parent = groupContent

					-- Dynamic resize for multiline text
					local function adjustHeight()
						if lbl.TextFits then return end
						lbl.Size = UDim2.new(1, 0, 0, 36)
					end
					adjustHeight()

					local state = { Text = labelText }

					return setmetatable({}, {
						__index = function(_, k)
							if k == "Parent" then return lbl.Parent or true end
							if k == "Text" then return lbl.Text end
							return state[k]
						end,
						__newindex = function(_, k, v)
							if k == "Text" then
								state.Text = tostring(v)
								pcall(function()
									lbl.Text = tostring(v)
									adjustHeight()
								end)
							else
								state[k] = v
							end
						end
					})
				end
				G.AddParagraph = G.AddLabel

				-- AddDivider
				function G:AddDivider()
					local div = Instance.new("Frame")
					div.Size = UDim2.new(1, 0, 0, 1)
					div.BackgroundColor3 = COLORS.borderGlass
					div.BackgroundTransparency = 0.7
					div.BorderSizePixel = 0
					div.ZIndex = 3
					div.Parent = groupContent
					return div
				end

				return G
			end

			return TB
		end

		return S
	end

	syncShadow()
	return W
end

------------------------------------------------
-- 📤 EXPORT TO GLOBAL ENVIRONMENTS
------------------------------------------------
local env = (getgenv and getgenv()) or _G
env.FlowLibrary = FlowLibrary
_G.FlowLibrary = FlowLibrary
if shared then shared.FlowLibrary = FlowLibrary end

env.HipHubUI = {
	FlowLibrary = FlowLibrary,
	COLORS = COLORS,
	TRANSPARENCY = TRANSPARENCY,
	CORNER = CORNER,
}
_G.HipHubUI = env.HipHubUI
