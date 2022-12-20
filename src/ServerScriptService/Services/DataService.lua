local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local packages = ReplicatedStorage.SnowballFight.Packages
local Knit = require(packages.Knit)
local TableUtil = require(packages.TableUtil)
local PlayerData = DataStoreService:GetDataStore("PlayerData")
local KillsData = DataStoreService:GetOrderedDataStore("Kills")

local sessionData = {}
local DataService = Knit.CreateService { Name = "DataService" }

-- 리더보드 초기 설정
local function LeaderboardSetup(kills, player)
	local leaderstats
	if player:FindFirstChild("leaderstats") then
		leaderstats = player:FindFirstChild("leaderstats")
	else
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"	
		leaderstats.Parent = player
	end

	local money = Instance.new("IntValue")
	money.Name = "Kills"
	money.Value = kills
	money.Parent = leaderstats
	
	return leaderstats
end

-- 전적 데이터 불러오기
local function LoadData(player)
	local success, result = pcall(function()
		return KillsData:GetAsync(player.UserId)
	end)
	if not success then
		warn(result)
	end
	return success, result
end

-- 전적 데이터 저장하기
local function SaveData(player, data)
	local success, result = pcall(function()
		KillsData:SetAsync(player.UserId, data)
	end)
	if not success then 
		warn(result)
	end
	return success
end

-- 전적 관련 체계 시작
function DataService:KnitStart()
	-- 플레이어 참가 시 데이터 불러오기
	local function onPlayerAdded(player)
		local success, data = LoadData(player)
		-- Currently only support saving kills
		sessionData[player.UserId] = { Kills = if success and data ~= nil then data else 0 } -- 데이터 없을 시 초기 설정
		LeaderboardSetup(sessionData[player.UserId].Kills, player)
	end

	-- 플레이어 퇴장 시 데이터 저장하기
	local function onPlayerRemoving(player)
		-- Only supports saving kills
		SaveData(player, sessionData[player.UserId].Kills)
		sessionData[player.UserId] = nil
	end

	-- 게임이 종료될 때(플레이어가 없어 서버가 닫힐 때)
	local function onClose()
		if RunService:IsStudio() then
			return
		end

		for _, player in pairs(Players:GetPlayers()) do -- 스튜디오가 아니여서 플레이어가 여러 명일 경우
			task.spawn(onPlayerRemoving(player))
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		task.defer(onPlayerAdded, player)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	game:BindToClose(onClose)
end

--[[
	player is the one who made the kill
]]
function DataService:AddKill(player)
	local data = sessionData[player.UserId]
	if data then
		data.Kills += 1

		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			leaderstats.Kills.Value += 1
		end
	end
end

return DataService