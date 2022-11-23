local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local packages = ReplicatedStorage.Packages
local Knit = require(packages.Knit)

--[[
	A service whose sole purpose is to supply the player
	with a snowballer at all times, because I think it'll be
	fun to pelt your friends in the lobby with a snowball cause why not
]]
local SnowballerService = Knit.CreateService { Name = "SnowballerService" }

-- 플레이어 참가 시 Snowballer로 등록
function SnowballerService:KnitStart()
	-- Handles every single case for the player to always get their baller
	local function onCharacterAdded(character)
		CollectionService:AddTag(character, "Snowballer")
	end
	
	local function onCharacterRemoving(character)
		CollectionService:RemoveTag(character, "Snowballer")
	end
	
	local function onPlayerAdded(player: Player)
		if player.Character then
			onCharacterAdded(player.Character)
		end
		player.CharacterAdded:Connect(onCharacterAdded)
		player.CharacterRemoving:Connect(onCharacterRemoving)
	end
	
	
	for _, player in ipairs(Players:GetPlayers()) do
		task.defer(onPlayerAdded, player)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
end

return SnowballerService