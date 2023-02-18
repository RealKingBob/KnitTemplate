----- Services -----
local Players = game:GetService("Players"); 
local MarketplaceService = game:GetService("MarketplaceService")

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local ProfileService = require(script.Parent.ProfileService);

local ThemeData = workspace:GetAttribute("Theme")

local SETTINGS = {
    ProfileTemplate = {	
		Currency = {
            Coins = 0;
        }, -- User current currency

        Level = 0, -- User current level
        EXP = 0, -- User experience to level up

        DailyItemsBought = 0, -- Num of daily items bought in daily store
        CurrencyBought = 0, -- Coin amount a user has bought
        LifeTimeCurrency = 0, -- counts how many Currency a user has had overall

        LogInTimes = 0, -- Num of times a player has logged on this game
        SecondsPlayed = 0, -- Num of seconds a user has played the game
        
        MissionInfo = false, -- {lastOnline, streak}
        DailyShopInfo = false, -- {lastOnline, streak}
		
		Inventory = {
            CurrentDeathEffect = "Default",
			CurrentHat = "Default",
			Boosters = {},
			Hats = {
                Default = {
                    Quantity = 1;
                    Rarity = 1
                }
            },
            DeathEffects = {
                Default = {
                    Quantity = 1;
                    Rarity = 1
                }
            },
		}, -- Inventory of the user
        SkillUpgrades = {
            World1 = { -- World
                ["Player Speed"] = 1; -- 1x speed
            },
		}, -- Player Skill Upgrades
	};

    Products = { -- developer_product_id = function(profile)
		-- COIN PURCHASES --
		[00000000000] = function(profile)
            profile.Data.Currency[ThemeData] += 1000
        end,
    },

    PurchaseIdLog = 50, -- Store this amount of purchase id's in MetaTags;
        -- This value must be reasonably big enough so the player would not be able
        -- to purchase products faster than individual purchases can be confirmed.
        -- Anything beyond 30 should be good enough.
}

local GameProfileStore = ProfileService.GetProfileStore(
	"PlayerDataTest1",
	SETTINGS.ProfileTemplate
);

local Profiles = {} -- {player = profile, ...}

local DataService = Knit.CreateService {
	Name = "DataService";
	Client = {};
}

local Signal = require(Knit.Util.Signal)
DataService.RequestDailyShop = Signal.new();

----- Private Functions -----

local function PlayerAdded(player)
    local profile = GameProfileStore:LoadProfileAsync("Player_" .. player.UserId)
    if profile ~= nil then
        profile:AddUserId(player.UserId) -- GDPR compliance
        profile:Reconcile() -- Fill in missing variables from ProfileTemplate (optional)
        profile:ListenToRelease(function()
            Profiles[player] = nil
            player:Kick() -- The profile could've been loaded on another Roblox server
        end)
        if player:IsDescendantOf(Players) == true then
            Profiles[player] = profile
        else
            profile:Release() -- Player left before the profile loaded
        end
    else
        -- The profile couldn't be loaded possibly due to other
        --   Roblox servers trying to load this profile at the same time:
        player:Kick("Kicked to prevent data corruption... | Unable to retieve data for "..player.Name.." | Please rejoin");
    end
end

function PurchaseIdCheckAsync(profile, purchase_id, grant_product_callback) --> Enum.ProductPurchaseDecision
    -- Yields until the purchase_id is confirmed to be saved to the profile or the profile is released

    if profile:IsActive() ~= true then

        return Enum.ProductPurchaseDecision.NotProcessedYet

    else

        local meta_data = profile.MetaData

        local local_purchase_ids = meta_data.MetaTags.ProfilePurchaseIds
        if local_purchase_ids == nil then
            local_purchase_ids = {}
            meta_data.MetaTags.ProfilePurchaseIds = local_purchase_ids
        end

        -- Granting product if not received:

        if table.find(local_purchase_ids, purchase_id) == nil then
            while #local_purchase_ids >= SETTINGS.PurchaseIdLog do
                table.remove(local_purchase_ids, 1)
            end
            table.insert(local_purchase_ids, purchase_id)
            task.spawn(grant_product_callback)
        end

        -- Waiting until the purchase is confirmed to be saved:

        local result = nil

        local function check_latest_meta_tags()
            local saved_purchase_ids = meta_data.MetaTagsLatest.ProfilePurchaseIds
            if saved_purchase_ids ~= nil and table.find(saved_purchase_ids, purchase_id) ~= nil then
                result = Enum.ProductPurchaseDecision.PurchaseGranted
            end
        end

        check_latest_meta_tags()

        local meta_tags_connection = profile.MetaTagsUpdated:Connect(function()
            check_latest_meta_tags()
            -- When MetaTagsUpdated fires after profile release:
            if profile:IsActive() == false and result == nil then
                result = Enum.ProductPurchaseDecision.NotProcessedYet
            end
        end)

        while result == nil do
            task.wait()
        end

        meta_tags_connection:Disconnect()

        return result

    end

end

local function GetPlayerProfileAsync(player) --> [Profile] / nil
    -- Yields until a Profile linked to a player is loaded or the player leaves
    local profile = Profiles[player]
    while profile == nil and player:IsDescendantOf(Players) == true do
        task.wait()
        profile = Profiles[player]
    end
    return profile
end

local function GrantProduct(player, product_id)
    -- We shouldn't yield during the product granting process!
    local profile = Profiles[player]
    local product_function = SETTINGS.Products[product_id]
    if product_function ~= nil then
        product_function(profile)
    else
        warn("ProductId " .. tostring(product_id) .. " has not been defined in Products table")
    end
end

local function ProcessReceipt(receipt_info)

    local player = Players:GetPlayerByUserId(receipt_info.PlayerId)

    if player == nil then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    local profile = GetPlayerProfileAsync(player)

    if profile ~= nil then

        return PurchaseIdCheckAsync(
            profile,
            receipt_info.PurchaseId,
            function()
                GrantProduct(player, receipt_info.ProductId)
            end
        )

    else
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

end

----- Initialize -----

function DataService:GetProfile(Player)
    if not Player then return nil end;
	local Profile = Profiles[Player];

	if Profile then
		return Profile;
	end;
end;

function DataService:GetPlayer(Profile)
	for Player, _profile in next, Profiles do
		if _profile == Profile then
			return Player;
		end;
	end;
end;

function DataService:KnitStart()
	
end

function DataService:KnitInit()
    for _, player in ipairs(Players:GetPlayers()) do
        coroutine.wrap(PlayerAdded)(player);
    end;

    MarketplaceService.ProcessReceipt = ProcessReceipt

    ----- Connections -----

	Players.PlayerAdded:Connect(PlayerAdded);
    Players.PlayerRemoving:Connect(function(Player)
        local PlayerProfile = Profiles[Player];

        if PlayerProfile ~= nil then
            PlayerProfile:Release();
        end;
    end);
end


return DataService;