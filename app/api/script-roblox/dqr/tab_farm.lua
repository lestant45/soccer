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

	createInput(settSec.Content,"Kill Delay (s)","0.1",tostring(CFG.autoFarmDelay),1,function(v)
		local n=tonumber(v); if n then CFG.autoFarmDelay=math.clamp(n,0,5); saveConfig() end
	end)

	local _,telTrack,telThumb = createToggle(settSec.Content,"Teleport to Enemy",2)
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
				pcall(function()
					local char=player.Character
					local hrp=char and char:FindFirstChild("HumanoidRootPart")
					if not char or not hrp then return end
					local enemies = getAllEnemies()
					if #enemies == 0 then
						task.wait(0.5)
						return
					end
					for _, enemy in ipairs(enemies) do
						if not farmActive or not CFG.autoFarm then break end
						local eh = enemy.humanoid
						local erp = enemy.rootPart
						if not (eh and eh.Health > 0 and erp) then continue end
						while farmActive and CFG.autoFarm and eh.Health > 0 and enemy.model.Parent do
							attackTarget(enemy)
							task.wait(CFG.autoFarmDelay or 0.1)
						end
						if eh.Health <= 0 then
							STATS.enemiesKilled += 1
							statusLbl.Text = "Status: <font color='#00d4a8'>Active</font>   Enemies Killed: "..STATS.enemiesKilled
						end
					end
				end)
				task.wait(0.2)
			end
		end)
	end,function()
		farmActive=false
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
