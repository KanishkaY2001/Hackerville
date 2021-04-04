local playerData = {}

local droneData = {
	["Augment"] = {
		["Dreadnought"] = "Stagger"
	},
	
	["AmmoType"] = {
		["Dreadnought"] = {30}
	},
	
	["DamageList"] = {
		["Dreadnought"] = {15}
	},
	
	["Cooldown"] = {
		["Dreadnought"] = {0.25}
	},
	
	["ReloadCooldown"] = {
		["Dreadnought"] = {3}
	}
}
local playerDroneData = {
	-- ["PlayerName"] = {"Augment", "AmmoType", CurrentAmmo, magCount}
}

function playerData.addDroneData(playerName,currentDrone,currentAmmo)
	if droneData["AmmoType"][currentDrone] and droneData["Augment"][currentDrone] then
		playerDroneData[playerName] = {droneData["Augment"][currentDrone],droneData["AmmoType"][currentDrone]}
	end
end

function playerData.removeDroneData(playerName)
	playerDroneData[playerName] = nil
end

function playerData.getDamage(playerName,make,num)
	if playerDroneData[playerName] then
		return droneData["DamageList"][make][num]
	end
	return 0
end

return playerData
