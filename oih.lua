local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local playerGui = player:WaitForChild("PlayerGui")

if playerGui:FindFirstChild("OiHHub") then
	playerGui.OiHHub:Destroy()
end

local config = {
	lang = "RU", -- "RU" по умолчанию, переключается на "EN"
	fly = false,
	airJump = false,
	holdJump = false,
	noclip = false,
	speedBoost = false,
	jumpBoost = false,
	spin = false,
	clickTp = false,
	customFov = false,
	customGravity = false,
	fullbright = false,
	noFog = false,
	antiAfk = false,
	autoRespawn = false,
}

local values = {
	flySpeed = 60,
	airJumpPower = 52,
	airJumpDelay = 0.25,
	walkSpeed = 32,
	jumpPower = 75,
	spinSpeed = 12,
	fov = 75,
	gravity = 196,
}

local defaults = {
	walkSpeed = 16,
	jumpPower = 50,
	fov = camera.FieldOfView,
	gravity = workspace.Gravity,
}

local lastAirJumpTime = 0
local jumpHeld = false
local savedCollides = {}

local savedLighting = {
	Brightness = Lighting.Brightness,
	ClockTime = Lighting.ClockTime,
	FogEnd = Lighting.FogEnd,
	GlobalShadows = Lighting.GlobalShadows,
}

local LOCALE = {
	RU = {
		title = "OiH HUB PRO",
		secMove = "Движение и полёт",
		secWorld = "Камера и мир",
		secUtil = "Утилиты",
		fly = "Полёт (Fly)",
		flySpeed = "Скорость полёта",
		airJump = "Прыжок в воздухе",
		holdJump = "Удержание прыжка",
		airJumpPower = "Сила прыжка в воздухе",
		airJumpDelay = "Задержка прыжка (сек)",
		noclip = "Сквозь стены (Noclip)",
		speedBoost = "Буст скорости",
		walkSpeed = "Скорость бега",
		jumpBoost = "Буст прыжка",
		jumpPower = "Сила прыжка",
		spin = "Вращение",
		spinSpeed = "Скорость вращения",
		clickTp = "Телепорт кликом",
		customFov = "Свой FOV",
		fov = "Угол обзора (FOV)",
		customGravity = "Своя гравитация",
		gravity = "Гравитация",
		fullbright = "Яркий свет",
		noFog = "Убрать туман",
		antiAfk = "Анти-АФК",
		autoRespawn = "Авто-респавн",
		copyPos = "Копировать позицию",
		resetChar = "Перезапустить персонажа",
		confirmTitle = "Закрыть OiH?",
		confirmDesc = "Все активные функции будут отключены, а меню закроется.",
		cancel = "Отмена",
		close = "Закрыть",
		lockedHint = "Заблокировано при Hold Jump",
	},
	EN = {
		title = "OiH HUB PRO",
		secMove = "Movement & Flight",
		secWorld = "Camera & World",
		secUtil = "Utilities",
		fly = "Fly",
		flySpeed = "Fly Speed",
		airJump = "Air Jump",
		holdJump = "Hold Jump",
		airJumpPower = "AirJump Power",
		airJumpDelay = "AirJump Delay (s)",
		noclip = "Noclip",
		speedBoost = "Speed Boost",
		walkSpeed = "WalkSpeed",
		jumpBoost = "Jump Boost",
		jumpPower = "JumpPower",
		spin = "Spin",
		spinSpeed = "Spin Speed",
		clickTp = "Click TP",
		customFov = "Custom FOV",
		fov = "FOV",
		customGravity = "Custom Gravity",
		gravity = "Gravity",
		fullbright = "Fullbright",
		noFog = "No Fog",
		antiAfk = "Anti-AFK",
		autoRespawn = "Auto Respawn",
		copyPos = "Copy Position",
		resetChar = "Reset Character",
		confirmTitle = "Close OiH?",
		confirmDesc = "All active features will be disabled and the menu will close.",
		cancel = "Cancel",
		close = "Close",
		lockedHint = "Locked while Hold Jump is ON",
	},
}

local function tr(key)
	local pack = LOCALE[config.lang] or LOCALE.RU
	return pack[key] or LOCALE.RU[key] or key
end

local function getChar()
	local char = player.Character
	if not char then return nil, nil, nil end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	return char, hum, root
end

local function applySpeedBoost(enabled)
	local _, hum = getChar()
	if not hum then return end
	if enabled then
		hum.WalkSpeed = values.walkSpeed
	else
		hum.WalkSpeed = defaults.walkSpeed
	end
end

local function applyJumpBoost(enabled)
	local _, hum = getChar()
	if not hum then return end
	hum.UseJumpPower = true
	if enabled then
		hum.JumpPower = values.jumpPower
	else
		hum.JumpPower = defaults.jumpPower
	end
end

local function applyFullbright(enabled)
	if enabled then
		Lighting.Brightness = 2
		Lighting.ClockTime = 14
		Lighting.GlobalShadows = false
		if not config.noFog then
			Lighting.FogEnd = 100000
		end
	else
		Lighting.Brightness = savedLighting.Brightness
		Lighting.ClockTime = savedLighting.ClockTime
		Lighting.GlobalShadows = savedLighting.GlobalShadows
		if not config.noFog then
			Lighting.FogEnd = savedLighting.FogEnd
		end
	end
end

local function applyNoFog(enabled)
	if enabled then
		Lighting.FogEnd = 100000
		for _, obj in ipairs(Lighting:GetDescendants()) do
			if obj:IsA("Atmosphere") then
				obj.Density = 0
			end
		end
	else
		Lighting.FogEnd = savedLighting.FogEnd
		for _, obj in ipairs(Lighting:GetDescendants()) do
			if obj:IsA("Atmosphere") then
				obj.Density = 0.3
			end
		end
	end
end

local function applyFov()
	camera.FieldOfView = config.customFov and values.fov or defaults.fov
end

local function applyGravity()
	workspace.Gravity = config.customGravity and values.gravity or defaults.gravity
end

local function restoreNoclip()
	for part, oldCollide in pairs(savedCollides) do
		if part and part.Parent then
			part.CanCollide = oldCollide
		end
	end
	table.clear(savedCollides)
end

local function cleanupAll()
	restoreNoclip()
	applyFullbright(false)
	applyNoFog(false)
	applySpeedBoost(false)
	applyJumpBoost(false)
	camera.FieldOfView = defaults.fov
	workspace.Gravity = defaults.gravity
end

-- Anti-AFK
player.Idled:Connect(function()
	if config.antiAfk then
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end
end)

-- Хук персонажа: запоминаем стандартные WalkSpeed/JumpPower и возвращаем при отключении бустов
local function hookCharacter(char)
	local hum = char:WaitForChild("Humanoid", 10)
	if hum then
		defaults.walkSpeed = hum.WalkSpeed
		hum.UseJumpPower = true
		defaults.jumpPower = hum.JumpPower > 0 and hum.JumpPower or 50

		if config.speedBoost then
			hum.WalkSpeed = values.walkSpeed
		end
		if config.jumpBoost then
			hum.JumpPower = values.jumpPower
		end

		hum.Died:Connect(function()
			if config.autoRespawn then
				task.wait(0.25)
				player:LoadCharacter()
			end
		end)
	end
end

if player.Character then
	hookCharacter(player.Character)
end
player.CharacterAdded:Connect(hookCharacter)

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "OiHHub"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local floatIcon = Instance.new("TextButton")
floatIcon.Name = "FloatingIcon"
floatIcon.Size = UDim2.new(0, 54, 0, 54)
floatIcon.Position = UDim2.new(0.04, 0, 0.2, 0)
floatIcon.BackgroundColor3 = Color3.fromRGB(32, 37, 52)
floatIcon.BorderSizePixel = 0
floatIcon.Text = "OiH"
floatIcon.TextColor3 = Color3.fromRGB(240, 246, 255)
floatIcon.Font = Enum.Font.GothamBold
floatIcon.TextSize = 15
floatIcon.Visible = false
floatIcon.ZIndex = 20
floatIcon.Parent = gui

local floatCorner = Instance.new("UICorner")
floatCorner.CornerRadius = UDim.new(1, 0)
floatCorner.Parent = floatIcon

local floatStroke = Instance.new("UIStroke")
floatStroke.Color = Color3.fromRGB(95, 125, 210)
floatStroke.Thickness = 2
floatStroke.Parent = floatIcon

local fullSize = UDim2.new(0, 305, 0, 450)
local main = Instance.new("Frame")
main.Name = "MainFrame"
main.Size = fullSize
main.Position = UDim2.new(0.04, 0, 0.14, 0)
main.BackgroundColor3 = Color3.fromRGB(19, 21, 27)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = main

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(65, 74, 96)
mainStroke.Thickness = 1.2
mainStroke.Parent = main

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundColor3 = Color3.fromRGB(28, 32, 42)
header.BorderSizePixel = 0
header.Parent = main

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -116, 1, 0)
title.Position = UDim2.new(0, 14, 0, 0)
title.BackgroundTransparency = 1
title.Text = tr("title")
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(240, 244, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Parent = header

local langBtn = Instance.new("TextButton")
langBtn.Size = UDim2.new(0, 34, 0, 28)
langBtn.Position = UDim2.new(1, -104, 0.5, -14)
langBtn.BackgroundColor3 = Color3.fromRGB(55, 72, 118)
langBtn.Text = "RU"
langBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
langBtn.Font = Enum.Font.GothamBold
langBtn.TextSize = 11
langBtn.Parent = header

local langCorner = Instance.new("UICorner")
langCorner.CornerRadius = UDim.new(0, 7)
langCorner.Parent = langBtn

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 28, 0, 28)
minBtn.Position = UDim2.new(1, -66, 0.5, -14)
minBtn.BackgroundColor3 = Color3.fromRGB(45, 51, 68)
minBtn.Text = "-"
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 16
minBtn.Parent = header

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 7)
minCorner.Parent = minBtn

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -34, 0.5, -14)
closeBtn.BackgroundColor3 = Color3.fromRGB(150, 45, 55)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 13
closeBtn.Parent = header

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 7)
closeCorner.Parent = closeBtn

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -16, 1, -50)
scroll.Position = UDim2.new(0, 8, 0, 46)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = main

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 7)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

local pad = Instance.new("UIPadding")
pad.PaddingBottom = UDim.new(0, 10)
pad.Parent = scroll

-- Модальное окно предупреждения о закрытии
local confirmOverlay = Instance.new("Frame")
confirmOverlay.Name = "ConfirmOverlay"
confirmOverlay.Size = UDim2.new(1, 0, 1, 0)
confirmOverlay.BackgroundColor3 = Color3.fromRGB(10, 12, 16)
confirmOverlay.BackgroundTransparency = 0.35
confirmOverlay.BorderSizePixel = 0
confirmOverlay.Visible = false
confirmOverlay.ZIndex = 15
confirmOverlay.Parent = main

local overlayCorner = Instance.new("UICorner")
overlayCorner.CornerRadius = UDim.new(0, 12)
overlayCorner.Parent = confirmOverlay

local confirmBox = Instance.new("Frame")
confirmBox.Name = "ConfirmBox"
confirmBox.Size = UDim2.new(0.86, 0, 0, 152)
confirmBox.Position = UDim2.new(0.07, 0, 0.5, -76)
confirmBox.BackgroundColor3 = Color3.fromRGB(28, 32, 42)
confirmBox.BorderSizePixel = 0
confirmBox.ZIndex = 16
confirmBox.Parent = confirmOverlay

local confirmCorner = Instance.new("UICorner")
confirmCorner.CornerRadius = UDim.new(0, 10)
confirmCorner.Parent = confirmBox

local confirmStroke = Instance.new("UIStroke")
confirmStroke.Color = Color3.fromRGB(185, 70, 80)
confirmStroke.Thickness = 1.4
confirmStroke.Parent = confirmBox

local confirmTitle = Instance.new("TextLabel")
confirmTitle.Size = UDim2.new(1, -20, 0, 28)
confirmTitle.Position = UDim2.new(0, 10, 0, 10)
confirmTitle.BackgroundTransparency = 1
confirmTitle.Text = tr("confirmTitle")
confirmTitle.TextColor3 = Color3.fromRGB(255, 240, 240)
confirmTitle.Font = Enum.Font.GothamBold
confirmTitle.TextSize = 15
confirmTitle.ZIndex = 17
confirmTitle.Parent = confirmBox

local confirmDesc = Instance.new("TextLabel")
confirmDesc.Size = UDim2.new(1, -24, 0, 48)
confirmDesc.Position = UDim2.new(0, 12, 0, 38)
confirmDesc.BackgroundTransparency = 1
confirmDesc.Text = tr("confirmDesc")
confirmDesc.TextWrapped = true
confirmDesc.TextColor3 = Color3.fromRGB(195, 202, 220)
confirmDesc.Font = Enum.Font.GothamMedium
confirmDesc.TextSize = 12
confirmDesc.ZIndex = 17
confirmDesc.Parent = confirmBox

local cancelBtn = Instance.new("TextButton")
cancelBtn.Size = UDim2.new(0.43, 0, 0, 34)
cancelBtn.Position = UDim2.new(0.05, 0, 1, -46)
cancelBtn.BackgroundColor3 = Color3.fromRGB(52, 58, 76)
cancelBtn.Text = tr("cancel")
cancelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
cancelBtn.Font = Enum.Font.GothamBold
cancelBtn.TextSize = 12
cancelBtn.ZIndex = 17
cancelBtn.Parent = confirmBox

local cancelCorner = Instance.new("UICorner")
cancelCorner.CornerRadius = UDim.new(0, 7)
cancelCorner.Parent = cancelBtn

local acceptCloseBtn = Instance.new("TextButton")
acceptCloseBtn.Size = UDim2.new(0.43, 0, 0, 34)
acceptCloseBtn.Position = UDim2.new(0.52, 0, 1, -46)
acceptCloseBtn.BackgroundColor3 = Color3.fromRGB(165, 48, 58)
acceptCloseBtn.Text = tr("close")
acceptCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
acceptCloseBtn.Font = Enum.Font.GothamBold
acceptCloseBtn.TextSize = 12
acceptCloseBtn.ZIndex = 17
acceptCloseBtn.Parent = confirmBox

local acceptCorner = Instance.new("UICorner")
acceptCorner.CornerRadius = UDim.new(0, 7)
acceptCorner.Parent = acceptCloseBtn

-- Плавное открытие/закрытие окна через иконку OiH
local isHubOpen = true
local isAnimating = false

local function setHubOpen(open)
	if isAnimating or isHubOpen == open then return end
	isAnimating = true
	isHubOpen = open

	if open then
		main.Position = UDim2.new(
			floatIcon.Position.X.Scale,
			floatIcon.Position.X.Offset,
			floatIcon.Position.Y.Scale,
			floatIcon.Position.Y.Offset
		)
		main.Size = UDim2.new(0, 54, 0, 54)
		main.BackgroundTransparency = 1
		main.Visible = true
		floatIcon.Visible = false

		local tween = TweenService:Create(
			main,
			TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{
				Size = fullSize,
				BackgroundTransparency = 0,
			}
		)
		tween:Play()
		tween.Completed:Connect(function()
			isAnimating = false
		end)
	else
		confirmOverlay.Visible = false
		floatIcon.Position = UDim2.new(
			main.Position.X.Scale,
			main.Position.X.Offset,
			main.Position.Y.Scale,
			main.Position.Y.Offset
		)

		local tween = TweenService:Create(
			main,
			TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
			{
				Size = UDim2.new(0, 54, 0, 54),
				BackgroundTransparency = 1,
			}
		)
		tween:Play()
		tween.Completed:Connect(function()
			main.Visible = false
			main.Size = fullSize
			main.BackgroundTransparency = 0
			floatIcon.Visible = true
			isAnimating = false
		end)
	end
end

local draggingIcon = false
local movedEnough = false
local dragStartInputPos = Vector2.zero
local iconStartOffset = Vector2.zero
local iconStartScale = Vector2.zero
local activeDragTween = nil

floatIcon.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingIcon = true
		movedEnough = false
		dragStartInputPos = input.Position
		iconStartScale = Vector2.new(floatIcon.Position.X.Scale, floatIcon.Position.Y.Scale)
		iconStartOffset = Vector2.new(floatIcon.Position.X.Offset, floatIcon.Position.Y.Offset)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not draggingIcon then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		local delta = input.Position - dragStartInputPos
		if delta.Magnitude > 6 then
			movedEnough = true
		end

		local targetPos = UDim2.new(
			iconStartScale.X,
			iconStartOffset.X + delta.X,
			iconStartScale.Y,
			iconStartOffset.Y + delta.Y
		)

		if activeDragTween then
			activeDragTween:Cancel()
		end
		activeDragTween = TweenService:Create(
			floatIcon,
			TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Position = targetPos }
		)
		activeDragTween:Play()
	end
end)

floatIcon.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		if draggingIcon then
			draggingIcon = false
			if not movedEnough then
				setHubOpen(not isHubOpen)
			end
		end
	end
end)

minBtn.MouseButton1Click:Connect(function()
	setHubOpen(false)
end)

closeBtn.MouseButton1Click:Connect(function()
	confirmOverlay.Visible = true
end)

cancelBtn.MouseButton1Click:Connect(function()
	confirmOverlay.Visible = false
end)

acceptCloseBtn.MouseButton1Click:Connect(function()
	cleanupAll()
	gui:Destroy()
end)

-- Система перевода всех элементов
local uiUpdaters = {}

local orderCounter = 0
local function nextOrder()
	orderCounter += 1
	return orderCounter
end

local function createSection(localeKey)
	local lbl = Instance.new("TextLabel")
	lbl.LayoutOrder = nextOrder()
	lbl.Size = UDim2.new(1, 0, 0, 22)
	lbl.BackgroundTransparency = 1
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextColor3 = Color3.fromRGB(130, 155, 210)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 11
	lbl.Parent = scroll

	local function refresh()
		lbl.Text = string.upper(tr(localeKey))
	end
	refresh()
	table.insert(uiUpdaters, refresh)
end

local function createToggle(localeKey, key, onChanged)
	local btn = Instance.new("TextButton")
	btn.LayoutOrder = nextOrder()
	btn.Size = UDim2.new(1, 0, 0, 34)
	btn.BackgroundColor3 = Color3.fromRGB(33, 37, 49)
	btn.BorderSizePixel = 0
	btn.TextColor3 = Color3.fromRGB(220, 225, 240)
	btn.Font = Enum.Font.GothamSemibold
	btn.TextSize = 13
	btn.Parent = scroll

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = btn

	local function refresh()
		local stateStr = config[key] and "[ON]" or "[OFF]"
		btn.Text = tr(localeKey) .. "  " .. stateStr
		if config[key] then
			btn.BackgroundColor3 = Color3.fromRGB(38, 125, 82)
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			btn.BackgroundColor3 = Color3.fromRGB(33, 37, 49)
			btn.TextColor3 = Color3.fromRGB(220, 225, 240)
		end
	end

	btn.MouseButton1Click:Connect(function()
		config[key] = not config[key]
		refresh()
		if onChanged then
			onChanged(config[key])
		end
	end)

	refresh()
	table.insert(uiUpdaters, refresh)
	return refresh
end

local function createNumberInput(localeKey, tableRef, field, minVal, maxVal, allowDecimals, lockChecker, onValueChanged)
	local row = Instance.new("Frame")
	row.LayoutOrder = nextOrder()
	row.Size = UDim2.new(1, 0, 0, 34)
	row.BackgroundColor3 = Color3.fromRGB(27, 30, 40)
	row.BorderSizePixel = 0
	row.Parent = scroll

	local rc = Instance.new("UICorner")
	rc.CornerRadius = UDim.new(0, 8)
	rc.Parent = row

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0.62, -8, 1, 0)
	lbl.Position = UDim2.new(0, 10, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextColor3 = Color3.fromRGB(210, 215, 230)
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 12
	lbl.Parent = row

	local box = Instance.new("TextBox")
	box.Size = UDim2.new(0.35, 0, 0, 24)
	box.Position = UDim2.new(0.63, 0, 0.5, -12)
	box.BackgroundColor3 = Color3.fromRGB(42, 47, 63)
	box.BorderSizePixel = 0
	box.ClearTextOnFocus = false
	box.Text = tostring(tableRef[field])
	box.TextColor3 = Color3.fromRGB(255, 255, 255)
	box.Font = Enum.Font.GothamBold
	box.TextSize = 12
	box.Parent = row

	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 6)
	bc.Parent = box

	local function refreshState()
		lbl.Text = tr(localeKey)
		box.Text = tostring(tableRef[field])
		local isLocked = lockChecker and lockChecker() or false
		box.TextEditable = not isLocked
		box.Active = not isLocked
		if isLocked then
			box.BackgroundColor3 = Color3.fromRGB(68, 36, 42)
			box.TextColor3 = Color3.fromRGB(255, 175, 180)
		else
			box.BackgroundColor3 = Color3.fromRGB(42, 47, 63)
			box.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	end

	local function commitValue()
		if lockChecker and lockChecker() then
			box.Text = tostring(tableRef[field])
			return
		end
		local raw = string.gsub(box.Text, ",", ".")
		local num = tonumber(raw)
		if num then
			num = math.clamp(num, minVal, maxVal)
			if not allowDecimals then
				num = math.floor(num + 0.5)
			else
				num = math.floor(num * 100 + 0.5) / 100
			end
			tableRef[field] = num
			box.Text = tostring(num)
			if onValueChanged then
				onValueChanged(num)
			end
		else
			box.Text = tostring(tableRef[field])
		end
	end

	box.FocusLost:Connect(commitValue)

	refreshState()
	table.insert(uiUpdaters, refreshState)
	return refreshState
end

local function createAction(localeKey, callback)
	local btn = Instance.new("TextButton")
	btn.LayoutOrder = nextOrder()
	btn.Size = UDim2.new(1, 0, 0, 34)
	btn.BackgroundColor3 = Color3.fromRGB(52, 66, 110)
	btn.BorderSizePixel = 0
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 12
	btn.Parent = scroll

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = btn

	btn.MouseButton1Click:Connect(callback)

	local function refresh()
		btn.Text = tr(localeKey)
	end
	refresh()
	table.insert(uiUpdaters, refresh)
end

local refreshDelayInput = nil

-- Секции и функции
createSection("secMove")
createToggle("fly", "fly")
createNumberInput("flySpeed", values, "flySpeed", 10, 300, false)

createToggle("airJump", "airJump")
createToggle("holdJump", "holdJump", function()
	if refreshDelayInput then
		refreshDelayInput()
	end
end)
createNumberInput("airJumpPower", values, "airJumpPower", 15, 200, false)
refreshDelayInput = createNumberInput("airJumpDelay", values, "airJumpDelay", 0.05, 3.0, true, function()
	return config.holdJump
end)

createToggle("noclip", "noclip", function(on)
	if not on then
		restoreNoclip()
	end
end)
createToggle("speedBoost", "speedBoost", applySpeedBoost)
createNumberInput("walkSpeed", values, "walkSpeed", 8, 250, false, nil, function()
	if config.speedBoost then
		applySpeedBoost(true)
	end
end)
createToggle("jumpBoost", "jumpBoost", applyJumpBoost)
createNumberInput("jumpPower", values, "jumpPower", 20, 300, false, nil, function()
	if config.jumpBoost then
		applyJumpBoost(true)
	end
end)
createToggle("spin", "spin")
createNumberInput("spinSpeed", values, "spinSpeed", 1, 80, false)
createToggle("clickTp", "clickTp")

createSection("secWorld")
createToggle("customFov", "customFov", applyFov)
createNumberInput("fov", values, "fov", 40, 120, false, nil, function()
	if config.customFov then
		applyFov()
	end
end)
createToggle("customGravity", "customGravity", applyGravity)
createNumberInput("gravity", values, "gravity", 10, 500, false, nil, function()
	if config.customGravity then
		applyGravity()
	end
end)
createToggle("fullbright", "fullbright", applyFullbright)
createToggle("noFog", "noFog", applyNoFog)

createSection("secUtil")
createToggle("antiAfk", "antiAfk")
createToggle("autoRespawn", "autoRespawn")
createAction("copyPos", function()
	local _, _, root = getChar()
	if root and setclipboard then
		local pos = root.Position
		setclipboard(string.format("%.1f, %.1f, %.1f", pos.X, pos.Y, pos.Z))
	end
end)
createAction("resetChar", function()
	local _, hum = getChar()
	if hum then
		hum.Health = 0
	end
end)

local function applyLanguage(newLang)
	config.lang = newLang
	langBtn.Text = newLang
	title.Text = tr("title")
	confirmTitle.Text = tr("confirmTitle")
	confirmDesc.Text = tr("confirmDesc")
	cancelBtn.Text = tr("cancel")
	acceptCloseBtn.Text = tr("close")
	for _, fn in ipairs(uiUpdaters) do
		fn()
	end
end

langBtn.MouseButton1Click:Connect(function()
	applyLanguage(config.lang == "RU" and "EN" or "RU")
end)

-- Click TP
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.Space then
		jumpHeld = true
	end

	if gameProcessed then return end
	if not config.clickTp then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		local _, _, root = getChar()
		if not root then return end

		local pos2D = input.Position
		local ray = camera:ViewportPointToRay(pos2D.X, pos2D.Y)
		local params = RaycastParams.new()
		params.FilterDescendantsInstances = { player.Character }
		params.FilterType = Enum.RaycastFilterType.Exclude

		local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
		if result then
			root.CFrame = CFrame.new(result.Position + Vector3.new(0, 3.5, 0))
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Space then
		jumpHeld = false
	end
end)

local function tryAirJump()
	if config.fly then return end
	if not config.airJump and not config.holdJump then return end

	local _, hum, root = getChar()
	if not hum or not root then return end

	local now = os.clock()
	if (now - lastAirJumpTime) < values.airJumpDelay then
		return
	end
	lastAirJumpTime = now

	local currentVel = root.AssemblyLinearVelocity
	root.AssemblyLinearVelocity = Vector3.new(
		currentVel.X,
		values.airJumpPower,
		currentVel.Z
	)
end

-- Обычное нажатие прыжка (ПК + мобильный)
UserInputService.JumpRequest:Connect(function()
	if config.airJump then
		tryAirJump()
	end
end)

-- Главный цикл
RunService.RenderStepped:Connect(function(dt)
	local char, hum, root = getChar()
	if not char or not hum or not root then return end

	-- Удержание прыжка (Hold Jump): работает когда включён Hold Jump и зажат прыжок
	if config.holdJump and (jumpHeld or UserInputService:IsKeyDown(Enum.KeyCode.Space)) then
		tryAirJump()
	end

	-- Бусты скорости и прыжка: применяем при включении, возвращаем стандарт при выключении
	if config.speedBoost then
		if hum.WalkSpeed ~= values.walkSpeed then
			hum.WalkSpeed = values.walkSpeed
		end
	elseif hum.WalkSpeed == values.walkSpeed then
		hum.WalkSpeed = defaults.walkSpeed
	end

	if config.jumpBoost then
		hum.UseJumpPower = true
		if hum.JumpPower ~= values.jumpPower then
			hum.JumpPower = values.jumpPower
		end
	elseif hum.JumpPower == values.jumpPower then
		hum.JumpPower = defaults.jumpPower
	end

	if config.noclip then
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then
				if savedCollides[part] == nil then
					savedCollides[part] = part.CanCollide
				end
				part.CanCollide = false
			end
		end
	end

	if config.spin then
		root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(values.spinSpeed * 60 * dt), 0)
	end

	if config.fly then
		local moveDir = hum.MoveDirection
		local velocity = Vector3.zero

		if moveDir.Magnitude > 0 then
			local lookDir = camera.CFrame.LookVector
			local rightDir = camera.CFrame.RightVector
			local forwardInput = moveDir:Dot(lookDir)
			local rightInput = moveDir:Dot(rightDir)

			local flyDir = lookDir * forwardInput + rightDir * rightInput
			if flyDir.Magnitude > 0 then
				flyDir = flyDir.Unit
			end
			velocity = flyDir * values.flySpeed
		end

		root.AssemblyLinearVelocity = velocity
	end
end)
