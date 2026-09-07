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

	createInput(settSec.Content,"Attack Delay (s)","0.28",tostring(CFG.autoFarmDelay or 0.28),1,function(v)
		local n=tonumber(v); if n then CFG.autoFarmDelay=math.clamp(n,0.1,5); saveConfig() end
	end)

	createInput(settSec.Content,"Hover Height (studs)","4.5",tostring(CFG.farmHoverHeight or 4.5),2,function(v)
		local n=tonumber(v); if n then CFG.farmHoverHeight=math.clamp(n,2,30); saveConfig() end
	end)

	createInput(settSec.Content,"Tween Speed (studs/s)","26",tostring(CFG.tweenSpeed or 26),3,function(v)
		local n=tonumber(v); if n then CFG.tweenSpeed=math.clamp(n,10,60); saveConfig() end
	end)

	local _,posTrack,posThumb = createToggle(settSec.Content,"Safe Distance Kite (No Hit)",4)
	local isBehind = (CFG.farmPositionMode or "behind") == "behind"
	if isBehind then
		posTrack.BackgroundColor3 = C.toggleOn
		posThumb.Position = UDim2.new(1,-17,0.5,-7)
	end
	posTrack.MouseButton1Click:Connect(function()
		isBehind = not isBehind
		if isBehind then
			posTrack.BackgroundColor3 = C.toggleOn
			posThumb.Position = UDim2.new(1,-17,0.5,-7)
			CFG.farmPositionMode = "behind"
		else
			posTrack.BackgroundColor3 = C.toggleOff
			posThumb.Position = UDim2.new(0,3,0.5,-7)
			CFG.farmPositionMode = "hover"
		end
		saveConfig()
	end)

	local _,telTrack,telThumb = createToggle(settSec.Content,"Smooth Tween Movement",5)
	setupToggle(telTrack,telThumb,"farmTeleport",nil,nil)

	-- Control section
	local ctrlSec = createSection(frame,"Farm Control",6,true)
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
							stopFarmTween()
							-- If in dungeon with no enemies at all, smoothly advance to room checkpoint/startPart
							local dungeon = Workspace:FindFirstChild("dungeon")
							if dungeon then
								for _, room in ipairs(dungeon:GetChildren()) do
									if room.Name ~= "initialRoom" then
										local cp = room:FindFirstChild("checkPoint") or room:FindFirstChild("startPart")
										if cp and (cp.Position - hrp.Position).Magnitude > 15 then
											local targetCF = cp.CFrame + Vector3.new(0, 2.5, 0)
											groundTweenTo(targetCF, tonumber(CFG.tweenSpeed) or 26)
											break
										end
									end
								end
							end
						end
						task.wait(0.3)
						return
					end

					-- Step 1: Smoothly approach target once if outside melee reach
					local eh = target.humanoid
					if target.rootPart and hrp then
						local initialDist = (hrp.Position - target.rootPart.Position).Magnitude
						if initialDist > 4.0 then
							statusLbl.Text = "Status: <font color='#00d4a8'>Approaching " .. tostring(target.name) .. "</font>   Enemies Killed: "..STATS.enemiesKilled
							approachTarget(target)
						end
					end

					-- Step 2: In-combat strike loop (auto-spacing kiting: keeps 3.7 studs distance)
					statusLbl.Text = "Status: <font color='#00d4a8'>Attacking " .. tostring(target.name) .. "</font>   Enemies Killed: "..STATS.enemiesKilled
					while farmActive and CFG.autoFarm and eh and eh.Health > 0 and target.model.Parent do
						local currentHrp = char and char:FindFirstChild("HumanoidRootPart")
						if not currentHrp or not target.rootPart then break end

						local currentDist = (currentHrp.Position - target.rootPart.Position).Magnitude
						if currentDist > 5.0 then
							-- Target walked away, step closer into safe weapon reach
							approachTarget(target)
						elseif (CFG.farmPositionMode or "behind") == "behind" and currentDist < 3.2 then
							-- Too close (inside enemy 3-stud danger radius), step back to safe 3.7 studs!
							local enemyCF = target.rootPart.CFrame
							local safeCF = enemyCF * CFrame.new(0, 0, 3.7)
							groundTweenTo(safeCF, tonumber(CFG.tweenSpeed) or 26)
						else
							-- In safe sweet spot (3.2 - 5.0 studs): out of enemy reach, inside player weapon reach!
							performAttack(target)
							task.wait(tonumber(CFG.autoFarmDelay) or 0.28)
						end
					end

					if eh and eh.Health <= 0 then
						STATS.enemiesKilled += 1
						statusLbl.Text = "Status: <font color='#00d4a8'>Defeated " .. tostring(target.name) .. "!</font>   Enemies Killed: "..STATS.enemiesKilled
					end
				end)
				if not ok then
					warn("[HipHub DQR Farm Error]:", err)
				end
				task.wait(0.08)
			end
			stopFarmFly()
			stopFarmTween()
		end)
	end,function()
		farmActive = false
		stopFarmFly()
		stopFarmTween()
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
