-- ═══ TAB: FARM ═══
do
	local frame = tabFrames.Farm
	applyList(frame, 10)

	-- Status card
	local statusCard=Instance.new("Frame"); statusCard.Size=UDim2.new(1,0,0,54); statusCard.BackgroundColor3=C.glassCard
	statusCard.BackgroundTransparency=TR.glassCard; statusCard.BorderSizePixel=0; statusCard.LayoutOrder=0; statusCard.Parent=frame
	applyGlass(statusCard,{corner=CR.medium,stroke=true,strokeColor=C.borderGlass,strokeThickness=1,strokeTransparency=0.7})
	applyPadding(statusCard,14,14,10,10)

	local statusLbl=Instance.new("TextLabel"); statusLbl.Size=UDim2.new(1,0,1,0)
	statusLbl.BackgroundTransparency=1
	statusLbl.Text="Status: <font color='#ff4d4d'>Inactive</font>   Enemies Killed: 0"
	statusLbl.TextColor3=C.textSecondary; statusLbl.TextSize=12; statusLbl.RichText=true
	statusLbl.TextWrapped=true; statusLbl.Font=Enum.Font.GothamMedium
	statusLbl.TextXAlignment=Enum.TextXAlignment.Left; statusLbl.LineHeight=1.4; statusLbl.Parent=statusCard

	-- Settings section
	local settSec = createSection(frame,"Farm Settings",2,true)
	applyList(settSec.Content,6)

	createInput(settSec.Content,"Kill Delay (s)","0.15",tostring(CFG.autoFarmDelay or 0.15),1,function(v)
		local n=tonumber(v); if n then CFG.autoFarmDelay=math.clamp(n,0.05,5); saveConfig() end
	end)

	createInput(settSec.Content,"Hover Height (studs)","4.5",tostring(CFG.farmHoverHeight or 4.5),2,function(v)
		local n=tonumber(v); if n then CFG.farmHoverHeight=math.clamp(n,2,30); saveConfig() end
	end)

	local _,telTrack,telThumb = createToggle(settSec.Content,"Fly Above Enemy",3)
	setupToggle(telTrack,telThumb,"farmTeleport",nil,nil)

	-- Control section
	local ctrlSec = createSection(frame,"Farm Control",4,true)
	applyList(ctrlSec.Content,6)

	local _,farmTrack,farmThumb = createToggle(ctrlSec.Content,"Auto Farm Enemies",1)
	local farmActive = false
	setupToggle(farmTrack,farmThumb,"autoFarm",function()
		farmActive = true
		statusLbl.Text="Status: <font color='#00d4a8'>Active</font>   Enemies Killed: "..STATS.enemiesKilled
		task.spawn(function()
			while farmActive and CFG.autoFarm do
				local ok, err = pcall(function()
					local char = player.Character
					local hrp = char and char:FindFirstChild("HumanoidRootPart")
					if not char or not hrp then return end

					-- Check if dungeon needs to start (click green START button)
					pcall(function()
						local r = getRemote("changeStartValue")
						if r then r:FireServer() end
					end)

					local target = getNearestEnemy()
					if not target then
						statusLbl.Text = "Status: <font color='#ffaa00'>Searching enemies...</font>   Enemies Killed: "..STATS.enemiesKilled
						local allE = getAllEnemies()
						if #allE == 0 then
							stopFarmFly()
							-- If in dungeon with no enemies at all, advance room checkpoint/startPart
							local dungeon = Workspace:FindFirstChild("dungeon")
							if dungeon then
								for _, room in ipairs(dungeon:GetChildren()) do
									if room.Name ~= "initialRoom" then
										local cp = room:FindFirstChild("checkPoint") or room:FindFirstChild("startPart")
										if cp and (cp.Position - hrp.Position).Magnitude > 25 then
											local targetCF = cp.CFrame + Vector3.new(0, 4, 0)
											hrp.CFrame = targetCF
											pcall(function() char:PivotTo(targetCF) end)
											break
										end
									end
								end
							end
						end
						task.wait(0.3)
						return
					end

					-- Attack nearest target while hovering above it
					local eh = target.humanoid
					statusLbl.Text = "Status: <font color='#00d4a8'>Farming " .. tostring(target.name) .. "</font>   Enemies Killed: "..STATS.enemiesKilled
					while farmActive and CFG.autoFarm and eh and eh.Health > 0 and target.model.Parent do
						attackTarget(target)
						task.wait(tonumber(CFG.autoFarmDelay) or 0.15)
					end

					if eh and eh.Health <= 0 then
						STATS.enemiesKilled += 1
						statusLbl.Text = "Status: <font color='#00d4a8'>Active</font>   Enemies Killed: "..STATS.enemiesKilled
					end
				end)
				if not ok then
					warn("[HipHub DQR Farm Error]:", err)
				end
				task.wait(0.08)
			end
			stopFarmFly()
		end)
	end,function()
		farmActive = false
		stopFarmFly()
		statusLbl.Text="Status: <font color='#ff4d4d'>Inactive</font>   Enemies Killed: "..STATS.enemiesKilled
	end)

	local _,readyTrack,readyThumb = createToggle(ctrlSec.Content,"Auto Ready Up",2)
	setupToggle(readyTrack,readyThumb,"bossAutoReady",function()
		task.spawn(function()
			while CFG.bossAutoReady do
				task.wait(2)
				pcall(function() local r=getRemote("readyUp"); if r then r:FireServer(true) end end)
			end
		end)
	end,nil)

	local _,replayTrack,replayThumb = createToggle(ctrlSec.Content,"Auto Replay Dungeon",3)
	setupToggle(replayTrack,replayThumb,"autoReplay",function()
		task.spawn(function()
			while CFG.autoReplay do
				task.wait(3)
				pcall(function()
					local dp=Workspace:FindFirstChild("dungeonProgress")
					if dp and dp.Value=="complete" then
						task.wait(2)
						local r=getRemote("replayDungeon"); if r then r:FireServer() end
					end
				end)
			end
		end)
	end,nil)

	-- Start dungeon section
	local dungSec = createSection(frame,"Start Dungeon",10,true)
	applyList(dungSec.Content,8)

	createButton(dungSec.Content,"Start Dungeon",C.accentCyan,1,function()
		pcall(function() local r=getRemote("startDungeon"); if r then r:FireServer() end end)
	end)
	createButton(dungSec.Content,"Join Dungeon",C.accentViolet,2,function()
		pcall(function() local r=getRemote("joinDungeon"); if r then r:FireServer() end end)
	end)
	createButton(dungSec.Content,"Leave Dungeon",C.red,3,function()
		pcall(function() local r=getRemote("leaveDungeon"); if r then r:FireServer() end end)
	end)
end
