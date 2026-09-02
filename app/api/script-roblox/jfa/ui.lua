-- ==============================================================================
-- 🐾 HipHub UI Base Controller — Jump for Animals!
-- Theme: Liquid Glass Futuristic Glassmorphism (Cyan & Violet Accents)
-- Architecture matched exactly to HipHub standard baseui.lua
-- ==============================================================================

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Players = game:GetService("Players")
local player = Players.LocalPlayer
while not player do
	task.wait(0.5)
	player = Players.LocalPlayer
end

local success, err = pcall(function()
	local TweenService = game:GetService("TweenService")
	local UserInputService = game:GetService("UserInputService")
	local GuiService = game:GetService("GuiService")

	player:WaitForChild("PlayerGui")

	------------------------------------------------
	-- 🎨 DESIGN TOKENS (Liquid Glass Palette)
	------------------------------------------------
	local COLORS = {
		-- Glass surfaces
		glassPrimary  = Color3.fromRGB(10, 12, 24),
		glassSurface  = Color3.fromRGB(16, 20, 36),
		glassCard     = Color3.fromRGB(20, 24, 44),
		glassHover    = Color3.fromRGB(28, 34, 58),
		glassActive   = Color3.fromRGB(34, 40, 68),
		-- Accent
		accentCyan    = Color3.fromRGB(0, 200, 255),
		accentViolet  = Color3.fromRGB(140, 120, 255),
		accentBlend   = Color3.fromRGB(80, 160, 255),
		accentGlow    = Color3.fromRGB(60, 180, 255),
		accentMuted   = Color3.fromRGB(50, 60, 100),
		-- Toggle
		toggleOn      = Color3.fromRGB(0, 180, 230),
		toggleOff     = Color3.fromRGB(40, 46, 70),
		-- Text
		textPrimary   = Color3.fromRGB(225, 235, 255),
		textSecondary = Color3.fromRGB(140, 155, 185),
		textMuted     = Color3.fromRGB(90, 105, 135),
		textWhite     = Color3.fromRGB(255, 255, 255),
		-- Borders
		borderGlass   = Color3.fromRGB(50, 65, 110),
		borderGlow    = Color3.fromRGB(0, 180, 255),
		dangerRed     = Color3.fromRGB(255, 80, 80),
		-- Shadow
		shadow        = Color3.fromRGB(2, 3, 8),
	}

	local TRANSPARENCY = {
		glassMain    = 0.02,
		glassSurface = 0.05,
		glassCard    = 0.08,
		glassSidebar = 0.04,
		glassTopBar  = 0.03,
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
	-- 🧹 REMOVE OLD GUI & BLUR
	------------------------------------------------
	local oldGui = player:WaitForChild("PlayerGui"):FindFirstChild("HipHub_JFA_UI") or player.PlayerGui:FindFirstChild("HipHub")
	if oldGui then
		oldGui:Destroy()
	end
	local Lighting = game:GetService("Lighting")
	local oldBlur = Lighting:FindFirstChild("HipHubBlur")
	if oldBlur then
		oldBlur:Destroy()
	end

	------------------------------------------------
	-- 🛠️ HELPERS
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
			if opts.returnStroke then return stroke end
		end

		if opts.gradient then
			local grad = Instance.new("UIGradient")
			grad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 190, 220)),
			})
			grad.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.05),
				NumberSequenceKeypoint.new(0.5, 0.12),
				NumberSequenceKeypoint.new(1, 0.03),
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
	end

	local function applyListLayout(parent, padding, sortOrder)
		local layout = Instance.new("UIListLayout")
		layout.SortOrder = sortOrder or Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, padding or 4)
		layout.Parent = parent
		return layout
	end

	local function tween(inst, props, duration, style, dir)
		local tInfo = TweenInfo.new(duration or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
		local t = TweenService:Create(inst, tInfo, props)
		t:Play()
		return t
	end

	------------------------------------------------
	-- 🖥️ SCREEN GUI
	------------------------------------------------
	local gui = Instance.new("ScreenGui")
	gui.Name = "HipHub_JFA_UI"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 2147483647
	pcall(function() gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling end)
	gui.Parent = player:WaitForChild("PlayerGui")

	------------------------------------------------
	-- 🌑 SHADOW BACKING
	------------------------------------------------
	local shadowFrame = Instance.new("Frame")
	shadowFrame.Size = UDim2.new(0, 612, 0, 422)
	shadowFrame.Position = UDim2.new(0.5, -306, 0.5, -211)
	shadowFrame.BackgroundColor3 = COLORS.shadow
	shadowFrame.BackgroundTransparency = 0.45
	shadowFrame.BorderSizePixel = 0
	shadowFrame.ZIndex = 0
	shadowFrame.Parent = gui

	local shadowCorner = Instance.new("UICorner")
	shadowCorner.CornerRadius = UDim.new(0, 18)
	shadowCorner.Parent = shadowFrame

	------------------------------------------------
	-- 🖼️ MAIN FRAME (Glass Panel)
	------------------------------------------------
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 600, 0, 410)
	mainFrame.Position = UDim2.new(0.5, -300, 0.5, -205)
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

	local function syncShadow()
		shadowFrame.Position = UDim2.new(
			mainFrame.Position.X.Scale, mainFrame.Position.X.Offset - 6,
			mainFrame.Position.Y.Scale, mainFrame.Position.Y.Offset - 6
		)
		shadowFrame.Size = UDim2.new(
			mainFrame.Size.X.Scale, mainFrame.Size.X.Offset + 12,
			mainFrame.Size.Y.Scale, mainFrame.Size.Y.Offset + 12
		)
		shadowFrame.Visible = mainFrame.Visible
	end
	syncShadow()

	-- Animated pulsing glow border
	local mainStroke = mainFrame:FindFirstChildOfClass("UIStroke")
	if mainStroke then
		task.spawn(function()
			while mainFrame and mainFrame.Parent do
				TweenService:Create(mainStroke, TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
					Color = COLORS.accentViolet
				}):Play()
				task.wait(2.5)
				if not mainFrame or not mainFrame.Parent then break end
				TweenService:Create(mainStroke, TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
					Color = COLORS.accentCyan
				}):Play()
				task.wait(2.5)
			end
		end)
	end

	local glassHighlight = Instance.new("Frame")
	glassHighlight.Size = UDim2.new(1, 0, 0, 60)
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

	------------------------------------------------
	-- 📌 TOP BAR
	------------------------------------------------
	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.Size = UDim2.new(1, 0, 0, 42)
	topBar.BackgroundColor3 = COLORS.glassSurface
	topBar.BackgroundTransparency = TRANSPARENCY.glassTopBar
	topBar.BorderSizePixel = 0
	topBar.ZIndex = 2
	topBar.Parent = mainFrame

	applyGlass(topBar, { corner = CORNER.large })

	local topBarCover = Instance.new("Frame")
	topBarCover.Size = UDim2.new(1, 0, 0, 14)
	topBarCover.Position = UDim2.new(0, 0, 1, -14)
	topBarCover.BackgroundColor3 = COLORS.glassSurface
	topBarCover.BackgroundTransparency = TRANSPARENCY.glassTopBar
	topBarCover.BorderSizePixel = 0
	topBarCover.ZIndex = 2
	topBarCover.Parent = topBar

	local topBarAccent = Instance.new("Frame")
	topBarAccent.Size = UDim2.new(1, 0, 0, 1)
	topBarAccent.Position = UDim2.new(0, 0, 1, -1)
	topBarAccent.BackgroundColor3 = COLORS.accentCyan
	topBarAccent.BackgroundTransparency = 0.7
	topBarAccent.BorderSizePixel = 0
	topBarAccent.ZIndex = 3
	topBarAccent.Parent = topBar

	local accentGrad = Instance.new("UIGradient")
	accentGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, COLORS.accentCyan),
		ColorSequenceKeypoint.new(0.5, COLORS.accentViolet),
		ColorSequenceKeypoint.new(1, COLORS.accentCyan),
	})
	accentGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(0.3, 0.2),
		NumberSequenceKeypoint.new(0.7, 0.2),
		NumberSequenceKeypoint.new(1, 0.8),
	})
	accentGrad.Parent = topBarAccent

	local hubTitle = Instance.new("TextLabel")
	hubTitle.Name = "HubTitle"
	hubTitle.Size = UDim2.new(0, 75, 1, 0)
	hubTitle.Position = UDim2.new(0, 14, 0, 0)
	hubTitle.BackgroundTransparency = 1
	hubTitle.Text = "HipHub"
	hubTitle.TextColor3 = COLORS.textWhite
	hubTitle.Font = Enum.Font.GothamBold
	hubTitle.TextSize = 16
	hubTitle.TextXAlignment = Enum.TextXAlignment.Left
	hubTitle.ZIndex = 3
	hubTitle.Parent = topBar

	local badge = Instance.new("TextLabel")
	badge.Name = "GameBadge"
	badge.Size = UDim2.new(0, 125, 0, 22)
	badge.Position = UDim2.new(0, 92, 0.5, -11)
	badge.BackgroundColor3 = COLORS.accentViolet
	badge.BackgroundTransparency = 0.25
	badge.Text = "Jump for Animals"
	badge.TextColor3 = COLORS.textWhite
	badge.Font = Enum.Font.GothamBold
	badge.TextSize = 10
	badge.ZIndex = 3
	badge.Parent = topBar

	applyGlass(badge, {
		corner = CORNER.pill,
		stroke = true,
		strokeColor = COLORS.accentViolet,
		strokeThickness = 1,
		strokeTransparency = 0.5
	})

	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 30, 0, 30)
	closeButton.Position = UDim2.new(1, -38, 0.5, -15)
	closeButton.BackgroundTransparency = 1
	closeButton.Text = "X"
	closeButton.TextColor3 = COLORS.textSecondary
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextSize = 14
	closeButton.ZIndex = 3
	closeButton.Parent = topBar

	pcall(function()
		closeButton.MouseEnter:Connect(function()
			TweenService:Create(closeButton, TweenInfo.new(0.15), { TextColor3 = COLORS.dangerRed }):Play()
		end)
		closeButton.MouseLeave:Connect(function()
			TweenService:Create(closeButton, TweenInfo.new(0.15), { TextColor3 = COLORS.textSecondary }):Play()
		end)
	end)

	local fullscreenButton = Instance.new("TextButton")
	fullscreenButton.Name = "FullscreenButton"
	fullscreenButton.Size = UDim2.new(0, 30, 0, 30)
	fullscreenButton.Position = UDim2.new(1, -70, 0.5, -15)
	fullscreenButton.BackgroundTransparency = 1
	fullscreenButton.Text = ""
	fullscreenButton.ZIndex = 3
	fullscreenButton.Parent = topBar

	local fsIcon = Instance.new("Frame")
	fsIcon.Size = UDim2.new(0, 10, 0, 10)
	fsIcon.Position = UDim2.new(0.5, -5, 0.5, -5)
	fsIcon.BackgroundTransparency = 1
	fsIcon.BorderSizePixel = 0
	fsIcon.ZIndex = 4
	fsIcon.Parent = fullscreenButton

	local fsIconStroke = Instance.new("UIStroke")
	fsIconStroke.Color = COLORS.textSecondary
	fsIconStroke.Thickness = 1.5
	fsIconStroke.Parent = fsIcon

	local fsIcon2 = Instance.new("Frame")
	fsIcon2.Size = UDim2.new(0, 8, 0, 8)
	fsIcon2.Position = UDim2.new(0.5, -3, 0.5, -7)
	fsIcon2.BackgroundTransparency = 1
	fsIcon2.BorderSizePixel = 0
	fsIcon2.Visible = false
	fsIcon2.ZIndex = 4
	fsIcon2.Parent = fullscreenButton

	local fsIcon2Stroke = Instance.new("UIStroke")
	fsIcon2Stroke.Color = COLORS.textSecondary
	fsIcon2Stroke.Thickness = 1.5
	fsIcon2Stroke.Parent = fsIcon2

	local isFullscreenState = false
	local function updateFullscreenIcon(isFullscreen)
		isFullscreenState = isFullscreen
		if isFullscreen then
			fsIcon.Size = UDim2.new(0, 8, 0, 8)
			fsIcon.Position = UDim2.new(0.5, -6, 0.5, -2)
			fsIcon2.Visible = true
		else
			fsIcon.Size = UDim2.new(0, 10, 0, 10)
			fsIcon.Position = UDim2.new(0.5, -5, 0.5, -5)
			fsIcon2.Visible = false
		end
	end

	pcall(function()
		fullscreenButton.MouseEnter:Connect(function()
			TweenService:Create(fsIconStroke, TweenInfo.new(0.15), { Color = COLORS.accentCyan }):Play()
			TweenService:Create(fsIcon2Stroke, TweenInfo.new(0.15), { Color = COLORS.accentCyan }):Play()
		end)
		fullscreenButton.MouseLeave:Connect(function()
			TweenService:Create(fsIconStroke, TweenInfo.new(0.15), { Color = COLORS.textSecondary }):Play()
			TweenService:Create(fsIcon2Stroke, TweenInfo.new(0.15), { Color = COLORS.textSecondary }):Play()
		end)
	end)

	local minimizeButton = Instance.new("TextButton")
	minimizeButton.Name = "MinimizeButton"
	minimizeButton.Size = UDim2.new(0, 30, 0, 30)
	minimizeButton.Position = UDim2.new(1, -102, 0.5, -15)
	minimizeButton.BackgroundTransparency = 1
	minimizeButton.Text = "-"
	minimizeButton.TextColor3 = COLORS.textSecondary
	minimizeButton.Font = Enum.Font.GothamBold
	minimizeButton.TextSize = 16
	minimizeButton.ZIndex = 3
	minimizeButton.Parent = topBar

	pcall(function()
		minimizeButton.MouseEnter:Connect(function()
			TweenService:Create(minimizeButton, TweenInfo.new(0.15), { TextColor3 = COLORS.accentCyan }):Play()
		end)
		minimizeButton.MouseLeave:Connect(function()
			TweenService:Create(minimizeButton, TweenInfo.new(0.15), { TextColor3 = COLORS.textSecondary }):Play()
		end)
	end)

	------------------------------------------------
	-- 📂 SIDEBAR (Glass Panel)
	------------------------------------------------
	local sidebar = Instance.new("Frame")
	sidebar.Name = "Sidebar"
	sidebar.Size = UDim2.new(0, 150, 1, -42)
	sidebar.Position = UDim2.new(0, 0, 0, 42)
	sidebar.BackgroundColor3 = COLORS.glassSurface
	sidebar.BackgroundTransparency = TRANSPARENCY.glassSidebar
	sidebar.BorderSizePixel = 0
	sidebar.ZIndex = 1
	sidebar.Parent = mainFrame

	applyGlass(sidebar, { corner = CORNER.large })

	local sidebarCover = Instance.new("Frame")
	sidebarCover.Size = UDim2.new(0, 14, 1, 0)
	sidebarCover.Position = UDim2.new(1, -14, 0, 0)
	sidebarCover.BackgroundColor3 = COLORS.glassSurface
	sidebarCover.BackgroundTransparency = TRANSPARENCY.glassSidebar
	sidebarCover.BorderSizePixel = 0
	sidebarCover.ZIndex = 1
	sidebarCover.Parent = sidebar

	local sidebarGlow = Instance.new("Frame")
	sidebarGlow.Size = UDim2.new(0, 1, 1, -20)
	sidebarGlow.Position = UDim2.new(1, -1, 0, 10)
	sidebarGlow.BackgroundColor3 = COLORS.accentCyan
	sidebarGlow.BackgroundTransparency = 0.78
	sidebarGlow.BorderSizePixel = 0
	sidebarGlow.ZIndex = 2
	sidebarGlow.Parent = sidebar

	local sidebarGlowGrad = Instance.new("UIGradient")
	sidebarGlowGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0.5),
		NumberSequenceKeypoint.new(0.8, 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	sidebarGlowGrad.Rotation = 90
	sidebarGlowGrad.Parent = sidebarGlow

	local tabContainer = Instance.new("Frame")
	tabContainer.Name = "TabContainer"
	tabContainer.Size = UDim2.new(1, 0, 1, -60)
	tabContainer.BackgroundTransparency = 1
	tabContainer.ZIndex = 2
	tabContainer.Parent = sidebar

	applyListLayout(tabContainer, 3)
	applyPadding(tabContainer, 8, 8, 12, 0)

	-- 👤 USER PROFILE CARD (PINNED AT BOTTOM LEFT)
	local profileCard = Instance.new("Frame")
	profileCard.Name = "UserProfile"
	profileCard.Size = UDim2.new(1, -16, 0, 44)
	profileCard.Position = UDim2.new(0, 8, 1, -52)
	profileCard.BackgroundColor3 = COLORS.glassCard
	profileCard.BackgroundTransparency = TRANSPARENCY.glassCard
	profileCard.BorderSizePixel = 0
	profileCard.ZIndex = 2
	profileCard.Parent = sidebar

	applyGlass(profileCard, {
		corner = CORNER.small,
		stroke = true,
		strokeColor = COLORS.borderGlass,
		strokeThickness = 1,
		strokeTransparency = 0.7
	})

	local avatarLabel = Instance.new("ImageLabel")
	avatarLabel.Name = "AvatarLabel"
	avatarLabel.Size = UDim2.new(0, 28, 0, 28)
	avatarLabel.Position = UDim2.new(0, 8, 0.5, -14)
	avatarLabel.BackgroundColor3 = COLORS.glassHover
	avatarLabel.BorderSizePixel = 0
	avatarLabel.ZIndex = 3
	avatarLabel.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(player.UserId) .. "&w=150&h=150"
	avatarLabel.Parent = profileCard

	local avatarCorner = Instance.new("UICorner")
	avatarCorner.CornerRadius = CORNER.pill
	avatarCorner.Parent = avatarLabel

	local avatarStroke = Instance.new("UIStroke")
	avatarStroke.Color = COLORS.accentCyan
	avatarStroke.Thickness = 1
	avatarStroke.Transparency = 0.5
	avatarStroke.Parent = avatarLabel

	task.spawn(function()
		pcall(function()
			local content, isReady = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
			if isReady and content then
				avatarLabel.Image = content
			end
		end)
	end)

	local usernameLabel = Instance.new("TextLabel")
	usernameLabel.Name = "UsernameLabel"
	usernameLabel.Size = UDim2.new(1, -48, 1, 0)
	usernameLabel.Position = UDim2.new(0, 42, 0, 0)
	usernameLabel.BackgroundTransparency = 1
	usernameLabel.Text = player.DisplayName or player.Name
	usernameLabel.TextColor3 = COLORS.textPrimary
	usernameLabel.Font = Enum.Font.GothamMedium
	usernameLabel.TextSize = 11
	usernameLabel.TextXAlignment = Enum.TextXAlignment.Left
	usernameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	usernameLabel.ZIndex = 3
	usernameLabel.Parent = profileCard

	------------------------------------------------
	-- 🖥️ CONTENT AREA
	------------------------------------------------
	local contentArea = Instance.new("Frame")
	contentArea.Name = "ContentArea"
	contentArea.Size = UDim2.new(1, -150, 1, -42)
	contentArea.Position = UDim2.new(0, 150, 0, 42)
	contentArea.BackgroundTransparency = 1
	contentArea.ZIndex = 1
	contentArea.Parent = mainFrame

	------------------------------------------------
	-- 📑 TAB SYSTEM
	------------------------------------------------
	local tabs = {}
	local activeTab = nil
	local tabButtons = {}

	local function createTabContent(name)
		local frame = Instance.new("ScrollingFrame")
		frame.Name = "Tab_" .. name
		frame.Size = UDim2.new(1, 0, 1, 0)
		frame.BackgroundTransparency = 1
		frame.BorderSizePixel = 0
		pcall(function()
			frame.ScrollBarThickness = 3
			frame.ScrollBarImageColor3 = COLORS.accentCyan
			frame.ScrollBarImageTransparency = 0.4
		end)
		frame.CanvasSize = UDim2.new(0, 0, 0, 0)
		frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
		frame.ClipsDescendants = true
		frame.Visible = false
		frame.ZIndex = 2
		frame.Parent = contentArea

		applyPadding(frame, 14, 14, 14, 14)
		applyListLayout(frame, 8)

		return frame
	end

	local function selectTab(tabName)
		for name, data in pairs(tabs) do
			if name == tabName then
				data.Frame.Visible = true
				if data.Button then
					TweenService:Create(data.Button, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
						BackgroundColor3 = COLORS.glassActive,
						BackgroundTransparency = 0.15,
					}):Play()
					pcall(function() data.Button.TextColor3 = COLORS.textWhite end)
				end
				if data.Indicator then
					data.Indicator.Visible = true
					TweenService:Create(data.Indicator, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
						BackgroundTransparency = 0,
					}):Play()
				end
			else
				data.Frame.Visible = false
				if data.Button then
					TweenService:Create(data.Button, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
						BackgroundColor3 = COLORS.glassSurface,
						BackgroundTransparency = 1,
					}):Play()
					pcall(function() data.Button.TextColor3 = COLORS.textSecondary end)
				end
				if data.Indicator then
					TweenService:Create(data.Indicator, TweenInfo.new(0.15), {
						BackgroundTransparency = 1,
					}):Play()
					task.delay(0.15, function()
						if activeTab ~= name and data.Indicator then
							data.Indicator.Visible = false
						end
					end)
				end
			end
		end
		activeTab = tabName
	end

	local function addTab(name, iconText, layoutOrder)
		local button = Instance.new("TextButton")
		button.Name = "Nav_" .. name
		button.Size = UDim2.new(1, 0, 0, 30)
		button.BackgroundColor3 = COLORS.glassSurface
		button.BackgroundTransparency = 1
		button.BorderSizePixel = 0
		button.ZIndex = 3
		button.Text = "   " .. name
		button.TextColor3 = COLORS.textSecondary
		button.Font = Enum.Font.GothamMedium
		button.TextSize = 12
		button.TextXAlignment = Enum.TextXAlignment.Left
		button.LayoutOrder = layoutOrder or 1
		button.Parent = tabContainer

		applyGlass(button, { corner = CORNER.small })

		local indicator = Instance.new("Frame")
		indicator.Name = "Indicator"
		indicator.Size = UDim2.new(0, 3, 0, 16)
		indicator.Position = UDim2.new(0, 2, 0.5, -8)
		indicator.BackgroundColor3 = COLORS.accentCyan
		indicator.BackgroundTransparency = 1
		indicator.BorderSizePixel = 0
		indicator.Visible = false
		indicator.ZIndex = 4
		indicator.Parent = button

		local indicatorCorner = Instance.new("UICorner")
		indicatorCorner.CornerRadius = UDim.new(0, 2)
		indicatorCorner.Parent = indicator

		tabButtons[name] = button

		local contentFrame = createTabContent(name)
		tabs[name] = {
			Frame = contentFrame,
			Button = button,
			Indicator = indicator,
		}

		button.MouseButton1Click:Connect(function()
			selectTab(name)
		end)

		pcall(function()
			button.MouseEnter:Connect(function()
				if activeTab ~= name then
					TweenService:Create(button, TweenInfo.new(0.15), {
						BackgroundColor3 = COLORS.glassHover,
						BackgroundTransparency = 0.5,
					}):Play()
				end
			end)
			button.MouseLeave:Connect(function()
				if activeTab ~= name then
					TweenService:Create(button, TweenInfo.new(0.15), {
						BackgroundColor3 = COLORS.glassSurface,
						BackgroundTransparency = 1,
					}):Play()
				end
			end)
		end)

		return contentFrame
	end

	------------------------------------------------
	-- 📦 COLLAPSIBLE SECTION COMPONENT
	------------------------------------------------
	local function createCollapsibleSection(parent, title, layoutOrder)
		local sectionCard = Instance.new("Frame")
		sectionCard.Name = "Section_" .. title
		sectionCard.Size = UDim2.new(1, 0, 0, 0)
		sectionCard.AutomaticSize = Enum.AutomaticSize.Y
		sectionCard.BackgroundTransparency = 1
		sectionCard.LayoutOrder = layoutOrder or 1
		sectionCard.Parent = parent

		local sectionLayout = Instance.new("UIListLayout")
		sectionLayout.SortOrder = Enum.SortOrder.LayoutOrder
		sectionLayout.Padding = UDim.new(0, 6)
		sectionLayout.Parent = sectionCard

		local header = Instance.new("TextButton")
		header.Name = "Header"
		header.Size = UDim2.new(1, 0, 0, 34)
		header.BackgroundColor3 = Color3.fromRGB(24, 28, 52)
		header.BackgroundTransparency = 0.08
		header.BorderSizePixel = 0
		header.Text = ""
		header.LayoutOrder = 1
		header.Parent = sectionCard

		local hCorner = Instance.new("UICorner")
		hCorner.CornerRadius = UDim.new(0, 8)
		hCorner.Parent = header

		local hStroke = Instance.new("UIStroke")
		hStroke.Color = Color3.fromRGB(50, 65, 110)
		hStroke.Thickness = 1
		hStroke.Transparency = 0.55
		hStroke.Parent = header

		local accentBar = Instance.new("Frame")
		accentBar.Name = "AccentBar"
		accentBar.Size = UDim2.new(0, 3, 0, 18)
		accentBar.Position = UDim2.new(0, 6, 0.5, -9)
		accentBar.BackgroundColor3 = COLORS.accentCyan
		accentBar.BorderSizePixel = 0
		accentBar.Parent = header

		local accentCorner = Instance.new("UICorner")
		accentCorner.CornerRadius = UDim.new(0, 2)
		accentCorner.Parent = accentBar

		local hTitle = Instance.new("TextLabel")
		hTitle.Name = "headerTitle"
		hTitle.Size = UDim2.new(1, -50, 1, 0)
		hTitle.Position = UDim2.new(0, 18, 0, 0)
		hTitle.BackgroundTransparency = 1
		hTitle.Text = string.upper(title)
		hTitle.TextColor3 = COLORS.textPrimary
		hTitle.Font = Enum.Font.GothamBold
		hTitle.TextSize = 13
		hTitle.TextXAlignment = Enum.TextXAlignment.Left
		hTitle.Parent = header

		local arrow = Instance.new("TextLabel")
		arrow.Name = "Arrow"
		arrow.Size = UDim2.new(0, 24, 0, 24)
		arrow.Position = UDim2.new(1, -24, 0.5, 0)
		arrow.AnchorPoint = Vector2.new(0.5, 0.5)
		arrow.BackgroundTransparency = 1
		arrow.Text = "v"
		arrow.TextColor3 = COLORS.accentCyan
		arrow.Font = Enum.Font.GothamBold
		arrow.TextSize = 13
		arrow.TextXAlignment = Enum.TextXAlignment.Center
		arrow.TextYAlignment = Enum.TextYAlignment.Center
		arrow.Parent = header

		local container = Instance.new("Frame")
		container.Name = "Container"
		container.Size = UDim2.new(1, 0, 0, 0)
		container.AutomaticSize = Enum.AutomaticSize.Y
		container.BackgroundTransparency = 1
		container.LayoutOrder = 2
		container.ClipsDescendants = false
		container.Visible = true
		container.Parent = sectionCard

		local contentLayout = Instance.new("UIListLayout")
		contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
		contentLayout.Padding = UDim.new(0, 6)
		contentLayout.Parent = container

		pcall(function()
			header.MouseEnter:Connect(function()
				TweenService:Create(header, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(30, 36, 64) }):Play()
				TweenService:Create(accentBar, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(60, 220, 255) }):Play()
				hTitle.TextColor3 = COLORS.textWhite
			end)
			header.MouseLeave:Connect(function()
				TweenService:Create(header, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(24, 28, 52) }):Play()
				TweenService:Create(accentBar, TweenInfo.new(0.15), { BackgroundColor3 = COLORS.accentCyan }):Play()
				hTitle.TextColor3 = COLORS.textPrimary
			end)
		end)

		local isExpanded = true
		header.MouseButton1Click:Connect(function()
			isExpanded = not isExpanded
			container.Visible = isExpanded
			local targetRot = isExpanded and 0 or -90
			TweenService:Create(arrow, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Rotation = targetRot }):Play()
		end)

		return container
	end

	------------------------------------------------
	-- 🔘 GLASS TOGGLE COMPONENT
	------------------------------------------------
	local function createGlassToggle(parent, labelText, defaultState, callback, layoutOrder)
		local card = Instance.new("Frame")
		card.Name = "Toggle_" .. labelText
		card.Size = UDim2.new(1, 0, 0, 34)
		card.BackgroundColor3 = COLORS.glassCard
		card.BackgroundTransparency = TRANSPARENCY.glassCard
		card.BorderSizePixel = 0
		card.LayoutOrder = layoutOrder or 0
		card.ZIndex = 2
		card.Parent = parent

		applyGlass(card, {
			corner = CORNER.small,
			stroke = true,
			strokeColor = COLORS.borderGlass,
			strokeThickness = 1,
			strokeTransparency = 0.75
		})

		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.Size = UDim2.new(0.65, 0, 1, 0)
		title.Position = UDim2.new(0, 12, 0, 0)
		title.BackgroundTransparency = 1
		title.Text = labelText
		title.TextColor3 = COLORS.textPrimary
		title.Font = Enum.Font.GothamMedium
		title.TextSize = 12
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.ZIndex = 3
		title.Parent = card

		local track = Instance.new("TextButton")
		track.Name = "Track"
		track.Size = UDim2.new(0, 38, 0, 20)
		track.Position = UDim2.new(1, -48, 0.5, -10)
		track.BackgroundColor3 = defaultState and COLORS.toggleOn or COLORS.toggleOff
		track.BackgroundTransparency = 0.15
		track.BorderSizePixel = 0
		track.Text = ""
		track.ZIndex = 3
		track.Parent = card

		local trackCorner = Instance.new("UICorner")
		trackCorner.CornerRadius = CORNER.pill
		trackCorner.Parent = track

		local trackStroke = Instance.new("UIStroke")
		trackStroke.Color = COLORS.accentCyan
		trackStroke.Thickness = 1
		trackStroke.Transparency = defaultState and 0.3 or 0.7
		trackStroke.Parent = track

		local thumb = Instance.new("Frame")
		thumb.Name = "Thumb"
		thumb.Size = UDim2.new(0, 14, 0, 14)
		thumb.Position = defaultState and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
		thumb.BackgroundColor3 = COLORS.textWhite
		thumb.BorderSizePixel = 0
		thumb.ZIndex = 4
		thumb.Parent = track

		local thumbCorner = Instance.new("UICorner")
		thumbCorner.CornerRadius = CORNER.pill
		thumbCorner.Parent = thumb

		local fullClickBtn = Instance.new("TextButton")
		fullClickBtn.Name = "FullClick"
		fullClickBtn.Size = UDim2.new(1, 0, 1, 0)
		fullClickBtn.BackgroundTransparency = 1
		fullClickBtn.Text = ""
		fullClickBtn.ZIndex = 5
		fullClickBtn.Parent = card

		local state = defaultState or false

		local function updateToggle(newState, triggerCallback)
			state = newState
			local targetColor = state and COLORS.toggleOn or COLORS.toggleOff
			local targetThumbPos = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
			local targetStrokeTrans = state and 0.3 or 0.7

			TweenService:Create(track, TweenInfo.new(0.2), { BackgroundColor3 = targetColor }):Play()
			TweenService:Create(thumb, TweenInfo.new(0.2), { Position = targetThumbPos }):Play()
			TweenService:Create(trackStroke, TweenInfo.new(0.2), { Transparency = targetStrokeTrans }):Play()

			if triggerCallback and callback then
				task.spawn(callback, state)
			end
		end

		fullClickBtn.MouseButton1Click:Connect(function()
			updateToggle(not state, true)
		end)
		track.MouseButton1Click:Connect(function()
			updateToggle(not state, true)
		end)

		return {
			Frame = card,
			Set = function(v) updateToggle(v, false) end,
			Get = function() return state end
		}
	end

	------------------------------------------------
	-- 🔘 GLASS BUTTON COMPONENT
	------------------------------------------------
	local function createGlassButton(parent, labelText, callback, layoutOrder)
		local card = Instance.new("Frame")
		card.Name = "Button_" .. labelText
		card.Size = UDim2.new(1, 0, 0, 34)
		card.BackgroundColor3 = COLORS.glassCard
		card.BackgroundTransparency = TRANSPARENCY.glassCard
		card.BorderSizePixel = 0
		card.LayoutOrder = layoutOrder or 0
		card.ZIndex = 2
		card.Parent = parent

		applyGlass(card, {
			corner = CORNER.small,
			stroke = true,
			strokeColor = COLORS.borderGlass,
			strokeThickness = 1,
			strokeTransparency = 0.75
		})

		local button = Instance.new("TextButton")
		button.Name = "ActionBtn"
		button.Size = UDim2.new(1, -16, 0, 26)
		button.Position = UDim2.new(0, 8, 0.5, -13)
		button.BackgroundColor3 = COLORS.glassPrimary
		button.BackgroundTransparency = 0.2
		button.BorderSizePixel = 0
		button.Text = labelText or "Button"
		button.TextColor3 = COLORS.accentCyan
		button.Font = Enum.Font.GothamBold
		button.TextSize = 12
		button.ZIndex = 3
		button.Parent = card

		applyGlass(button, {
			corner = CORNER.small,
			stroke = true,
			strokeColor = COLORS.accentCyan,
			strokeThickness = 1,
			strokeTransparency = 0.55
		})

		pcall(function()
			button.MouseEnter:Connect(function()
				TweenService:Create(button, TweenInfo.new(0.15), { BackgroundTransparency = 0.05, TextColor3 = COLORS.textWhite }):Play()
			end)
			button.MouseLeave:Connect(function()
				TweenService:Create(button, TweenInfo.new(0.15), { BackgroundTransparency = 0.2, TextColor3 = COLORS.accentCyan }):Play()
			end)
		end)

		if callback then
			button.MouseButton1Click:Connect(function()
				task.spawn(callback)
			end)
		end

		return { Frame = card, Button = button }
	end

	------------------------------------------------
	-- 🎚️ GLASS SLIDER COMPONENT
	------------------------------------------------
	local function addSlider(parent, title, minVal, maxVal, defaultVal, callback, layoutOrder, unit)
		local card = Instance.new("Frame")
		card.Name = "Slider_" .. title
		card.Size = UDim2.new(1, 0, 0, 46)
		card.BackgroundColor3 = COLORS.glassCard
		card.BackgroundTransparency = TRANSPARENCY.glassCard
		card.BorderSizePixel = 0
		card.LayoutOrder = layoutOrder or 1
		card.ZIndex = 2
		card.Parent = parent

		applyGlass(card, {
			corner = CORNER.small,
			stroke = true,
			strokeColor = COLORS.borderGlass,
			strokeThickness = 1,
			strokeTransparency = 0.75
		})

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Name = "Title"
		titleLabel.Size = UDim2.new(0.65, 0, 0, 18)
		titleLabel.Position = UDim2.new(0, 12, 0, 6)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = title
		titleLabel.TextColor3 = COLORS.textPrimary
		titleLabel.Font = Enum.Font.GothamMedium
		titleLabel.TextSize = 12
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.ZIndex = 3
		titleLabel.Parent = card

		local valLabel = Instance.new("TextLabel")
		valLabel.Name = "Value"
		valLabel.Size = UDim2.new(0.35, -12, 0, 18)
		valLabel.Position = UDim2.new(0.65, 0, 0, 6)
		valLabel.BackgroundTransparency = 1
		valLabel.Text = tostring(defaultVal or minVal) .. (unit and (" " .. unit) or "")
		valLabel.TextColor3 = COLORS.accentCyan
		valLabel.Font = Enum.Font.GothamBold
		valLabel.TextSize = 11
		valLabel.TextXAlignment = Enum.TextXAlignment.Right
		valLabel.ZIndex = 3
		valLabel.Parent = card

		local track = Instance.new("Frame")
		track.Name = "Track"
		track.Size = UDim2.new(1, -24, 0, 6)
		track.Position = UDim2.new(0, 12, 1, -12)
		track.BackgroundColor3 = COLORS.glassSurface
		track.BorderSizePixel = 0
		track.ZIndex = 3
		track.Parent = card

		applyGlass(track, { corner = CORNER.pill })

		local fill = Instance.new("Frame")
		fill.Name = "Fill"
		fill.Size = UDim2.new(0, 0, 1, 0)
		fill.BackgroundColor3 = COLORS.accentCyan
		fill.BorderSizePixel = 0
		fill.ZIndex = 4
		fill.Parent = track

		applyGlass(fill, { corner = CORNER.pill })

		local thumb = Instance.new("Frame")
		thumb.Name = "Thumb"
		thumb.Size = UDim2.new(0, 12, 0, 12)
		thumb.Position = UDim2.new(0, -6, 0.5, -6)
		thumb.BackgroundColor3 = COLORS.textWhite
		thumb.BorderSizePixel = 0
		thumb.ZIndex = 5
		thumb.Parent = fill

		applyGlass(thumb, { corner = CORNER.pill })

		local clickArea = Instance.new("TextButton")
		clickArea.Name = "ClickArea"
		clickArea.Size = UDim2.new(1, 0, 0, 18)
		clickArea.Position = UDim2.new(0, 0, 0.5, -9)
		clickArea.BackgroundTransparency = 1
		clickArea.Text = ""
		clickArea.ZIndex = 6
		clickArea.Parent = track

		local val = defaultVal or minVal
		local sliding = false

		local function setVal(newVal, triggerCallback)
			newVal = math.clamp(newVal, minVal, maxVal)
			val = newVal
			local pct = (val - minVal) / (maxVal - minVal)
			fill.Size = UDim2.new(pct, 0, 1, 0)
			valLabel.Text = tostring(val) .. (unit and (" " .. unit) or "")
			if triggerCallback and callback then
				task.spawn(callback, val)
			end
		end

		local function updateFromPos(xPos)
			local trackAbsPos = track.AbsolutePosition.X
			local trackAbsSize = track.AbsoluteSize.X
			local pct = math.clamp((xPos - trackAbsPos) / trackAbsSize, 0, 1)
			local calculated = math.floor(minVal + pct * (maxVal - minVal) + 0.5)
			setVal(calculated, true)
		end

		clickArea.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				sliding = true
				updateFromPos(input.Position.X)
			end
		end)

		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				sliding = false
			end
		end)

		UserInputService.InputChanged:Connect(function(input)
			if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				updateFromPos(input.Position.X)
			end
		end)

		setVal(val, false)

		return {
			Frame = card,
			Set = function(v) setVal(v, false) end,
			Get = function() return val end
		}
	end

	------------------------------------------------
	-- 📋 MULTI-SELECT DROPDOWN COMPONENT
	------------------------------------------------
	local dropdownsList = {}
	local function closeAllDropdowns()
		for _, dd in ipairs(dropdownsList) do
			if dd.isOpen then
				dd.isOpen = false
				local m = dd.menu
				local targetWidth = m.Size.X.Offset
				local tw = TweenService:Create(m, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					BackgroundTransparency = 1,
					Size = UDim2.new(0, targetWidth > 0 and targetWidth or 230, 0, 0)
				})
				tw.Completed:Connect(function()
					if not dd.isOpen then m.Visible = false end
				end)
				tw:Play()
			end
		end
	end

	local function addMultiDropdown(parent, labelText, optionsList, initialMap, callback, layoutOrder)
		local card = Instance.new("Frame")
		card.Name = "MultiDropdown_" .. labelText
		card.Size = UDim2.new(1, 0, 0, 34)
		card.BackgroundColor3 = COLORS.glassCard
		card.BackgroundTransparency = TRANSPARENCY.glassCard
		card.BorderSizePixel = 0
		card.LayoutOrder = layoutOrder or 0
		card.ZIndex = 2
		card.Parent = parent

		applyGlass(card, {
			corner = CORNER.small,
			stroke = true,
			strokeColor = COLORS.borderGlass,
			strokeThickness = 1,
			strokeTransparency = 0.75
		})

		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.Size = UDim2.new(0.5, 0, 1, 0)
		title.Position = UDim2.new(0, 12, 0, 0)
		title.BackgroundTransparency = 1
		title.Text = labelText
		title.TextColor3 = COLORS.textSecondary
		title.Font = Enum.Font.GothamMedium
		title.TextSize = 12
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.ZIndex = 3
		title.Parent = card

		local mainBtn = Instance.new("TextButton")
		mainBtn.Name = "MainBtn"
		mainBtn.Size = UDim2.new(0, 150, 0, 24)
		mainBtn.Position = UDim2.new(1, -160, 0.5, -12)
		mainBtn.BackgroundColor3 = COLORS.glassPrimary
		mainBtn.BackgroundTransparency = 0.2
		mainBtn.BorderSizePixel = 0
		mainBtn.Text = ""
		mainBtn.ZIndex = 3
		mainBtn.Parent = card

		applyGlass(mainBtn, {
			corner = CORNER.small,
			stroke = true,
			strokeColor = COLORS.accentCyan,
			strokeThickness = 1,
			strokeTransparency = 0.55
		})

		local selText = Instance.new("TextLabel")
		selText.Name = "SelectedText"
		selText.Size = UDim2.new(1, -26, 1, 0)
		selText.Position = UDim2.new(0, 8, 0, 0)
		selText.BackgroundTransparency = 1
		selText.Text = "All Selected"
		selText.TextColor3 = COLORS.textPrimary
		selText.Font = Enum.Font.GothamMedium
		selText.TextSize = 11
		selText.TextXAlignment = Enum.TextXAlignment.Left
		selText.TextTruncate = Enum.TextTruncate.AtEnd
		selText.ZIndex = 4
		selText.Parent = mainBtn

		local arrow = Instance.new("TextLabel")
		arrow.Name = "Arrow"
		arrow.Size = UDim2.new(0, 18, 1, 0)
		arrow.Position = UDim2.new(1, -18, 0, 0)
		arrow.BackgroundTransparency = 1
		arrow.Text = "v"
		arrow.TextColor3 = COLORS.accentCyan
		arrow.Font = Enum.Font.GothamBold
		arrow.TextSize = 11
		arrow.ZIndex = 4
		arrow.Parent = mainBtn

		local fullClick = Instance.new("TextButton")
		fullClick.Name = "FullClick"
		fullClick.Size = UDim2.new(1, 0, 1, 0)
		fullClick.BackgroundTransparency = 1
		fullClick.Text = ""
		fullClick.ZIndex = 5
		fullClick.Parent = card

		-- Dropdown Menu Popout Overlay
		local menu = Instance.new("Frame")
		menu.Name = "Menu_" .. labelText
		menu.Size = UDim2.new(0, 230, 0, 0)
		menu.BackgroundColor3 = COLORS.glassSurface
		menu.BackgroundTransparency = 0.05
		menu.BorderSizePixel = 0
		menu.ClipsDescendants = true
		menu.Visible = false
		menu.ZIndex = 500
		menu.Parent = mainFrame

		applyGlass(menu, {
			corner = CORNER.medium,
			stroke = true,
			strokeColor = COLORS.accentCyan,
			strokeThickness = 1,
			strokeTransparency = 0.45,
			gradient = true,
			gradientRotation = 180
		})

		local search = Instance.new("TextBox")
		search.Name = "SearchBox"
		search.Size = UDim2.new(1, -40, 0, 26)
		search.Position = UDim2.new(0, 8, 0, 8)
		search.BackgroundColor3 = COLORS.glassPrimary
		search.BackgroundTransparency = 0.15
		search.BorderSizePixel = 0
		search.Text = ""
		search.PlaceholderText = "Search..."
		search.PlaceholderColor3 = COLORS.textMuted
		search.TextColor3 = COLORS.textWhite
		search.Font = Enum.Font.GothamMedium
		search.TextSize = 11
		search.ClearTextOnFocus = false
		search.ZIndex = 501
		search.Parent = menu

		applyGlass(search, {
			corner = CORNER.small,
			stroke = true,
			strokeColor = COLORS.borderGlass,
			strokeThickness = 1,
			strokeTransparency = 0.6
		})

		local closeBtn = Instance.new("TextButton")
		closeBtn.Name = "CloseBtn"
		closeBtn.Size = UDim2.new(0, 24, 0, 24)
		closeBtn.Position = UDim2.new(1, -28, 0, 9)
		closeBtn.BackgroundTransparency = 1
		closeBtn.Text = "✕"
		closeBtn.TextColor3 = COLORS.textMuted
		closeBtn.Font = Enum.Font.GothamBold
		closeBtn.TextSize = 12
		closeBtn.ZIndex = 502
		closeBtn.Parent = menu

		closeBtn.MouseButton1Click:Connect(function()
			closeAllDropdowns()
		end)

		local scroll = Instance.new("ScrollingFrame")
		scroll.Name = "Scroll"
		scroll.Size = UDim2.new(1, 0, 1, -42)
		scroll.Position = UDim2.new(0, 0, 0, 42)
		scroll.BackgroundTransparency = 1
		scroll.BorderSizePixel = 0
		scroll.ScrollBarThickness = 3
		scroll.ScrollBarImageColor3 = COLORS.accentCyan
		scroll.ScrollBarImageTransparency = 0.4
		scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		scroll.ZIndex = 501
		scroll.Parent = menu

		applyListLayout(scroll, 3)
		applyPadding(scroll, 8, 8, 4, 4)

		local options = optionsList or {}
		local selectedMap = {}

		if typeof(initialMap) == "table" then
			for k, v in pairs(initialMap) do
				if typeof(k) == "string" and v == true then
					selectedMap[k] = true
				elseif typeof(v) == "string" then
					selectedMap[v] = true
				end
			end
		end
		if next(selectedMap) == nil then
			selectedMap["All"] = true
		end

		local function getSummaryText()
			if selectedMap["All"] then return "All Selected" end
			local picked = {}
			for opt, isSel in pairs(selectedMap) do
				if isSel and opt ~= "All" then
					table.insert(picked, opt)
				end
			end
			if #picked == 0 then return "None" end
			if #picked == 1 then return picked[1] end
			if #picked <= 2 then return table.concat(picked, ", ") end
			return string.format("%d Selected", #picked)
		end

		local optionButtons = {}
		local optionIndicators = {}

		local function updateOptionVisuals()
			for _, opt in ipairs(options) do
				local isSel = false
				if opt == "All" then
					isSel = (selectedMap["All"] == true)
				else
					isSel = (selectedMap["All"] == true) or (selectedMap[opt] == true)
				end

				local oBtn = optionButtons[opt]
				local oInd = optionIndicators[opt]
				if oBtn and oInd then
					if isSel then
						oBtn.TextColor3 = COLORS.textWhite
						oBtn.Font = Enum.Font.GothamBold
						oBtn.BackgroundColor3 = Color3.fromRGB(32, 42, 72)
						oInd.Visible = true
					else
						oBtn.TextColor3 = COLORS.textSecondary
						oBtn.Font = Enum.Font.GothamMedium
						oBtn.BackgroundColor3 = Color3.fromRGB(16, 20, 36)
						oInd.Visible = false
					end
				end
			end
		end

		local function rebuildMenu()
			scroll:ClearAllChildren()
			table.clear(optionButtons)
			table.clear(optionIndicators)

			local layout = applyListLayout(scroll, 3)
			applyPadding(scroll, 8, 8, 4, 4)

			for i, opt in ipairs(options) do
				local optBtn = Instance.new("TextButton")
				optBtn.Name = "Opt_" .. opt
				optBtn.Size = UDim2.new(1, 0, 0, 28)
				optBtn.BackgroundColor3 = Color3.fromRGB(16, 20, 36)
				optBtn.BorderSizePixel = 0
				optBtn.Text = "     " .. opt
				optBtn.TextColor3 = COLORS.textSecondary
				optBtn.Font = Enum.Font.GothamMedium
				optBtn.TextSize = 11
				optBtn.TextXAlignment = Enum.TextXAlignment.Left
				optBtn.ZIndex = 502
				optBtn.LayoutOrder = i
				optBtn.Parent = scroll

				local optCorner = Instance.new("UICorner")
				optCorner.CornerRadius = UDim.new(0, 6)
				optCorner.Parent = optBtn

				local leftIndicator = Instance.new("Frame")
				leftIndicator.Name = "Indicator"
				leftIndicator.Size = UDim2.new(0, 3, 0, 16)
				leftIndicator.Position = UDim2.new(0, 4, 0.5, -8)
				leftIndicator.BackgroundColor3 = COLORS.accentCyan
				leftIndicator.BorderSizePixel = 0
				leftIndicator.Visible = false
				leftIndicator.ZIndex = 503
				leftIndicator.Parent = optBtn

				local leftCorner = Instance.new("UICorner")
				leftCorner.CornerRadius = UDim.new(0, 2)
				leftCorner.Parent = leftIndicator

				optionButtons[opt] = optBtn
				optionIndicators[opt] = leftIndicator

				optBtn.MouseButton1Click:Connect(function()
					if opt == "All" then
						if selectedMap["All"] then
							selectedMap = {}
						else
							selectedMap = { ["All"] = true }
						end
					else
						selectedMap["All"] = nil
						selectedMap[opt] = not selectedMap[opt]
						local any = false
						for _, v in pairs(selectedMap) do
							if v then any = true break end
						end
						if not any then selectedMap["All"] = true end
					end

					selText.Text = getSummaryText()
					updateOptionVisuals()
					if callback then
						task.spawn(callback, selectedMap)
					end
				end)
			end
		end

		local ddData = { btn = mainBtn, menu = menu, card = card, isOpen = false, openedAt = 0 }
		table.insert(dropdownsList, ddData)

		local function toggleMenu()
			local isOpen = ddData.isOpen
			closeAllDropdowns()
			if not isOpen then
				ddData.isOpen = true
				ddData.openedAt = tick()

				local mainSize = mainFrame.AbsoluteSize
				local menuWidth = 230
				local menuHeight = math.clamp(mainSize.Y - 24, 280, 370)
				local relX = mainSize.X - menuWidth - 10
				local relY = 12

				menu.Size = UDim2.new(0, menuWidth, 0, 0)
				menu.Position = UDim2.new(0, relX, 0, relY)
				menu.BackgroundTransparency = 1
				menu.Visible = true

				TweenService:Create(menu, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = UDim2.new(0, menuWidth, 0, menuHeight),
					BackgroundTransparency = 0.05
				}):Play()
			end
		end

		mainBtn.MouseButton1Click:Connect(toggleMenu)
		fullClick.MouseButton1Click:Connect(toggleMenu)

		search:GetPropertyChangedSignal("Text"):Connect(function()
			local query = search.Text:lower():gsub("%s+", "")
			for _, opt in ipairs(options) do
				local oBtn = optionButtons[opt]
				if oBtn then
					if query == "" or opt:lower():gsub("%s+", ""):find(query, 1, true) then
						oBtn.Visible = true
					else
						oBtn.Visible = false
					end
				end
			end
		end)

		rebuildMenu()
		selText.Text = getSummaryText()
		updateOptionVisuals()

		return {
			Frame = card,
			Set = function(newMap)
				selectedMap = {}
				if typeof(newMap) == "table" then
					for k, v in pairs(newMap) do
						if typeof(k) == "string" and v == true then
							selectedMap[k] = true
						elseif typeof(v) == "string" then
							selectedMap[v] = true
						end
					end
				end
				if next(selectedMap) == nil then selectedMap["All"] = true end
				selText.Text = getSummaryText()
				updateOptionVisuals()
			end,
			Get = function() return selectedMap end
		}
	end

	------------------------------------------------
	-- 📊 STAT CARD COMPONENT
	------------------------------------------------
	local function addStatCard(parent, title, initialVal, layoutOrder)
		local card = Instance.new("Frame")
		card.Name = "Stat_" .. title
		card.Size = UDim2.new(1, 0, 0, 36)
		card.BackgroundColor3 = COLORS.glassSurface
		card.BackgroundTransparency = 0.4
		card.LayoutOrder = layoutOrder or 1
		card.ZIndex = 2
		card.Parent = parent

		applyGlass(card, {
			corner = CORNER.small,
			stroke = true,
			strokeColor = COLORS.borderGlass,
			strokeTransparency = 0.8
		})

		local titleLbl = Instance.new("TextLabel")
		titleLbl.Name = "Title"
		titleLbl.Size = UDim2.new(0.5, 0, 1, 0)
		titleLbl.Position = UDim2.new(0, 10, 0, 0)
		titleLbl.BackgroundTransparency = 1
		titleLbl.Text = title
		titleLbl.TextColor3 = COLORS.textSecondary
		titleLbl.TextSize = 11
		titleLbl.Font = Enum.Font.GothamMedium
		titleLbl.TextXAlignment = Enum.TextXAlignment.Left
		titleLbl.ZIndex = 3
		titleLbl.Parent = card

		local valLbl = Instance.new("TextLabel")
		valLbl.Name = "Value"
		valLbl.Size = UDim2.new(0.5, -10, 1, 0)
		valLbl.Position = UDim2.new(0.5, 0, 0, 0)
		valLbl.BackgroundTransparency = 1
		valLbl.Text = tostring(initialVal or "-")
		valLbl.TextColor3 = COLORS.accentCyan
		valLbl.TextSize = 12
		valLbl.Font = Enum.Font.GothamBold
		valLbl.TextXAlignment = Enum.TextXAlignment.Right
		valLbl.ZIndex = 3
		valLbl.Parent = card

		return {
			Frame = card,
			Update = function(newVal)
				valLbl.Text = tostring(newVal)
			end
		}
	end

	------------------------------------------------
	-- 🖱️ WINDOW DRAGGING & RESIZING
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

	-- Minimize & Close actions
	local isMinimized = false
	minimizeButton.MouseButton1Click:Connect(function()
		isMinimized = not isMinimized
		if isMinimized then
			mainFrame.ClipsDescendants = true
			TweenService:Create(mainFrame, TweenInfo.new(0.25), { Size = UDim2.new(0, 600, 0, 42) }):Play()
			minimizeButton.Text = "+"
		else
			TweenService:Create(mainFrame, TweenInfo.new(0.25), { Size = UDim2.new(0, 600, 0, 410) }):Play()
			minimizeButton.Text = "-"
		end
		task.delay(0.26, syncShadow)
	end)

	closeButton.MouseButton1Click:Connect(function()
		mainFrame.Visible = false
		syncShadow()
	end)

	-- Interactive Resize Handle
	local resizeHandle = Instance.new("TextButton")
	resizeHandle.Name = "ResizeHandle"
	resizeHandle.Size = UDim2.new(0, 18, 0, 18)
	resizeHandle.Position = UDim2.new(1, -18, 1, -18)
	resizeHandle.BackgroundTransparency = 1
	resizeHandle.Text = "⋱"
	resizeHandle.TextColor3 = COLORS.textMuted
	resizeHandle.Font = Enum.Font.GothamBold
	resizeHandle.TextSize = 14
	resizeHandle.ZIndex = 10
	resizeHandle.Parent = mainFrame

	local resizing = false
	local resizeStartPos, resizeStartSize

	resizeHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			resizing = true
			resizeStartPos = input.Position
			resizeStartSize = mainFrame.AbsoluteSize
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					resizing = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - resizeStartPos
			local newW = math.clamp(resizeStartSize.X + delta.X, 480, 850)
			local newH = math.clamp(resizeStartSize.Y + delta.Y, 320, 600)
			mainFrame.Size = UDim2.new(0, newW, 0, newH)
			syncShadow()
		end
	end)

	-- Close dropdowns when clicking outside
	UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			local mousePos = UserInputService:GetMouseLocation()
			local inset = GuiService:GetGuiInset()
			local actualMousePos = mousePos - inset
			local function inBounds(guiObj)
				if not guiObj or not guiObj.Visible then return false end
				local pos = guiObj.AbsolutePosition
				local size = guiObj.AbsoluteSize
				return actualMousePos.X >= pos.X and actualMousePos.X <= pos.X + size.X and
					actualMousePos.Y >= pos.Y and actualMousePos.Y <= pos.Y + size.Y
			end
			local clickedInsideAny = false
			for _, dd in ipairs(dropdownsList) do
				if dd.isOpen then
					if (tick() - (dd.openedAt or 0)) < 0.25 then
						clickedInsideAny = true
					elseif inBounds(dd.menu) or inBounds(dd.btn) or (dd.card and inBounds(dd.card)) then
						clickedInsideAny = true
					end
				end
			end
			if not clickedInsideAny then
				closeAllDropdowns()
			end
		end
	end)

	------------------------------------------------
	-- 🚀 BUILD CORE TABS
	------------------------------------------------
	addTab("Training", "", 1)
	addTab("Farming", "", 2)
	addTab("Shops", "", 3)
	addTab("Defense", "", 4)
	addTab("Movement", "", 5)
	addTab("Visuals", "", 6)
	addTab("Settings", "", 7)

	selectTab("Training")

	------------------------------------------------
	-- 🌐 EXPORT GLOBAL UI INTERFACE
	------------------------------------------------
	local env = (getgenv and getgenv()) or _G
	local uiTable = {
		gui = gui,
		screenGui = gui,
		mainFrame = mainFrame,
		topBar = topBar,
		sidebar = sidebar,
		contentArea = contentArea,
		tabs = tabs,
		closeButton = closeButton,
		minimizeButton = minimizeButton,
		fullscreenButton = fullscreenButton,
		profileCard = profileCard,
		usernameLabel = usernameLabel,
		avatarLabel = avatarLabel,
		SyncShadow = syncShadow,
		Colors = COLORS,
		-- API Component Functions
		AddTab = addTab,
		CreateTab = addTab,
		AddSection = createCollapsibleSection,
		AddToggle = createGlassToggle,
		AddButton = createGlassButton,
		AddSlider = addSlider,
		AddMultiDropdown = addMultiDropdown,
		AddDropdown = addMultiDropdown,
		AddStatCard = addStatCard,
		SelectTab = selectTab,
		Tween = tween,
		UpdateFullscreenIcon = updateFullscreenIcon
	}

	env.HipHubUI = uiTable
	_G.HipHubUI = uiTable
	if shared then shared.HipHubUI = uiTable end

	print("[HipHub JFA UI] Initialized successfully with Liquid Glass futuristic architecture.")
end)

if not success then
	warn("HipHub UI Init Error: " .. tostring(err))
	local errGui = Instance.new("ScreenGui")
	errGui.Name = "HipHubError"
	errGui.ResetOnSpawn = false
	errGui.DisplayOrder = 2147483647

	pcall(function()
		errGui.Parent = player:WaitForChild("PlayerGui")

		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(0, 480, 0, 160)
		frame.Position = UDim2.new(0.5, -240, 0.5, -80)
		frame.BackgroundColor3 = Color3.fromRGB(16, 8, 8)
		frame.BackgroundTransparency = 0.1
		frame.BorderSizePixel = 0
		frame.Parent = errGui

		local errCorner = Instance.new("UICorner")
		errCorner.CornerRadius = UDim.new(0, 14)
		errCorner.Parent = frame

		local errStroke = Instance.new("UIStroke")
		errStroke.Color = Color3.fromRGB(255, 60, 60)
		errStroke.Thickness = 1
		errStroke.Transparency = 0.5
		errStroke.Parent = frame

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, -20, 0, 30)
		title.Position = UDim2.new(0, 10, 0, 10)
		title.BackgroundTransparency = 1
		title.Text = "HipHub UI Init Error"
		title.TextColor3 = Color3.fromRGB(255, 80, 80)
		title.Font = Enum.Font.GothamBold
		title.TextSize = 14
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Parent = frame

		local body = Instance.new("TextLabel")
		body.Size = UDim2.new(1, -20, 1, -50)
		body.Position = UDim2.new(0, 10, 0, 40)
		body.BackgroundTransparency = 1
		body.Text = tostring(err)
		body.TextColor3 = Color3.fromRGB(200, 180, 180)
		body.Font = Enum.Font.Gotham
		body.TextSize = 12
		body.TextWrapped = true
		body.TextXAlignment = Enum.TextXAlignment.Left
		body.TextYAlignment = Enum.TextYAlignment.Top
		body.Parent = frame
	end)
end
