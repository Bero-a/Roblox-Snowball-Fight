local packages = game:GetService("ReplicatedStorage").SnowballFight.Packages
local Component = require(packages.Component)
local Trove = require(packages.Trove)
local FastCast = require(packages.FastCast)
local Comm = require(packages.Comm)
local Knit = require(packages.Knit)
local t = require(packages.t)
local Players = game:GetService("Players")
local Constants = require(game:GetService("ReplicatedStorage").SnowballFight.Common.Constants)
local snowball = game:GetService("ServerStorage").SnowballFight.Snowball
local playerSnowball = game:GetService("ServerStorage").SnowballFight.PlayerSnowball
local wall = workspace.SnowballFight.Lobby.Wall -- to keep players out, but snowballs can come

local CACHE_SIZE = 25
local THROW_SPEED = 750

local throwCheck = t.tuple(t.Vector3, t.numberMax(Constants.MAX_THROW_TIME))

-- Workspace에서 마우스 포인터가 향하는 방향
local function newCastParams(character)
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { character, wall }
	params.FilterType = Enum.RaycastFilterType.Blacklist
	return params
end

-- 위 값을 활용한 눈덩이 궤적에 물리량 반영
local function newThrowBehavior(castParams, provider)
	local behavior = FastCast.newBehavior()
	behavior.Acceleration = Vector3.FromAxis(Enum.Axis.Y) * -workspace.Gravity
	behavior.RaycastParams = castParams
	behavior.CosmeticBulletProvider = provider
	return behavior
end

-- 패키지 빌드업
local Snowballer = Component.new({
	Tag = "Snowballer",
})

-- 눈덩이 관련 체계 생성
function Snowballer:Construct()
	self._trove = Trove.new()
	self._player = Players:GetPlayerFromCharacter(self.Instance)
	self._comm = self._trove:Construct(Comm.ServerComm, self.Instance)
	self._comm:WrapMethod(self, "Throw")
	self._hitSignal = self._comm:CreateSignal("Hit")
	self._canThrow = self._comm:CreateProperty("CanThrow", true)
	self._caster = FastCast.new()
	-- VERY IMPORTANT: If you set the parent of the cache to just workspace, it won't work! No clue why!
	self._cache = self._trove:Add(FastCast.PartCache.new(snowball, CACHE_SIZE, workspace.SnowballFight.Snowballs), "Dispose")
	self._behavior = newThrowBehavior(newCastParams(self.Instance), self._cache)
	self._playerBall = self._trove:Add(playerSnowball:Clone())
end

-- 눈덩이 관련 체계 시작
function Snowballer:Start()
	self:_attachBallToPlayer()
	self:_handleLengthChanged()
	self:_handleRayHit()
	self:_handleCastTerminating()

end

-- 게임 시작 시 눈덩이를 플레이어 손에 붙임
function Snowballer:_attachBallToPlayer()
	-- the instance is the player character
	local grip = self.Instance:FindFirstChild("RightGripAttachment", true)
	if grip then
		self._playerBall.Parent = self.Instance
		self._playerBall.RigidConstraint.Attachment0 = grip
	end
end

-- 눈덩이를 맞혔을 때 관련
function Snowballer:_handleRayHit()
	self._trove:Connect(self._caster.RayHit, function(cast, result, velocity, ball)
		-- particles!
		ball.Puff:Emit(30)
		-- sounds!
		ball.Impact:Play()

		local character = result.Instance:FindFirstAncestorWhichIsA("Model")
		if character then
			local player = Players:GetPlayerFromCharacter(character)
			if player 
				and self._player.Neutral == false -- actually in the game
				and self._player.Team ~= player.Team  -- targeting an enemy, not teammate
				and player.Neutral == false -- target player is actually in the game
			then
				-- 위에서 가려낸 대상에게 피해 주기
				local humanoid = character:FindFirstChild("Humanoid") 
				if humanoid then
					humanoid:TakeDamage(Constants.SNOWBALL_DAMAGE)
					-- Let the client know to play a sound
					local killed = humanoid.Health <= 0
					if killed then
						Knit.GetService("DataService"):AddKill(self._player) -- 처치 시 전적에 반영
					end
					self._hitSignal:Fire(self._player, killed)
				end
			end
		end
	end)
end

-- 눈덩이를 던졌을 때 궤적 표시
function Snowballer:_handleCastTerminating()
	self._trove:Connect(self._caster.CastTerminating, function(cast)
		local ball = cast.RayInfo.CosmeticBulletObject
		if ball then
			task.delay(0.5, function()
				ball.Trail.Enabled = false
				self._cache:ReturnPart(ball)
			end)
		end
	end)
end

-- 손에서 날아가는 Ray에 계속 눈덩이를 이동시킴
function Snowballer:_handleLengthChanged()
	self._trove:Connect(self._caster.LengthChanged, function(cast, lastPoint, dir, displacement, velocity, ball)
		-- Ugly, but there is no way to do it one time when the caster spawns it in
		local currentPoint = lastPoint + (dir * displacement)
		ball.Position = currentPoint
	end)
end

-- 눈덩이 던지기
function Snowballer:Throw(player, mousePos, throwTime)
	assert(throwCheck(mousePos, throwTime))
	if player ~= self._player or self._canThrow:Get() == false then
		return 
	end
	self:_setThrowable(false) -- 눈덩이를 던질 수 없는 상태로 만듦

	-- 손에서 눈덩이가 발사되도록 하기 위해 플레이어 기준이 아닌
	-- 월드 기준에서의 눈덩이 위치 획득
	local pos do
		pos = player.Character:GetPrimaryPartCFrame().Position
		local grip = player.Character:FindFirstChild("RightGripAttachment", true)
		if grip then
			pos = grip.WorldPosition
		end
	end

	-- We have to do this because the snowball is launched from the 
	-- player's hand, so the dir might be different by a bit.
	local dir = (mousePos - pos).Unit
	local cast = self._caster:Fire(pos, dir, throwTime * THROW_SPEED, self._behavior)
	local ball = cast.RayInfo.CosmeticBulletObject
	if ball then
		-- We have to enable/disable the trail since it still goes when we use partcache,
		-- as parts are not being created and destroyed they are being moved, and trails work on movement.
		ball.Trail.Enabled = true
	end

	-- 재사용 대기시간 후에 눈덩이를 다시 던질 수 있도록 설정
	task.delay(Constants.COOLDOWN, function()
		self:_setThrowable(true)
	end)
end

-- 던질 수 있는지 여부에 따라 플레이어 손의 눈덩이 투명도 설정(던질 수 있으면 표시, 아니면 숨기기)
function Snowballer:_setThrowable(canThrow)
	self._canThrow:Set(canThrow)
	self._playerBall.Transparency = if canThrow then 0 else 1
end

-- 눈덩이 관련 체계 파괴
function Snowballer:Stop()
	self._trove:Destroy()
end

return Snowballer