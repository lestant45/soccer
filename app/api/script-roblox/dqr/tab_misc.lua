-- ═══ TAB: MISC ═══
do
	local frame = tabFrames.Misc
	applyList(frame, 10)

	local miscSec = createSection(frame,"Miscellaneous",2,true)
	applyList(miscSec.Content,6)

	-- Anti-AFK
	local _,afkTrack,afkThumb = createToggle(miscSec.Content,"Anti-AFK",1)
	setupToggle(afkTrack,afkThumb,"antiAfk",function()
		task.spawn(function()
			while CFG.antiAfk do
				task.wait(55)
				pcall(function()
					local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
					if h then h:Move(Vector3.new(0.1,0,0)) end
				end)
			end
		end)
	end,nil)

	-- FPS Booster
	local _,fpsTrack,fpsThumb = createToggle(miscSec.Content,"FPS Booster (No 3D Render)",2)
	setupToggle(fpsTrack,fpsThumb,"fpsBooster",function()
		pcall(function() RunService:Set3dRenderingEnabled(false) end)
	end,function()
		pcall(function() RunService:Set3dRenderingEnabled(true) end)
	end)

	-- Hide Chat
	local _,chatTrack,chatThumb = createToggle(miscSec.Content,"Hide Chat",3)
	setupToggle(chatTrack,chatThumb,"chatBypass",function()
		pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat,false) end)
	end,function()
		pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat,true) end)
	end)

	-- Drop Notif
	local dropSec = createSection(frame,"Drop Notifications",10,false)
	applyList(dropSec.Content,5)
	local _,dropTrack,dropThumb = createToggle(dropSec.Content,"Item Drop Notification",1)
	setupToggle(dropTrack,dropThumb,"dropNotif",function()
		local r=getRemote("AnnounceDrop")
		if r then
			addConn(r.OnClientEvent:Connect(function(...)
				if not CFG.dropNotif then return end
				print("[HipHub DQR] Drop:", ...)
			end))
		end
	end,nil)

	-- Credits
	local credSec = createSection(frame,"Credits",30,false)
	applyList(credSec.Content,4)
	applyPadding(credSec.Content,14,14,8,8)

	local credits = {
		{"Script by HipHub Team", C.accentCyan, true},
		{"Game: Dungeon Quest Reborn", C.textSecondary, false},
		{"PlaceId: 77649408247578", C.textMuted, false},
		{"Remotes: discovered via MCP", C.textMuted, false},
		{"UI: Liquid Glass Base v2", C.textSecondary, false},
	}
	for i,d in ipairs(credits) do
		local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,0,0,20); lbl.BackgroundTransparency=1
		lbl.Text=d[1]; lbl.TextColor3=d[2]; lbl.Font=d[3] and Enum.Font.GothamBold or Enum.Font.Gotham
		lbl.TextSize=11; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.LayoutOrder=i; lbl.Parent=credSec.Content
	end
end

-- ═══ INIT ═══
selectTab("Info")

if CFG.antiAfk then
	task.spawn(function()
		while CFG.antiAfk do
			task.wait(55)
			pcall(function()
				local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
				if h then h:Move(Vector3.new(0.1,0,0)) end
			end)
		end
	end)
end

print("[HipHub DQR] Loaded | PlaceId: 77649408247578")
