
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local authorizedControllers = {}
local primaryController = nil
local currentController = nil
local motionConnection = nil
local motionMode = "stop"
local searchText = ""
local stackTarget = nil

local ORBIT_RADIUS = 8
local ORBIT_HEIGHT = 3
local ORBIT_SPEED = 1.8
local FOLLOW_SPACING = 4
local SHOULDER_SIDE_OFFSET = 2.5
local SHOULDER_HEIGHT_OFFSET = 1.5
local FIREWORKS_SPEED = 40
local FIREWORKS_DURATION = 5
local SIDELINE_RIGHT_OFFSET = 5
local SIDELINE_SPACING = 2.6
local DETECTION_RADIUS = 18

local rng = Random.new()
local funFacts = {
	"Octopuses have three hearts.",
	"Honey never spoils and can stay edible for thousands of years.",
	"Bananas are berries, but strawberries are not.",
	"A day on Venus is longer than a year on Venus.",
	"Wombat poop is cube-shaped.",
	"Sharks existed before trees.",
	"The Eiffel Tower can grow taller in summer heat.",
	"Some turtles can breathe through their butts.",
	"A group of flamingos is called a flamboyance.",
	"Scotland's national animal is the unicorn.",
	"Koalas have unique fingerprints like humans.",
	"The heart of a blue whale is about the size of a car.",
	"There are more stars in the universe than grains of sand on Earth.",
	"Your nose can remember around 50,000 different scents.",
	"The shortest war in history lasted 38 to 45 minutes.",
	"Sloths can hold their breath longer than dolphins.",
	"An ostrich's eye is bigger than its brain.",
	"Cows have best friends and can get stressed when separated.",
	"Hot water can freeze faster than cold water under some conditions.",
	"A bolt of lightning is five times hotter than the surface of the sun.",
	"Sea otters hold hands while sleeping.",
	"The moon has moonquakes.",
	"A single cloud can weigh more than a million pounds.",
	"Butterflies taste with their feet.",
	"There is a species of jellyfish that is biologically immortal.",
	"The dot over the letters i and j is called a tittle.",
	"Avocados are fruit, and technically they are berries.",
	"The inventor of the frisbee was turned into a frisbee after he died.",
	"Humans share about 60 percent of their DNA with bananas.",
	"A snail can sleep for up to three years.",
	"Rats laugh when tickled.",
	"There are more possible chess games than atoms in the observable universe.",
	"The first alarm clock could only ring at 4 a.m.",
	"Pineapples take about two years to grow.",
	"A clouded leopard has the longest canine teeth relative to body size of any wild cat.",
	"The fingerprints of a koala are so close to humans they can confuse crime scenes.",
	"Bamboo can grow up to about 35 inches in a single day.",
	"A day on Mercury lasts about 59 Earth days.",
	"Mantis shrimp can punch faster than a bullet.",
	"Antarctica is the largest desert in the world.",
	"An apple, potato, and onion all taste the same if you eat them with your nose plugged.",
	"You are slightly taller in the morning than at night.",
	"Some cats are allergic to humans.",
	"A crocodile cannot stick its tongue out.",
	"The smell of fresh-cut grass is a plant distress signal.",
	"Sunsets on Mars are blue.",
	"A group of crows is called a murder.",
	"Peanuts are not nuts; they are legumes.",
	"The first oranges were green.",
	"The longest hiccuping spree lasted 68 years.",
	"The average person walks the equivalent of five times around the world in a lifetime.",
	"Some frogs can freeze solid and then thaw back to life.",
	"Dolphins have names for each other.",
	"A shrimp's heart is in its head.",
	"The Great Wall of China is not visible from space with the naked eye.",
	"The inventor of the microwave discovered it after a chocolate bar melted in his pocket.",
	"There are more trees on Earth than stars in the Milky Way.",
	"A day on Jupiter is about 10 hours long.",
	"The human brain can generate about 12 to 25 watts of electricity.",
	"The fingerprints on a hand develop by around 24 weeks in the womb.",
	"Venus is the hottest planet in our solar system.",
	"Some metals are so reactive they explode on contact with water.",
	"Bees can recognize human faces.",
	"A jiffy is an actual unit of time: 1/100th of a second.",
	"The first computer bug was an actual moth.",
	"The Eiffel Tower was originally meant to be temporary.",
	"There are no muscles in your fingers; movement comes from forearm muscles.",
	"Platypuses glow under UV light.",
	"A group of porcupines is called a prickle.",
	"The shortest complete sentence in English is 'I am.'",
	"An adult human has fewer bones than a baby.",
	"Humans are the only animals that blush.",
	"A leap year doesn't happen every 100 years unless divisible by 400.",
	"The hottest chili peppers can be over 200 times hotter than jalapenos.",
	"Some fungi create zombies out of insects.",
	"There are volcanoes taller than Mount Everest, measured from base to summit, under the ocean.",
	"Sound travels about four times faster in water than in air.",
	"The Amazon rainforest produces around 20 percent of the world's oxygen cycling.",
	"A group of owls is called a parliament.",
	"Kangaroos cannot walk backward easily.",
	"The largest snowflake ever recorded was 15 inches wide.",
	"Saturn would float in water because it is less dense than water.",
	"The human body contains enough iron to make a small nail.",
	"Fingernails grow faster than toenails.",
	"A teaspoon of neutron star would weigh about a billion tons on Earth.",
	"There are more possible Rubik's Cube combinations than atoms in the solar system.",
	"Mosquitoes are attracted to certain blood types more than others.",
	"Some sharks can reproduce without mating.",
	"The oldest known living tree is over 4,800 years old.",
	"A blue whale's tongue can weigh as much as an elephant.",
	"You cannot hum while holding your nose closed.",
	"There are rivers and lakes under the ocean.",
	"The first camera photograph took about 8 hours of exposure.",
	"Shakespeare invented over 1,700 words.",
	"Some penguins propose with pebbles.",
	"The speed of a computer mouse is measured in 'Mickeys'.",
	"An astronaut's height can increase in space.",
	"There is enough DNA in the average human body to stretch from the sun to Pluto and back.",
	"Giraffes only need 5 to 30 minutes of sleep per day.",
	"The first video game is often credited as Tennis for Two from 1958."
}

local chatConnections = {}
local buttonByPlayer = {}

local function characterAndRoot(player)
	local character = player and player.Character
	if not character then
		return nil, nil
	end
	return character, character:FindFirstChild("HumanoidRootPart")
end

local function normalizeMessage(message)
	return string.lower((message or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function optimizeClientPerformance()
	pcall(function()
		Lighting.GlobalShadows = false
		Lighting.Brightness = 1
		Lighting.EnvironmentDiffuseScale = 0
		Lighting.EnvironmentSpecularScale = 0
		Lighting.FogEnd = 100000
		Lighting.Technology = Enum.Technology.Compatibility
	end)

	pcall(function()
		local gameSettings = UserSettings():GetService("UserGameSettings")
		gameSettings.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
	end)

	for _, instance in ipairs(workspace:GetDescendants()) do
		if instance:IsA("Decal") or instance:IsA("Texture") then
			instance.Transparency = 1
		elseif instance:IsA("ParticleEmitter") or instance:IsA("Trail") or instance:IsA("Beam") then
			instance.Enabled = false
		elseif instance:IsA("Fire") or instance:IsA("Smoke") or instance:IsA("Sparkles") then
			instance.Enabled = false
		end
	end
end

local function updatePreferredPrimary()
	local preferred = Players:FindFirstChild("LoganStarryH3ro")
	if preferred and preferred ~= localPlayer then
		primaryController = preferred
		authorizedControllers[preferred] = true
	elseif primaryController and primaryController.Parent ~= Players then
		primaryController = nil
	end
end

local function calculateExpression(rawExpression)
	local expression = (rawExpression or ""):gsub("%s+", "")
	local left, op, right = expression:match("^(%-?%d+%.?%d*)([+/])(%-?%d+%.?%d*)$")
	if not left or not op or not right then
		return nil, "Use: /calc number+number or /calc number/number"
	end

	local leftNumber = tonumber(left)
	local rightNumber = tonumber(right)
	if not leftNumber or not rightNumber then
		return nil, "Invalid numbers"
	end

	if op == "+" then
		return leftNumber + rightNumber, nil
	end

	if rightNumber == 0 then
		return nil, "Cannot divide by zero"
	end

	return leftNumber / rightNumber, nil
end

local function getRandomFunFact()
	local randomIndex = rng:NextInteger(1, #funFacts)
	return funFacts[randomIndex]
end

local function sendChatMessage(message)
	if not message or message == "" then
		return
	end

	if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
		local textChannels = TextChatService:FindFirstChild("TextChannels")
		local general = textChannels and textChannels:FindFirstChild("RBXGeneral")
		if general then
			general:SendAsync(message)
		end
		return
	end

	local legacyEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
	local sayRequest = legacyEvents and legacyEvents:FindFirstChild("SayMessageRequest")
	if sayRequest then
		sayRequest:FireServer(message, "All")
	end
end

local function clearMotion()
	if motionConnection then
		motionConnection:Disconnect()
		motionConnection = nil
	end
	motionMode = "stop"
end

local function moveNearTarget(targetRoot, offset)
	local _, localRoot = characterAndRoot(localPlayer)
	if not localRoot or not targetRoot then
		return
	end
	localRoot.CFrame = targetRoot.CFrame * offset
end

local function getCompanionIndex(targetRoot)
	local companions = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= currentController then
			local _, root = characterAndRoot(player)
			if root and (root.Position - targetRoot.Position).Magnitude <= DETECTION_RADIUS then
				table.insert(companions, player)
			end
		end
	end

	table.sort(companions, function(a, b)
		return a.UserId < b.UserId
	end)

	for index, player in ipairs(companions) do
		if player == localPlayer then
			return index, #companions
		end
	end

	return 1, math.max(#companions, 1)
end

local function startMotion(mode, targetPlayer, optionalStackTarget)
	clearMotion()
	currentController = targetPlayer
	motionMode = mode
	stackTarget = optionalStackTarget
	local angle = 0
	local elapsed = 0

	motionConnection = RunService.Heartbeat:Connect(function(deltaTime)
		if not currentController or not authorizedControllers[currentController] or currentController.Parent ~= Players then
			clearMotion()
			currentController = nil
			stackTarget = nil
			return
		end

		local _, targetRoot = characterAndRoot(currentController)
		if not targetRoot then
			return
		end

		local companionIndex, companionCount = getCompanionIndex(targetRoot)

		if motionMode == "fireworks" then
			elapsed += deltaTime
			local _, localRoot = characterAndRoot(localPlayer)
			if localRoot then
				local velocity = localRoot.AssemblyLinearVelocity
				localRoot.AssemblyLinearVelocity = Vector3.new(velocity.X, FIREWORKS_SPEED, velocity.Z)
			end
			if elapsed >= FIREWORKS_DURATION then
				clearMotion()
				currentController = nil
				stackTarget = nil
			end
		elseif motionMode == "stack" then
			local targetPlayerForStack = stackTarget or currentController
			local _, stackRoot = characterAndRoot(targetPlayerForStack)
			if stackRoot then
				local heightOffset = 3 + (companionIndex - 1) * 2.5
				moveNearTarget(stackRoot, CFrame.new(0, heightOffset, 0))
			end
		elseif motionMode == "swarm" then
			local targetPlayerForSwarm = stackTarget or currentController
			local _, swarmRoot = characterAndRoot(targetPlayerForSwarm)
			if swarmRoot then
				moveNearTarget(swarmRoot, CFrame.new(0, 0, 0))
			end
		elseif motionMode == "side_line" then
			local centeredIndex = companionIndex - ((companionCount + 1) / 2)
			local zOffset = centeredIndex * SIDELINE_SPACING
			moveNearTarget(targetRoot, CFrame.new(SIDELINE_RIGHT_OFFSET, SHOULDER_HEIGHT_OFFSET, zOffset))
		elseif motionMode == "follow" or motionMode == "line" then
			local spacingOffset = FOLLOW_SPACING * companionIndex
			moveNearTarget(targetRoot, CFrame.new(0, 0, -spacingOffset))
		elseif motionMode == "orbit" then
			angle += deltaTime * (ORBIT_SPEED * math.pi)
			local slotAngle = (2 * math.pi / companionCount) * (companionIndex - 1)
			local finalAngle = angle + slotAngle
			local x = math.cos(finalAngle) * ORBIT_RADIUS
			local z = math.sin(finalAngle) * ORBIT_RADIUS
			moveNearTarget(targetRoot, CFrame.new(x, ORBIT_HEIGHT, z))
		elseif motionMode == "shoulders" then
			local side = companionIndex == 1 and -SHOULDER_SIDE_OFFSET or SHOULDER_SIDE_OFFSET
			if companionIndex > 2 then
				side = ((companionIndex % 2) == 0 and 1 or -1) * (SHOULDER_SIDE_OFFSET + math.floor(companionIndex / 2) * 1.5)
			end
			moveNearTarget(targetRoot, CFrame.new(side, SHOULDER_HEIGHT_OFFSET, 0))
		end
	end)
end

local function findPlayerByName(text)
	local lookup = normalizeMessage(text)
	if lookup == "" then
		return nil
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if normalizeMessage(player.Name) == lookup then
			return player
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if string.sub(normalizeMessage(player.Name), 1, #lookup) == lookup then
			return player
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if normalizeMessage(player.DisplayName) == lookup then
			return player
		end
	end

	return nil
end

local function setAuthorized(player, value)
	if not player or player == localPlayer then
		return false
	end

	if value then
		authorizedControllers[player] = true
		if not primaryController then
			primaryController = player
		end
		return true
	end

	if player == primaryController then
		return false
	end

	authorizedControllers[player] = nil
	if currentController == player or stackTarget == player then
		clearMotion()
		currentController = nil
		stackTarget = nil
	end
	return true
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ControllerMenu"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = UDim2.fromOffset(360, 460)
frame.Position = UDim2.new(0.05, 0, 0.2, 0)
frame.BackgroundColor3 = Color3.fromRGB(24, 26, 34)
frame.BorderSizePixel = 0
frame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 10)
frameCorner.Parent = frame

local frameStroke = Instance.new("UIStroke")
frameStroke.Thickness = 1.2
frameStroke.Color = Color3.fromRGB(78, 92, 129)
frameStroke.Transparency = 0.25
frameStroke.Parent = frame

local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 46)
topBar.BackgroundColor3 = Color3.fromRGB(36, 40, 53)
topBar.BorderSizePixel = 0
topBar.Parent = frame

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 10)
topCorner.Parent = topBar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 1, 0)
title.Position = UDim2.fromOffset(12, 0)
title.BackgroundTransparency = 1
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "Authorized Controllers"
title.TextSize = 20
title.Font = Enum.Font.GothamBold
title.TextColor3 = Color3.fromRGB(230, 234, 255)
title.Parent = topBar

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -24, 0, 54)
subtitle.Position = UDim2.fromOffset(12, 52)
subtitle.BackgroundTransparency = 1
subtitle.TextWrapped = true
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Text = "Commands: /follow /stack [name] /side line /orbit /line /fly /fireworks /stop /funfact /swarm [name] /say <msg> /calc <a+b|a/b> /auth <name> /unauth <name> /commands"
subtitle.TextSize = 12
subtitle.Font = Enum.Font.Gotham
subtitle.TextColor3 = Color3.fromRGB(170, 182, 220)
subtitle.Parent = frame

local searchBox = Instance.new("TextBox")
searchBox.Name = "SearchBox"
searchBox.Size = UDim2.new(1, -24, 0, 30)
searchBox.Position = UDim2.fromOffset(12, 108)
searchBox.BackgroundColor3 = Color3.fromRGB(30, 34, 47)
searchBox.BorderSizePixel = 0
searchBox.PlaceholderText = "Search players..."
searchBox.Text = ""
searchBox.TextColor3 = Color3.fromRGB(230, 234, 255)
searchBox.PlaceholderColor3 = Color3.fromRGB(145, 156, 194)
searchBox.TextSize = 14
searchBox.Font = Enum.Font.Gotham
searchBox.ClearTextOnFocus = false
searchBox.Parent = frame

local searchCorner = Instance.new("UICorner")
searchCorner.CornerRadius = UDim.new(0, 8)
searchCorner.Parent = searchBox

local scrolling = Instance.new("ScrollingFrame")
scrolling.Name = "PlayerList"
scrolling.Size = UDim2.new(1, -24, 1, -152)
scrolling.Position = UDim2.fromOffset(12, 144)
scrolling.BackgroundColor3 = Color3.fromRGB(18, 20, 27)
scrolling.BorderSizePixel = 0
scrolling.ScrollBarThickness = 6
scrolling.CanvasSize = UDim2.fromOffset(0, 0)
scrolling.Parent = frame

local scrollingCorner = Instance.new("UICorner")
scrollingCorner.CornerRadius = UDim.new(0, 8)
scrollingCorner.Parent = scrolling

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.Parent = scrolling

local listPadding = Instance.new("UIPadding")
listPadding.PaddingTop = UDim.new(0, 10)
listPadding.PaddingBottom = UDim.new(0, 10)
listPadding.PaddingLeft = UDim.new(0, 10)
listPadding.PaddingRight = UDim.new(0, 10)
listPadding.Parent = scrolling

local function refreshButtonVisual(player)
	local button = buttonByPlayer[player]
	if not button then
		return
	end

	local stroke = button:FindFirstChildOfClass("UIStroke")
	local isAuthorized = authorizedControllers[player] == true
	local isPrimary = player == primaryController

	if isAuthorized then
		button.BackgroundColor3 = isPrimary and Color3.fromRGB(80, 120, 185) or Color3.fromRGB(64, 84, 150)
		if stroke then
			stroke.Transparency = 0
		end
	else
		button.BackgroundColor3 = Color3.fromRGB(38, 45, 66)
		if stroke then
			stroke.Transparency = 0.55
		end
	end

	local suffix = ""
	if isPrimary then
		suffix = " [PRIMARY]"
	elseif isAuthorized then
		suffix = " [AUTH]"
	end
	button.Text = player.DisplayName .. " (@" .. player.Name .. ")" .. suffix
end

local function refreshAllButtonVisuals()
	for player in pairs(buttonByPlayer) do
		refreshButtonVisual(player)
	end
end

local function createPlayerButton(player)
	if player == localPlayer then
		return
	end

	local query = normalizeMessage(searchText)
	if query ~= "" then
		local display = normalizeMessage(player.DisplayName)
		local username = normalizeMessage(player.Name)
		if not string.find(display, query, 1, true) and not string.find(username, query, 1, true) then
			return
		end
	end

	local button = Instance.new("TextButton")
	button.Name = player.Name
	button.Size = UDim2.new(1, 0, 0, 42)
	button.BackgroundColor3 = Color3.fromRGB(38, 45, 66)
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Font = Enum.Font.GothamMedium
	button.TextColor3 = Color3.fromRGB(223, 231, 255)
	button.TextSize = 16
	button.Text = player.DisplayName .. " (@" .. player.Name .. ")"
	button.Parent = scrolling

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.Color = Color3.fromRGB(100, 122, 187)
	stroke.Transparency = 0.55
	stroke.Parent = button

	buttonByPlayer[player] = button

	button.MouseButton1Click:Connect(function()
		local isAuthorized = authorizedControllers[player] == true
		if isAuthorized then
			setAuthorized(player, false)
		else
			setAuthorized(player, true)
		end
		refreshAllButtonVisuals()
	end)

	refreshButtonVisual(player)
end

local function refreshPlayerList()
	updatePreferredPrimary()

	buttonByPlayer = {}
	for _, child in ipairs(scrolling:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		createPlayerButton(player)
	end

	task.wait()
	scrolling.CanvasSize = UDim2.fromOffset(0, listLayout.AbsoluteContentSize.Y + 20)
	refreshAllButtonVisuals()
end

local function processCommand(speaker, message)
	if not authorizedControllers[speaker] then
		return
	end

	local normalized = normalizeMessage(message)
	if normalized == "/follow" then
		startMotion("follow", speaker)
		return
	elseif normalized == "/stack" then
		startMotion("stack", speaker, speaker)
		return
	elseif normalized == "/side line" then
		startMotion("side_line", speaker)
		return
	elseif normalized == "/orbit" then
		startMotion("orbit", speaker)
		return
	elseif normalized == "/line" then
		startMotion("line", speaker)
		return
	elseif normalized == "/fly" or normalized == "/shoulders" then
		startMotion("shoulders", speaker)
		return
	elseif normalized == "/fireworks" then
		startMotion("fireworks", speaker)
		return
	elseif normalized == "/stop" then
		clearMotion()
		currentController = nil
		stackTarget = nil
		return
	elseif normalized == "/commands" then
		sendChatMessage("/follow /stack [name] /side line /orbit /line /fly /fireworks /stop /funfact /swarm [name] /say /calc /auth /unauth /commands")
		return
	elseif normalized == "/funfact" then
		sendChatMessage("[funfact] " .. getRandomFunFact())
		return
	end

	local stackName = string.match(message or "", "^/stack%s+(.+)$")
	if stackName then
		local stackPlayer = findPlayerByName(stackName)
		if stackPlayer then
			startMotion("stack", speaker, stackPlayer)
		else
			sendChatMessage("[stack] player not found")
		end
		return
	end

	local swarmTargetName = string.match(message or "", "^/swarm%s+(.+)$")
	if swarmTargetName then
		local swarmTargetPlayer = findPlayerByName(swarmTargetName)
		if swarmTargetPlayer then
			startMotion("swarm", speaker, swarmTargetPlayer)
		else
			sendChatMessage("[swarm] player not found")
		end
		return
	end

	local authTarget = string.match(normalized, "^/auth%s+(.+)$")
	if authTarget then
		local player = findPlayerByName(authTarget)
		if player then
			setAuthorized(player, true)
			refreshAllButtonVisuals()
		end
		return
	end

	local unauthTarget = string.match(normalized, "^/unauth%s+(.+)$")
	if unauthTarget then
		local player = findPlayerByName(unauthTarget)
		if player then
			setAuthorized(player, false)
			refreshAllButtonVisuals()
		end
		return
	end

	local sayMessage = string.match(message or "", "^/say%s+(.+)$")
	if sayMessage and sayMessage ~= "" then
		sendChatMessage(sayMessage)
		return
	end

	local calcExpression = string.match(message or "", "^/calc%s+(.+)$")
	if calcExpression then
		local result, err = calculateExpression(calcExpression)
		if err then
			sendChatMessage("[calc] " .. err)
		else
			local resultText = tostring(math.floor(result * 10000 + 0.5) / 10000)
			sendChatMessage("[calc] " .. calcExpression .. " = " .. resultText)
		end
	end
end

local function hookLegacyChat(player)
	if chatConnections[player] then
		chatConnections[player]:Disconnect()
	end

	chatConnections[player] = player.Chatted:Connect(function(message)
		processCommand(player, message)
	end)
end

for _, player in ipairs(Players:GetPlayers()) do
	if player ~= localPlayer then
		hookLegacyChat(player)
	end
end

Players.PlayerAdded:Connect(function(player)
	if player ~= localPlayer then
		hookLegacyChat(player)
	end
	refreshPlayerList()
end)

Players.PlayerRemoving:Connect(function(player)
	if chatConnections[player] then
		chatConnections[player]:Disconnect()
		chatConnections[player] = nil
	end

	authorizedControllers[player] = nil
	buttonByPlayer[player] = nil

	if currentController == player or stackTarget == player then
		clearMotion()
		currentController = nil
		stackTarget = nil
	end

	refreshPlayerList()
end)

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scrolling.CanvasSize = UDim2.fromOffset(0, listLayout.AbsoluteContentSize.Y + 20)
end)

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	searchText = searchBox.Text
	refreshPlayerList()
end)

if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
	TextChatService.MessageReceived:Connect(function(textChatMessage)
		if not textChatMessage.TextSource then
			return
		end
		local speaker = Players:GetPlayerByUserId(textChatMessage.TextSource.UserId)
		if speaker then
			processCommand(speaker, textChatMessage.Text)
		end
	end)
end

optimizeClientPerformance()
refreshPlayerList()

local dragging = false
local dragStart
local frameStart

local function startDrag(input)
	dragging = true
	dragStart = input.Position
	frameStart = frame.Position
end

local function updateDrag(input)
	if not dragging then
		return
	end
	local delta = input.Position - dragStart
	frame.Position = UDim2.new(
		frameStart.X.Scale,
		frameStart.X.Offset + delta.X,
		frameStart.Y.Scale,
		frameStart.Y.Offset + delta.Y
	)
end

topBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		startDrag(input)
	end
end)

topBar.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		updateDrag(input)
	end
end)
