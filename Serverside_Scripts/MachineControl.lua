----- Object Definitions -----
local players = game:GetService("Players")
local machineFolder = game:GetService("Workspace"):WaitForChild("Machines")
local remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")

----- Variable Definitions -----
local displayCMDRemote = remotes:WaitForChild("DisplayCMD")
local machineArray = {
	engines = {}
}

----- Machine Identification -----
for _,machine in pairs(machineFolder:GetChildren()) do
	if machine.Name == "Engine" then
		table.insert(machineArray.engines, machine)
	end
end

----- Coding Tasks -----
----- Engine Tasks -----
local engineTasks = {
	'unstableEngine',
}

----- Main Loop -----
for _,engine in pairs(machineArray.engines) do
	spawn(function()
		----- Object definitions -----
		local top, mid, bottom, ped = engine:WaitForChild("Top"), engine:WaitForChild("Mid"), engine:WaitForChild("Bottom"), engine:WaitForChild("Pedestal")
		local sfx = engine:WaitForChild('SoundEffects')
		local engineGears = bottom:WaitForChild("Gears")
		local pedGears = ped:WaitForChild("Gears")
		local pumps = mid:WaitForChild("Pumps")
		local batteries = bottom:WaitForChild("Batteries")
		local interface = ped:WaitForChild("Interface")
		local interfaceCircle = interface:WaitForChild("Circle")
		local touchPad = ped:WaitForChild("TouchPadFrame"):WaitForChild("TouchPad")
		
		----- Variable definitions -----
		local rhythm = 0
		local direction = 0
		local alternate = 1
		local onPad = false
		local padBusy = false
		
		local function displayInterface(display)
			local var
			if display then
				var = 0.05
			else
				var = -0.05
			end
			for i = 1,20 do
				wait()
				for _,part in pairs(interface:GetChildren()) do
					part.Transparency -= var
					if part.Name ~= "Hologram" then
						part.CFrame = part.CFrame * CFrame.new(0,var,0)
					end
				end
			end
		end
		
		local function engineFunctions(response)
			if response == 'stabilizeEngine' then
				spawn(function()
					local function emitterChange(visible, rate)
						for _,steamPart in pairs(mid:GetChildren()) do
							if steamPart.Name == 'SteamEmitter' then
								steamPart.ParticleEmitter.Enabled = visible
							end
							if steamPart.Name == 'EmitterPart' then
								steamPart.ParticleEmitter.Rate = rate
							end
						end
					end
					sfx:WaitForChild('Event'):WaitForChild('SteamRelease'):Play()
					emitterChange(true, 500)
					wait(sfx:WaitForChild('Event'):WaitForChild('SteamRelease').TimeLength-2.5)
					emitterChange(false, 100)
				end)
			end
		end
		
		touchPad.Touched:Connect(function(limb)
			if limb.Parent ~= nil and limb.Parent:IsA("Model") and limb.Parent:FindFirstChild("Humanoid") then
				if not onPad and not padBusy then
					if limb.Parent:FindFirstChild("Humanoid") then
						limb.Parent:FindFirstChild("Humanoid").WalkSpeed = 0
						limb.Parent:FindFirstChild("Humanoid").JumpPower = 0
						limb.Parent:FindFirstChild("Humanoid").AutoRotate = false
						limb.Parent:FindFirstChild("HumanoidRootPart").CFrame = CFrame.new(touchPad.Position + Vector3.new(0,2,0), ped.Frame.Body.Position)
					end
					padBusy = true
					displayInterface(true)
					onPad = true
					padBusy = false
					if players:FindFirstChild(limb.Parent.Name) then
						displayCMDRemote:FireClient(players:FindFirstChild(limb.Parent.Name), engineTasks[1], ped.Interface.Screen.Position) -- Passing task to Client
					end
				end
			end
		end)
		
		displayCMDRemote.OnServerEvent:Connect(function(player, response) -- Client completes task
			engineFunctions(response)
			if onPad and not padBusy then
				padBusy = true
				displayInterface(false)
				padBusy = false
				if player.Character:WaitForChild("Humanoid") ~= nil then
					player.Character:FindFirstChild("Humanoid").WalkSpeed = 16
					player.Character:FindFirstChild("Humanoid").JumpPower = 50
					player.Character:FindFirstChild("Humanoid").AutoRotate = true
				end
				wait(3)
				onPad = false
			end
		end)
		
		for _,sound in pairs(sfx:WaitForChild('Constant'):GetChildren()) do
			sound:Play()	
		end
		
		while true do
			wait(0.05)
			
			----- Engine gear rotation -----
			for _,gear in pairs(engineGears:GetChildren()) do
				local rotatedCFrame = CFrame.Angles(0, math.rad(5), math.rad(0))
				gear.CFrame = gear.CFrame:ToWorldSpace(rotatedCFrame)
			end
			
			for _,gear in pairs(pedGears:GetChildren()) do
				local rotatedCFrame = CFrame.Angles(0, math.rad(5), math.rad(0))
				gear.CFrame = gear.CFrame:ToWorldSpace(rotatedCFrame)
			end
			
			----- Interface circle rotation -----
			interfaceCircle.CFrame = interfaceCircle.CFrame:ToWorldSpace(CFrame.Angles(0, math.rad(5), math.rad(0)))
			
			----- Pedestal gear rotation -----
			for _,pump in pairs(pumps:GetChildren()) do
				if rhythm < 30 and rhythm > 0 then
					pump.CFrame = CFrame.new(pump.Position) * CFrame.new(0,0.02,0) * CFrame.Angles(0,0,math.rad(90))
				elseif rhythm == 30 then
					pump.CFrame = CFrame.new(pump.Position) * CFrame.new(0,-0.02 * alternate,0) * CFrame.Angles(0,0,math.rad(90))
					rhythm = -31
				elseif rhythm == 0 then
					pump.CFrame = CFrame.new(pump.Position) * CFrame.new(0,0.04 * alternate,0) * CFrame.Angles(0,0,math.rad(90))
				elseif rhythm < 0 then
					pump.CFrame = CFrame.new(pump.Position) * CFrame.new(0,-0.02,0) * CFrame.Angles(0,0,math.rad(90))
				end
			end
			
			----- Battery lighting config -----
			for _,battery in pairs(batteries:GetChildren()) do
				local light = battery:WaitForChild("LightPart"):WaitForChild("PointLight")
				if rhythm < 30 and rhythm > 0 then
					light.Range = light.Range - 0.08
					light.Brightness = light.Brightness - 0.01
				elseif rhythm == 30 then
					light.Range = light.Range + 0.08
					light.Brightness = light.Brightness + 0.01
					rhythm = -31
				elseif rhythm == 0 then
					light.Range = light.Range - 0.16
					light.Brightness = light.Brightness - 0.02
				elseif rhythm < 0 then
					light.Range = light.Range + 0.08
					light.Brightness = light.Brightness + 0.01
				end
			end
			
			rhythm +=1
		end
	end)
end