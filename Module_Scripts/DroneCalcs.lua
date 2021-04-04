local droneCalculation = {}

----- Data Objects -----
local replicatedStorage = game:GetService("ReplicatedStorage")
local cam = game:GetService('Workspace').CurrentCamera

-- Player Variables --

local makeEffect = {
	['Dreadnought'] = {0, 0.2}
}

function droneCalculation.Create(make,drone,info_1)
	if drone:FindFirstChild("Effect") then
		if make == 'Dreadnought' then
			local CameraDirection = drone.Effect.LH.Joint.CFrame:toObjectSpace(workspace.CurrentCamera.CFrame).lookVector.unit
			makeEffect[make][1] = -math.asin(CameraDirection.y)
			for _,folder in pairs(drone.Effect:GetChildren()) do
				local j = folder.Joint
				for _,motor in pairs(j:GetChildren()) do
					local x,y,z = motor.C0:ToEulerAnglesXYZ()
					local newCF = CFrame.new(motor.C0.p) * CFrame.Angles(0, y, -math.asin(CameraDirection.y))
					motor.C0 = newCF
				end
			end
		elseif make == "Vespula" then
			for _,folder in pairs(drone.Effect:GetChildren()) do
				if folder.Name == 'BL' or folder.Name == 'TL' then
					local j = folder.Joint
					local m1, m2 = j:FindFirstChild('motor1') , j:FindFirstChild('motor2')
					m1.C0, m2.C0 = m1.C0 * CFrame.Angles(0,math.rad(30*info_1),0), m2.C0 * CFrame.Angles(0,math.rad(30*info_1),0)
				elseif folder.Name == 'BR' or folder.Name == 'TR' then
					local j = folder.Joint
					local m1, m2 = j:FindFirstChild('motor1') , j:FindFirstChild('motor2')
					m1.C0, m2.C0 = m1.C0 * CFrame.Angles(0,math.rad(-30*info_1),0), m2.C0 * CFrame.Angles(0,math.rad(-30*info_1),0)
				end
			end
		end
	end
end

return droneCalculation
