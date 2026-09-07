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

	createInput(settSec.Content,"Hover Height (studs)","4.0",tostring(CFG.farmHoverHeight or 4.0),2,function(v)
		local n=tonumber(v); if n then CFG.farmHoverHeight=math.clamp(n,2,30); saveConfig() end
	end)

	createInput(settSec.Content,"Tween Speed (studs/s)","26",tostring(CFG.tweenSpeed or 26),3,function(v)
		local n=tonumber(v); if n then CFG.tweenSpeed=math.clamp(n,10,60); saveConfig() end
	end)

	local _,posTrack,posThumb = createToggle(settSec.Content,"2-Phase Safe Hover (Ground+Fly)",4)
	local isHover = (CFG.farmPositionMode or "hover") == "hover"
	if isHover then
		posTrack.BackgroundColor3 = C.toggleOn
		posThumb.Position = UDim2.new(1,-17,0.5,-7)
	end
	posTrack.MouseButton1Click:Connect(function()
		isHover = not isHover
		if isHover then
			posTrack.BackgroundColor3 = C.toggleOn
			posThumb.Position = UDim2.new(1,-17,0.5,-7)
			CFG.farmPositionMode = "hover"
		else
			posTrack.BackgroundColor3 = C.toggleOff
			posThumb.Position = UDim2.new(0,3,0.5,-7)
			CFG.farmPositionMode = "behind"
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
							-- Smoothly advance to the entrance door of the NEXT stage (startPart)
							local nextDoor = getNextRoomDoor()
							if nextDoor and hrp then
								local doorDist = (nextDoor.Position - hrp.Position).Magnitude
								if doorDist > 6 then
									statusLbl.Text = "Status: <font color='#00d4a8'>Moving to Next Stage Door...</font>"
									local targetCF = nextDoor.CFrame + Vector3.new(0, 2.5, 0)
									groundTweenTo(targetCF, tonumber(CFG.tweenSpeed) or 26, false)
								else
									statusLbl.Text = "Status: <font color='#00d4a8'>Waiting at Next Stage Door</font>"
								end
							end
						end
						task.wait(0.3)
						return
					end

					-- Step 1: Smoothly approach target
					local eh = target.humanoid
					if target.rootPart and hrp then
						local initialDist = (hrp.Position - target.rootPart.Position).Magnitude
						local hoverHeight = tonumber(CFG.farmHoverHeight) or 4.0
						if initialDist > (hoverHeight + 2.5) then
							statusLbl.Text = "Status: <font color='#00d4a8'>Approaching " .. tostring(target.name) .. "</font>   Enemies Killed: "..STATS.enemiesKilled
							approachTarget(target)
						end
					end

					-- Step 2: In-combat strike loop
					statusLbl.Text = "Status: <font color='#00d4a8'>Attacking " .. tostring(target.name) .. "</font>   Enemies Killed: "..STATS.enemiesKilled
					while farmActive and CFG.autoFarm and eh and eh.Health > 0 and target.model.Parent do
						local currentHrp = char and char:FindFirstChild("HumanoidRootPart")
						if not currentHrp or not target.rootPart then break end

						local currentDist = (currentHrp.Position - target.rootPart.Position).Magnitude
						local hoverHeight = tonumber(CFG.farmHoverHeight) or 4.0

						if currentDist > 25 then
							-- More than 25 studs: Switch back to ground travel
							approachTarget(target)
							break
						elseif currentDist > (hoverHeight + 3.0) or currentDist < (hoverHeight - 1.2) then
							-- Re-align hover height and position directly above enemy
							approachTarget(target)
						else
							-- In safe hover range above enemy: strike downwards!
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
