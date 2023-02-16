local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

----- Knit -----
Knit.PlayerScripts = Knit.Player:WaitForChild("PlayerScripts")

Knit.Modules = Knit.PlayerScripts:WaitForChild("Modules");
Knit.Controllers = Knit.PlayerScripts:WaitForChild("Controllers")

----- Loaded Modules -----

Knit.AddControllersDeep(Knit.Controllers)

Knit.Start():andThen(function()
	print("Client started");
end):catch(warn)