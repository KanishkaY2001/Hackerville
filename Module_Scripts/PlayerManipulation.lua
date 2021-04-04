local playerManipulate = {}

function playerManipulate.damagePlayer(ownHumanoid,enemyHumanoid,dmg,ignoreLocalPlayer)
	if not ignoreLocalPlayer or (ignoreLocalPlayer and enemyHumanoid ~= ownHumanoid) then
		enemyHumanoid.Health -= dmg
	end
end

return playerManipulate
