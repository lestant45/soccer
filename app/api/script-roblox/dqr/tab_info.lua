-- ═══ TAB: INFO ═══
do
	local frame = tabFrames.Info
	applyList(frame, 10)

	-- Welcome Card
	local wCard = Instance.new("Frame"); wCard.Size=UDim2.new(1,0,0,78); wCard.BackgroundColor3=C.glassCard
	wCard.BackgroundTransparency=TR.glassCard; wCard.BorderSizePixel=0; wCard.LayoutOrder=1; wCard.Parent=frame
	applyGlass(wCard,{corner=CR.medium,stroke=true,strokeColor=C.borderGlass,strokeThickness=1,strokeTransparency=0.7,gradient=true,gradientRotation=120})

	local wTitle=Instance.new("TextLabel"); wTitle.Size=UDim2.new(1,-24,0,28); wTitle.Position=UDim2.new(0,14,0,12)
	wTitle.BackgroundTransparency=1; wTitle.Text="Sword Welcome, "..player.DisplayName.."!"
	wTitle.TextColor3=C.textWhite; wTitle.Font=Enum.Font.GothamBold; wTitle.TextSize=13
	wTitle.TextXAlignment=Enum.TextXAlignment.Left; wTitle.Parent=wCard

	local wDesc=Instance.new("TextLabel"); wDesc.Size=UDim2.new(1,-24,0,28); wDesc.Position=UDim2.new(0,14,0,40)
	wDesc.BackgroundTransparency=1; wDesc.Text="HipHub DQR | Auto Farm  Boss Raid  ESP  Move Hacks"
	wDesc.TextColor3=C.textSecondary; wDesc.Font=Enum.Font.Gotham; wDesc.TextSize=10
	wDesc.TextWrapped=true; wDesc.TextXAlignment=Enum.TextXAlignment.Left; wDesc.Parent=wCard

	-- Stats Grid Card
	local statsCard=Instance.new("Frame"); statsCard.Size=UDim2.new(1,0,0,168); statsCard.BackgroundColor3=C.glassCard
	statsCard.BackgroundTransparency=TR.glassCard; statsCard.BorderSizePixel=0; statsCard.LayoutOrder=2; statsCard.Parent=frame
	applyGlass(statsCard,{corner=CR.medium,stroke=true,strokeColor=C.borderGlass,strokeThickness=1,strokeTransparency=0.7})

	local scT=Instance.new("TextLabel"); scT.Size=UDim2.new(1,-24,0,24); scT.Position=UDim2.new(0,14,0,8)
	scT.BackgroundTransparency=1; scT.Text="SESSION STATS"; scT.TextColor3=C.accentCyan
	scT.Font=Enum.Font.GothamBold; scT.TextSize=9; scT.TextXAlignment=Enum.TextXAlignment.Left; scT.Parent=statsCard

	local scGrid=Instance.new("Frame"); scGrid.Size=UDim2.new(1,-24,1,-38); scGrid.Position=UDim2.new(0,12,0,34)
	scGrid.BackgroundTransparency=1; scGrid.Parent=statsCard
	local gLayout=Instance.new("UIGridLayout"); gLayout.CellSize=UDim2.new(0.5,-6,0,52)
	gLayout.CellPadding=UDim2.new(0,12,0,10); gLayout.SortOrder=Enum.SortOrder.LayoutOrder; gLayout.Parent=scGrid

	local function addStatBox(title, val, order)
		local box=Instance.new("Frame"); box.BackgroundColor3=C.glassSurface; box.BackgroundTransparency=0.25
		box.BorderSizePixel=0; box.LayoutOrder=order; box.Parent=scGrid
		applyGlass(box,{corner=CR.small,stroke=true,strokeColor=C.borderGlass,strokeThickness=1,strokeTransparency=0.85})
		local bT=Instance.new("TextLabel"); bT.Size=UDim2.new(1,-10,0,16); bT.Position=UDim2.new(0,8,0,6)
		bT.BackgroundTransparency=1; bT.Text=title:upper(); bT.TextColor3=C.textMuted
		bT.Font=Enum.Font.GothamMedium; bT.TextSize=8; bT.TextXAlignment=Enum.TextXAlignment.Left; bT.Parent=box
		local bV=Instance.new("TextLabel"); bV.Size=UDim2.new(1,-10,0,22); bV.Position=UDim2.new(0,8,0,22)
		bV.BackgroundTransparency=1; bV.Text=val; bV.TextColor3=C.textPrimary
		bV.Font=Enum.Font.GothamBold; bV.TextSize=13; bV.TextXAlignment=Enum.TextXAlignment.Left; bV.Parent=box
		return bV
	end

	local statKilled = addStatBox("Enemies Killed","0",1)
	local statBosses = addStatBox("Bosses Done","0",2)
	local statUptime = addStatBox("Uptime","00:00:00",3)
	local statPing   = addStatBox("Ping","...",4)

	task.spawn(function()
		local st=os.time()
		while statsCard and statsCard.Parent do
			task.wait(1)
			local e=os.time()-st
			statUptime.Text=string.format("%02d:%02d:%02d",math.floor(e/3600),math.floor((e%3600)/60),e%60)
			local ok,p=pcall(function() return player:GetNetworkPing()*1000 end)
			statPing.Text=ok and string.format("%d ms",math.round(p)) or "N/A"
			statKilled.Text=tostring(STATS.enemiesKilled)
			statBosses.Text=tostring(STATS.bossesKilled)
		end
	end)

	-- Leaderstats Card
	local lsCard=Instance.new("Frame"); lsCard.Size=UDim2.new(1,0,0,0); lsCard.AutomaticSize=Enum.AutomaticSize.Y
	lsCard.BackgroundColor3=C.glassCard; lsCard.BackgroundTransparency=TR.glassCard
	lsCard.BorderSizePixel=0; lsCard.LayoutOrder=3; lsCard.Parent=frame
	applyGlass(lsCard,{corner=CR.medium,stroke=true,strokeColor=C.borderGlass,strokeThickness=1,strokeTransparency=0.7})
	applyList(lsCard,5); applyPadding(lsCard,14,14,10,10)

	local lsH=Instance.new("TextLabel"); lsH.Size=UDim2.new(1,0,0,22); lsH.BackgroundTransparency=1
	lsH.Text="PLAYER STATS"; lsH.TextColor3=C.accentCyan; lsH.Font=Enum.Font.GothamBold
	lsH.TextSize=9; lsH.TextXAlignment=Enum.TextXAlignment.Left; lsH.LayoutOrder=0; lsH.Parent=lsCard

	local function makeRow(lbl, val, lo)
		local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,26); row.BackgroundTransparency=1
		row.LayoutOrder=lo; row.Parent=lsCard
		local l=Instance.new("TextLabel"); l.Size=UDim2.new(0.6,0,1,0); l.BackgroundTransparency=1
		l.Text=lbl; l.TextColor3=C.textSecondary; l.Font=Enum.Font.GothamMedium; l.TextSize=12
		l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=row
		local v=Instance.new("TextLabel"); v.Size=UDim2.new(0.4,0,1,0); v.Position=UDim2.new(0.6,0,0,0)
		v.BackgroundTransparency=1; v.Text=val; v.TextColor3=C.accentCyan
		v.Font=Enum.Font.GothamBold; v.TextSize=12; v.TextXAlignment=Enum.TextXAlignment.Right; v.Parent=row
		return v
	end

	local valGold  = makeRow("Gold",  "0", 1)
	local valGems  = makeRow("Gems",  "0", 2)
	local valLevel = makeRow("Level", "1", 3)

	task.spawn(function()
		while lsCard and lsCard.Parent do
			task.wait(4)
			pcall(function()
				local ls=player:FindFirstChild("leaderstats")
				if ls then
					local g=ls:FindFirstChild("Gold"); if g then valGold.Text=tostring(g.Value) end
					local gm=ls:FindFirstChild("Gems"); if gm then valGems.Text=tostring(gm.Value) end
					local lv=ls:FindFirstChild("Level"); if lv then valLevel.Text=tostring(lv.Value) end
				end
			end)
		end
	end)
end
