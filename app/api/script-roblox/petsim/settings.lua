-- ==============================================================================
-- ⚙️ HipHub Settings — Pet Simulator 99 Configuration & Profile Manager
-- ==============================================================================

local success, err = pcall(function()
	local env = (getgenv and getgenv()) or _G
	local HttpService = game:GetService("HttpService")

	local CONFIG_FILE = "HipHub/petsim_config.json"

	local function saveConfig()
		if not writefile then return end
		pcall(function()
			if makefolder and not isfolder("HipHub") then
				makefolder("HipHub")
			end
			local data = {
				autoWorldConfig = env.autoWorldConfig,
				autoStageFarmConfig = env.autoStageFarmConfig,
				autoChestConfig = env.autoChestConfig,
				autoBalloonChestConfig = env.autoBalloonChestConfig,
				breakableFarmConfig = env.breakableFarmConfig,
				antiAfkConfig = env.antiAfkConfig,
				performanceConfig = env.performanceConfig,
				giftRedeemConfig = env.giftRedeemConfig,
			}
			writefile(CONFIG_FILE, HttpService:JSONEncode(data))
		end)
	end

	local function loadConfig()
		if not readfile or not isfile or not isfile(CONFIG_FILE) then return end
		pcall(function()
			local content = readfile(CONFIG_FILE)
			local data = HttpService:JSONDecode(content)
			if type(data) == "table" then
				if data.autoWorldConfig and env.autoWorldConfig then
					for k, v in pairs(data.autoWorldConfig) do env.autoWorldConfig[k] = v end
				end
				if data.autoStageFarmConfig and env.autoStageFarmConfig then
					for k, v in pairs(data.autoStageFarmConfig) do env.autoStageFarmConfig[k] = v end
				end
				if data.autoChestConfig and env.autoChestConfig then
					for k, v in pairs(data.autoChestConfig) do env.autoChestConfig[k] = v end
				end
				if data.autoBalloonChestConfig and env.autoBalloonChestConfig then
					for k, v in pairs(data.autoBalloonChestConfig) do env.autoBalloonChestConfig[k] = v end
				end
				if data.breakableFarmConfig and env.breakableFarmConfig then
					for k, v in pairs(data.breakableFarmConfig) do env.breakableFarmConfig[k] = v end
				end
				if data.antiAfkConfig and env.antiAfkConfig then
					for k, v in pairs(data.antiAfkConfig) do env.antiAfkConfig[k] = v end
				end
				if data.performanceConfig and env.performanceConfig then
					for k, v in pairs(data.performanceConfig) do env.performanceConfig[k] = v end
				end
				if data.giftRedeemConfig and env.giftRedeemConfig then
					for k, v in pairs(data.giftRedeemConfig) do env.giftRedeemConfig[k] = v end
				end
			end
		end)
	end

	env.HipHubSaveConfig = saveConfig
	env.HipHubLoadConfig = loadConfig
	_G.HipHubSaveConfig = saveConfig
	_G.HipHubLoadConfig = loadConfig
end)

if not success then
	warn("[HipHub PS99 Settings Error]:", err)
end
