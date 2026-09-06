-- ═══ TAB: SELL ═══
do
	local frame = tabFrames.Sell
	applyList(frame, 10)

	local sellSec = createSection(frame,"Auto Sell",2,true)
	applyList(sellSec.Content,6)

	createInput(sellSec.Content,"Sell Interval (s)","30",tostring(CFG.autoSellDelay),1,function(v)
		local n=tonumber(v); if n then CFG.autoSellDelay=math.clamp(n,5,600); saveConfig() end
	end)

	local _,sellTrack,sellThumb = createToggle(sellSec.Content,"Auto Sell Weak Items",2)
	setupToggle(sellTrack,sellThumb,"autoSell",function()
		task.spawn(function()
			while CFG.autoSell do
				task.wait(CFG.autoSellDelay)
				if not CFG.autoSell then break end
				pcall(function()
					local r1=getRemote("openSellShop"); if r1 then r1:FireServer() end
					task.wait(0.8)
					local r2=getRemote("sellItemEvent"); if r2 then r2:FireServer(); STATS.itemsSold+=1 end
				end)
			end
		end)
	end,nil)

	createButton(sellSec.Content,"Sell Now (Manual)",C.yellow,3,function()
		pcall(function()
			local r1=getRemote("openSellShop"); if r1 then r1:FireServer() end
			task.wait(0.8)
			local r2=getRemote("sellItemEvent"); if r2 then r2:FireServer(); STATS.itemsSold+=1 end
		end)
	end)
	createButton(sellSec.Content,"Open Blacksmith",C.accentBlend,4,function()
		pcall(function() local r=getRemote("openBlacksmith"); if r then r:FireServer() end end)
	end)
	createButton(sellSec.Content,"Open Shop",C.green,5,function()
		pcall(function() local r=getRemote("openShop"); if r then r:FireServer() end end)
	end)
end
