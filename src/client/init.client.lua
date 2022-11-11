local packages = game:GetService("ReplicatedStorage"):WaitForChild("Packages")
local Knit = require(packages.Knit)
local Loader = require(packages.Loader)

-- 하위 컴포넌트랑 컨트롤러 로드
Knit.AddControllers(script.Controllers)
Knit.Start():andThen(function()
	-- Make sure to load components after knit has started
	-- In case any of them need to reference a service
	Loader.LoadChildren(script.Components)
end):catch(warn)