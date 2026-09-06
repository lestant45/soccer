-- ═══ TAB: MOVE ═══
do
	local frame = tabFrames.Move
	applyList(frame, 10)

	-- Speed & Jump
	local speedSec = createSection(frame,"Speed and Jump",2,true)
	applyList(speedSec.Content,6)

	local _,speedTrack,speedThumb = createToggle(speedSec.Content,"Speed Hack",1)
	createInput(speedSec.Content,"Walk Speed","50",tostring(CFG.speedValue),2,function(v)
		local n=tonumber(v); if n then CFG.speedValue=n
		if CFG.speedEnabled then pcall(function() player.Character.Humanoid.WalkSpeed=n end) end
		saveConfig() end
	end)
	setupToggle(speedTrack,speedThumb,"speedEnabled",function()
		task.spawn(function()
			while CFG.speedEnabled do
				task.wait(0.5)
				pcall(function() local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed=CFG.speedValue end end)
			end
		end)
	end,function()
		pcall(function() local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed=16 end end)
	end)

	local _,jumpTrack,jumpThumb = createToggle(speedSec.Content,"Jump Power Hack",3)
	createInput(speedSec.Content,"Jump Power","100",tostring(CFG.jumpValue),4,function(v)
		local n=tonumber(v); if n then CFG.jumpValue=n
		if CFG.jumpEnabled then pcall(function() player.Character.Humanoid.JumpPower=n end) end
		saveConfig() end
	end)
	setupToggle(jumpTrack,jumpThumb,"jumpEnabled",function()
		task.spawn(function()
			while CFG.jumpEnabled do
				task.wait(0.5)
				pcall(function() local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h then h.JumpPower=CFG.jumpValue end end)
			end
		end)
	end,function()
		pcall(function() local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h then h.JumpPower=50 end end)
	end)

	-- Noclip & Inf Jump
	local noclipSec = createSection(frame,"Noclip and Fly",10,true)
	applyList(noclipSec.Content,6)

	local _,noclipTrack,noclipThumb = createToggle(noclipSec.Content,"Noclip",1)
	setupToggle(noclipTrack,noclipThumb,"noclipEnabled",function()
		task.spawn(function()
			while CFG.noclipEnabled do
				task.wait()
				pcall(function()
					if not player.Character then return end
					for _,p in ipairs(player.Character:GetDescendants()) do
						if p:IsA("BasePart") then p.CanCollide=false end
					end
				end)
			end
			pcall(function()
				if not player.Character then return end
				for _,p in ipairs(player.Character:GetDescendants()) do
					if p:IsA("BasePart") then p.CanCollide=true end
				end
			end)
		end)
	end,function()
		pcall(function()
			if not player.Character then return end
			for _,p in ipairs(player.Character:GetDescendants()) do
				if p:IsA("BasePart") then p.CanCollide=true end
			end
		end)
	end)

	local _,infJumpTrack,infJumpThumb = createToggle(noclipSec.Content,"Infinite Jump",2)
	setupToggle(infJumpTrack,infJumpThumb,"infJump",function()
		addConn(UserInputService.JumpRequest:Connect(function()
			if not CFG.infJump then return end
			pcall(function()
				local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
				if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
			end)
		end))
	end,nil)

	-- Teleport
	local tpSec = createSection(frame,"Teleport",20,true)
	applyList(tpSec.Content,6)

	createButton(tpSec.Content,"Teleport to Lobby",C.accentBlend,1,function()
		pcall(function() local r=getRemote("teleToLobby"); if r then r:FireServer() end end)
	end)
	createButton(tpSec.Content,"Open Travel GUI",C.accentViolet,2,function()
		pcall(function() local r=getRemote("openTravelGui"); if r then r:FireServer() end end)
	end)
	createButton(tpSec.Content,"Teleport to Dungeon",C.accentCyan,3,function()
		pcall(function()
			local dungeonFolder = Workspace:FindFirstChild("dungeon") or Workspace:FindFirstChild("Dungeon")
			if dungeonFolder then
				local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if hrp then hrp.CFrame = CFrame.new(dungeonFolder:GetPivot().Position + Vector3.new(0,5,0)) end
			end
		end)
	end)
end
