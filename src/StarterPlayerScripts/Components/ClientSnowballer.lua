local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local packages = game:GetService("ReplicatedStorage"):WaitForChild("SnowballFight"):WaitForChild("Packages")
local Component = require(packages.Component)
local Comm = require(packages.Comm)
local Trove = require(packages.Trove)
local Knit = require(packages.Knit)
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local TweenService = game:GetService("TweenService")
local powerGui = game:GetService("ReplicatedStorage"):WaitForChild("SnowballFight"):WaitForChild("ThrowPower")
local Constants = require(game:GetService("ReplicatedStorage").SnowballFight.Common.Constants)
local animations = game:GetService("ReplicatedStorage").SnowballFight.Animations
local throwAnim = animations.Throw
local windupAnim = animations.Windup
local hitSound = ReplicatedStorage.SnowballFight.Hit
local killSound = ReplicatedStorage.SnowballFight.Kill
local wall = workspace.SnowballFight.Lobby.Wall

-- Workspace에서 마우스 포인터가 향하는 방향
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Blacklist
local function getMousePos()
	params.FilterDescendantsInstances = { player.Character, wall }
	local pos = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(pos.X, pos.Y)
	local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
	return if result then result.Position else ray.Origin + ray.Direction * 1000
end

local OnlyLocalPlayer = {}
--[[
	This assumes that the component will only be attached 
	to the player's character, which it should be. 
]]
function OnlyLocalPlayer.ShouldConstruct(component)
	-- For some reason, we sometimes have to wait for the character to load in 
	-- even though the tag is added after they load in on the server
	-- task.wait(1) -- good ol wait to fix a bug!
	local char = player.character or player.CharacterAppearanceLoaded:Wait()
	return component.Instance == char
end

-- 패키지 빌드업
local Snowballer = Component.new({
	Tag = "Snowballer",
	Extensions = { OnlyLocalPlayer }
})

-- 눈덩이 관련 체계 생성
function Snowballer:Construct()
	self._trove = Trove.new()
	self._powerGui = self._trove:Add(powerGui:Clone())
	self._startThrow = 0
	self._throwTime = 0
	self._comm = self._trove:Construct(Comm.ClientComm, self.Instance, true)

	self.GUI_INFO = TweenInfo.new(Constants.MAX_THROW_TIME, Enum.EasingStyle.Linear)
end

-- 눈덩이 관련 체계 시작
function Snowballer:Start()
	local canThrow = self._comm:GetProperty("CanThrow")
	local humanoid = self.Instance:WaitForChild("Humanoid")
	local animator = humanoid:WaitForChild("Animator")

	local function windup()
		local anim = animator:LoadAnimation(windupAnim)
		anim:Play()
		anim:AdjustSpeed(2)
		return anim
	end

	self._powerGui.Parent = player.PlayerGui.SnowballFight

	local windupRef = nil
	local winding = false
	-- Wait for the bool to be ready to be used
	canThrow:OnReady():await()
	canThrow:Observe(function(value)
		-- just so the client doesn't yell at you
	end)
	-- 눈덩이 던지는 액션
	ContextActionService:BindAction("Throw", function(name, state, obj)
		if state == Enum.UserInputState.Begin and canThrow:Get() == true then
			winding = true
			self:_startGuiTween()
			self._startThrow = time()
			windupRef = windup()
			wait(windupRef.Length/2 - 0.05) -- Make sure to stop it just before it finishes
			windupRef:AdjustSpeed(0)
		elseif state == Enum.UserInputState.End and winding then
			winding = false
			-- Throw time can't go over the max, hence the math.min
			local throwTime = math.min(time() - self._startThrow, Constants.MAX_THROW_TIME)
			self:_endGuiTween()
			self._comm:GetFunction("Throw")(getMousePos(), throwTime):catch(warn)

			if windupRef then
				windupRef:Stop()
			end
			local anim = animator:LoadAnimation(throwAnim)
			anim:Play()
			anim:AdjustSpeed(4)
		end
	end, false, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR1)

	self._trove:Add(function()
		ContextActionService:UnbindAction("Throw")
	end)

	self._trove:Connect(self._comm:GetSignal("Hit"), function(killed)
		-- Nice sounds for game feel
		if killed then
			killSound:Play()
		else
			hitSound:Play()
		end
	end)
end

-- 눈덩이 던지기 시작할 떄 나오는 gui
function Snowballer:_startGuiTween()
	self._powerGui.Enabled = true
	local bar = self._powerGui.Base.Bounds.Bar
	-- Reset bar to bottom
	bar.Size = UDim2.fromScale(1, 0)

	self._guiTween = TweenService:Create(bar, self.GUI_INFO, { Size = UDim2.fromScale(1, 1)})
	self._guiTween:Play() 
end

function Snowballer:_windup()
	
end

-- 도중에 던졌을 때 gui 지우기
function Snowballer:_endGuiTween()
	if self._guiTween then
		self._guiTween:Cancel()
		self._guiTween = nil
	end
	self._powerGui.Enabled = false
end

function Snowballer:Stop()
	self._trove:Destroy()
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	local gameStateUI = player.PlayerGui:WaitForChild("SnowballFight"):WaitForChild("GameState")
	if input.KeyCode == Enum.KeyCode.N then
		Knit.GetService("SnowballerService"):KeyPressed()
		gameStateUI.Enabled = true
	elseif input.KeyCode == Enum.KeyCode.M then
		Knit.GetService("SnowballerService"):KeyPresseded()
		gameStateUI.Enabled = false
	end
end)

return Snowballer