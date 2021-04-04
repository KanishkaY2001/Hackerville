----- Object Definitions -----
local player = game.Players.LocalPlayer
local currentCam = game:GetService('Workspace').CurrentCamera
local playerGui = player.PlayerGui
local starterGui = game:GetService('StarterGui')
local SoundService = game:GetService("SoundService")
local runService = game:GetService("RunService")
local userInputService = game:GetService('UserInputService')
local remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")

----- Rich Text Identifiers ------
local enemyColor = '<font color="rgb(254,228,120)">' -- Yellow
local commentColor = '<font color="rgb(105,227,92)">' -- Green
local keywordColor = '<font color="rgb(254, 75, 78)">' -- Red
local commandColor = '<font color="rgb(171,88,254)">' -- Blue
local colorEnd = '</font>'

----- Variable Definitions -----
local displayCMDRemote = remotes:WaitForChild("DisplayCMD")
local typeSound = Instance.new("Sound")
typeSound.Name = 'TypeSound'
typeSound.SoundId = 'rbxassetid://5843089039'
typeSound.Parent = player

----- Special Text -----
local enemyList = {
	'Enemy1',
	'Enemy2',
	'Enemy3',
	'Enemy4'
}

local keywordList = {
	'for ',
	'in ',
	'they ',
	'it ',
	'if ',
	'is ',
	'not ',
	'do:',
	'on ',
	'then:',
	'Task:',
	'Keywords:'
}

local commandList = {
	'stabilize ',
	'destroy ',
	'hack ',
	'build ',
	'purchase ',
	'deploy '
}

local machineList = {
	'engine',
	'resources',
	'attackDrone'
}

local commentList = {
	'engine',
	'stable'
}

----- User Interface -----
local interface = playerGui:WaitForChild('Interface')
local cmdPrompt = playerGui:WaitForChild('CMDPrompt')
local outerFrame = cmdPrompt:WaitForChild('OuterFrame')
local innerFrame = outerFrame:WaitForChild('InnerFrame')
local cmdFrame = innerFrame:WaitForChild('CMDFrame')
local loadBar = outerFrame:WaitForChild('OuterLoadBar')
local codeParentFrame = cmdFrame:WaitForChild('CodeParentFrame')
local scrollBar = cmdFrame:WaitForChild('ScrollBar')
local keywordsContext = outerFrame:WaitForChild('KeywordsContext')
local taskContext = outerFrame:WaitForChild('TaskContext')
local keywordsLabel = outerFrame:WaitForChild('KeywordsLabel')
local taskLabel = outerFrame:WaitForChild('TaskLabel')
local labelList = {
	keywordsContext,
	taskContext,
	keywordsLabel,
	taskLabel
}

cmdFrame.Position = UDim2.new(-1.01,0,0,0)
loadBar.Position = UDim2.new(-0.17,0,0,0)

scrollBar:GetPropertyChangedSignal('CanvasPosition'):Connect(function()
	codeParentFrame.CanvasPosition = scrollBar.CanvasPosition
end)

codeParentFrame:GetPropertyChangedSignal('AbsoluteSize'):Connect(function(size)
	for _,text in pairs(codeParentFrame:GetChildren()) do
		if text.ClassName == 'TextLabel' or text.ClassName == 'TextBox' then
			text.TextSize = math.floor(codeParentFrame.AbsoluteSize.Y/20)
		end
	end
	for _,label in pairs(labelList) do
		label.TextSize = math.floor(codeParentFrame.AbsoluteSize.Y/20)
	end
end)

----- Rich Text Function -----
function richTextify(text)
	local modifiedText = text
	
	for _,word in pairs(enemyList) do
		modifiedText = string.gsub(modifiedText, word, enemyColor .. word .. colorEnd)
	end
	for _,word in pairs(keywordList) do
		modifiedText = string.gsub(modifiedText, word, keywordColor .. word .. colorEnd)
	end
	for _,word in pairs(commandList) do
		modifiedText = string.gsub(modifiedText, word, commandColor .. word .. colorEnd)
	end
	for _,word in pairs(commentList) do
		modifiedText = string.gsub(modifiedText, word, commentColor .. word .. colorEnd)
	end
	return modifiedText
end

----- Spawn Text -----
function textSpawn(text, label)
	for _,letter in pairs(string.split(text,'')) do
		if letter ~= " " then
			wait(0.05)
		else
			wait(0.01)
		end
		label.Text = label.Text .. letter
	end
end

----- Text Transparency -----
function changeTextTrans(parent, labelNameList, sign)
	for i = 1,5 do
		for _,removalLine in pairs(parent:GetChildren()) do
			for _,name in pairs(labelNameList) do
				if removalLine.Name == name then
					removalLine.TextTransparency += 0.2 * sign
					wait()
					if removalLine.Text ~= '' and removalLine.TextTransparency == 1 then
						removalLine.Text = ''
					end
					break
				end
			end
		end
	end
end

----- Interface Hide/Show -----
function interfaceDisplay(display)
	local frame = interface:WaitForChild('InterfaceFrame')
	if not display then
		local showInterface = frame:TweenPosition(UDim2.new(0.5,0,-0.2,0),Enum.EasingDirection.In,Enum.EasingStyle.Quad,0.75,false)
	else
		local hideInterface = frame:TweenPosition(UDim2.new(0.5,0,0,0),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.75,false)
	end
end

----------------------------------------------------------------------------------------------------
----- Coding Tasks -----

----- Lines -----
local codeProblems = {
	['stabilizeEngine'] = {
		"if |      | is not |      | then:",
		1,
		"stabilize |      |",
		---1,
		--0,
		--"if enough resources for attackDrone then:",
		--1,
		--"purchase |           |",
		--"|      | attackDrone |  | Enemy3"
	}
}

----- Solutions -----
local codeSolutions = {
	['stabilizeEngine'] = {
		['a1'] = {"    engine          stable",4,6,10,6},
		['a3'] = {"           engine",11,6},
		--['a8'] = {"          attackDrone",10,11},
		--['a9'] = {" deploy               on",1,6,15,2}
	}
}

----- Context -----
local codeContext = {
	['stabilizeEngine'] = {
		"Check if the engine is stable or not.\n\nIf not then stabilize it.",
		"engine x2\nstable x1"
	}
}

local codeResponses = {
	['unstableEngine'] = 'stabilizeEngine'
}

----------------------------------------------------------------------------------------------------
----- Remotes -----

displayCMDRemote.OnClientEvent:Connect(function(codeType, lookAt)
	for _,response in pairs(codeResponses) do
		if codeResponses[codeType] then
			codingTask(codeResponses[codeType], lookAt)
		end
	end
	
end)

----------------------------------------------------------------------------------------------------

function codingTask(currentProblem, lookAt)
	if interface.Enabled then
		interfaceDisplay(false)
	end
	local previousCamPos = currentCam.CFrame.Position
	local previousCamFocus = currentCam.Focus.Position
	currentCam.CFrame = CFrame.new(currentCam.CFrame.p, lookAt)
	player.PlayerGui:FindFirstChild('FPMouseMove').Enabled = true
	currentCam.CameraType = Enum.CameraType.Scriptable
	currentCam:Interpolate(CFrame.new(player.Character.Head.Position),CFrame.new(lookAt),1)
	outerFrame.Visible = true
	taskContext.Visible = true
	keywordsContext.Visible = true
	keywordsLabel.Visible = true
	taskLabel.Visible = true
	local showLoadBar = loadBar:TweenPosition(UDim2.new(0.17,0,0,0),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.75,false)
	wait(0.75)
	for i = 1,4 do
		for j = 1,5 do
			local loadP = Instance.new('TextLabel')
			loadP.Parent = loadBar
			loadP.Name = 'LoadPart'
			loadP.BackgroundTransparency = 1
			loadP.BorderSizePixel = 0
			loadP.Text = ''
			loadP.BackgroundColor3 = Color3.fromRGB(i*50,i*50,i*50)
			for k = 1,3 do
				loadP.BackgroundTransparency -= 0.334
				wait()
			end
		end
	end
	for i = 1,10 do
		for _,obj in pairs(loadBar:GetChildren()) do
			if obj.Name == 'LoadPart' then
				obj.Transparency += 0.1
				
			end
			
		end
		wait(0.01)
	end
	for _,obj in pairs(loadBar:GetChildren()) do
		if obj.Name == 'LoadPart' then
			obj:Destroy()
		end
	end
	
	local showCmdBar = cmdFrame:TweenPosition(UDim2.new(0,0,0,0),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.75,false)
	wait(0.75)
	local resizeLoadBar = loadBar:TweenSize(UDim2.new(0.377,0,0.99,0),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.75,false)
	wait(0.75)
	
	----- Displaying Contexts, Keywords, Labels -----
	textSpawn("Task:",taskLabel)
	taskLabel.Text = richTextify(taskLabel.Text)
	textSpawn(codeContext[currentProblem][1],taskContext)
	textSpawn("Keywords:",keywordsLabel)
	keywordsLabel.Text = richTextify(keywordsLabel.Text)
	textSpawn(codeContext[currentProblem][2],keywordsContext)
	keywordsContext.Text = richTextify(keywordsContext.Text)
	
	----- Code Line Generation -----
	local textPosY = 0
	local tab = 0

	----- Create Line -----
	local function createLine(textType)
		local line
		if textType == 'label' then
			line = Instance.new('TextLabel')
		elseif textType == 'box' then
			line = Instance.new('TextBox')
			line.ClearTextOnFocus = false
			line.Selectable = false
		end
		line.Size = UDim2.new(1,0,0.01,0)
		line.Position = UDim2.new(tab,0,textPosY,0)
		line.BorderSizePixel = 0
		line.BackgroundTransparency = 1
		line.Text = ''
		line.RichText = true
		line.TextXAlignment = Enum.TextXAlignment.Left
		line.Font = Enum.Font.Code
		line.TextColor3 = Color3.fromRGB(255,255,255)
		line.Parent = codeParentFrame
		line.Name = 'CodeLine'
		line.TextSize = math.floor(codeParentFrame.AbsoluteSize.Y/20)
		return line
	end

	----- Get maxSize & spacingList -----
	local function getMaxSize(array)
		local sum = 0
		local sum2 = 0
		local sum3 = 0
		local wordCount = (#array-1)/2
		local spacingList = {}
		
		for i,v in pairs(array) do
			if i > 1 then
				sum += v
			end
		end
		for c = 1,wordCount-1 do
			for i,v in pairs(array) do
				if i > 1 and i >= c*2 and i <= c*2+1 then
					sum2 += v
				end
			end
			table.insert(spacingList,sum2)
			table.insert(spacingList,sum2+array[c*2+2])
		end
		return {sum, spacingList}
	end

	if codeProblems[currentProblem] then
		local solved = 0
		local totalSolutions = 0
		for _,_ in pairs(codeSolutions[currentProblem]) do
			totalSolutions += 1
		end
		for index,codeLine in pairs(codeProblems[currentProblem]) do
			if codeLine == 1 then
				tab += 0.04
			elseif codeLine == -1 then
				tab -= 0.04
			elseif codeLine == 0 then
				textPosY += 0.014
			else
				local line = createLine('label')
				textSpawn(codeLine,line)
				if codeSolutions[currentProblem]['a' .. index] ~= nil then
					local answerLine = createLine('box')
					local minSize = codeSolutions[currentProblem]['a' .. index][2]
					local sizeAndList = getMaxSize(codeSolutions[currentProblem]['a' .. index])
					local maxSize = sizeAndList[1]
					local spacingList = sizeAndList[2]
					local completed = false
					local halfDone = false
					answerLine.Text = string.rep(" ", codeSolutions[currentProblem]['a' .. index][2])
					
					answerLine:GetPropertyChangedSignal('Text'):Connect(function()
						spawn(function() -- Need to change this so that it only works when actual proper text is typed in, instead of going out of bounds and blah blah
							if player:FindFirstChild('TypeSound') then
								typeSound:Play()
							end
						end)
						if answerLine.Text == codeSolutions[currentProblem]['a' .. index][1] and not completed then
							completed = true
							answerLine.TextEditable = false
							answerLine.Text = commentColor .. answerLine.Text .. colorEnd
							answerLine:ReleaseFocus()
							solved += 1
							if solved == totalSolutions then
								if player:FindFirstChild('TypeSound') ~= nil then
									typeSound:Destroy()
								end
								spawn(function()
									changeTextTrans(codeParentFrame, {'CodeLine'}, 1)
								end)
								changeTextTrans(outerFrame, {'TaskContext','KeywordsContext','TaskLabel','KeywordsLabel'}, 1)
								local resizeLoadBar = loadBar:TweenSize(UDim2.new(0.08,0,0.99,0),Enum.EasingDirection.In,Enum.EasingStyle.Sine,0.5,false)
								wait(0.5)
								local hideCmdBar = cmdFrame:TweenPosition(UDim2.new(-1.01,0,0,0),Enum.EasingDirection.In,Enum.EasingStyle.Sine,0.5,false)
								wait(0.5)
								local hideLoadBar = loadBar:TweenPosition(UDim2.new(-0.17,0,0,0),Enum.EasingDirection.In,Enum.EasingStyle.Sine,0.5,false)
								wait(0.5)
								outerFrame.Visible = false
								taskContext.Visible = false
								keywordsContext.Visible = false
								keywordsLabel.Visible = false
								taskLabel.Visible = false
								currentCam:Interpolate(CFrame.new(previousCamPos),CFrame.new(previousCamFocus),1)
								interfaceDisplay(true)
								wait(1)
								currentCam.CameraType = Enum.CameraType.Custom
								changeTextTrans(outerFrame, {'TaskContext','KeywordsContext','TaskLabel','KeywordsLabel'}, -1)
								player.PlayerGui:FindFirstChild('FPMouseMove').Enabled = false
								displayCMDRemote:FireServer(currentProblem)
							end
						elseif not completed then
							if #answerLine.Text < minSize then
								answerLine.Text = string.rep(" ", minSize)
							elseif #answerLine.Text > maxSize then
								answerLine.Text = string.sub(answerLine.Text,1,maxSize)
							end
							for i,v in pairs(spacingList) do
								if i%2 ~= 0 then
									if #answerLine.Text == v and answerLine.Text == string.sub(codeSolutions[currentProblem]['a' .. index][1],1,v) then
										halfDone = true
										answerLine.Text = answerLine.Text .. string.rep(" ", codeSolutions[currentProblem]['a' .. index][#spacingList+2])
									elseif #answerLine.Text >= v+1 and not halfDone then
										answerLine.Text = string.sub(answerLine.Text,1,#answerLine.Text-1)
									end
								else
									if #answerLine.Text == v-1 then
										answerLine.Text = answerLine.Text .. " "
									end
								end
							end
						end
					end)
					
					answerLine:GetPropertyChangedSignal('SelectionStart'):Connect(function()
						answerLine.SelectionStart = -1
					end)
					answerLine.Focused:Connect(function()
						if completed then
							answerLine:ReleaseFocus()
						end
					end)
					
					answerLine:GetPropertyChangedSignal('CursorPosition'):Connect(function()
						wait()
						if not completed and answerLine:IsFocused() then
							answerLine.CursorPosition = #answerLine.Text+1
						end
					end)
				end
				wait(0.2)
				textPosY += 0.014
				line.Text = richTextify(line.Text)
			end
		end
	end
end