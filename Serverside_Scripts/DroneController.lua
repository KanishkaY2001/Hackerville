----- Object Definitions -----
local players = game:GetService('Players')
local droneFolder = game:GetService('Workspace'):WaitForChild('Drones')
local remotes = game:GetService('ReplicatedStorage'):WaitForChild('Remotes')
local PhysicsService = game:GetService("PhysicsService")
local ignoreFolder = game.Workspace:WaitForChild("Ignore")
local miscFolder = ignoreFolder:WaitForChild("Misc")
local liveFolder = game.Workspace:WaitForChild("Live")

----- Remotes -----
local droneRemote = remotes:WaitForChild("DroneRemote")
local locationList = {}
local max = 10 -- Maximum distance between hit part and actual part for hit detection

----- ModuleInfo -----
local weldEffect = require(script:WaitForChild('DroneWelding'))
local droneCalcs = require(game:GetService("ReplicatedStorage").Modules.DroneCalcs)
local playerDroneData = require(script:WaitForChild('PlayerDroneData'))
local playerManipulate = require(script.Parent:WaitForChild("Modules"):WaitForChild("PlayerManipulation"))

----- Collision Data -----
_G.charCollisionList = "Character"
_G.droneCollisionList = "Drone"
PhysicsService:CreateCollisionGroup(_G.charCollisionList)
PhysicsService:CreateCollisionGroup(_G.droneCollisionList)

----- Drones Data -----
local playerDrones = {}
local playerCooldowns = {}
local allDroneMakes = {}
for _,drone in pairs(game:GetService('ServerStorage').Drones:GetChildren()) do
	if drone:FindFirstChild('Properties') and drone:FindFirstChild('Properties'):FindFirstChild('Make') ~= nil then
		table.insert(allDroneMakes, {drone:FindFirstChild('Properties'):FindFirstChild('Make').Value, drone})
	end
end

function anchor(model,val)
	for _,p in pairs(model:GetChildren()) do
		if p:IsA('Part') or p:IsA('MeshPart') or p:IsA('UnionOperation') then
			p.Anchored = val
		end
	end
end

function droneNamer(droneName, userId)
	local letterList = {"A","B","C","D","E","F","G","H","I","J","K","L","M","Q","R","S","T","X","Y","Z"}
	local finalName = ""
	finalName = finalName .. userId .. droneName
	for i = 1,8 do
		if math.random() > 0.5 then
			finalName = finalName .. letterList[math.random(1,#letterList)]
		else
			finalName = finalName .. math.random(0,9)
		end
	end
	return finalName
end

function setCollisions(drone)
	for _,v in pairs(drone:GetDescendants()) do
		if v:IsA("BasePart") then
			PhysicsService:SetPartCollisionGroup(v, _G.droneCollisionList)
		end
	end
	PhysicsService:CollisionGroupSetCollidable(_G.charCollisionList, _G.droneCollisionList, false)
end

droneRemote.OnServerEvent:Connect(function(player,command,make,targetDrone)	
	if command == "Remove" and droneFolder:FindFirstChild(make) and playerDrones[player.Name] == make then
		droneFolder:FindFirstChild(make):Destroy()
		playerDrones[player.Name] = nil
		playerDroneData.removeDroneData(player.Name)
		return
	elseif command == "FireProjectile" and droneFolder:FindFirstChild(make) and playerDrones[player.Name] == make then
		local drone = droneFolder:FindFirstChild(make)
		local droneName = drone.Properties.Make.Value or nil
		local otherInfo = targetDrone
		if playerCooldowns[player.Name] == nil and droneName and otherInfo and otherInfo[1] then
			playerCooldowns[player.Name] = otherInfo[1]
			local plrName = otherInfo[2]
			local limb = otherInfo[3]
			local localRay = otherInfo[4]
			local bulletOrg = otherInfo[5]
			local barrel
			if bulletOrg then
				barrel = drone:FindFirstChild(bulletOrg,true)
			end
			local hitPos = otherInfo[6]
			local checkRay
			local effects = { -- Make this and other things not specific to dreadnought
				["Sounds"] = {
					["HeavyBullet"] = drone.PrimaryPart.Position
				}
			}
			
			if barrel and plrName and limb and localRay and hitPos then
				----- Creating Part for Ray -----
				local model = Instance.new("Model")
				local rayPart = createPart("rayPart",Vector3.new(1,1,1),CFrame.new(hitPos),model)
				local rayPos = rayPart.Position
				
				--local rayPos = rayPart.Position
				model.Parent = miscFolder
				
				----- Creating Ray from weapon barrel -----
				checkRay = Ray.new(barrel.WorldPosition,otherInfo[4].Direction * 350)
				local plrModel = liveFolder:FindFirstChild(plrName)
				local raycastParams = RaycastParams.new()
				raycastParams.FilterDescendantsInstances = {drone, plrModel}
				raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
				local raycheckResult = workspace:Raycast(checkRay.Origin,checkRay.Direction, raycastParams)
				model:Destroy()
				local hitSucc = raycheckResult and raycheckResult.Instance.Name == "rayPart" and plrModel
				local tempMax = max
				----- Check for hit detection and Damage -----
				if hitSucc then
					local tempMin = tempMax
					for _,v in pairs(plrModel:GetChildren()) do
						if v:IsA("BasePart") then
							local mag = (v.Position-rayPos).Magnitude
							if mag < tempMax then
								tempMax = mag
							else
								tempMin = mag
							end
						end
					end
					if tempMax < max then
						local plrHum = plrModel:FindFirstChild("Humanoid")
						local ownHum = player.Character:FindFirstChild("Humanoid")
						local dmg =  playerDroneData.getDamage(player.Name,droneName,otherInfo[1])
						if limb == "head" then
							dmg *= 1.5
						end
						playerManipulate.damagePlayer(ownHum,plrHum,dmg,true)
						print("Hit Target!!!___________________________________________________________________________________________________________")
					else
						print(tempMin)
					end
				end
			elseif not otherInfo[6] then
				droneRemote:FireAllClients("FiredBullet",effects,player.Name,nil)
			end
			if checkRay then
				if game.Players:FindFirstChild(plrName) then
					effects["Sounds"]["GunWound"] = 0
				end
				droneRemote:FireAllClients("FiredBullet",effects,player.Name,{checkRay.Origin,checkRay.Direction})
			else
				effects["Sounds"]["Ricochet_" .. math.random(1,5)] = hitPos
				droneRemote:FireAllClients("FiredBullet",effects,player.Name,nil)
			end
			playerCooldowns[player.Name] = nil
		end
	elseif command == "DroneEffect" and droneFolder:FindFirstChild(make) and playerDrones[player.Name] == make then
		droneCalcs.Create(make,targetDrone)
		return
	elseif command == "Add" and playerDrones[player.Name] == nil then
		for _,existingMake in pairs(allDroneMakes) do
			if make == existingMake[1] then
				local hrp = player.Character:WaitForChild('HumanoidRootPart')
				
				----- Spawn Drone -----
				local drone = existingMake[2]:Clone()
				drone.Name = droneNamer(make, player.UserId)
				playerDrones[player.Name] = drone.Name
				local owner = drone:WaitForChild('Properties'):WaitForChild('Owner')
				owner.Value = player.Name
				local droneType = drone:WaitForChild('Properties'):WaitForChild('Type')
				drone:SetPrimaryPartCFrame(hrp.CFrame:ToWorldSpace(CFrame.new(0,0,-5)) * CFrame.Angles(0,math.rad(180),0))
				local body = drone.PrimaryPart

				----- Create Movers -----	
				local bPos = Instance.new('BodyPosition')
				local bGyro = Instance.new('BodyGyro')
				bGyro.D, bGyro.P = 500, 5000
				local droneCF = CFrame.new(bPos.Position) * (bGyro.CFrame - bGyro.CFrame.p)
				droneCF = hrp.CFrame:ToWorldSpace(CFrame.new(0,0,-5))
				bPos.Position = droneCF.p
				bGyro.MaxTorque = Vector3.new(math.huge,math.huge,math.huge)
				bGyro.CFrame = hrp.CFrame
				bPos.Parent = body
				bGyro.Parent = body

				----- Weld Drone -----
				for _,part in pairs(drone:GetChildren()) do
					if part ~= body and part:IsA('BasePart') then
						local m6d = Instance.new('Motor6D')
						m6d.Parent = body
						m6d.C0 = part.CFrame:Inverse()* body.CFrame
						m6d.Part0 = part
						m6d.Part1 = body
					end
				end

				----- Initializing Drone -----
				if drone:FindFirstChild('Effect') then
					weldEffect[make](player,hrp,drone,make)
				end
				drone.Parent = droneFolder
				setCollisions(drone)
				droneRemote:FireClient(player,"Add",drone.Name)
				playerDroneData.addDroneData(player.Name,make,15) -- NUMBER DEPENDENT ON WHICH MAG YOU CURRENTLY HAVE EQUIPPED
				body:SetNetworkOwner(player)
				return
			end
		end
	end
end)

----- Latency Checking -----
function addToEnd(plrName,cf,cap)
	if not locationList[plrName] then
		--local mod = charModel(cf,game.Workspace)
		locationList[plrName] = {
			false,
			{cf},
			--{mod}
		}
	else
		if #locationList[plrName][2] == cap then
			table.remove(locationList[plrName][2],1)
			--locationList[plrName][3][1]:Destroy()
			--table.remove(locationList[plrName][3],1)
		end
		table.insert(locationList[plrName][2],cf)
		--local mod = charModel(cf,game.Workspace)
		--table.insert(locationList[plrName][3],mod)
	end
end

----- Creating Replication Model -----
function createPart(name,size,cf,parent)
	local p = Instance.new("Part",parent)
	p.CFrame = cf
	p.Name = name
	p.Size = size
	p.Anchored = true
	p.CanCollide = false
	p.Transparency = 1
	return p
end

----- Character Added -----
function CharacterAdded(char)
	local plrName = char.Name
	local hum = char:WaitForChild("Humanoid")
	local hrp = char:WaitForChild("HumanoidRootPart")
	addToEnd(plrName,hrp.CFrame,20)
	locationList[plrName][1] = true

	for _,v in pairs(char:GetDescendants()) do
		if v:IsA("BasePart") then
			PhysicsService:SetPartCollisionGroup(v, _G.charCollisionList)
		end
	end
	
	hum.Died:Connect(function()
		locationList[plrName][1] = false
		for i = 1,#locationList[plrName][2] do
			table.remove(locationList[plrName][2],1)
		end
	end)
	
	repeat
		wait()
	until char.Parent == game.Workspace
	char.Parent = liveFolder
	
end

local function PlayerAdded(player)
	player.CharacterAdded:Connect(CharacterAdded)
	local char = player.Character
	if char then
		CharacterAdded(char)
	end
end

----- Player Added -----
players.PlayerAdded:Connect(PlayerAdded)
for i,v in next,game.Players:GetPlayers() do
	PlayerAdded(v)
end