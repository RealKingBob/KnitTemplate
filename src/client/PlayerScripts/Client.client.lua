local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

----- Knit -----
Knit.PlayerScripts = Knit.Player:WaitForChild("PlayerScripts")

Knit.Modules = Knit.PlayerScripts:WaitForChild("Modules");
Knit.Controllers = Knit.PlayerScripts:WaitForChild("Controllers")

Knit.Shared = ReplicatedStorage.Common;

----- Loaded Modules -----

Knit.AddControllersDeep(Knit.Controllers)

local KnitClient = Knit.CreateController { Name = "KnitClient" }

function KnitClient:KnitInit()

end

Knit.Start():andThen(function()
	print("Client started");
end):catch(warn)