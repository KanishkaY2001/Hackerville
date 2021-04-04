local weldEffect = {}

----- ModuleInfo -----
local droneCalcs = require(game:GetService("ReplicatedStorage").Modules.DroneCalcs)

----- Vespula (Cleric) -----
function weldEffect.Vespula(player,hrp,drone,dType)
	local sign = -1
	local sign2 = -1
	for _,folder in pairs(drone.Effect:GetChildren()) do
		local joint = folder.Joint
		local m6d = Instance.new('Motor6D')
		m6d.Parent = drone.PrimaryPart
		m6d.C0 = drone.PrimaryPart.CFrame:Inverse()* joint.CFrame
		m6d.Part0 = drone.PrimaryPart
		m6d.Part1 = joint
		for i,part in pairs(folder:GetChildren()) do
			if part ~= joint and part:IsA('Part') or part:IsA('MeshPart') or part:IsA('UnionOperation') then
				local m6d = Instance.new('Motor6D')
				m6d.Name = 'motor' .. i
				m6d.Parent = joint
				m6d.C0 = part.CFrame:Inverse()* joint.CFrame
				m6d.Part0 = part
				m6d.Part1 = joint
			end
		end
	end
	
	spawn(function()
		while drone ~= nil do
			wait()
			sign = sign *-1
			wait()
			if drone ~= nil then
				droneCalcs.Create("Vespula",drone,sign)
			end
		end
	end)
	
end

----- Dreadnought (Assault) -----
function weldEffect.Dreadnought(player,hrp,drone,make)
	for _,folder in pairs(drone.Effect:GetChildren()) do
		local joint = folder.Joint
		local m6d = Instance.new('Motor6D')
		m6d.Parent = drone.PrimaryPart
		m6d.C0 = drone.PrimaryPart.CFrame:Inverse()* joint.CFrame
		m6d.Part0 = drone.PrimaryPart
		m6d.Part1 = joint
		for i,part in pairs(folder:GetChildren()) do
			if part ~= joint and part:IsA('Part') or part:IsA('MeshPart') or part:IsA('UnionOperation') then
				local m6d = Instance.new('Motor6D')
				m6d.Name = 'motor' .. i
				m6d.Parent = joint
				m6d.C0 = part.CFrame:Inverse()* joint.CFrame
				m6d.Part0 = part
				m6d.Part1 = joint
			end
		end
	end
end

return weldEffect


