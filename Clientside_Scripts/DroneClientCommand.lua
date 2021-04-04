local droneControl = {}

----- Objects -----
local remotes = game:GetService("ReplicatedStorage").Remotes
local runService = game:GetService("RunService")
local InputService = game:GetService("UserInputService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local terrain = game:GetService("Workspace").Terrain
local cam = game:GetService('Workspace').CurrentCamera
local tweenService = game:GetService("TweenService")
local ignoreFolder = game.Workspace:WaitForChild("Ignore")
local miscFolder = ignoreFolder:WaitForChild("Misc")
local soundService = game:GetService("SoundService")
local droneRemote = remotes.DroneRemote
local player = game.Players.LocalPlayer
local mouse = player:GetMouse()

----- ModuleInfo -----
local droneCalcs = require(replicatedStorage.Modules.DroneCalcs)

----- Default Drone Stats -----
local lev
local top
local droneRot
local elevated
local heading
local totalForce
local upForce
local downForce
local controlForce
local firing
local currentMake
local currentFunc
local cooldown
local ammo
local windowFocused
local tempOrg
local tempDir
local zoomDebounce
local mags
local reloading
local previousRicochet
local lockedVector = Vector3.new(0,0,0)

----- Exploit Prevention Stats -----
local posCheckCount = 1
local dronePosStats = {nil,nil}
local exploiterDebounce = false
local curControlling = false

----- Drone Information -----
local droneInput = {
	[Enum.KeyCode.W] = false,
	[Enum.KeyCode.S] = false,
	[Enum.KeyCode.A] = false,
	[Enum.KeyCode.D] = false,
	[Enum.KeyCode.Space] = false,
	[Enum.KeyCode.LeftShift] = false,
	[Enum.UserInputType.MouseButton1] = false,
	[Enum.UserInputType.MouseButton2] = false
}
local curPlayerDrone = nil	

-- Camera Stuff / Other --
local zoomTween
local cursorTween
local crosshairTween = {}
local crosshairConfig = {
	["CrosshairLeft"] = UDim2.new(0.5,-9,0.5,9),
	["CrosshairRight"] = UDim2.new(0.5,9,0.5,9),
	["CrosshairTop"] = UDim2.new(0.5,0,0.5,-12)
}
local bulletTxt
local droneTxt
local currentLatency = 0

----- Reset Stats -----
function resetStats()
	lev = 0
	top = false
	droneRot = CFrame.Angles(0,0,0)
	elevated = false
	heading = 0
	totalForce = CFrame.new(0,0.208,0)
	upForce = 9
	downForce = 7
	controlForce = 3
	firing = false
	currentMake = nil
	currentFunc = 0
	cooldown = false
	tempOrg = Vector3.new(0,0,0)
	tempDir = Vector3.new(0,0,0)
	zoomDebounce = false
	ammo = 15 -- NUMBER DEPENDENT ON WHICH MAG YOU CURRENTLY HAVE EQUIPPED
	mags = 15
	reloading = false
	windowFocused = true
	previousRicochet = ""
	lockedVector = Vector3.new(0,0,0)
end

----- Elevation Loop -----
function levitation()
	while curPlayerDrone ~= nil do
		wait()
		if not top then
			lev = lev + 1
		end
		if lev == 11 then
			top = true
		elseif lev == -10 then
			top = false
		end
		if top then
			lev = lev - 1
		end
	end
end

----- Adding Drone -----
function droneControl.addDrone(droneName)
	if curPlayerDrone == nil then
		resetStats()
		curPlayerDrone = game.Workspace.Drones:FindFirstChild(droneName)
		bulletTxt = player.PlayerGui.LeftSideUI.MainFrame.LoadoutFrame.LoadoutBackground.Bullets
		droneTxt = player.PlayerGui.LeftSideUI.MainFrame.LoadoutFrame.LoadoutBackground.DroneName
	end
end

-- Window Focus Check --
function droneControl.windowFocusCheck(val)
	windowFocused = val
end

function droneControl.removeCurDrone(defaultZoom)
	if curPlayerDrone ~= nil and cooldown == false then
		local droneName = curPlayerDrone.Name
		curPlayerDrone = nil
		curControlling = false
		droneRemote:FireServer("Remove",droneName)
		dronePosStats = {nil,nil}
		for i,v in pairs(droneInput) do
			droneInput[i] = false
		end
		cam.CameraType = "Custom"
		cam.FieldOfView = 80
		zoomTween = nil
		cursorTween = nil
		tweenCrosshairSize(UDim2.new(0,0,0,0), false)
		
		if player.Character then
			local char = player.Character
			if char:FindFirstChild("Humanoid") then
				local hum = char:FindFirstChild("Humanoid")
				hum.WalkSpeed = 16
				hum.JumpPower = 50
				hum.AutoRotate = true
				cam.CameraSubject = hum
				print(cam.CameraSubject)
				wait()
				player.CameraMinZoomDistance = defaultZoom
				player.CameraMaxZoomDistance = defaultZoom
			end
		end 
		return true
	end
	return false
end

----- Camera Effects -----
function zoomInOut(value)
	local chUI = player.PlayerGui.FullscreenUI.MainFrame.Crosshair
	if value then
		if zoomTween ~= nil and crosshairTween ~= nil and cursorTween ~= nil then
			zoomTween:Pause()
			cursorTween:Pause()
			for _,v in pairs(crosshairTween) do
				v:Pause()
			end
		end
		zoomTween = tweenService:Create(cam, TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.In), {FieldOfView = 45}):Play()
		cursorTween = tweenService:Create(chUI.Cursor, TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.In), {Size = UDim2.new(1,0,1,0), Rotation = 0, ImageTransparency = 0}):Play()
		for _,v in pairs(chUI:GetChildren()) do
			if v.Name ~= "Cursor" and v.Name ~= "SuccessHit" then
				local tempTween = tweenService:Create(v, TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.In), {Position = UDim2.new(0.5,0,0.5,0), ImageTransparency = 0})
				table.insert(crosshairTween, tempTween)
				tempTween:Play()
			end
		end
	else
		if zoomTween ~= nil and crosshairTween ~= nil then
			zoomTween:Pause()
			cursorTween:Pause()
			for _,v in pairs(crosshairTween) do
				v:Pause()
			end
		end
		zoomTween = tweenService:Create(cam, TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out), {FieldOfView = 80}):Play()
		cursorTween = tweenService:Create(chUI.Cursor, TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.In), {Size = UDim2.new(1.2,0,1.2,0), Rotation = -90, ImageTransparency = 0.5}):Play()
		for _,v in pairs(chUI:GetChildren()) do
			if v.Name ~= "Cursor" and v.Name ~= "SuccessHit" then	
				local tempTween = tweenService:Create(v, TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.In), {Position = crosshairConfig[v.Name], ImageTransparency = 0.5})
				table.insert(crosshairTween, tempTween)
				tempTween:Play()
			end
		end
	end
end

function tweenCrosshairSize(newSize, val)
	if crosshairTween ~= nil then
		for _,v in pairs(crosshairTween) do
			v:Pause()
		end
	end
	crosshairTween = {}
	local chUI = player.PlayerGui.FullscreenUI.MainFrame.Crosshair
	if val then
		player.PlayerGui.FullscreenUI.MainFrame.Crosshair.Visible = true
	end
	local tempTween = tweenService:Create(chUI, TweenInfo.new(0.5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out), {Size = newSize})
	table.insert(crosshairTween, tempTween)
	tempTween:Play()
	if not val then
		spawn(function()
			wait(0.5)
			if not curControlling then
				player.PlayerGui.FullscreenUI.MainFrame.Crosshair.Visible = false
			end
		end)
	end
end

----- Drone Raycast Check -----
function droneControl.checkValidation(checkOrg,checkDir)
	if not tempOrg == checkOrg or not checkDir == tempDir then
		game.Players.LocalPlayer:Kick("Contact a moderator for appeal. ErrorCode: 4.5")
	end
end

----- Drone Input Begin -----
function droneControl.inputStart(key, processed, mouse2)
	if droneInput[key] ~= nil or droneInput[mouse2] ~= nil then
		if curPlayerDrone ~= nil and curControlling == true then
			if mouse2 == Enum.UserInputType.MouseButton1 and droneInput[mouse2] == false
				and not cooldown and windowFocused and not reloading and math.floor(mouse.X) == math.floor(player.PlayerGui.FullscreenUI.MainFrame.AbsoluteSize.X/2) then
				droneInput[mouse2] = true
				currentFunc += 1
				if currentMake == "Dreadnought" then
					local side = true
					local tempNum = currentFunc
					while droneInput[mouse2] == true and ammo > 0 and mags > 0 do
						ammo -= 1
						bulletTxt.Text = "Bullets: " .. ammo
						side = not side
						
						dreadnoughtDefault(mouse2, tempNum, side, mouse.Hit.p)
						if ammo == 0 and mags > 1 then
							reloading = true
							mags -= 1
							bulletTxt.Text = "Reloading..."
							soundService:PlayLocalSound(replicatedStorage.SFX.SteamRelease)
							if curPlayerDrone then
								curPlayerDrone.Effect.LH.SteamPart.Steam.Enabled = true
								curPlayerDrone.Effect.RH.SteamPart.Steam.Enabled = true
							end
							wait(3)
							if curPlayerDrone then
								curPlayerDrone.Effect.LH.SteamPart.Steam.Enabled = false
								curPlayerDrone.Effect.RH.SteamPart.Steam.Enabled = false
							end
							ammo = 30
							bulletTxt.Text = "Bullets: " .. ammo
							reloading = false
						end
					end
				end
			elseif droneInput[key] == false then
				if not processed then
					if key == Enum.KeyCode.W then
						totalForce = totalForce * CFrame.new(0,0,upForce)
					end
					if key == Enum.KeyCode.A then
						totalForce = totalForce * CFrame.new(upForce,0,0)
						droneRot = droneRot * CFrame.Angles(0,0,math.rad(-20))
					end
					if key == Enum.KeyCode.S then
						totalForce = totalForce * CFrame.new(0,0,-upForce)
					end
					if key == Enum.KeyCode.D then
						totalForce = totalForce * CFrame.new(-upForce,0,0)
						droneRot = droneRot * CFrame.Angles(0,0,math.rad(20))
					end
					if key == Enum.KeyCode.Space then
						totalForce = totalForce * CFrame.new(0,downForce,0)
					end
					if key == Enum.KeyCode.LeftShift then
						totalForce = totalForce * CFrame.new(0,-downForce,0)
						droneInput[key] = true
					end
					if droneInput[key] ~= nil then
						droneInput[key] = true
					end
				end
			elseif mouse2 == Enum.UserInputType.MouseButton2 and not zoomDebounce then
				zoomDebounce = true
				if droneInput[mouse2] == true then
					droneInput[mouse2] = false
					zoomInOut(false)
				else
					droneInput[mouse2] = true
					zoomInOut(true)
				end
				wait(0.25)
				zoomDebounce = false
			end
		end
	end
end

----- Drone Input End -----
function droneControl.inputEnd(key, mouse2)
	if droneInput[key] ~= nil or droneInput[mouse2] ~= nil then
		if curPlayerDrone ~= nil and curControlling == true then
			if droneInput[key] == true or droneInput[mouse2] == true then
				if key == Enum.KeyCode.W then
					totalForce = totalForce * CFrame.new(0,0,-upForce)
				end
				if key == Enum.KeyCode.A then
					totalForce = totalForce * CFrame.new(-upForce,0,0)
					droneRot = droneRot * CFrame.Angles(0,0,math.rad(20))
				end
				if key == Enum.KeyCode.S then
					totalForce = totalForce * CFrame.new(0,0,upForce)
				end
				if key == Enum.KeyCode.D then
					totalForce = totalForce * CFrame.new(upForce,0,0)
					droneRot = droneRot * CFrame.Angles(0,0,math.rad(-20))
				end
				if key == Enum.KeyCode.Space then
					totalForce = totalForce * CFrame.new(0,-downForce,0)
				end
				if key == Enum.KeyCode.LeftShift then
					totalForce = totalForce * CFrame.new(0,downForce,0)
				end
				if droneInput[key] ~= nil then
					droneInput[key] = false
				end

				if mouse2 == Enum.UserInputType.MouseButton1 and droneInput[mouse2] == true then
					currentFunc += 1
					droneInput[mouse2] = false
					firing = false
				end
			end
		end
	end
end

----- Local Drone Movement -----
local function checkExploit()
	if dronePosStats[1] ~= nil and dronePosStats[2] ~= nil then
		if (dronePosStats[2]-dronePosStats[1]).Magnitude > 25 then
			return true
		else
			return false
		end
	end
end

local function droneMovement(bPos, bGyro, relPartCF, changeCF, heading)
	if not exploiterDebounce then
		local exploiter
		if posCheckCount%21 == 0 then
			dronePosStats[2] = bPos.Position
			exploiter = checkExploit()
			posCheckCount = 1
		elseif posCheckCount%11 == 0 then
			dronePosStats[1] = bPos.Position
			posCheckCount += 1
		else
			posCheckCount += 1
		end
		if exploiter == nil or exploiter == false then
			local droneCF = CFrame.new(bPos.Position) * (bGyro.CFrame - bGyro.CFrame.p)
			droneCF = relPartCF:ToWorldSpace(changeCF)
			if bPos.Position.Y > 50 then
				bPos.Position = Vector3.new(droneCF.p.X,50,droneCF.p.Z) + Vector3.new(0,lev/10,0)
			else
				if (droneInput[Enum.KeyCode.A] or droneInput[Enum.KeyCode.D])
					and not (droneInput[Enum.KeyCode.Space] or droneInput[Enum.KeyCode.LeftShift]) then
					local lockedY = lockedVector.Y
					bPos.Position = Vector3.new(droneCF.p.X,lockedY,droneCF.p.Z) + Vector3.new(0,lev/10,0)
				else
					bPos.Position = droneCF.p + Vector3.new(0,lev/10,0)
					lockedVector = bPos.Position
				end
			end

			bGyro.CFrame = CFrame.Angles(0, heading + math.rad(180), 0) * droneRot
		else
			exploiterDebounce = true
			spawn(function()
				for i = 1,180 do
					runService.Heartbeat:Wait()
					bPos.Position = dronePosStats[1]
					bPos.D = math.huge
				end
				exploiterDebounce = false
				bPos.D = 1250
			end)
			player:Kick("Contact a moderator for appeal. ErrorCode: 1")
		end
	end
end


----- Drone Local Effects -----
local makeEffect = {
	['Dreadnought'] = {0, 0.2}
}
local function droneEffects(make,drone)
	if make == 'Dreadnought' then
		droneCalcs.Create("Dreadnought",curPlayerDrone)
	end
end

----- Controlling Drone -----
function droneControl.control(hum, player)
	if curPlayerDrone ~= nil and not curControlling then
		curControlling = true
		
		-- Reset Stats --
		resetStats(true)
		currentMake = curPlayerDrone.Properties.Make.Value
		
		-- Manipulating Player --
		local bPos = curPlayerDrone.PrimaryPart.BodyPosition
		local bGyro = curPlayerDrone.PrimaryPart.BodyGyro
		hum.WalkSpeed = 0
		hum.JumpPower = 0
		hum.AutoRotate = false
		cam.CameraSubject = curPlayerDrone.PrimaryPart
		spawn(function()
			wait()
			player.CameraMinZoomDistance = 4
			player.CameraMaxZoomDistance = 4
		end)
		
		tweenCrosshairSize(UDim2.new(0,95,0,95),true)
		local chUI = player.PlayerGui.FullscreenUI.MainFrame.Crosshair
		chUI.Cursor.Size =  UDim2.new(1.2,0,1.2,0)
		chUI.Cursor.Rotation = -90
		chUI.Cursor.ImageTransparency = 0.5
		for _,v in pairs(chUI:GetChildren()) do
			if v.Name ~= "Cursor" and v.Name ~= "SuccessHit" then
				v.Position = crosshairConfig[v.Name]
				v.ImageTransparency = 0.5
			end
		end
		
		-- Initial Client Setup --
		bulletTxt.Text = "Bullets: " .. ammo
		droneTxt.Text = "Drone: " .. currentMake
		
		spawn(function()
			levitation()
		end)

		spawn(function()
			while curPlayerDrone ~= nil do
				game:GetService('RunService').Heartbeat:wait()
				local mouseCFrame = mouse.Hit
				local _, _, _, _, _, m02, _, _, _, _, _, m22 = mouseCFrame:components()
				heading = math.atan2(m02, m22)
				if curPlayerDrone ~= nil then
					-- Move Drone --
					droneMovement(bPos, bGyro, curPlayerDrone.PrimaryPart.CFrame, totalForce, heading)
					if makeEffect[currentMake] ~= nil then
						droneEffects(currentMake, curPlayerDrone)
					end
				end
			end
		end)
		return curPlayerDrone.Name
	end
	return nil
end

----- DRONE ACTIONS -----
----- DREADNOUGHT -----
function dreadnoughtDefault(mouse2, tempNum, side, mouseHit)
	if droneInput[mouse2] == true and tempNum == currentFunc and curPlayerDrone then
		cooldown = true
		local barrel
		local sideCheck = {
			[false] = {curPlayerDrone.Effect.RH.GunPart.rightBarrel},
			[true] = {curPlayerDrone.Effect.LH.GunPart.leftBarrel}
		}
		
		barrel = sideCheck[side][1]
		local ray = cam:ScreenPointToRay(player.PlayerGui.FullscreenUI.MainFrame.AbsoluteSize.X/2, mouse.Y, 4.5)
		local checkRay = Ray.new(barrel.WorldPosition,CFrame.new(mouseHit, barrel.WorldPosition).LookVector*-1)
		
		tempOrg, tempDir = ray.Origin, ray.Direction
		local origin = Vector3.new()
		origin = barrel.WorldPosition
		local diff = (origin - mouseHit).Magnitude
		if diff > 350 then
			diff = 350
		end

		table.insert(sideCheck[false],CFrame.new(origin, mouseHit).rightVector * 4)
		table.insert(sideCheck[true],-(CFrame.new(origin, mouseHit).rightVector * 4))

		local shellObj = Instance.new("Part",miscFolder)
		--local bullet = replicatedStorage.VFX.EnergyBullet:Clone()
		local ray1 = Ray.new(ray.Origin, ray.Direction * 350)
		local ray2 = Ray.new(checkRay.Origin, checkRay.Direction * 350)
		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = {miscFolder}
		raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
		--local camRay = workspace:Raycast(ray1.Origin, ray1.Direction, raycastParams)
		local hitPart, hitPosition, normal = workspace:FindPartOnRay(ray2, miscFolder)
		local hitPart2, hitPosition2, normal2 = workspace:FindPartOnRay(ray1, miscFolder)
		
		shellObj.Size = Vector3.new(0.085, 0.085, 0.5)
		shellObj.Color = Color3.fromRGB(213, 115, 61)
		shellObj.Material = Enum.Material.Neon
		shellObj.CFrame = CFrame.new(origin, mouseHit) * CFrame.new(0, 0, -3)
		shellObj.Velocity = sideCheck[side][2]
		--[[bullet.Parent = cam
		bullet.CFrame = CFrame.new(origin, mouseHit)--CFrame.new(mouseHit)
		bullet.BV.Velocity = CFrame.new(origin, mouseHit).LookVector * 200]]
		
		local hit = false
		local shell = replicatedStorage.SFX.BulletShellEject:Clone()
		shell.Parent = shellObj
		shellObj.Touched:Connect(function(part)
			if not hit then --and part ~= bullet then
				hit = true
				soundService:PlayLocalSound(shell)
				wait(0.5)
				shellObj:Destroy()
			end
		end)
		
		-- Effects --
		soundService:PlayLocalSound(replicatedStorage.SFX.HeavyBullet)
		if hitPart and player.Character and not hitPart:IsDescendantOf(player.Character) then
			local function setparticles(model,value)
				for _,v in pairs(model:GetChildren()) do
					if v:IsA("ParticleEmitter") then
						v.Enabled = value
					end
				end
			end
			local hum1 = hitPart.Parent:FindFirstChild("Humanoid")
			local armorCheck = hitPart:FindFirstAncestor("BodyArmor")
			local accessoryCheck = hitPart:FindFirstAncestorOfClass("Accessory")
			
			if (not hum1 and not armorCheck and not accessoryCheck) or (hitPart2 ~= hitPart) then -- kinda broken, shows blood and durt when shooting my own character, fix this...
				droneRemote:FireServer("FireProjectile",curPlayerDrone.Name,{1,nil,nil,nil,nil,hitPosition})
				local impact = replicatedStorage.VFX.Impact:Clone()
				local hole = replicatedStorage.VFX.Hole:Clone()
				local newRicochet = previousRicochet
				repeat
					newRicochet = "Ricochet_" .. math.random(1,5)
				until newRicochet ~= previousRicochet
				local ricochet = replicatedStorage.SFX:FindFirstChild(newRicochet):Clone()
				previousRicochet = newRicochet
				ricochet.Parent = impact
				hole.Parent = miscFolder
				impact.Parent = miscFolder
				
				if not hum1 then
					--impact.CFrame = CFrame.new(hitPosition,barrel.WorldPosition)
					impact.CFrame = CFrame.new(hitPosition, hitPosition + normal)
					hole.CFrame = CFrame.new(hitPosition, hitPosition + normal)
				else
					--impact.CFrame = CFrame.new(hitPosition2,barrel.WorldPosition)
					impact.CFrame = CFrame.new(hitPosition2, hitPosition2 + normal)
					hole.CFrame = CFrame.new(hitPosition2, hitPosition2 + normal)
				end
				
				setparticles(impact,true)
				spawn(function()
					wait((origin - mouseHit).Magnitude/525)
					soundService:PlayLocalSound(ricochet)
					wait(0.2)
					setparticles(impact,false)
					wait(2)
					impact:Destroy()
					wait(3)
					hole:Destroy()
				end)
			elseif hitPart2 and hitPart2 == hitPart then
				local enemyPlr
				local limb = ""
				if not enemyPlr then
					if hitPart:FindFirstAncestor("BodyArmor") then
						enemyPlr = hitPart:FindFirstAncestor("BodyArmor").Parent.Name
					elseif hitPart:FindFirstAncestorOfClass("Accessory") then
						enemyPlr = hitPart:FindFirstAncestorOfClass("Accessory").Parent.Name
					else
						enemyPlr = hitPart.Parent.Name
					end
				end
				local succHitUI = player.PlayerGui.FullscreenUI.MainFrame.Crosshair.SuccessHit
				if hitPart.Name == "Head" or hitPart:FindFirstAncestorOfClass("Accessory") then
					limb = "head"
					local shot = replicatedStorage.SFX:FindFirstChild("SuccessShot"):Clone()
					soundService:PlayLocalSound(shot)
					succHitUI.ImageColor3 = Color3.fromRGB(240,39,43)
				else
					limb = "limb"
				end
				droneRemote:FireServer("FireProjectile",curPlayerDrone.Name,{1,enemyPlr,limb,checkRay,barrel.Name,hitPosition})

				local blood = replicatedStorage.VFX.Blood:Clone()
				blood.Parent = miscFolder
				blood.CFrame = CFrame.new(hitPosition,barrel.WorldPosition)
				blood.Anchored = false
				local wc = Instance.new("WeldConstraint")
				wc.Parent = hitPart
				wc.Part0 = hitPart
				wc.Part1 = blood
				succHitUI.Visible = true
				setparticles(blood,true)
				spawn(function()
					wait(0.2)
					setparticles(blood,false)
					succHitUI.Visible = false
					succHitUI.ImageColor3 = Color3.fromRGB(255,255,255)
					wait(0.8)
					blood:Destroy()
					wc:Destroy()
				end)
			end
		else
			droneRemote:FireServer("FireProjectile",curPlayerDrone.Name,{1})
		end
		
		totalForce = totalForce * CFrame.new(0,0,-3)
		barrel.Parent.Smoke.Enabled = true
		barrel.Flash.Enabled = true
		curPlayerDrone.PrimaryPart.BulletLight.Enabled = true
		
		local sign = math.random(-1,1)*0.04
		local sign_2 = math.random(-1,1)*0.04
		if droneInput[Enum.UserInputType.MouseButton2] then
			cam.CFrame = cam.CFrame * CFrame.Angles(math.rad(1),sign/4,sign_2/4) -- Recoil
		else
			cam.CFrame = cam.CFrame * CFrame.Angles(math.rad(1.3),sign,sign_2) -- Recoil
		end
		
		wait(0.03)
		barrel.Flash.Enabled = false
		wait(0.02)
		barrel.Parent.Smoke.Enabled = false
		curPlayerDrone.PrimaryPart.BulletLight.Enabled = false
		wait(0.1)
		totalForce = totalForce * CFrame.new(0,0,3)
		
		spawn(function()
			wait(2)
			if shellObj.Parent then
				shellObj:Destroy()
			end
		end)
		wait(0.1)
		cooldown = false
	end
end

return droneControl