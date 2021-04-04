----- Object Definitions -----
local players = game:GetService('Players')
local droneFolder = game:GetService('Workspace'):WaitForChild('Drones')
local remotes = game:GetService('ReplicatedStorage'):WaitForChild('Remotes')
local PhysicsService = game:GetService("PhysicsService")
local ignoreFolder = game.Workspace:WaitForChild("Ignore")
local miscFolder = ignoreFolder:WaitForChild("Misc")
local liveFolder = game.Workspace:WaitForChild("Live")

----- Remotes -----
local checkRemote = remotes:WaitForChild("CheckRemote")

checkRemote.OnServerEvent:Connect(function(player,checkList)
	local liveObjects = {}
	local legit = true
	for _,v in pairs(liveFolder:GetChildren()) do
		liveObjects[v.Name] = false
	end
	for _,v in pairs(checkList) do
		if liveObjects[v] ~= nil then
			liveObjects[v] = nil
		else
			legit = false
		end
	end
	for _,v in pairs(liveObjects) do
		legit = false
	end
	if not legit then
		player:Kick("Contact a moderator for appeal. ErrorCode: 5.1")
	end
end)

local whitelist = {
	["testerWhitelist"] = {
		4501781, -- Scarulus // 272613916365029376
		1216307539, -- Sensei_Kyon // 268870889775431680
		22689352, -- Maag // 301781086856413195
		2246379654, -- Instinct // 602443795254214657
		2249788156, -- Korosensei // 725429612355649626
		1729238081, -- BrickingBad // 531305563380908052
		1921414834 -- Fruitykuola // 670109896682897409
	},
	["developerWhitelist"] = {
		110027475, -- Nikola // 291945549379141632
		1467362277, -- Orange // 706183289903382591
		264097377 -- Orange // (Orange Alt)
	}
}

local function PlayerAdded(player)
	local whitelisted = false
	for i,v in pairs(whitelist) do
		for _,id in pairs(v) do
			if player.UserId == id then
				whitelisted = true
			end
		end
	end
	if not whitelisted and player.UserId > 0 then
		player:Kick("You do not have access. ErrorCode: 2")
	end
end

----- Player Added -----
game.Players.PlayerAdded:Connect(PlayerAdded)
for i,v in next,game.Players:GetPlayers() do
	PlayerAdded(v)
end
