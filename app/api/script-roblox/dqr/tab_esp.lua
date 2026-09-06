-- ═══ TAB: ESP ═══
do
	local frame = tabFrames.ESP
	applyList(frame, 10)

	local settSec = createSection(frame,"ESP Settings",2,true)
	applyList(settSec.Content,6)

	createInput(settSec.Content,"Max Distance (studs)","500",tostring(CFG.espDistance),1,function(v)
		local n=tonumber(v); if n then CFG.espDistance=n; saveConfig() end
	end)

	local togSec = createSection(frame,"ESP Toggles",10,true)
	applyList(togSec.Content,6)

	-- Highlight helper (uses _espObjects from core)
	local function mkHighlight(target, fillColor, outlineColor, fillT, outlineT, espType)
		local h=Instance.new("Highlight")
		h.FillColor=fillColor or Color3.fromRGB(255,100,100)
		h.OutlineColor=outlineColor or Color3.fromRGB(255,255,255)
		h.FillTransparency=fillT or 0.7; h.OutlineTransparency=outlineT or 0
		h.Adornee=target; h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; h.Parent=gui
		h:SetAttribute("espType",espType or "")
		table.insert(_espObjects,h); return h
	end

	-- Player ESP
	local _,pTrack,pThumb = createToggle(togSec.Content,"Player ESP",1)
	setupToggle(pTrack,pThumb,"playerESP",function()
		task.spawn(function()
			while CFG.playerESP do
				task.wait(3)
				pcall(function()
					for i=#_espObjects,1,-1 do
						local e=_espObjects[i]
						if e and e:IsA("Highlight") and e:GetAttribute("espType")=="player" then
							pcall(function() e:Destroy() end); table.remove(_espObjects,i)
						end
					end
					for _,plr in ipairs(Players:GetPlayers()) do
						if plr~=player and plr.Character then
							mkHighlight(plr.Character,Color3.fromRGB(50,150,255),Color3.fromRGB(100,200,255),0.6,0,"player")
						end
					end
				end)
			end
		end)
	end,function()
		for i=#_espObjects,1,-1 do
			local e=_espObjects[i]
			if e and e:IsA("Highlight") and e:GetAttribute("espType")=="player" then
				pcall(function() e:Destroy() end); table.remove(_espObjects,i)
			end
		end
	end)

	-- Enemy ESP
	local _,eTrack,eThumb = createToggle(togSec.Content,"Enemy ESP",2)
	setupToggle(eTrack,eThumb,"enemyESP",function()
		task.spawn(function()
			while CFG.enemyESP do
				task.wait(2)
				pcall(function()
					for i=#_espObjects,1,-1 do
						local e=_espObjects[i]
						if e and e:IsA("Highlight") and e:GetAttribute("espType")=="enemy" then
							pcall(function() e:Destroy() end); table.remove(_espObjects,i)
						end
					end
					local ef=Workspace:FindFirstChild("enemies")
					if not ef then return end
					for _,enemy in ipairs(ef:GetChildren()) do
						local eh=enemy:FindFirstChildOfClass("Humanoid")
						if eh and eh.Health>0 then
							mkHighlight(enemy,Color3.fromRGB(255,60,60),Color3.fromRGB(255,150,150),0.5,0,"enemy")
						end
					end
				end)
			end
		end)
	end,function()
		for i=#_espObjects,1,-1 do
			local e=_espObjects[i]
			if e and e:IsA("Highlight") and e:GetAttribute("espType")=="enemy" then
				pcall(function() e:Destroy() end); table.remove(_espObjects,i)
			end
		end
	end)
end
