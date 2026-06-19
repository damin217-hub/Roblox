local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalizationService = game:GetService("LocalizationService")
local Localization = require(ReplicatedStorage.ArtAcademy.Localization)
local CanvasController = require(script.Parent.CanvasController)

local UIController = {}
UIController.__index = UIController

local function corner(parent, radius)
	local value = Instance.new("UICorner")
	value.CornerRadius = UDim.new(0, radius or 12)
	value.Parent = parent
	return value
end

local function text(parent, value, size, position, textSize, bold)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = size
	label.Position = position
	label.Text = value
	label.TextColor3 = Color3.fromRGB(35, 38, 55)
	label.TextSize = textSize or 18
	label.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	label.TextWrapped = true
	label.Parent = parent
	return label
end

local function button(parent, value, size, position, color)
	local item = Instance.new("TextButton")
	item.Size = size
	item.Position = position
	item.Text = value
	item.TextColor3 = Color3.new(1, 1, 1)
	item.TextSize = 16
	item.Font = Enum.Font.GothamBold
	item.BackgroundColor3 = color or Color3.fromRGB(112, 83, 245)
	item.AutoButtonColor = true
	item.Parent = parent
	corner(item, 10)
	return item
end

function UIController.new(remotes)
	local self = setmetatable({}, UIController)
	self.player = Players.LocalPlayer
	self.remotes = remotes
	self.strings = Localization(LocalizationService.RobloxLocaleId)
	self.hidden = false
	self.lastState = nil
	return self
end

function UIController:build()
	local gui = Instance.new("ScreenGui")
	gui.Name = "ArtAcademyUI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = self.player.PlayerGui

	local backdrop = Instance.new("Frame")
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3 = Color3.fromRGB(238, 232, 255)
	backdrop.BackgroundTransparency = 0.08
	backdrop.Parent = gui

	local top = Instance.new("Frame")
	top.Size = UDim2.new(1, -24, 0, 76)
	top.Position = UDim2.fromOffset(12, 10)
	top.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	top.Parent = gui
	corner(top, 18)
	self.title = text(top, self.strings.title, UDim2.new(0.35, 0, 1, 0), UDim2.fromOffset(20, 0), 24, true)
	self.status = text(top, self.strings.waiting, UDim2.new(0.4, 0, 1, 0), UDim2.new(0.34, 0, 0, 0), 20, true)
	self.timer = text(top, "--", UDim2.new(0.12, 0, 1, 0), UDim2.new(0.76, 0, 0, 0), 30, true)
	self.currency = text(top, "0 coins", UDim2.new(0.12, -10, 1, 0), UDim2.new(0.88, 0, 0, 0), 16, true)

	local main = Instance.new("Frame")
	main.Size = UDim2.new(0.72, -18, 1, -110)
	main.Position = UDim2.fromOffset(12, 98)
	main.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	main.Parent = gui
	corner(main, 20)

	self.prompt = text(main, "", UDim2.new(1, -30, 0, 48), UDim2.fromOffset(15, 8), 22, true)
	self.canvas = Instance.new("Frame")
	self.canvas.Name = "Canvas"
	self.canvas.Active = true
	self.canvas.ClipsDescendants = true
	self.canvas.Size = UDim2.new(1, -30, 1, -125)
	self.canvas.Position = UDim2.fromOffset(15, 55)
	self.canvas.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	self.canvas.BorderColor3 = Color3.fromRGB(216, 211, 232)
	self.canvas.BorderSizePixel = 2
	self.canvas.Parent = main
	corner(self.canvas, 12)

	local tools = Instance.new("Frame")
	tools.Size = UDim2.new(1, -30, 0, 54)
	tools.Position = UDim2.new(0, 15, 1, -62)
	tools.BackgroundTransparency = 1
	tools.Parent = main

	for index, color in CanvasController.COLORS do
		local colorButton = Instance.new("TextButton")
		colorButton.Text = ""
		colorButton.Size = UDim2.fromOffset(36, 36)
		colorButton.Position = UDim2.fromOffset((index - 1) * 42, 8)
		colorButton.BackgroundColor3 = color
		colorButton.Parent = tools
		corner(colorButton, 18)
		colorButton.MouseButton1Click:Connect(function() self.canvasController:setColor(color) end)
	end
	local erase = button(tools, "Eraser", UDim2.fromOffset(76, 36), UDim2.fromOffset(344, 8), Color3.fromRGB(93, 100, 120))
	erase.MouseButton1Click:Connect(function() self.canvasController:setErase(true) end)
	local undo = button(tools, self.strings.undo, UDim2.fromOffset(92, 36), UDim2.fromOffset(428, 8))
	undo.MouseButton1Click:Connect(function() self.remotes.UndoStroke:FireServer() end)
	local clear = button(tools, self.strings.clear, UDim2.fromOffset(82, 36), UDim2.fromOffset(528, 8), Color3.fromRGB(238, 89, 106))
	clear.MouseButton1Click:Connect(function() self.remotes.ClearCanvas:FireServer() end)

	local side = Instance.new("Frame")
	side.Size = UDim2.new(0.28, -18, 1, -110)
	side.Position = UDim2.new(0.72, 6, 0, 98)
	side.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	side.Parent = gui
	corner(side, 20)
	text(side, "Players / 플레이어", UDim2.new(1, -20, 0, 40), UDim2.fromOffset(10, 6), 19, true)
	self.scoreList = text(side, "", UDim2.new(1, -20, 0.38, 0), UDim2.fromOffset(10, 45), 16, false)
	self.scoreList.TextYAlignment = Enum.TextYAlignment.Top

	self.feed = text(side, "", UDim2.new(1, -20, 0.25, 0), UDim2.new(0, 10, 0.4, 0), 15, false)
	self.feed.TextYAlignment = Enum.TextYAlignment.Bottom
	self.feed.TextColor3 = Color3.fromRGB(70, 72, 90)

	self.guessBox = Instance.new("TextBox")
	self.guessBox.Size = UDim2.new(1, -112, 0, 44)
	self.guessBox.Position = UDim2.new(0, 10, 0.69, 0)
	self.guessBox.PlaceholderText = self.strings.guessPlaceholder
	self.guessBox.Text = ""
	self.guessBox.TextSize = 16
	self.guessBox.Font = Enum.Font.Gotham
	self.guessBox.BackgroundColor3 = Color3.fromRGB(244, 242, 250)
	self.guessBox.Parent = side
	corner(self.guessBox, 10)
	local send = button(side, self.strings.submit, UDim2.fromOffset(88, 44), UDim2.new(1, -98, 0.69, 0))
	local function submit()
		if self.guessBox.Text ~= "" then
			self.remotes.SubmitGuess:FireServer(self.guessBox.Text)
			self.guessBox.Text = ""
		end
	end
	send.MouseButton1Click:Connect(submit)
	self.guessBox.FocusLost:Connect(function(enter) if enter then submit() end end)

	local hide = button(side, self.strings.hide, UDim2.new(0.48, -5, 0, 42), UDim2.new(0, 10, 0.79, 0), Color3.fromRGB(93, 100, 120))
	hide.MouseButton1Click:Connect(function()
		self.hidden = not self.hidden
		self.canvas.Visible = not self.hidden
	end)
	local skip = button(side, self.strings.skip, UDim2.new(0.48, -5, 0, 42), UDim2.new(0.52, 0, 0.79, 0), Color3.fromRGB(255, 156, 56))
	skip.MouseButton1Click:Connect(function() self.remotes.VoteSkip:FireServer() end)
	local report = button(side, self.strings.report, UDim2.new(1, -20, 0, 40), UDim2.new(0, 10, 0.89, 0), Color3.fromRGB(226, 67, 87))
	report.MouseButton1Click:Connect(function()
		self.remotes.ReportDrawing:FireServer("Inappropriate or disruptive drawing")
		self.hidden = true
		self.canvas.Visible = false
	end)

	self.choiceFrame = Instance.new("Frame")
	self.choiceFrame.Size = UDim2.new(0, 520, 0, 210)
	self.choiceFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	self.choiceFrame.Position = UDim2.fromScale(0.5, 0.48)
	self.choiceFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	self.choiceFrame.Visible = false
	self.choiceFrame.ZIndex = 20
	self.choiceFrame.Parent = gui
	corner(self.choiceFrame, 20)
	text(self.choiceFrame, "Choose a prompt / 단어 선택", UDim2.new(1, 0, 0, 55), UDim2.fromOffset(0, 8), 22, true).ZIndex = 21

	self.toast = text(gui, "", UDim2.fromOffset(420, 50), UDim2.new(0.5, -210, 0, 90), 18, true)
	self.toast.BackgroundTransparency = 0.1
	self.toast.BackgroundColor3 = Color3.fromRGB(35, 38, 55)
	self.toast.TextColor3 = Color3.new(1, 1, 1)
	self.toast.Visible = false
	self.toast.ZIndex = 50
	corner(self.toast, 14)

	self.canvasController = CanvasController.new(self.canvas, self.remotes)
	self.canvasController:bind()
end

function UIController:_showChoices(choices)
	for _, child in self.choiceFrame:GetChildren() do
		if child:IsA("TextButton") then child:Destroy() end
	end
	for index, choice in choices do
		local item = button(self.choiceFrame, choice.ko .. "\n" .. choice.en, UDim2.fromOffset(145, 100), UDim2.fromOffset(32 + (index - 1) * 160, 82))
		item.ZIndex = 21
		item.MouseButton1Click:Connect(function()
			self.remotes.ChoosePrompt:FireServer(choice.id)
			self.choiceFrame.Visible = false
		end)
	end
	self.choiceFrame.Visible = true
end

function UIController:onState(payload)
	self.lastState = payload
	self.timer.Text = payload.seconds > 0 and tostring(payload.seconds) or "--"
	local isArtist = payload.artistUserId == self.player.UserId
	self.canvasController:setEnabled(payload.state == "Drawing" and isArtist, payload.mode)
	self.guessBox.Visible = payload.state == "Drawing" and not isArtist

	if payload.state == "Waiting" then self.status.Text = self.strings.waiting
	elseif payload.state == "Intermission" then self.status.Text = self.strings.intermission
	elseif payload.state == "Choosing" then self.status.Text = self.strings.choosing
	elseif payload.state == "Drawing" then self.status.Text = isArtist and self.strings.yourTurn or self.strings.drawing
	elseif payload.state == "Reveal" then self.status.Text = self.strings.reveal
	elseif payload.state == "Results" then self.status.Text = self.strings.results end

	if payload.state == "Choosing" and isArtist and payload.choices then
		self:_showChoices(payload.choices)
	elseif payload.state ~= "Choosing" then
		self.choiceFrame.Visible = false
	end

	if payload.prompt then
		if isArtist or payload.state == "Reveal" then
			self.prompt.Text = payload.prompt.ko .. "  •  " .. payload.prompt.en
		else
			self.prompt.Text = payload.artistName .. " is drawing..."
		end
	else
		self.prompt.Text = payload.artistName ~= "" and ("Artist: " .. payload.artistName) or ""
	end

	local lines = {}
	for index, entry in payload.scores do
		table.insert(lines, string.format("%d. %s  —  %d", index, entry.name, entry.score))
	end
	self.scoreList.Text = table.concat(lines, "\n")
end

function UIController:bind()
	self.remotes.RoundState.OnClientEvent:Connect(function(payload) self:onState(payload) end)
	self.remotes.GuessBroadcast.OnClientEvent:Connect(function(message)
		local line = message.correct and (message.name .. " ✓") or (message.name .. ": " .. message.text)
		self.feed.Text = string.sub(self.feed.Text .. "\n" .. line, -500)
	end)
	self.remotes.Toast.OnClientEvent:Connect(function(message)
		self.toast.Text = tostring(message)
		self.toast.Visible = true
		task.delay(2.5, function() self.toast.Visible = false end)
	end)
	self.remotes.PlayerData.OnClientEvent:Connect(function(data)
		self.currency.Text = tostring(data.coins or 0) .. " " .. self.strings.coins
	end)
end

return UIController
