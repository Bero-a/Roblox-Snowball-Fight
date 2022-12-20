local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local packages = ReplicatedStorage.SnowballFight.Packages
local TableUtil = require(packages.TableUtil)
local Knit = require(packages.Knit)
local Trove = require(packages.Trove)
local Signal = require(packages.Signal)
local Timer = require(packages.Timer)
local court = workspace.SnowballFight.Court
local Constants = require(ReplicatedStorage.SnowballFight.Common.Constants)

local EventConnected = false
local enoughPlayers = false

-- 라운드 관련 서비스 생성
local RoundService = Knit.CreateService {
	Name = "RoundService",
	Client = {
		GameState = Knit.CreateProperty({
			State = "Waiting for Players",
			TimeLeft = ""
		})
	},
	_trove = Trove.new()
}

-- 라운드 관련 체계 시작
function RoundService:KnitStart()
	-- 모든 플레이어를 죽여서 리셋
	local function resetPlayers()
		for _, team in ipairs(Teams:GetTeams()) do
			for _, player in ipairs(team:GetPlayers()) do
				local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
				if humanoid then
					humanoid.Health = 0 -- Kill all players
				end
			end
		end
	end

	task.defer(function()
		task.wait(3) -- just to get everything started
		while true do
			self._trove:Add(resetPlayers)
			self:_waitForPlayers()
			self:_intermission()
			self:_begin()
			self:_yieldUntilFinished()
			self:_end()
			print("Ended!")
		end
	end)
end

-- 플레이어 대기 시 
function RoundService:_waitForPlayers()
	print("_waitForPlayers")
	self.Client.GameState:Set({
		State = "Waiting for Players...",
		TimeLeft = ""
	})
	enoughPlayers = false
	local count = 0
	local function updateCount() -- 인원 충족 시 시작
		count = #CollectionService:GetTagged("Snowballer")
		print(count)
		if count >= 1 then
			enoughPlayers = true
		else
			enoughPlayers = false
		end
	end
	if not EventConnected then
		CollectionService:GetInstanceAddedSignal("Snowballer"):Connect(updateCount)
		CollectionService:GetInstanceRemovedSignal("Snowballer"):Connect(updateCount)
		EventConnected = true
	end
	--task.delay(1, updateCount) -- just so the event wait can actually detect it
	print("before wait")
	repeat wait() until enoughPlayers
end

-- 경기 시작 전 대기시간 설정
function RoundService:_intermission()
	print("_intermission")
	for i = Constants.INTERMISSION_TIME, 0, -1 do
		if #CollectionService:GetTagged("Snowballer") < Constants.MIN_PLAYERS then return end
		self.Client.GameState:Set({
			State = "Intermission",
			TimeLeft = i
		})
		task.wait(1)
	end
end

-- 경기 시작
function RoundService:_begin()
	print("_begin")
	if #CollectionService:GetTagged("Snowballer") < Constants.MIN_PLAYERS then return end
	workspace.SnowballFight.Lobby.Wall.CanCollide = true
	self:_generateTeams()
	self:_teleportTeam(Teams.Red)
	self:_teleportTeam(Teams.Blue)
end

-- 팀 생성
function RoundService:_generateTeams()
	local characters = CollectionService:GetTagged("Snowballer")
	
	-- Not sure if the shuffle is necessary, but I think it'll be fine
	for i, character in ipairs(TableUtil.Shuffle(characters)) do

		local player = Players:GetPlayerFromCharacter(character)

		player.Team = if i <= #characters/2 then Teams.Red else Teams.Blue
		self:_watchPlayer(player)
	end
end

-- 사망 시 관전
function RoundService:_watchPlayer(player)
	local humanoid = player.Character:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end

	humanoid.Died:Connect(function()
		-- Remove them from their team, pretty easy,
		-- they will respawn out of the arena automatically 
		player.Team = nil
	end)
end

--각 팀마다 팀 지역 근처에서 무작위 장소로 이동
function RoundService:_teleportTeam(team)
	local function teleportPlayer(player, pos)
		local character = player.Character
		if character then
			character:SetPrimaryPartCFrame(CFrame.new(pos))
		end
	end

	local function getRandomPos(startPos, maxRadius)
		-- Get a random angle (in radians) around the unit circle
		local theta = math.random() * math.pi * 2
		local radius = math.random(1, maxRadius)
		local x = math.cos(theta) * radius
		local z = math.sin(theta) * radius
		return startPos + Vector3.new(x, 0, z)
	end

	local spawnPoint = court:FindFirstChild(team.Name).Start
	for _, player in ipairs(team:GetPlayers()) do
		-- Spawns players randomly in a circle around the start
		teleportPlayer(player, getRandomPos(spawnPoint.Position, 5))
	end
end

-- 경기 시간이 다 될 때까지 남은 시간과 팀별 인원수 표시
function RoundService:_yieldUntilFinished()
	print("_yieldUntilFinished")
	for i = Constants.ROUND_TIME, 0, -1 do
		if #CollectionService:GetTagged("Snowballer") < Constants.MIN_PLAYERS then return end
		self.Client.GameState:Set({
			State = "Fight!",
			TimeLeft = i
		})
		task.wait(1)
		local numRed = #Teams.Red:GetPlayers()
		local numBlue = #Teams.Blue:GetPlayers()
		if numBlue < 1 or numRed < 1 then
			-- One team completely died, move on!
			break
		end
	end
end

-- 경기가 끝났을 때 승자 표시, 인원 수가 같을 경우 타이브레이크
function RoundService:_end()
	print("_end")
	if #CollectionService:GetTagged("Snowballer") < Constants.MIN_PLAYERS then return end
	local numRed = #Teams.Red:GetPlayers()
	local numBlue = #Teams.Blue:GetPlayers()
	local winner = if numBlue > numRed then Teams.Blue elseif numBlue == numRed then nil else Teams.Red
	for i = Constants.END_TIME, 0, -1 do
		self.Client.GameState:Set({
			State = if winner then "Winner: " .. winner.Name else "Tie!",
			TimeLeft = i
		})
		task.wait(1)
	end
	self._trove:Clean()
	workspace.SnowballFight.Lobby.Wall.CanCollide = false
end

return RoundService