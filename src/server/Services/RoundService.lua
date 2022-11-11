local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local packages = ReplicatedStorage.Packages
local TableUtil = require(packages.TableUtil)
local Knit = require(packages.Knit)
local Trove = require(packages.Trove)
local Signal = require(packages.Signal)
local Timer = require(packages.Timer)
local court = workspace.Court
local Constants = require(ReplicatedStorage.Common.Constants)

-- 라운드 관련 서비스 생성
local RoundService = Knit.CreateService {
	Name = "RoundService",
	Client = {
		GameState = Knit.CreateProperty({
			State = "Waiting for Players",
			TimeLeft = "",
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
		end
	end)
end

-- 플레이어 대기 시 
function RoundService:_waitForPlayers()
	self.Client.GameState:Set({
		State = "Waiting for Players...",
		TimeLeft = ""
	})
	local enoughPlayers = Signal.new()
	local count = 0
	local function updateCount() -- 인원 충족 시 시작
		count = #Players:GetPlayers()
		if count > 1 
		--	or RunService:IsStudio() -- 스튜디오 테스트용
		then
			enoughPlayers:Fire()
		end
	end
	Players.PlayerAdded:Connect(updateCount)
	Players.PlayerRemoving:Connect(updateCount)
	task.delay(1, updateCount) -- just so the event wait can actually detect it
	enoughPlayers:Wait()
end

-- 경기 시작 전 대기시간 설정
function RoundService:_intermission()
	for i = Constants.INTERMISSION_TIME, 0, -1 do
		self.Client.GameState:Set({
			State = "Intermission",
			TimeLeft = i,
		})
		task.wait(1)
	end
end

-- 경기 시작
function RoundService:_begin()
	self:_generateTeams()
	self:_teleportTeam(Teams.Red)
	self:_teleportTeam(Teams.Blue)
end

-- 팀 생성
function RoundService:_generateTeams()
	local players = Players:GetPlayers()
	-- Not sure if the shuffle is necessary, but I think it'll be fine
	for i, player in ipairs(TableUtil.Shuffle(players)) do
		if not player.Character then
			continue
		end

		player.Team = if i <= #players/2 then Teams.Red else Teams.Blue
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
	for i = Constants.ROUND_TIME, 0, -1 do
		self.Client.GameState:Set({
			State = "Fight!",
			TimeLeft = i,
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
end

return RoundService