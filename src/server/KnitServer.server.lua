local RunService = game:GetService("RunService");

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Component = require(Knit.Util.Component);
local Promise = require(Knit.Util.Promise);

-- Load all services within 'Services':
Knit.AddServices(script.Parent.Services)


--// Ensures that all components are loaded
function Knit.OnComponentsLoaded()
	if Knit.ComponentsLoaded then
		return Promise.Resolve();
	end

	return Promise.new(function(resolve, reject, onCancel)
		local heartbeat;

		heartbeat = RunService.Heartbeat:Connect(function()
			if Knit.ComponentsLoaded then
				heartbeat:Disconnect();
				heartbeat = nil;
			end
		end)

		onCancel(function()
			if heartbeat then
				heartbeat:Disconnect();
				heartbeat = nil;
			end
		end)
	end)
end


Knit.Start():andThen(function()
    Component.Auto(Knit.Components);
	Knit.ComponentsLoaded = true;
	print("Server Initialized");
end):catch(function(err)
    warn(err);
end)