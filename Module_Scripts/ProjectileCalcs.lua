local projectileModule = {}

local projectileProperties = {
	["Weapon"] = {
		["Dreadnought"] = "Energy"
	},
	
	
	["Type"] = {
		["Energy"] = 2
	},
	
	
	["Damage"] = {
		["Dreadnought"] = 5
	},
	
	
	["AmmoType"] = {
		["Dreadnought_Default"] = 30
	},
	
	
	["Augment"] = {
		["Stagger"] = "Stagger"
	}
}

function projectileModule.getProjectileInfo(weapon,augment,ammoType)
	if projectileProperties["Weapon"][weapon] then
		local bulletType = projectileProperties["Type"][projectileProperties["Weapon"][weapon]]
		if bulletType and projectileProperties["Damage"][weapon] and projectileProperties["Augment"][augment] and projectileProperties["AmmoType"][ammoType] then
			local totalDamage = bulletType + projectileProperties["Damage"][weapon]
			--print("Player used: " ..  weapon .. " to fire " .. bulletType .. " bullets, creating a " .. augment .. " effect.")
			return {projectileProperties["AmmoType"][ammoType],totalDamage,augment}
		end
	end
	return nil
end


return projectileModule
