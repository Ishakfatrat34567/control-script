local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local authorizedControllers = {}
local activeTarget = nil
local followConnection = nil
local orbitConnection = nil
local chatConnections = {}

local ORBIT_RADIUS = 6
local ORBIT_HEIGHT = 3
local ORBIT_SPEED = 2

local function clearMotion()
	if followConnection then
		followConnection:Disconnect()
		followConnection = nil
	end
	if orbitConnection then
		orbitConnection:Disconnect()
		orbitConnection = nil
	end
end

local function characterAndRoot(player)
	local character = player.Character
	if not character then
		return nil, nil
	end
	return character, character:FindFirstChild("HumanoidRootPart")
end

local function moveNearTarget(targetRoot, offset)
	local _, localRoot = characterAndRoot(localPlayer)
	if not localRoot or not targetRoot then
		return
	end
	localRoot.CFrame = targetRoot.CFrame * offset
end

local function startFollow(targetPlayer)
	clearMotion()

	followConnection = RunService.Heartbeat:Connect(function()
		if not targetPlayer or targetPlayer.Parent ~= Players then
			clearMotion()
			return
		end
		local _, targetRoot = characterAndRoot(targetPlayer)
		if targetRoot then
			moveNearTarget(targetRoot, CFrame.new(0, 0, -2.5))
		end
	end)
end

local function startOrbit(targetPlayer)
	clearMotion()
	local angle = 0

	orbitConnection = RunService.Heartbeat:Connect(function(deltaTime)
		if not targetPlayer or targetPlayer.Parent ~= Players then
			clearMotion()
			return
		end

		local _, targetRoot = characterAndRoot(targetPlayer)
		if not targetRoot then
			return
		end

		angle += deltaTime * (ORBIT_SPEED * math.pi)
		local x = math.cos(angle) * ORBIT_RADIUS
		local z = math.sin(angle) * ORBIT_RADIUS
		moveNearTarget(targetRoot, CFrame.new(x, ORBIT_HEIGHT, z))
	end)
end

local function stopMotion()
	clearMotion()
end

local function normalizeMessage(message)
	return string.lower((message or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function processCommand(speaker, message)
	if not authorizedControllers[speaker] then
		return
	end
	if activeTarget ~= speaker then
		return
	end

	local normalized = normalizeMessage(message)
	if normalized == "/follow" then
		startFollow(speaker)
	elseif normalized == "/orbit" then
		startOrbit(speaker)
	elseif normalized == "/stop" then
		stopMotion()
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
end)

Players.PlayerRemoving:Connect(function(player)
	if chatConnections[player] then
		chatConnections[player]:Disconnect()
		chatConnections[player] = nil
	end
	authorizedControllers[player] = nil
	if activeTarget == player then
		activeTarget = nil
		stopMotion()
	end
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

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ControllerMenu"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = UDim2.fromOffset(340, 420)
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
title.Text = "Authorized Controller"
title.TextSize = 20
title.Font = Enum.Font.GothamBold
title.TextColor3 = Color3.fromRGB(230, 234, 255)
title.Parent = topBar

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -24, 0, 24)
subtitle.Position = UDim2.fromOffset(12, 52)
subtitle.BackgroundTransparency = 1
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Text = "Pick one player to authorize: /follow /orbit /stop"
subtitle.TextSize = 13
subtitle.Font = Enum.Font.Gotham
subtitle.TextColor3 = Color3.fromRGB(170, 182, 220)
subtitle.Parent = frame

local scrolling = Instance.new("ScrollingFrame")
scrolling.Name = "PlayerList"
scrolling.Size = UDim2.new(1, -24, 1, -98)
scrolling.Position = UDim2.fromOffset(12, 84)
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

local function setAuthorized(targetPlayer)
	activeTarget = targetPlayer
	for player in pairs(authorizedControllers) do
		authorizedControllers[player] = false
	end
	if targetPlayer then
		authorizedControllers[targetPlayer] = true
	end
end

local function createPlayerButton(player)
	if player == localPlayer then
		return
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

	local function refreshVisual()
		if activeTarget == player then
			button.BackgroundColor3 = Color3.fromRGB(64, 84, 150)
			stroke.Transparency = 0
		else
			button.BackgroundColor3 = Color3.fromRGB(38, 45, 66)
			stroke.Transparency = 0.55
		end
	end

	button.MouseButton1Click:Connect(function()
		setAuthorized(player)
		refreshVisual()
		for _, child in ipairs(scrolling:GetChildren()) do
			if child:IsA("TextButton") and child ~= button then
				child.BackgroundColor3 = Color3.fromRGB(38, 45, 66)
				local childStroke = child:FindFirstChildOfClass("UIStroke")
				if childStroke then
					childStroke.Transparency = 0.55
				end
			end
		end
	end)

	refreshVisual()
end

local function refreshPlayerList()
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
end

Players.PlayerAdded:Connect(refreshPlayerList)
Players.PlayerRemoving:Connect(refreshPlayerList)
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scrolling.CanvasSize = UDim2.fromOffset(0, listLayout.AbsoluteContentSize.Y + 20)
end)

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
