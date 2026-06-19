local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalizationService = game:GetService("LocalizationService")
local Localization = require(ReplicatedStorage.ArtAcademy.Localization)
local Catalog = require(ReplicatedStorage.ArtAcademy.Catalog)
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
	self.playerData = nil
	self.questData = {}
	self.galleryData = { approved = {}, pending = {}, isAdmin = false }
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

	local tools = Instance.new("ScrollingFrame")
	tools.Size = UDim2.new(1, -30, 0, 54)
	tools.Position = UDim2.new(0, 15, 1, -62)
	tools.BackgroundTransparency = 1
	tools.BorderSizePixel = 0
	tools.ScrollBarThickness = 4
	tools.ScrollingDirection = Enum.ScrollingDirection.X
	tools.CanvasSize = UDim2.fromOffset(625, 0)
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

	local reactions = Instance.new("Frame")
	reactions.Size = UDim2.new(1, -20, 0, 38)
	reactions.Position = UDim2.new(0, 10, 0.63, 0)
	reactions.BackgroundTransparency = 1
	reactions.Parent = side
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

	self.canvasController = CanvasController.new(self.canvas, self.remotes)
	self.canvasController:bind()

	local camera = workspace.CurrentCamera
	local function applyResponsiveLayout()
		local width = camera and camera.ViewportSize.X or 1280
		if width < 900 then
			top.Size = UDim2.new(1, -16, 0, 62)
			top.Position = UDim2.fromOffset(8, 6)
			self.title.Visible = false
			main.Size = UDim2.new(1, -16, 0.6, -42)
			main.Position = UDim2.fromOffset(8, 76)
			side.Size = UDim2.new(1, -16, 0.4, -42)
			side.Position = UDim2.new(0, 8, 0.6, 42)
			self.modal.Size = UDim2.new(0.94, 0, 0.82, 0)
		else
			self.title.Visible = true
			top.Size = UDim2.new(1, -24, 0, 76)
			top.Position = UDim2.fromOffset(12, 10)
			main.Size = UDim2.new(0.72, -18, 1, -110)
			main.Position = UDim2.fromOffset(12, 98)
			side.Size = UDim2.new(0.28, -18, 1, -110)
			side.Position = UDim2.new(0.72, 6, 0, 98)
			self.modal.Size = UDim2.new(0.76, 0, 0.72, 0)
		end
	end
	applyResponsiveLayout()
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(applyResponsiveLayout)
	end
end

function UIController:_clearModal()
	for _, child in self.modalList:GetChildren() do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
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
	self.modalTitle.Text = "Daily Missions / 오늘의 미션"
	for _, quest in self.questData do
		local complete = quest.progress >= quest.requirement
		local actionText = quest.claimed and "Claimed" or (complete and "Claim" or "In progress")
		self:_modalRow(
			quest.nameKo .. " / " .. quest.nameEn,
			string.format("%d / %d  •  +%d coins", quest.progress, quest.requirement, quest.reward),
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
				UDim2.new(0.58, 0, 1, 0),
				UDim2.fromOffset(14, 0),
				16,
				true
			)
			rowTitle.ZIndex = 62
			local approve = button(row, "Approve", UDim2.new(0.18, 0, 0, 42), UDim2.new(0.6, 0, 0.5, -21), Color3.fromRGB(74, 190, 108))
			approve.ZIndex = 63
			approve.MouseButton1Click:Connect(function()
				self.remotes.ModerateGallery:FireServer(artwork.id, "approve")
			end)
			local reject = button(row, "Reject", UDim2.new(0.18, 0, 0, 42), UDim2.new(0.8, 0, 0.5, -21), Color3.fromRGB(226, 67, 87))
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
				nil,
				nil
			)
		end
	end
	self.modal.Visible = true
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
		self.playerData = data
		self.currency.Text = tostring(data.coins or 0) .. " " .. self.strings.coins
		if self.modal.Visible and string.find(self.modalTitle.Text, "Shop") then
			self:_openShop()
		end
	end)
	self.remotes.OpenPanel.OnClientEvent:Connect(function(panel)
		if panel == "shop" then
			self:_openShop()
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
end

return UIController
