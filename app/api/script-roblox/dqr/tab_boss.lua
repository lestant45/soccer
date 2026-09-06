-- ═══ TAB: BOSS ═══
do
	local frame = tabFrames.Boss
	applyList(frame, 10)

	local settSec = createSection(frame,"Boss Settings",2,true)
	applyList(settSec.Content,6)

	createInput(settSec.Content,"Boss Tier (1-5)","1",tostring(CFG.bossTier),1,function(v)
		local n=tonumber(v); if n then CFG.bossTier=math.clamp(math.floor(n),1,5); saveConfig() end
	end)

	local _,bReadyTrack,bReadyThumb = createToggle(settSec.Content,"Auto Ready in Boss",2)
	setupToggle(bReadyTrack,bReadyThumb,"bossAutoReady",function()
		task.spawn(function()
			while CFG.bossAutoReady do
				task.wait(2)
				pcall(function() local r=getRemote("readyUp"); if r then r:FireServer(true) end end)
			end
		end)
	end,nil)

	local _,bReplayTrack,bReplayThumb = createToggle(settSec.Content,"Auto Replay Boss",3)
	setupToggle(bReplayTrack,bReplayThumb,"bossAutoReplay",nil,nil)

	-- Auto Boss Farm toggle
	local autoBossSec = createSection(frame,"Auto Boss Farm",6,true)
	applyList(autoBossSec.Content,6)

	local _,autoBossTrack,autoBossThumb = createToggle(autoBossSec.Content,"Auto Boss Farm Loop",1)
	setupToggle(autoBossTrack,autoBossThumb,"autoBoss",function()
		task.spawn(function()
			while CFG.autoBoss do
				-- Create lobby
				pcall(function()
					local r=getRemoteF("createBossLobby"); if r then r:InvokeServer(CFG.bossTier,false) end
				end)
				task.wait(2)
				-- Start raid
				pcall(function()
					local r=getRemote("startBossRaid"); if r then r:FireServer() end
				end)
				task.wait(30) -- wait for boss to end
				STATS.bossesKilled+=1
			end
		end)
	end,nil)

	-- Boss Actions section
	local actionSec = createSection(frame,"Boss Actions",10,true)
	applyList(actionSec.Content,8)

	createButton(actionSec.Content,"Create Boss Lobby",C.accentCyan,1,function()
		pcall(function() local r=getRemoteF("createBossLobby"); if r then r:InvokeServer(CFG.bossTier,false) end end)
	end)
	createButton(actionSec.Content,"Start Boss Raid",C.accentViolet,2,function()
		pcall(function() local r=getRemote("startBossRaid"); if r then r:FireServer() end end)
	end)
	createButton(actionSec.Content,"Leave Boss Lobby",C.red,3,function()
		pcall(function() local r=getRemote("leaveBossLobby"); if r then r:FireServer() end end)
	end)
end
