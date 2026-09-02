-- ==============================================================================
-- 🐾 HipHub UI — Jump for Animals! (Ultra-Glassmorphic Component Library)
-- Theme: Cyber Emerald / Radiant Cyan Liquid Glass
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
	local RunService = game:GetService("RunService")

	player:WaitForChild("PlayerGui")

	------------------------------------------------
	-- 🎨 DESIGN TOKENS
	------------------------------------------------
	local COLORS = {
		glassPrimary   = Color3.fromRGB(8, 14, 22),
		glassSurface   = Color3.fromRGB(12, 22, 34),
		glassCard      = Color3.fromRGB(16, 28, 44),
		glassHover     = Color3.fromRGB(24, 40, 62),
		glassActive    = Color3.fromRGB(30, 52, 78),
		accentEmerald  = Color3.fromRGB(16, 185, 129), -- Nature / Animal Emerald
		accentCyan     = Color3.fromRGB(6, 182, 212),  -- Bright Cyan
		accentGold     = Color3.fromRGB(245, 158, 11), -- Golden Mutation
		accentViolet   = Color3.fromRGB(139, 92, 246), -- Rare / Mythic
		accentGlow     = Color3.fromRGB(16, 185, 129),
		accentMuted    = Color3.fromRGB(30, 60, 70),
		toggleOn       = Color3.fromRGB(16, 185, 129),
		toggleOff      = Color3.fromRGB(30, 42, 58),
		textPrimary    = Color3.fromRGB(230, 245, 255),
		textSecondary  = Color3.fromRGB(140, 170, 195),
		textMuted      = Color3.fromRGB(90, 115, 140),
		textWhite      = Color3.fromRGB(255, 255, 255),
		borderGlass    = Color3.fromRGB(35, 65, 85),
		borderGlow     = Color3.fromRGB(16, 185, 129),
		shadow         = Color3.fromRGB(2, 4, 8),
		successGreen   = Color3.fromRGB(34, 197, 94),
		warningYellow  = Color3.fromRGB(234, 179, 8),
		dangerRed      = Color3.fromRGB(239, 68, 68)
	}

	local TRANSPARENCY = {
		glassMain    = 0.04,
		glassSurface = 0.08,
		glassCard    = 0.12,
		glassSidebar = 0.06,
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
	-- 🧹 CLEANUP EXISTING INSTANCES
	------------------------------------------------
	local oldGui = player:WaitForChild("PlayerGui"):FindFirstChild("HipHub_JFA_UI") or player.PlayerGui:FindFirstChild("HipHub_UI")
	if oldGui then
		oldGui:Destroy()
	end

	------------------------------------------------
	-- 🛠️ HELPER FUNCTIONS
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
				ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 230, 220)),
			})
			grad.Rotation = opts.gradientRotation or 45
			grad.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 0.25),
			})
			grad.Parent = frame
		end
	end

	local function tween(instance, properties, duration, style, direction)
		style = style or Enum.EasingStyle.Quad
		direction = direction or Enum.EasingDirection.Out
		duration = duration or 0.25
		local t = TweenService:Create(instance, TweenInfo.new(duration, style, direction), properties)
		t:Play()
		return t
	end

	local function addHoverAnimation(btn, normalColor, hoverColor, targetProp)
		targetProp = targetProp or "BackgroundColor3"
		btn.MouseEnter:Connect(function()
			tween(btn, { [targetProp] = hoverColor }, 0.2)
		end)
		btn.MouseLeave:Connect(function()
			tween(btn, { [targetProp] = normalColor }, 0.2)
		end)
	end

	------------------------------------------------
	-- 📱 SCREEN GUI & MAIN CONTAINERS
	------------------------------------------------
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "HipHub_JFA_UI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = player.PlayerGui

	-- Outer drop shadow container
	local shadowFrame = Instance.new("Frame")
	shadowFrame.Name = "ShadowContainer"
	shadowFrame.Size = UDim2.new(0, 720, 0, 480)
	shadowFrame.Position = UDim2.new(0.5, -360, 0.5, -240)
	shadowFrame.BackgroundTransparency = 1
	shadowFrame.Parent = screenGui

	local shadowImg = Instance.new("ImageLabel")
	shadowImg.Name = "DropShadow"
	shadowImg.AnchorPoint = Vector2.new(0.5, 0.5)
	shadowImg.Position = UDim2.new(0.5, 0, 0.5, 6)
	shadowImg.Size = UDim2.new(1, 48, 1, 48)
	shadowImg.BackgroundTransparency = 1
	shadowImg.Image = "rbxassetid://6015897843"
	shadowImg.ImageColor3 = COLORS.shadow
	shadowImg.ImageTransparency = 0.2
	shadowImg.ScaleType = Enum.ScaleType.Slice
	shadowImg.SliceCenter = Rect.new(49, 49, 450, 450)
	shadowImg.Parent = shadowFrame

	-- Main Liquid Glass Frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 720, 0, 480)
	mainFrame.Position = UDim2.new(0.5, -360, 0.5, -240)
	mainFrame.BackgroundColor3 = COLORS.glassPrimary
	mainFrame.BackgroundTransparency = TRANSPARENCY.glassMain
	mainFrame.BorderSizePixel = 0
	mainFrame.ClipsDescendants = true
	mainFrame.Parent = screenGui

	applyGlass(mainFrame, { corner = CORNER.large, stroke = true, strokeColor = COLORS.borderGlass, gradient = true })

	local mainGlowStroke = Instance.new("UIStroke")
	mainGlowStroke.Name = "GlowStroke"
	mainGlowStroke.Color = COLORS.borderGlow
	mainGlowStroke.Thickness = 1.2
	mainGlowStroke.Transparency = TRANSPARENCY.borderGlow
	mainGlowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	mainGlowStroke.Parent = mainFrame

	local function syncShadow()
		shadowFrame.Position = mainFrame.Position
		shadowFrame.Size = mainFrame.Size
		shadowFrame.Visible = mainFrame.Visible
	end

	------------------------------------------------
	-- 🔝 TOP BAR
	------------------------------------------------
	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.Size = UDim2.new(1, 0, 0, 48)
	topBar.BackgroundColor3 = COLORS.glassSurface
	topBar.BackgroundTransparency = TRANSPARENCY.glassTopBar
	topBar.BorderSizePixel = 0
	topBar.Parent = mainFrame

	local topBarBottomBorder = Instance.new("Frame")
	topBarBottomBorder.Name = "BottomBorder"
	topBarBottomBorder.Size = UDim2.new(1, 0, 0, 1)
	topBarBottomBorder.Position = UDim2.new(0, 0, 1, -1)
	topBarBottomBorder.BackgroundColor3 = COLORS.borderGlass
	topBarBottomBorder.BackgroundTransparency = 0.4
	topBarBottomBorder.BorderSizePixel = 0
	topBarBottomBorder.Parent = topBar

	-- Title & Brand Icon
	local brandIcon = Instance.new("TextLabel")
	brandIcon.Name = "BrandIcon"
	brandIcon.Size = UDim2.new(0, 32, 0, 32)
	brandIcon.Position = UDim2.new(0, 12, 0.5, -16)
	brandIcon.BackgroundTransparency = 1
	brandIcon.Text = "🐾"
	brandIcon.TextSize = 22
	brandIcon.Parent = topBar

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(0, 240, 0, 24)
	titleLabel.Position = UDim2.new(0, 48, 0.5, -12)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "HIPHUB <font color='#10B981'><b>JUMP FOR ANIMALS</b></font>"
	titleLabel.RichText = true
	titleLabel.TextColor3 = COLORS.textPrimary
	titleLabel.TextSize = 15
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = topBar

	local versionTag = Instance.new("TextLabel")
	versionTag.Name = "VersionTag"
	versionTag.Size = UDim2.new(0, 60, 0, 18)
	versionTag.Position = UDim2.new(0, 268, 0.5, -9)
	versionTag.BackgroundColor3 = COLORS.glassCard
	versionTag.BackgroundTransparency = 0.2
	versionTag.Text = "v1.0.0"
	versionTag.TextColor3 = COLORS.accentEmerald
	versionTag.TextSize = 10
	versionTag.Font = Enum.Font.GothamBold
	versionTag.Parent = topBar
	applyGlass(versionTag, { corner = CORNER.small, stroke = true, strokeColor = COLORS.accentEmerald, strokeTransparency = 0.6 })

	-- Status Badge
	local statusBadge = Instance.new("Frame")
	statusBadge.Name = "StatusBadge"
	statusBadge.Size = UDim2.new(0, 105, 0, 24)
	statusBadge.Position = UDim2.new(1, -215, 0.5, -12)
	statusBadge.BackgroundColor3 = COLORS.glassCard
	statusBadge.BackgroundTransparency = 0.3
	statusBadge.Parent = topBar
	applyGlass(statusBadge, { corner = CORNER.pill, stroke = true, strokeColor = COLORS.borderGlass })

	local statusDot = Instance.new("Frame")
	statusDot.Name = "Dot"
	statusDot.Size = UDim2.new(0, 8, 0, 8)
	statusDot.Position = UDim2.new(0, 9, 0.5, -4)
	statusDot.BackgroundColor3 = COLORS.successGreen
	statusDot.BorderSizePixel = 0
	statusDot.Parent = statusBadge
	applyGlass(statusDot, { corner = CORNER.pill })

	local statusText = Instance.new("TextLabel")
	statusText.Name = "Text"
	statusText.Size = UDim2.new(1, -24, 1, 0)
	statusText.Position = UDim2.new(0, 22, 0, 0)
	statusText.BackgroundTransparency = 1
	statusText.Text = "ACTIVE"
	statusText.TextColor3 = COLORS.textSecondary
	statusText.TextSize = 11
	statusText.Font = Enum.Font.GothamBold
	statusText.TextXAlignment = Enum.TextXAlignment.Left
	statusText.Parent = statusBadge

	-- Window Control Buttons
	local minimizeButton = Instance.new("TextButton")
	minimizeButton.Name = "MinimizeButton"
	minimizeButton.Size = UDim2.new(0, 30, 0, 30)
	minimizeButton.Position = UDim2.new(1, -74, 0.5, -15)
	minimizeButton.BackgroundColor3 = COLORS.glassCard
	minimizeButton.BackgroundTransparency = 0.4
	minimizeButton.Text = "—"
	minimizeButton.TextColor3 = COLORS.textSecondary
	minimizeButton.TextSize = 13
	minimizeButton.Font = Enum.Font.GothamBold
	minimizeButton.Parent = topBar
	applyGlass(minimizeButton, { corner = CORNER.small, stroke = true, strokeColor = COLORS.borderGlass })
	addHoverAnimation(minimizeButton, COLORS.glassCard, COLORS.glassHover)

	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 30, 0, 30)
	closeButton.Position = UDim2.new(1, -38, 0.5, -15)
	closeButton.BackgroundColor3 = COLORS.glassCard
	closeButton.BackgroundTransparency = 0.4
	closeButton.Text = "✕"
	closeButton.TextColor3 = COLORS.dangerRed
	closeButton.TextSize = 13
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = topBar
	applyGlass(closeButton, { corner = CORNER.small, stroke = true, strokeColor = COLORS.dangerRed, strokeTransparency = 0.6 })
	addHoverAnimation(closeButton, COLORS.glassCard, Color3.fromRGB(60, 20, 25))

	------------------------------------------------
	-- 📑 SIDEBAR (NAVIGATION)
	------------------------------------------------
	local sidebar = Instance.new("Frame")
	sidebar.Name = "Sidebar"
	sidebar.Size = UDim2.new(0, 175, 1, -48)
	sidebar.Position = UDim2.new(0, 0, 0, 48)
	sidebar.BackgroundColor3 = COLORS.glassSurface
	sidebar.BackgroundTransparency = TRANSPARENCY.glassSidebar
	sidebar.BorderSizePixel = 0
	sidebar.Parent = mainFrame

	local sidebarRightBorder = Instance.new("Frame")
	sidebarRightBorder.Name = "RightBorder"
	sidebarRightBorder.Size = UDim2.new(0, 1, 1, 0)
	sidebarRightBorder.Position = UDim2.new(1, -1, 0, 0)
	sidebarRightBorder.BackgroundColor3 = COLORS.borderGlass
	sidebarRightBorder.BackgroundTransparency = 0.4
	sidebarRightBorder.BorderSizePixel = 0
	sidebarRightBorder.Parent = sidebar

	local navList = Instance.new("ScrollingFrame")
	navList.Name = "NavList"
	navList.Size = UDim2.new(1, -12, 1, -16)
	navList.Position = UDim2.new(0, 6, 0, 8)
	navList.BackgroundTransparency = 1
	navList.BorderSizePixel = 0
	navList.ScrollBarThickness = 2
	navList.ScrollBarImageColor3 = COLORS.accentEmerald
	navList.CanvasSize = UDim2.new(0, 0, 0, 0)
	navList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	navList.Parent = sidebar

	local navLayout = Instance.new("UIListLayout")
	navLayout.SortOrder = Enum.SortOrder.LayoutOrder
	navLayout.Padding = UDim.new(0, 5)
	navLayout.Parent = navList

	------------------------------------------------
	-- 📦 CONTENT CONTAINER
	------------------------------------------------
	local contentArea = Instance.new("Frame")
	contentArea.Name = "ContentArea"
	contentArea.Size = UDim2.new(1, -175, 1, -48)
	contentArea.Position = UDim2.new(0, 175, 0, 48)
	contentArea.BackgroundTransparency = 1
	contentArea.Parent = mainFrame

	local tabs = {}
	local currentTab = nil

	local function selectTab(tabName)
		if currentTab == tabName then return end
		for name, tabData in pairs(tabs) do
			local isTarget = (name == tabName)
			tabData.Frame.Visible = isTarget
			if isTarget then
				tween(tabData.Button, { BackgroundColor3 = COLORS.glassActive }, 0.2)
				tabData.Button.UIStroke.Color = COLORS.accentEmerald
				tabData.Button.UIStroke.Transparency = 0.2
				tabData.Button.Indicator.Visible = true
				tabData.Button.Label.TextColor3 = COLORS.textPrimary
			else
				tween(tabData.Button, { BackgroundColor3 = COLORS.glassCard }, 0.2)
				tabData.Button.UIStroke.Color = COLORS.borderGlass
				tabData.Button.UIStroke.Transparency = 0.7
				tabData.Button.Indicator.Visible = false
				tabData.Button.Label.TextColor3 = COLORS.textSecondary
			end
		end
		currentTab = tabName
	end

	------------------------------------------------
	-- 🧱 COMPONENT CREATORS
	------------------------------------------------
	local function createTab(name, icon, layoutOrder)
		local tabBtn = Instance.new("TextButton")
		tabBtn.Name = "Nav_" .. name
		tabBtn.Size = UDim2.new(1, 0, 0, 38)
		tabBtn.BackgroundColor3 = COLORS.glassCard
		tabBtn.BackgroundTransparency = 0.35
		tabBtn.Text = ""
		tabBtn.LayoutOrder = layoutOrder or 1
		tabBtn.Parent = navList
		local stroke = applyGlass(tabBtn, { corner = CORNER.medium, stroke = true, strokeColor = COLORS.borderGlass, strokeTransparency = 0.7, returnStroke = true })

		local indicator = Instance.new("Frame")
		indicator.Name = "Indicator"
		indicator.Size = UDim2.new(0, 3, 0, 20)
		indicator.Position = UDim2.new(0, 4, 0.5, -10)
		indicator.BackgroundColor3 = COLORS.accentEmerald
		indicator.BorderSizePixel = 0
		indicator.Visible = false
		indicator.Parent = tabBtn
		applyGlass(indicator, { corner = CORNER.pill })

		local iconLabel = Instance.new("TextLabel")
		iconLabel.Name = "Icon"
		iconLabel.Size = UDim2.new(0, 24, 1, 0)
		iconLabel.Position = UDim2.new(0, 12, 0, 0)
		iconLabel.BackgroundTransparency = 1
		iconLabel.Text = icon or "⚡"
		iconLabel.TextSize = 16
		iconLabel.Parent = tabBtn

		local textLabel = Instance.new("TextLabel")
		textLabel.Name = "Label"
		textLabel.Size = UDim2.new(1, -44, 1, 0)
		textLabel.Position = UDim2.new(0, 40, 0, 0)
		textLabel.BackgroundTransparency = 1
		textLabel.Text = name
		textLabel.TextColor3 = COLORS.textSecondary
		textLabel.TextSize = 12
		textLabel.Font = Enum.Font.GothamBold
		textLabel.TextXAlignment = Enum.TextXAlignment.Left
		textLabel.Parent = tabBtn

		tabBtn.MouseButton1Click:Connect(function()
			selectTab(name)
		end)

		-- Content ScrollFrame for this Tab
		local tabContent = Instance.new("ScrollingFrame")
		tabContent.Name = "Tab_" .. name
		tabContent.Size = UDim2.new(1, -20, 1, -20)
		tabContent.Position = UDim2.new(0, 10, 0, 10)
		tabContent.BackgroundTransparency = 1
		tabContent.BorderSizePixel = 0
		tabContent.ScrollBarThickness = 3
		tabContent.ScrollBarImageColor3 = COLORS.accentEmerald
		tabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
		tabContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
		tabContent.Visible = false
		tabContent.Parent = contentArea

		local tabLayout = Instance.new("UIListLayout")
		tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
		tabLayout.Padding = UDim.new(0, 10)
		tabLayout.Parent = tabContent

		local tabPadding = Instance.new("UIPadding")
		tabPadding.PaddingRight = UDim.new(0, 6)
		tabPadding.PaddingBottom = UDim.new(0, 12)
		tabPadding.Parent = tabContent

		tabs[name] = {
			Button = tabBtn,
			Frame = tabContent,
			UIStroke = stroke,
			Indicator = indicator,
			Label = textLabel
		}

		return tabContent
	end

	local function addSection(parent, titleText, layoutOrder)
		local sectionCard = Instance.new("Frame")
		sectionCard.Name = "Section_" .. titleText
		sectionCard.Size = UDim2.new(1, 0, 0, 0)
		sectionCard.AutomaticSize = Enum.AutomaticSize.Y
		sectionCard.BackgroundColor3 = COLORS.glassCard
		sectionCard.BackgroundTransparency = TRANSPARENCY.glassCard
		sectionCard.LayoutOrder = layoutOrder or 1
		sectionCard.Parent = parent
		applyGlass(sectionCard, { corner = CORNER.medium, stroke = true, strokeColor = COLORS.borderGlass, gradient = true })

		local secPadding = Instance.new("UIPadding")
		secPadding.PaddingTop = UDim.new(0, 10)
		secPadding.PaddingBottom = UDim.new(0, 10)
		secPadding.PaddingLeft = UDim.new(0, 12)
		secPadding.PaddingRight = UDim.new(0, 12)
		secPadding.Parent = sectionCard

		local secLayout = Instance.new("UIListLayout")
		secLayout.SortOrder = Enum.SortOrder.LayoutOrder
		secLayout.Padding = UDim.new(0, 8)
		secLayout.Parent = sectionCard

		local header = Instance.new("TextLabel")
		header.Name = "Header"
		header.Size = UDim2.new(1, 0, 0, 20)
		header.BackgroundTransparency = 1
		header.Text = string.upper(titleText)
		header.TextColor3 = COLORS.accentEmerald
		header.TextSize = 11
		header.Font = Enum.Font.GothamBold
		header.TextXAlignment = Enum.TextXAlignment.Left
		header.LayoutOrder = 0
		header.Parent = sectionCard

		return sectionCard
	end

	local function addToggle(parent, labelText, defaultVal, callback, layoutOrder)
		local state = defaultVal or false
		local toggleFrame = Instance.new("Frame")
		toggleFrame.Name = "Toggle_" .. labelText
		toggleFrame.Size = UDim2.new(1, 0, 0, 36)
		toggleFrame.BackgroundColor3 = COLORS.glassSurface
		toggleFrame.BackgroundTransparency = 0.4
		toggleFrame.LayoutOrder = layoutOrder or 1
		toggleFrame.Parent = parent
		applyGlass(toggleFrame, { corner = CORNER.small, stroke = true, strokeColor = COLORS.borderGlass, strokeTransparency = 0.8 })

		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.Size = UDim2.new(1, -60, 1, 0)
		label.Position = UDim2.new(0, 10, 0, 0)
		label.BackgroundTransparency = 1
		label.Text = labelText
		label.TextColor3 = COLORS.textPrimary
		label.TextSize = 12
		label.Font = Enum.Font.GothamMedium
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = toggleFrame

		local toggleTrack = Instance.new("TextButton")
		toggleTrack.Name = "Track"
		toggleTrack.Size = UDim2.new(0, 42, 0, 22)
		toggleTrack.Position = UDim2.new(1, -52, 0.5, -11)
		toggleTrack.BackgroundColor3 = state and COLORS.toggleOn or COLORS.toggleOff
		toggleTrack.Text = ""
		toggleTrack.Parent = toggleFrame
		applyGlass(toggleTrack, { corner = CORNER.pill, stroke = true, strokeColor = state and COLORS.accentEmerald or COLORS.borderGlass, strokeTransparency = 0.4 })

		local knob = Instance.new("Frame")
		knob.Name = "Knob"
		knob.Size = UDim2.new(0, 16, 0, 16)
		knob.Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
		knob.BackgroundColor3 = COLORS.textWhite
		knob.BorderSizePixel = 0
		knob.Parent = toggleTrack
		applyGlass(knob, { corner = CORNER.pill })

		local function updateToggle(animate)
			local targetBg = state and COLORS.toggleOn or COLORS.toggleOff
			local targetPos = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
			local targetStroke = state and COLORS.accentEmerald or COLORS.borderGlass
			if animate then
				tween(toggleTrack, { BackgroundColor3 = targetBg }, 0.2)
				tween(knob, { Position = targetPos }, 0.2, Enum.EasingStyle.Back)
				if toggleTrack:FindFirstChild("UIStroke") then
					tween(toggleTrack.UIStroke, { Color = targetStroke }, 0.2)
				end
			else
				toggleTrack.BackgroundColor3 = targetBg
				knob.Position = targetPos
				if toggleTrack:FindFirstChild("UIStroke") then
					toggleTrack.UIStroke.Color = targetStroke
				end
			end
		end

		toggleTrack.MouseButton1Click:Connect(function()
			state = not state
			updateToggle(true)
			if callback then
				task.spawn(callback, state)
			end
		end)

		return {
			Frame = toggleFrame,
			Set = function(v)
				state = v
				updateToggle(true)
			end,
			Get = function()
				return state
			end
		}
	end

	local function addButton(parent, text, callback, layoutOrder, isDanger)
		local btn = Instance.new("TextButton")
		btn.Name = "Btn_" .. text
		btn.Size = UDim2.new(1, 0, 0, 34)
		btn.BackgroundColor3 = isDanger and Color3.fromRGB(80, 25, 30) or COLORS.glassSurface
		btn.BackgroundTransparency = 0.3
		btn.Text = text
		btn.TextColor3 = isDanger and COLORS.dangerRed or COLORS.textPrimary
		btn.TextSize = 12
		btn.Font = Enum.Font.GothamBold
		btn.LayoutOrder = layoutOrder or 1
		btn.Parent = parent
		applyGlass(btn, { corner = CORNER.small, stroke = true, strokeColor = isDanger and COLORS.dangerRed or COLORS.accentEmerald, strokeTransparency = isDanger and 0.5 or 0.7 })

		local normalBg = isDanger and Color3.fromRGB(80, 25, 30) or COLORS.glassSurface
		local hoverBg = isDanger and Color3.fromRGB(110, 35, 40) or COLORS.glassHover
		addHoverAnimation(btn, normalBg, hoverBg)

		btn.MouseButton1Click:Connect(function()
			tween(btn, { Size = UDim2.new(1, -4, 0, 32) }, 0.08, Enum.EasingStyle.Quad).Completed:Connect(function()
				tween(btn, { Size = UDim2.new(1, 0, 0, 34) }, 0.08)
			end)
			if callback then
				task.spawn(callback)
			end
		end)

		return btn
	end

	local function addSlider(parent, labelText, minVal, maxVal, defaultVal, callback, layoutOrder, unit)
		unit = unit or ""
		local val = math.clamp(defaultVal or minVal, minVal, maxVal)

		local sliderFrame = Instance.new("Frame")
		sliderFrame.Name = "Slider_" .. labelText
		sliderFrame.Size = UDim2.new(1, 0, 0, 50)
		sliderFrame.BackgroundColor3 = COLORS.glassSurface
		sliderFrame.BackgroundTransparency = 0.4
		sliderFrame.LayoutOrder = layoutOrder or 1
		sliderFrame.Parent = parent
		applyGlass(sliderFrame, { corner = CORNER.small, stroke = true, strokeColor = COLORS.borderGlass, strokeTransparency = 0.8 })

		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.Size = UDim2.new(1, -70, 0, 22)
		label.Position = UDim2.new(0, 10, 0, 4)
		label.BackgroundTransparency = 1
		label.Text = labelText
		label.TextColor3 = COLORS.textPrimary
		label.TextSize = 12
		label.Font = Enum.Font.GothamMedium
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = sliderFrame

		local valLabel = Instance.new("TextLabel")
		valLabel.Name = "ValLabel"
		valLabel.Size = UDim2.new(0, 55, 0, 22)
		valLabel.Position = UDim2.new(1, -65, 0, 4)
		valLabel.BackgroundTransparency = 1
		valLabel.Text = tostring(val) .. unit
		valLabel.TextColor3 = COLORS.accentEmerald
		valLabel.TextSize = 12
		valLabel.Font = Enum.Font.GothamBold
		valLabel.TextXAlignment = Enum.TextXAlignment.Right
		valLabel.Parent = sliderFrame

		local track = Instance.new("Frame")
		track.Name = "Track"
		track.Size = UDim2.new(1, -20, 0, 8)
		track.Position = UDim2.new(0, 10, 0, 32)
		track.BackgroundColor3 = COLORS.glassActive
		track.BorderSizePixel = 0
		track.Parent = sliderFrame
		applyGlass(track, { corner = CORNER.pill })

		local fill = Instance.new("Frame")
		fill.Name = "Fill"
		local pct = (val - minVal) / (maxVal - minVal)
		fill.Size = UDim2.new(pct, 0, 1, 0)
		fill.BackgroundColor3 = COLORS.accentEmerald
		fill.BorderSizePixel = 0
		fill.Parent = track
		applyGlass(fill, { corner = CORNER.pill })

		local dragging = false
		local function updateFromInput(input)
			local trackPos = track.AbsolutePosition.X
			local trackWidth = track.AbsoluteSize.X
			local inputX = input.Position.X
			local rel = math.clamp((inputX - trackPos) / trackWidth, 0, 1)
			val = math.floor(minVal + (maxVal - minVal) * rel)
			fill.Size = UDim2.new(rel, 0, 1, 0)
			valLabel.Text = tostring(val) .. unit
			if callback then
				task.spawn(callback, val)
			end
		end

		track.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				updateFromInput(input)
			end
		end)

		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)

		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				updateFromInput(input)
			end
		end)

		return {
			Frame = sliderFrame,
			Set = function(newVal)
				val = math.clamp(newVal, minVal, maxVal)
				local rel = (val - minVal) / (maxVal - minVal)
				fill.Size = UDim2.new(rel, 0, 1, 0)
				valLabel.Text = tostring(val) .. unit
			end,
			Get = function() return val end
		}
	end

	local function addDropdown(parent, labelText, options, defaultVal, callback, layoutOrder)
		local selected = defaultVal or options[1] or "Select"
		local isOpen = false

		local dropdownContainer = Instance.new("Frame")
		dropdownContainer.Name = "Dropdown_" .. labelText
		dropdownContainer.Size = UDim2.new(1, 0, 0, 60)
		dropdownContainer.BackgroundTransparency = 1
		dropdownContainer.LayoutOrder = layoutOrder or 1
		dropdownContainer.Parent = parent

		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.Size = UDim2.new(1, 0, 0, 18)
		label.BackgroundTransparency = 1
		label.Text = labelText
		label.TextColor3 = COLORS.textSecondary
		label.TextSize = 11
		label.Font = Enum.Font.GothamMedium
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = dropdownContainer

		local mainBtn = Instance.new("TextButton")
		mainBtn.Name = "MainBtn"
		mainBtn.Size = UDim2.new(1, 0, 0, 34)
		mainBtn.Position = UDim2.new(0, 0, 0, 22)
		mainBtn.BackgroundColor3 = COLORS.glassSurface
		mainBtn.BackgroundTransparency = 0.3
		mainBtn.Text = ""
		mainBtn.Parent = dropdownContainer
		applyGlass(mainBtn, { corner = CORNER.small, stroke = true, strokeColor = COLORS.borderGlass, strokeTransparency = 0.7 })

		local selText = Instance.new("TextLabel")
		selText.Name = "SelectedText"
		selText.Size = UDim2.new(1, -30, 1, 0)
		selText.Position = UDim2.new(0, 10, 0, 0)
		selText.BackgroundTransparency = 1
		selText.Text = selected
		selText.TextColor3 = COLORS.textPrimary
		selText.TextSize = 12
		selText.Font = Enum.Font.GothamBold
		selText.TextXAlignment = Enum.TextXAlignment.Left
		selText.Parent = mainBtn

		local arrow = Instance.new("TextLabel")
		arrow.Name = "Arrow"
		arrow.Size = UDim2.new(0, 20, 1, 0)
		arrow.Position = UDim2.new(1, -26, 0, 0)
		arrow.BackgroundTransparency = 1
		arrow.Text = "▼"
		arrow.TextColor3 = COLORS.accentEmerald
		arrow.TextSize = 10
		arrow.Parent = mainBtn

		-- Popup List Frame
		local listFrame = Instance.new("ScrollingFrame")
		listFrame.Name = "ListFrame"
		listFrame.Size = UDim2.new(1, 0, 0, math.min(#options * 30 + 8, 150))
		listFrame.Position = UDim2.new(0, 0, 0, 60)
		listFrame.BackgroundColor3 = COLORS.glassPrimary
		listFrame.BackgroundTransparency = 0.05
		listFrame.BorderSizePixel = 0
		listFrame.ScrollBarThickness = 2
		listFrame.ScrollBarImageColor3 = COLORS.accentEmerald
		listFrame.Visible = false
		listFrame.ZIndex = 50
		listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
		listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
		listFrame.Parent = dropdownContainer
		applyGlass(listFrame, { corner = CORNER.small, stroke = true, strokeColor = COLORS.accentEmerald, strokeTransparency = 0.5 })

		local listLayout = Instance.new("UIListLayout")
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder
		listLayout.Padding = UDim.new(0, 2)
		listLayout.Parent = listFrame

		local listPad = Instance.new("UIPadding")
		listPad.PaddingTop = UDim.new(0, 4)
		listPad.PaddingBottom = UDim.new(0, 4)
		listPad.PaddingLeft = UDim.new(0, 4)
		listPad.PaddingRight = UDim.new(0, 4)
		listPad.Parent = listFrame

		local function populate()
			for _, child in ipairs(listFrame:GetChildren()) do
				if child:IsA("TextButton") then child:Destroy() end
			end
			for i, opt in ipairs(options) do
				local optBtn = Instance.new("TextButton")
				optBtn.Name = "Opt_" .. opt
				optBtn.Size = UDim2.new(1, 0, 0, 28)
				optBtn.BackgroundColor3 = (opt == selected) and COLORS.glassActive or COLORS.glassSurface
				optBtn.BackgroundTransparency = 0.4
				optBtn.Text = opt
				optBtn.TextColor3 = (opt == selected) and COLORS.accentEmerald or COLORS.textPrimary
				optBtn.TextSize = 11
				optBtn.Font = Enum.Font.GothamMedium
				optBtn.ZIndex = 51
				optBtn.LayoutOrder = i
				optBtn.Parent = listFrame
				applyGlass(optBtn, { corner = CORNER.small })

				optBtn.MouseButton1Click:Connect(function()
					selected = opt
					selText.Text = selected
					isOpen = false
					listFrame.Visible = false
					arrow.Text = "▼"
					populate()
					if callback then
						task.spawn(callback, selected)
					end
				end)
			end
		end

		mainBtn.MouseButton1Click:Connect(function()
			isOpen = not isOpen
			listFrame.Visible = isOpen
			arrow.Text = isOpen and "▲" or "▼"
		end)

		populate()

		return {
			Frame = dropdownContainer,
			Set = function(newOpt)
				selected = newOpt
				selText.Text = selected
				populate()
			end,
			Get = function() return selected end,
			Refresh = function(newOptions)
				options = newOptions
				populate()
			end
		}
	end

	local function addStatCard(parent, title, initialVal, layoutOrder)
		local card = Instance.new("Frame")
		card.Name = "Stat_" .. title
		card.Size = UDim2.new(1, 0, 0, 42)
		card.BackgroundColor3 = COLORS.glassSurface
		card.BackgroundTransparency = 0.4
		card.LayoutOrder = layoutOrder or 1
		card.Parent = parent
		applyGlass(card, { corner = CORNER.small, stroke = true, strokeColor = COLORS.borderGlass, strokeTransparency = 0.8 })

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
		titleLbl.Parent = card

		local valLbl = Instance.new("TextLabel")
		valLbl.Name = "Value"
		valLbl.Size = UDim2.new(0.5, -10, 1, 0)
		valLbl.Position = UDim2.new(0.5, 0, 0, 0)
		valLbl.BackgroundTransparency = 1
		valLbl.Text = tostring(initialVal or "-")
		valLbl.TextColor3 = COLORS.accentEmerald
		valLbl.TextSize = 12
		valLbl.Font = Enum.Font.GothamBold
		valLbl.TextXAlignment = Enum.TextXAlignment.Right
		valLbl.Parent = card

		return {
			Frame = card,
			Update = function(newVal)
				valLbl.Text = tostring(newVal)
			end
		}
	end

	------------------------------------------------
	-- 🚀 BUILD CORE TABS
	------------------------------------------------
	createTab("Training", "🏋️‍♂️", 1)
	createTab("Farming", "🥚", 2)
	createTab("Shops", "🛒", 3)
	createTab("Defense", "🛡️", 4)
	createTab("Movement", "⚡", 5)
	createTab("Visuals", "👁️", 6)
	createTab("Settings", "⚙️", 7)

	selectTab("Training")

	------------------------------------------------
	-- 🌐 EXPORT GLOBAL UI INTERFACE
	------------------------------------------------
	local env = (getgenv and getgenv()) or _G
	local uiTable = {
		screenGui = screenGui,
		mainFrame = mainFrame,
		topBar = topBar,
		sidebar = sidebar,
		contentArea = contentArea,
		tabs = tabs,
		closeButton = closeButton,
		minimizeButton = minimizeButton,
		statusDot = statusDot,
		statusText = statusText,
		SyncShadow = syncShadow,
		Colors = COLORS,
		-- API Component Functions
		CreateTab = createTab,
		AddSection = addSection,
		AddToggle = addToggle,
		AddButton = addButton,
		AddSlider = addSlider,
		AddDropdown = addDropdown,
		AddStatCard = addStatCard,
		SelectTab = selectTab,
		Tween = tween
	}

	env.HipHubUI = uiTable
	_G.HipHubUI = uiTable
	if shared then shared.HipHubUI = uiTable end

	print("[HipHub JFA UI] Initialized successfully.")
end)

if not success then
	warn("[HipHub JFA UI Error]: " .. tostring(err))
end
