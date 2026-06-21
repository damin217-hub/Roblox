local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalizationService = game:GetService("LocalizationService")
local StarterGui = game:GetService("StarterGui")
local Localization = require(ReplicatedStorage.ArtAcademy.Localization)
local Catalog = require(ReplicatedStorage.ArtAcademy.Catalog)
local StrokeCodec = require(ReplicatedStorage.ArtAcademy.StrokeCodec)
local CanvasController = require(script.Parent.CanvasController)
local SoundController = require(script.Parent.SoundController)

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

local function attachTooltip(item, tooltip, value)
	item:SetAttribute("TooltipText", value)
	item.MouseEnter:Connect(function()
		tooltip.Text = value
		tooltip.Position = UDim2.fromOffset(
			item.AbsolutePosition.X + item.AbsoluteSize.X / 2,
			math.max(8, item.AbsolutePosition.Y - 8)
		)
		tooltip.Visible = true
	end)
	item.MouseLeave:Connect(function()
		tooltip.Visible = false
	end)
end

function UIController.new(remotes, playerOverride, localeOverride)
	local self = setmetatable({}, UIController)
	self.player = playerOverride or Players.LocalPlayer
	self.remotes = remotes
	self.strings = Localization(localeOverride or LocalizationService.RobloxLocaleId)
	self.hidden = false
	self.lastState = nil
	self.playerData = nil
	self.questData = {}
	self.galleryData = { approved = {}, pending = {}, isAdmin = false }
	self.colorButtons = {}
	self.galleryCanvasController = nil
	self.bubbleComposerController = nil
	self.hasShownTutorial = false
	self.lastRoundId = ""
	self.canvasPanelOpen = true
	self.sounds = SoundController.new()
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
	backdrop.BackgroundTransparency = 1
	backdrop.Parent = gui

	local top = Instance.new("Frame")
	top.Size = UDim2.new(1, -24, 0, 76)
	top.Position = UDim2.fromOffset(12, 10)
	top.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	top.Parent = gui
	corner(top, 18)
	self.title = text(top, self.strings.title, UDim2.new(0.35, 0, 1, 0), UDim2.fromOffset(20, 0), 24, true)
	self.status = text(top, self.strings.waiting, UDim2.new(0.3, 0, 1, 0), UDim2.new(0.34, 0, 0, 0), 20, true)
	self.roundBadge = text(top, "", UDim2.new(0.12, 0, 1, 0), UDim2.new(0.64, 0, 0, 0), 15, true)
	self.roundBadge.TextColor3 = Color3.fromRGB(112, 83, 245)
	self.timer = text(top, "--", UDim2.new(0.12, 0, 1, 0), UDim2.new(0.76, 0, 0, 0), 30, true)
	self.currency = text(top, "0 coins", UDim2.new(0.12, -10, 1, 0), UDim2.new(0.88, 0, 0, 0), 16, true)

	local main = Instance.new("Frame")
	main.Size = UDim2.new(0.72, -18, 1, -110)
	main.Position = UDim2.fromOffset(12, 98)
	main.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	main.Parent = gui
	corner(main, 20)
	self.canvasPanel = main

	self.prompt = text(main, "", UDim2.new(1, -190, 0, 48), UDim2.fromOffset(15, 8), 22, true)
	self.prompt.TextXAlignment = Enum.TextXAlignment.Left
	self.brushStatus = text(main, "마커  14px  80%", UDim2.fromOffset(128, 48), UDim2.new(1, -178, 0, 8), 13, true)
	self.brushStatus.TextColor3 = Color3.fromRGB(112, 83, 245)
	local minimizeCanvas = button(
		main,
		"—",
		UDim2.fromOffset(42, 36),
		UDim2.new(1, -54, 0, 12),
		Color3.fromRGB(93, 100, 120)
	)
	minimizeCanvas.Name = "MinimizeCanvas"
	minimizeCanvas.MouseButton1Click:Connect(function()
		self:setCanvasPanelOpen(false)
	end)

	self.openCanvasButton = button(
		gui,
		"그림판 열기 / Open Canvas",
		UDim2.fromOffset(210, 44),
		UDim2.fromOffset(12, 98),
		Color3.fromRGB(112, 83, 245)
	)
	self.openCanvasButton.Name = "OpenCanvas"
	self.openCanvasButton.Visible = false
	self.openCanvasButton.ZIndex = 15
	self.openCanvasButton.MouseButton1Click:Connect(function()
		self:setCanvasPanelOpen(true)
	end)
	self.tooltip = text(gui, "", UDim2.fromOffset(300, 54), UDim2.fromOffset(0, 0), 14, true)
	self.tooltip.Name = "ControlTooltip"
	self.tooltip.AnchorPoint = Vector2.new(0.5, 1)
	self.tooltip.BackgroundTransparency = 0.08
	self.tooltip.BackgroundColor3 = Color3.fromRGB(35, 38, 55)
	self.tooltip.TextColor3 = Color3.fromRGB(255, 255, 255)
	self.tooltip.Visible = false
	self.tooltip.ZIndex = 90
	corner(self.tooltip, 10)
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

	local tools = Instance.new("ScrollingFrame")
	tools.Size = UDim2.new(1, -30, 0, 54)
	tools.Position = UDim2.new(0, 15, 1, -62)
	tools.BackgroundTransparency = 1
	tools.BorderSizePixel = 0
	tools.ScrollBarThickness = 4
	tools.ScrollingDirection = Enum.ScrollingDirection.X
	tools.CanvasSize = UDim2.fromOffset(1520, 0)
	tools.Parent = main

	for index, color in CanvasController.COLORS do
		local colorButton = Instance.new("TextButton")
		colorButton.Text = ""
		colorButton.Size = UDim2.fromOffset(36, 36)
		colorButton.Position = UDim2.fromOffset((index - 1) * 42, 8)
		colorButton.BackgroundColor3 = color
		colorButton.Parent = tools
		corner(colorButton, 18)
		table.insert(self.colorButtons, colorButton)
		colorButton.MouseButton1Click:Connect(function()
			self.canvasController:setColor(colorButton.BackgroundColor3)
		end)
	end
	local erase = button(tools, "Eraser", UDim2.fromOffset(76, 36), UDim2.fromOffset(344, 8), Color3.fromRGB(93, 100, 120))
	erase.MouseButton1Click:Connect(function() self.canvasController:setErase(true) end)
	local undo = button(tools, self.strings.undo, UDim2.fromOffset(92, 36), UDim2.fromOffset(428, 8))
	undo.MouseButton1Click:Connect(function() self.remotes.UndoStroke:FireServer() end)
	local clear = button(tools, self.strings.clear, UDim2.fromOffset(82, 36), UDim2.fromOffset(528, 8), Color3.fromRGB(238, 89, 106))
	clear.MouseButton1Click:Connect(function() self.remotes.ClearCanvas:FireServer() end)
	self.finishDrawingButton = button(
		tools,
		"완성 제출 / Done",
		UDim2.fromOffset(120, 36),
		UDim2.fromOffset(618, 8),
		Color3.fromRGB(74, 190, 108)
	)
	self.finishDrawingButton.Visible = false
	self.finishDrawingButton.MouseButton1Click:Connect(function()
		self.remotes.FinishDrawing:FireServer()
	end)
	attachTooltip(
		self.finishDrawingButton,
		self.tooltip,
		"현재 그림을 제출하고 즉시 공개합니다. / Submit now and reveal the drawing."
	)
	local function updateBrushStatus(name)
		self.brushStatus.Text = string.format(
			"%s  %dpx  %d%%",
			name,
			self.canvasController.size,
			math.floor(self.canvasController.opacity * 100 + 0.5)
		)
	end
	local presets = {
		{ id = "fine", label = "세밀", x = 746 },
		{ id = "marker", label = "마커", x = 812 },
		{ id = "bold", label = "굵게", x = 878 },
		{ id = "soft", label = "부드럽게", x = 944 },
	}
	for _, preset in presets do
		local presetId = preset.id
		local presetLabel = preset.label
		local presetButton = button(
			tools,
			presetLabel,
			UDim2.fromOffset(60, 36),
			UDim2.fromOffset(preset.x, 8),
			Color3.fromRGB(112, 83, 245)
		)
		presetButton.MouseButton1Click:Connect(function()
			self.canvasController:applyPreset(presetId)
			updateBrushStatus(presetLabel)
		end)
	end
	for index, opacity in { 1, 0.7, 0.4 } do
		local selectedOpacity = opacity
		local opacityButton = button(
			tools,
			tostring(math.floor(selectedOpacity * 100)) .. "%",
			UDim2.fromOffset(58, 36),
			UDim2.fromOffset(1010 + (index - 1) * 64, 8),
			Color3.fromRGB(72, 162, 191)
		)
		opacityButton.MouseButton1Click:Connect(function()
			self.canvasController:setOpacity(selectedOpacity)
			updateBrushStatus("사용자")
		end)
	end
	local smaller = button(tools, "−", UDim2.fromOffset(42, 36), UDim2.fromOffset(1206, 8), Color3.fromRGB(93, 100, 120))
	smaller.MouseButton1Click:Connect(function()
		self.canvasController:setSize(self.canvasController.size - 2)
		updateBrushStatus("사용자")
	end)
	local larger = button(tools, "+", UDim2.fromOffset(42, 36), UDim2.fromOffset(1254, 8), Color3.fromRGB(93, 100, 120))
	larger.MouseButton1Click:Connect(function()
		self.canvasController:setSize(self.canvasController.size + 2)
		updateBrushStatus("사용자")
	end)
	local circleStamp = button(tools, "Round", UDim2.fromOffset(72, 36), UDim2.fromOffset(1306, 8), Color3.fromRGB(255, 156, 56))
	circleStamp.MouseButton1Click:Connect(function()
		self.canvasController:setStampType("circle")
	end)
	local squareStamp = button(tools, "Square", UDim2.fromOffset(72, 36), UDim2.fromOffset(1384, 8), Color3.fromRGB(255, 156, 56))
	squareStamp.MouseButton1Click:Connect(function()
		self.canvasController:setStampType("square")
	end)

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

	local bubbleShare = button(
		side,
		"그림 말풍선 / Draw Bubble",
		UDim2.new(1, -20, 0, 36),
		UDim2.new(0, 10, 0.585, 0),
		Color3.fromRGB(112, 83, 245)
	)
	bubbleShare.MouseButton1Click:Connect(function()
		self:_openDrawingBubbleComposer()
	end)

	local reactions = Instance.new("Frame")
	reactions.Size = UDim2.new(1, -20, 0, 38)
	reactions.Position = UDim2.new(0, 10, 0.63, 0)
	reactions.BackgroundTransparency = 1
	reactions.Visible = false
	reactions.Parent = side
	self.reactions = reactions
	for index, reaction in { "heart", "laugh", "wow" } do
		local reactionButton = button(
			reactions,
			string.upper(string.sub(reaction, 1, 1)),
			UDim2.new(0.31, 0, 1, 0),
			UDim2.new((index - 1) * 0.345, 0, 0, 0),
			Color3.fromRGB(255 - index * 20, 104 + index * 28, 160 + index * 20)
		)
		reactionButton.MouseButton1Click:Connect(function()
			self.remotes.ReactToDrawing:FireServer(reaction)
		end)
	end

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

	self.hideButton = button(side, self.strings.hide, UDim2.new(0.48, -5, 0, 42), UDim2.new(0, 10, 0.79, 0), Color3.fromRGB(93, 100, 120))
	self.hideButton.MouseButton1Click:Connect(function()
		self.hidden = not self.hidden
		self.canvas.Visible = not self.hidden
		self.hideButton.Text = self.hidden and "Show / 다시 보기" or self.strings.hide
	end)
	attachTooltip(
		self.hideButton,
		self.tooltip,
		"그림만 숨기거나 다시 표시합니다. / Hide or show only the current drawing."
	)
	self.skipButton = button(side, self.strings.skip, UDim2.new(0.48, -5, 0, 42), UDim2.new(0.52, 0, 0.79, 0), Color3.fromRGB(255, 156, 56))
	self.skipButton.MouseButton1Click:Connect(function() self.remotes.VoteSkip:FireServer() end)
	attachTooltip(
		self.skipButton,
		self.tooltip,
		"다수가 동의하면 현재 출제자를 건너뜁니다. / Majority vote skips the current artist."
	)
	self.blockButton = button(side, "Block / 차단", UDim2.new(0.48, -5, 0, 40), UDim2.new(0, 10, 0.89, 0), Color3.fromRGB(93, 100, 120))
	self.blockButton.MouseButton1Click:Connect(function()
		local artistUserId = self.lastState and self.lastState.artistUserId or 0
		local target = artistUserId > 0 and Players:GetPlayerByUserId(artistUserId) or nil
		if target and target ~= self.player then
			pcall(function()
				StarterGui:SetCore("PromptBlockPlayer", target)
			end)
		end
	end)
	attachTooltip(
		self.blockButton,
		self.tooltip,
		"현재 출제자를 Roblox에서 차단합니다. / Block the current artist on Roblox."
	)
	self.reportButton = button(side, self.strings.report, UDim2.new(0.48, -5, 0, 40), UDim2.new(0.52, 0, 0.89, 0), Color3.fromRGB(226, 67, 87))
	self.reportButton.MouseButton1Click:Connect(function()
		self.remotes.ReportDrawing:FireServer("inappropriate")
		self.hidden = true
		self.canvas.Visible = false
		self.hideButton.Text = "Show / 다시 보기"
	end)
	attachTooltip(
		self.reportButton,
		self.tooltip,
		"부적절한 그림을 신고하고 즉시 숨깁니다. / Report and hide inappropriate art."
	)

	self.choiceFrame = Instance.new("Frame")
	self.choiceFrame.Size = UDim2.new(0.8, 0, 0, 210)
	self.choiceFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	self.choiceFrame.Position = UDim2.fromScale(0.5, 0.48)
	self.choiceFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	self.choiceFrame.Visible = false
	self.choiceFrame.ZIndex = 20
	self.choiceFrame.Parent = gui
	corner(self.choiceFrame, 20)
	local choiceSizeConstraint = Instance.new("UISizeConstraint")
	choiceSizeConstraint.MinSize = Vector2.new(300, 210)
	choiceSizeConstraint.MaxSize = Vector2.new(560, 210)
	choiceSizeConstraint.Parent = self.choiceFrame
	text(self.choiceFrame, "Choose a prompt / 단어 선택", UDim2.new(1, 0, 0, 55), UDim2.fromOffset(0, 8), 22, true).ZIndex = 21

	self.toast = text(gui, "", UDim2.fromOffset(420, 50), UDim2.new(0.5, -210, 0, 90), 18, true)
	self.toast.BackgroundTransparency = 0.1
	self.toast.BackgroundColor3 = Color3.fromRGB(35, 38, 55)
	self.toast.TextColor3 = Color3.new(1, 1, 1)
	self.toast.Visible = false
	self.toast.ZIndex = 50
	corner(self.toast, 14)

	self.modalScrim = Instance.new("TextButton")
	self.modalScrim.Name = "ModalInputBlocker"
	self.modalScrim.Size = UDim2.fromScale(1, 1)
	self.modalScrim.BackgroundColor3 = Color3.fromRGB(20, 18, 35)
	self.modalScrim.BackgroundTransparency = 0.4
	self.modalScrim.Text = ""
	self.modalScrim.AutoButtonColor = false
	self.modalScrim.Active = true
	self.modalScrim.Visible = false
	self.modalScrim.ZIndex = 59
	self.modalScrim.Parent = gui

	self.modal = Instance.new("Frame")
	self.modal.Size = UDim2.new(0.76, 0, 0.72, 0)
	self.modal.AnchorPoint = Vector2.new(0.5, 0.5)
	self.modal.Position = UDim2.fromScale(0.5, 0.52)
	self.modal.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	self.modal.Visible = false
	self.modal.ZIndex = 60
	self.modal.Parent = gui
	corner(self.modal, 20)
	self.modalTitle = text(self.modal, "", UDim2.new(1, -90, 0, 54), UDim2.fromOffset(20, 8), 24, true)
	self.modalTitle.ZIndex = 61
	local closeModal = button(self.modal, "X", UDim2.fromOffset(44, 44), UDim2.new(1, -56, 0, 12), Color3.fromRGB(226, 67, 87))
	closeModal.ZIndex = 62
	closeModal.MouseButton1Click:Connect(function()
		self.modal.Visible = false
	end)
	self.modalList = Instance.new("ScrollingFrame")
	self.modalList.Size = UDim2.new(1, -40, 1, -80)
	self.modalList.Position = UDim2.fromOffset(20, 68)
	self.modalList.BackgroundTransparency = 1
	self.modalList.BorderSizePixel = 0
	self.modalList.ScrollBarThickness = 6
	self.modalList.ZIndex = 61
	self.modalList.Parent = self.modal
	local modalLayout = Instance.new("UIListLayout")
	modalLayout.Padding = UDim.new(0, 10)
	modalLayout.Parent = self.modalList
	modalLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		self.modalList.CanvasSize = UDim2.fromOffset(0, modalLayout.AbsoluteContentSize.Y + 10)
	end)
	self.modal:GetPropertyChangedSignal("Visible"):Connect(function()
		self.modalScrim.Visible = self.modal.Visible
		self.canvas.Active = not self.modal.Visible
		if not self.modal.Visible and self.bubbleComposerController then
			self.bubbleComposerController:setEnabled(false, "ALL_AGES")
		end
	end)

	self.canvasController = CanvasController.new(self.canvas, self.remotes)
	self.canvasController:applyPreset("marker")
	self.canvasController:bind()

	local camera = workspace.CurrentCamera
	local function applyResponsiveLayout(widthOverride)
		local width = widthOverride or (camera and camera.ViewportSize.X or 1280)
		if width < 900 then
			top.Size = UDim2.new(1, -16, 0, 62)
			top.Position = UDim2.fromOffset(8, 6)
			self.title.Visible = false
			self.status.Size = UDim2.new(0.48, -12, 1, 0)
			self.status.Position = UDim2.fromOffset(12, 0)
			self.roundBadge.Size = UDim2.new(0.18, 0, 1, 0)
			self.roundBadge.Position = UDim2.new(0.48, 0, 0, 0)
			self.timer.Size = UDim2.new(0.15, 0, 1, 0)
			self.timer.Position = UDim2.new(0.66, 0, 0, 0)
			self.currency.Size = UDim2.new(0.19, -8, 1, 0)
			self.currency.Position = UDim2.new(0.81, 0, 0, 0)
			main.Size = UDim2.new(1, -16, 0.6, -42)
			main.Position = UDim2.fromOffset(8, 76)
			side.Size = UDim2.new(1, -16, 0.4, -42)
			side.Position = UDim2.new(0, 8, 0.6, 42)
			self.modal.Size = UDim2.new(0.94, 0, 0.82, 0)
		else
			self.title.Visible = true
			self.status.Size = UDim2.new(0.3, 0, 1, 0)
			self.status.Position = UDim2.new(0.34, 0, 0, 0)
			self.roundBadge.Size = UDim2.new(0.12, 0, 1, 0)
			self.roundBadge.Position = UDim2.new(0.64, 0, 0, 0)
			self.timer.Size = UDim2.new(0.12, 0, 1, 0)
			self.timer.Position = UDim2.new(0.76, 0, 0, 0)
			self.currency.Size = UDim2.new(0.12, -10, 1, 0)
			self.currency.Position = UDim2.new(0.88, 0, 0, 0)
			top.Size = UDim2.new(1, -24, 0, 76)
			top.Position = UDim2.fromOffset(12, 10)
			main.Size = UDim2.new(0.72, -18, 1, -110)
			main.Position = UDim2.fromOffset(12, 98)
			side.Size = UDim2.new(0.28, -18, 1, -110)
			side.Position = UDim2.new(0.72, 6, 0, 98)
			self.modal.Size = UDim2.new(0.76, 0, 0.72, 0)
		end
	end
	self.applyResponsiveLayout = applyResponsiveLayout
	applyResponsiveLayout()
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(applyResponsiveLayout)
	end
end

function UIController:setCanvasPanelOpen(open: boolean)
	self.canvasPanelOpen = open
	if self.canvasPanel then
		self.canvasPanel.Visible = open
	end
	if self.openCanvasButton then
		self.openCanvasButton.Visible = not open
	end
end

function UIController:_openTutorial()
	self:_clearModal()
	self.modalTitle.Text = self.strings.tutorialTitle .. " / Momo's First Lesson"
	self:_modalRow(
		"1. 중앙 포털에서 참가 / Join at the center portal",
		"보라색 PLAY 포털에서 E 또는 탭으로 다음 게임 대기열에 참가합니다.",
		nil,
		nil
	)
	self:_modalRow(
		"2. 출제자는 단어를 선택 / Artist chooses a prompt",
		"세 단어 중 하나를 고르고 제한 시간 안에 그림으로 표현하세요.",
		nil,
		nil
	)
	self:_modalRow(
		"3. 다른 플레이어는 정답 추측 / Everyone else guesses",
		"필터링된 입력창에 정답을 적으세요. 빠를수록 더 높은 점수를 얻습니다.",
		nil,
		nil
	)
	self:_modalRow(
		"4. 5라운드 후 보상 / Rewards after 5 rounds",
		"코인으로 팔레트와 브러시 외형을 꾸미고, 미션과 갤러리도 확인하세요.",
		"수업 시작 / Got it",
		function()
			self.modal.Visible = false
			self.toast.Text = "중앙의 보라색 PLAY 포털로 이동하세요! / Head to the purple PLAY portal!"
			self.toast.Visible = true
			task.delay(4, function()
				self.toast.Visible = false
			end)
		end
	)
	self.modal.Visible = true
end

function UIController:_openResults(payload)
	self:_clearModal()
	self.modalTitle.Text = self.strings.results .. " / Final Results"
	local ranking = payload.ranking or payload.scores or {}
	if #ranking == 0 then
		self:_modalRow("게임 종료 / Match ended", "참가 인원이 부족해 게임이 종료되었습니다.", nil, nil)
	else
		for index, entry in ranking do
			local prefix = index == 1 and "WINNER  " or ""
			local detail = string.format("%d points", entry.score or 0)
			if index == 1 and (payload.winnerBonus or 0) > 0 then
				detail ..= string.format("  •  +%d winner coins", payload.winnerBonus)
			end
			self:_modalRow(prefix .. tostring(index) .. ". " .. entry.name, detail, nil, nil)
		end
	end
	self:_modalRow(
		"다음 수업 / What's next?",
		self.strings.playAgain,
		"확인 / Continue",
		function()
			self.modal.Visible = false
		end
	)
	self.modal.Visible = true
end

function UIController:_clearModal()
	if self.galleryCanvasController then
		self.galleryCanvasController:destroy()
		self.galleryCanvasController = nil
	end
	if self.bubbleComposerController then
		self.bubbleComposerController:destroy()
		self.bubbleComposerController = nil
	end
	for _, child in self.modalList:GetChildren() do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
end

function UIController:_openDrawingBubbleComposer()
	self:_clearModal()
	self.modalTitle.Text = "그림 말풍선 / Drawing Bubble"

	local composer = Instance.new("Frame")
	composer.Size = UDim2.new(1, -8, 0, 390)
	composer.BackgroundColor3 = Color3.fromRGB(244, 242, 250)
	composer.ZIndex = 61
	composer.Parent = self.modalList
	corner(composer, 14)

	local canvas = Instance.new("Frame")
	canvas.Name = "BubbleCanvas"
	canvas.Size = UDim2.new(1, -28, 0, 260)
	canvas.Position = UDim2.fromOffset(14, 14)
	canvas.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	canvas.ClipsDescendants = true
	canvas.Active = true
	canvas.ZIndex = 62
	canvas.Parent = composer
	corner(canvas, 12)

	local localId = 0
	local localController
	localController = CanvasController.new(canvas, {
		SubmitStroke = {
			FireServer = function(_, payload)
				localId += 1
				payload.id = localId
				localController:_render(payload)
			end,
		},
	})
	localController:applyPreset("fine")
	localController:setEnabled(true, "ALL_AGES")
	localController:bind()
	self.bubbleComposerController = localController

	for index, color in CanvasController.COLORS do
		local colorButton = Instance.new("TextButton")
		colorButton.Text = ""
		colorButton.Size = UDim2.fromOffset(30, 30)
		colorButton.Position = UDim2.fromOffset(14 + (index - 1) * 36, 286)
		colorButton.BackgroundColor3 = color
		colorButton.ZIndex = 63
		colorButton.Parent = composer
		corner(colorButton, 15)
		colorButton.MouseButton1Click:Connect(function()
			localController:setColor(color)
		end)
	end

	local clearBubble = button(composer, "지우기 / Clear", UDim2.fromOffset(120, 42), UDim2.new(0, 14, 1, -58), Color3.fromRGB(93, 100, 120))
	clearBubble.ZIndex = 63
	clearBubble.MouseButton1Click:Connect(function()
		localId = 0
		localController:clear()
	end)
	local shareBubble = button(composer, "공유 / Share", UDim2.fromOffset(150, 42), UDim2.new(1, -164, 1, -58), Color3.fromRGB(255, 116, 139))
	shareBubble.ZIndex = 63
	shareBubble.MouseButton1Click:Connect(function()
		if #localController.strokes > 0 then
			local safeStrokes = {}
			for index, stroke in localController.strokes do
				if index > 80 then break end
				table.insert(safeStrokes, {
					x = stroke.x, y = stroke.y, px = stroke.px, py = stroke.py,
					size = stroke.size,
					opacity = stroke.opacity,
					color = stroke.color,
					erase = stroke.erase,
					stampType = stroke.stampType,
				})
			end
			self.remotes.ShareDrawingBubble:FireServer(safeStrokes)
			self.modal.Visible = false
		end
	end)
	self.modal.Visible = true
end

function UIController:_refreshPalette()
	if not self.canvasController then
		return
	end
	local palette = self.canvasController:getPalette()
	for index, colorButton in self.colorButtons do
		colorButton.BackgroundColor3 = palette[index] or CanvasController.COLORS[index]
	end
	self.canvasController:setColor(palette[1])
end

function UIController:_modalRow(titleValue: string, detailValue: string, actionText: string?, callback)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -8, 0, 76)
	row.BackgroundColor3 = Color3.fromRGB(244, 242, 250)
	row.ZIndex = 61
	row.Parent = self.modalList
	corner(row, 12)
	local rowTitle = text(row, titleValue, UDim2.new(0.62, 0, 0.55, 0), UDim2.fromOffset(14, 5), 17, true)
	rowTitle.TextXAlignment = Enum.TextXAlignment.Left
	rowTitle.ZIndex = 62
	local detail = text(row, detailValue, UDim2.new(0.62, 0, 0.4, 0), UDim2.new(0, 14, 0.55, 0), 14, false)
	detail.TextXAlignment = Enum.TextXAlignment.Left
	detail.ZIndex = 62
	if actionText then
		local action = button(row, actionText, UDim2.new(0.3, 0, 0, 42), UDim2.new(0.68, 0, 0.5, -21))
		action.ZIndex = 63
		action.MouseButton1Click:Connect(callback)
	end
end

function UIController:_openShop()
	self:_clearModal()
	self.modalTitle.Text = "Palette Shop / 팔레트 상점"
	self:_modalRow(
		"프리미엄 아트 번들 / Premium Art Bundle",
		"Neon Brush + Candy Palette + Quick Thinker",
		"Robux",
		function()
			self.remotes.PurchasePremium:FireServer("bundle")
		end
	)
	self:_modalRow(
		"코인 묶음 / Coin Pack",
		"꾸미기 아이템 구매용 500 coins",
		"Robux",
		function()
			self.remotes.PurchasePremium:FireServer("coins_small")
		end
	)
	local data = self.playerData or { owned = {}, equipped = {} }
	for _, item in Catalog do
		local owned = table.find(data.owned or {}, item.id) ~= nil
		local equipped = data.equipped and data.equipped[item.category] == item.id
		local actionText = equipped and "Equipped" or (owned and "Equip" or (tostring(item.price) .. " coins"))
		self:_modalRow(
			item.nameKo .. " / " .. item.nameEn,
			string.upper(item.category),
			actionText,
			function()
				if equipped then
					return
				elseif owned then
					self.remotes.EquipItem:FireServer(item.id)
				else
					self.remotes.PurchaseItem:FireServer(item.id)
				end
			end
		)
	end
	self.modal.Visible = true
end

function UIController:_openQuests()
	self:_clearModal()
	self.modalTitle.Text = "Missions / 일일·주간 미션"
	for _, quest in self.questData do
		local complete = quest.progress >= quest.requirement
		local actionText = quest.claimed and "Claimed" or (complete and "Claim" or "In progress")
		self:_modalRow(
			quest.nameKo .. " / " .. quest.nameEn,
			string.format(
				"%s  •  %d / %d  •  +%d coins",
				string.upper(quest.scope or "daily"),
				quest.progress,
				quest.requirement,
				quest.reward
			),
			actionText,
			function()
				if complete and not quest.claimed then
					self.remotes.RequestGallery:FireServer("quests", quest.id)
				end
			end
		)
	end
	self.modal.Visible = true
end

function UIController:_openGallery()
	self:_clearModal()
	self.modalTitle.Text = "Curated Gallery / 시즌 갤러리"
	local approved = self.galleryData.approved or {}
	local pending = self.galleryData.pending or {}
	if self.galleryData.isAdmin and #pending > 0 then
		self:_modalRow("운영자 승인 대기 / Pending moderation", tostring(#pending) .. " artworks", nil, nil)
		for _, artwork in pending do
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, -8, 0, 92)
			row.BackgroundColor3 = Color3.fromRGB(255, 244, 222)
			row.ZIndex = 61
			row.Parent = self.modalList
			corner(row, 12)
			local rowTitle = text(
				row,
				artwork.promptKo .. " / " .. artwork.promptEn .. " — " .. artwork.artistName,
				UDim2.new(0.42, 0, 1, 0),
				UDim2.fromOffset(14, 0),
				16,
				true
			)
			rowTitle.ZIndex = 62
			local preview = button(row, "View", UDim2.new(0.16, 0, 0, 42), UDim2.new(0.43, 0, 0.5, -21), Color3.fromRGB(112, 83, 245))
			preview.ZIndex = 63
			preview.MouseButton1Click:Connect(function()
				self:_showGalleryArtwork(artwork)
			end)
			local approve = button(row, "Approve", UDim2.new(0.18, 0, 0, 42), UDim2.new(0.61, 0, 0.5, -21), Color3.fromRGB(74, 190, 108))
			approve.ZIndex = 63
			approve.MouseButton1Click:Connect(function()
				self.remotes.ModerateGallery:FireServer(artwork.id, "approve")
			end)
			local reject = button(row, "Reject", UDim2.new(0.18, 0, 0, 42), UDim2.new(0.81, 0, 0.5, -21), Color3.fromRGB(226, 67, 87))
			reject.ZIndex = 63
			reject.MouseButton1Click:Connect(function()
				self.remotes.ModerateGallery:FireServer(artwork.id, "reject")
			end)
		end
	end
	if #approved == 0 then
		self:_modalRow(
			"승인된 작품이 아직 없습니다 / No approved artwork yet",
			"Creator Dashboard에서 검토한 작품만 공개됩니다.",
			nil,
			nil
		)
	else
		for _, artwork in approved do
			self:_modalRow(
				artwork.promptKo .. " / " .. artwork.promptEn,
				"by " .. artwork.artistName,
				"View",
				function()
					self:_showGalleryArtwork(artwork)
				end
			)
		end
	end
	self.modal.Visible = true
end

function UIController:_showGalleryArtwork(artwork)
	self:_clearModal()
	self.modalTitle.Text = artwork.promptKo .. " / " .. artwork.promptEn .. " — " .. artwork.artistName
	local preview = Instance.new("Frame")
	preview.Size = UDim2.new(1, -20, 1, -20)
	preview.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	preview.ClipsDescendants = true
	preview.ZIndex = 62
	preview.Parent = self.modalList
	corner(preview, 12)
	self.galleryCanvasController = CanvasController.new(preview, {})
	self.galleryCanvasController:renderSnapshot(StrokeCodec.decode(artwork.strokes or {}))
end

function UIController:_showChoices(choices)
	for _, child in self.choiceFrame:GetChildren() do
		if child:IsA("TextButton") then child:Destroy() end
	end
	for index, choice in choices do
		local item = button(
			self.choiceFrame,
			choice.ko .. "\n" .. choice.en,
			UDim2.new(0.28, 0, 0, 100),
			UDim2.new(0.04 + (index - 1) * 0.32, 0, 0, 82)
		)
		item.ZIndex = 21
		item.MouseButton1Click:Connect(function()
			self.remotes.ChoosePrompt:FireServer(choice.id)
			self.choiceFrame.Visible = false
		end)
	end
	self.choiceFrame.Visible = true
end

function UIController:onState(payload)
	local previousState = self.lastState and self.lastState.state or nil
	if payload.roundId ~= "" and payload.roundId ~= self.lastRoundId then
		self.lastRoundId = payload.roundId
		self.hidden = false
		self.canvas.Visible = true
		self.hideButton.Text = self.strings.hide
	end
	self.lastState = payload
	if previousState and previousState ~= payload.state then
		self.sounds:play("round")
	end
	self.timer.Text = payload.seconds > 0 and tostring(payload.seconds) or "--"
	if (payload.roundNumber or 0) > 0 then
		self.roundBadge.Text = string.format(
			"%s %d/%d",
			self.strings.round,
			payload.roundNumber,
			payload.totalRounds or 5
		)
	else
		self.roundBadge.Text = ""
	end
	local isArtist = payload.artistUserId == self.player.UserId
	if payload.state == "Drawing" and isArtist and previousState ~= "Drawing" then
		self:setCanvasPanelOpen(true)
	end
	self.canvasController:setEnabled(payload.state == "Drawing" and isArtist, payload.mode)
	self.finishDrawingButton.Visible = payload.state == "Drawing" and isArtist
	self.guessBox.Visible = payload.state == "Drawing" and not isArtist
	self.reactions.Visible = payload.state == "Reveal"

	if payload.state == "Waiting" then
		local readyCount = payload.readyCount or 0
		self.status.Text = string.format("%s  (%d ready)", self.strings.waiting, readyCount)
	elseif payload.state == "Intermission" then self.status.Text = self.strings.intermission
	elseif payload.state == "Choosing" then self.status.Text = self.strings.choosing
	elseif payload.state == "Drawing" then self.status.Text = isArtist and self.strings.yourTurn or self.strings.drawing
	elseif payload.state == "Reveal" then self.status.Text = self.strings.reveal
	elseif payload.state == "Results" then self.status.Text = self.strings.results end

	if payload.state == "Results" and previousState ~= "Results" then
		self:_openResults(payload)
	end

	if payload.state == "Choosing" and isArtist and payload.choices then
		self:_showChoices(payload.choices)
	elseif payload.state ~= "Choosing" then
		self.choiceFrame.Visible = false
	end

	if payload.prompt then
		if isArtist or payload.state == "Reveal" then
			self.prompt.Text = payload.prompt.ko .. "  •  " .. payload.prompt.en
		else
			local hint = payload.hint and ("  •  Hint: " .. payload.hint) or ""
			self.prompt.Text = payload.artistName .. " is drawing..." .. hint
		end
	else
		self.prompt.Text = payload.artistName ~= "" and ("Artist: " .. payload.artistName) or ""
	end

	local lines = {}
	for index, entry in payload.scores do
		local titleSuffix = entry.title ~= "" and (" [" .. entry.title .. "]") or ""
		table.insert(lines, string.format("%d. %s%s  —  %d", index, entry.name, titleSuffix, entry.score))
	end
	self.scoreList.Text = table.concat(lines, "\n")
end

function UIController:bind()
	self.remotes.RoundState.OnClientEvent:Connect(function(payload) self:onState(payload) end)
	self.remotes.GuessBroadcast.OnClientEvent:Connect(function(message)
		local line = message.correct and (message.name .. " ✓") or (message.name .. ": " .. message.text)
		self.feed.Text = string.sub(self.feed.Text .. "\n" .. line, -500)
		if message.correct then
			self.sounds:play("success")
		end
	end)
	self.remotes.Toast.OnClientEvent:Connect(function(message)
		self.sounds:play("toast")
		self.toast.Text = tostring(message)
		self.toast.Visible = true
		task.delay(2.5, function() self.toast.Visible = false end)
	end)
	self.remotes.PlayerData.OnClientEvent:Connect(function(data)
		self.playerData = data
		self.canvasController:setCosmetics(data.equipped)
		self:_refreshPalette()
		self.currency.Text = tostring(data.coins or 0) .. " " .. self.strings.coins
		if not self.hasShownTutorial then
			self.hasShownTutorial = true
			task.delay(0.75, function()
				if not self.modal.Visible and (not self.lastState or self.lastState.state == "Waiting") then
					self:_openTutorial()
				end
			end)
		end
		if self.modal.Visible and string.find(self.modalTitle.Text, "Shop") then
			self:_openShop()
		end
	end)
	self.remotes.OpenPanel.OnClientEvent:Connect(function(panel)
		if panel == "shop" then
			self:_openShop()
		elseif panel == "tutorial" then
			self:_openTutorial()
		elseif panel == "quests" then
			self:_openQuests()
		elseif panel == "gallery" then
			self:_openGallery()
		end
	end)
	self.remotes.QuestData.OnClientEvent:Connect(function(data)
		self.questData = data
		if self.modal.Visible and string.find(self.modalTitle.Text, "Mission") then
			self:_openQuests()
		end
	end)
	self.remotes.GalleryData.OnClientEvent:Connect(function(data)
		self.galleryData = data
		if self.modal.Visible and string.find(self.modalTitle.Text, "Gallery") then
			self:_openGallery()
		end
	end)
	self.remotes.RequestGallery:FireServer("playerData")
end

return UIController
