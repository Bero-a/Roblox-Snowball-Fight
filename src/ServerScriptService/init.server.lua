local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local packages = game:GetService("ReplicatedStorage").SnowballFight.Packages
local Knit = require(packages.Knit)
local Loader = require(packages.Loader)

---- 하위 컴포넌트랑 서비스 로드
Knit.AddServices(script.Services)

Knit.Start():andThen(function()
	Loader.LoadChildren(script.Components)
end):catch(warn)
