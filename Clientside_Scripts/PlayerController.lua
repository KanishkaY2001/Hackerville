----- Object Definitions -----
local players = game:GetService('Players')
local replicatedStorage = game:GetService("ReplicatedStorage")
local uis = game:GetService('UserInputService')
local InputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local remotes = replicatedStorage.Remotes
local cam = game:GetService('Workspace').CurrentCamera
local mouse = game.Players.LocalPlayer:GetMouse()
local userSettings = UserSettings():GetService("UserGameSettings")
local imagesFolder = replicatedStorage:WaitForChild("VFX"):WaitForChild("Images")
local ignoreFolder = game.Workspace:WaitForChild("Ignore")
local miscFolder = ignoreFolder:WaitForChild("Misc")
local soundService = game:GetService("SoundService")
local liveFolder = game.Workspace:WaitForChild("Live")

----- Other Variables -----
-- Lists/Dictionaries --
local functions = {}
-- Debounces --
local specialKeyDebounce = false
-- Player Stuff --
local defMouseIcon = imagesFolder:WaitForChild("CursorDefault").Image--"https://www.roblox.com/asset/?id=6160375635"
local defaultZoom = 10
local mouseLockDist = 2.5
local droneEquipped = false
local zoomExploitCount = 1
local windowFocused = true
local lockCenter = false
local liveCount = 0
local charLoaded = false
--local tickDebounce = false
--local sentTick = 0
--local receivedTick = 0

----- Remotes -----
local droneRemote = remotes:WaitForChild("DroneRemote")
local checkRemote = remotes:WaitForChild("CheckRemote")

----- Module Information -----
local droneControlModule = require(script:WaitForChild("DroneClientCommand"))

----- Death Reset Function -----
function playerReset()
	for _,v in pairs(functions) do
		if v ~= nil then
		end
	end
	mouseLockDist = 2.5
	droneEquipped = false
	charLoaded = false
end

----- Ray Casting Function -----
function castRay(origin,direct,filter,filtType)
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = filter
	params.FilterType = filtType
	local rayResult = workspace:Raycast(origin, direct, params)
	if rayResult then
		print(rayResult.Instance)
	end
	return rayResult
end

----- Character Added -----
function CharacterAdded(char)
	if char.Name == game.Players.LocalPlayer.Name then
		local player = game.Players.LocalPlayer
		InputService.MouseIconEnabled = true
		
		--mouse.Icon = defMouseIcon
		if cam.FieldOfView ~= 80 then
			cam.FieldOfView = 80
		end
		
		--cam.CameraType = "Custom"
		local hum = char:WaitForChild("Humanoid")
		local hrp = char:WaitForChild("HumanoidRootPart")
		local connection
		local alive = true
		
		----- Player Death -----
		local function humanoidDied(player)
			alive = false
			playerReset()
			droneControlModule.removeCurDrone(defaultZoom)
		end
		connection = hum.Died:Connect(humanoidDied)
		table.insert(functions, connection)
		
		----- Drone Remote Controls -----
		local function droneRemoteConnection(command,droneName,playerName,validation)
			if alive then
				if command == "Add" then
					droneControlModule.addDrone(droneName)
				elseif command == "FiredBullet" then
					if playerName == player.Name then
						if validation then
							droneControlModule.checkValidation(validation[1],validation[2])
						end
					else
						local effects = droneName
						for effect,list in pairs(effects) do
							if effect == "Sounds" then
								for sound,pos in pairs(list) do
									spawn(function()
										local snd = replicatedStorage.SFX:FindFirstChild(sound)
										if pos and snd then
											if pos == 0 then
												soundService:PlayLocalSound(snd)
											elseif (hrp.Position-pos).Magnitude <= 350 then
												print()
												local sndClone = snd:Clone()
												local p = Instance.new("Part",miscFolder)
												p.Anchored = true
												p.CanCollide = false
												p.Transparency = 1
												p.Size = Vector3.new(0,0,0)
												p.CFrame = CFrame.new(pos)
												sndClone.Parent = p
												soundService:PlayLocalSound(sndClone)
												p:Destroy()
											end
										end
									end)
								end
							end
						end
						
					end
				end
			end
		end
		connection = droneRemote.OnClientEvent:Connect(droneRemoteConnection)
		table.insert(functions,connection)
		
		----- User Input Begins -----
		local function userInputStart(input, processed)
			if alive then
				local key = input.KeyCode
				droneControlModule.inputStart(key, processed, input.UserInputType)
				if not specialKeyDebounce then
					local spawnSuccess
					if not processed then
						if key == Enum.KeyCode.R then
							droneRemote:FireServer("Add","Dreadnought")
						elseif key == Enum.KeyCode.E then
							droneRemote:FireServer("Add","Espionage")
						elseif key == Enum.KeyCode.V then
							droneRemote:FireServer("Add","Vespula")
						elseif key == Enum.KeyCode.LeftShift and not droneEquipped then
							lockCenter = not lockCenter
						elseif key == Enum.KeyCode.C then
							spawnSuccess = droneControlModule.control(hum,player)
							if spawnSuccess ~= nil then
								droneEquipped = true
								InputService.MouseIconEnabled = false
								if string.find(spawnSuccess,"Dreadnought") then
									mouseLockDist = 1.75
								else
									mouseLockDist = 1
								end
							end
						elseif key == Enum.KeyCode.X then
							local success = droneControlModule.removeCurDrone(defaultZoom)
							if success then
								mouseLockDist = 2.5
								droneEquipped = false
								InputService.MouseIconEnabled = true
								mouse.Icon = defMouseIcon
								wait()
								player.CameraMaxZoomDistance = 10
								player.CameraMinZoomDistance = 10
								zoomExploitCount = 1
							end
						end
					end
				end
			end
		end
		connection = uis.InputBegan:Connect(userInputStart)
		table.insert(functions, connection)
		
		----- User Input Ends -----
		local function userInputEnd(input, processed)
			if alive then
				local key = input.KeyCode
				droneControlModule.inputEnd(key, input.UserInputType)
			end
		end
		connection = uis.InputEnded:Connect(userInputEnd)
		table.insert(functions, connection)
		
		----- Camera Manipulation -----
		player.CameraMaxZoomDistance = defaultZoom
		player.CameraMinZoomDistance = defaultZoom
		repeat
			char.Parent = liveFolder
		until wait()
		charLoaded = true
		
		print("Loaded Character")
	end
end

local function PlayerAdded(player)
	if player.Name == game.Players.LocalPlayer.Name then
		--local interval = 0.05
		--local counter = 0
		RunService:BindToRenderStep("ForceShiftlock", Enum.RenderPriority.Camera.Value + 1, function(step)
			local currentCamera = workspace.CurrentCamera
			if not currentCamera then return end
			
			if #liveFolder:GetChildren() ~= liveCount and charLoaded then
				liveCount = #liveFolder:GetChildren()
				local liveObjects = {}
				for _,v in pairs(liveFolder:GetChildren()) do
					table.insert(liveObjects,v.Name)
				end
				print(liveCount)
				checkRemote:FireServer(liveObjects)
			end
			
			--[[counter = counter + step
			if counter >= interval then
				counter = counter - interval
			end]]
			if droneEquipped or lockCenter then
				uis.MouseBehavior = Enum.MouseBehavior.LockCenter
				userSettings.RotationType = Enum.RotationType.CameraRelative
				if windowFocused and player.PlayerGui.FullscreenUI.MainFrame.Crosshair.Position ~= UDim2.new(0.5,0,0,mouse.Y) then
					player.PlayerGui.FullscreenUI.MainFrame.Crosshair.Position = UDim2.new(0.5,0,0,mouse.Y)
				end
				if droneEquipped and player.CameraMaxZoomDistance ~= 4 then
					player.CameraMaxZoomDistance = 4
					zoomExploitCount += 1
				end
			elseif not droneEquipped then
				if mouse.Icon ~= defMouseIcon then
					mouse.Icon = defMouseIcon
				end
				if player.CameraMaxZoomDistance ~= 10 then
					player.CameraMaxZoomDistance = 10
					zoomExploitCount += 1
				end
			end
			if zoomExploitCount%51 == 0 then
				game.Players.LocalPlayer:Kick("Contact a moderator for appeal. ErrorCode: 3")
			end
			if (currentCamera.Focus.Position - currentCamera.CFrame.Position).Magnitude >= 0.99 then
				currentCamera.CFrame = currentCamera.CFrame*CFrame.new(mouseLockDist, 0, 0)
				currentCamera.Focus = CFrame.fromMatrix(currentCamera.Focus.Position, currentCamera.CFrame.RightVector, currentCamera.CFrame.UpVector)*CFrame.new(mouseLockDist, 0, 0)
			end
		end)
		uis.WindowFocused:Connect(function()
			windowFocused = true
			droneControlModule.windowFocusCheck(true)
		end)
		uis.WindowFocusReleased:Connect(function()
			windowFocused = false
			droneControlModule.windowFocusCheck(false)
		end)
	end
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