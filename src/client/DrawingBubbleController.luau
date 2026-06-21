local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StrokeCodec = require(ReplicatedStorage.ArtAcademy.StrokeCodec)
local CanvasController = require(script.Parent.CanvasController)

local DrawingBubbleController = {}
DrawingBubbleController.__index = DrawingBubbleController

function DrawingBubbleController.new(remotes)
	return setmetatable({ remotes = remotes, active = {} }, DrawingBubbleController)
end

function DrawingBubbleController:show(payload)
	local player = Players:GetPlayerByUserId(payload.userId)
	local character = player and player.Character
	local head = character and character:FindFirstChild("Head")
	if not head then return end
	local previous = self.active[payload.userId]
	if previous then previous:Destroy() end

	local gui = Instance.new("BillboardGui")
	gui.Name = "DrawingBubble"
	gui.Size = UDim2.fromOffset(230, 180)
	gui.StudsOffset = Vector3.new(0, 5.8, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 65
	gui.Adornee = head
	gui.Parent = head

	local card = Instance.new("Frame")
	card.Size = UDim2.fromScale(1, 1)
	card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	card.BorderSizePixel = 0
	card.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 18)
	corner.Parent = card
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(112, 83, 245)
	stroke.Thickness = 3
	stroke.Parent = card

	local canvas = Instance.new("Frame")
	canvas.Size = UDim2.new(1, -16, 1, -38)
	canvas.Position = UDim2.fromOffset(8, 8)
	canvas.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	canvas.ClipsDescendants = true
	canvas.Parent = card
	local renderer = CanvasController.new(canvas, {})
	renderer:renderSnapshot(StrokeCodec.decode(payload.strokes))

	local report = Instance.new("TextButton")
	report.Size = UDim2.fromOffset(68, 22)
	report.Position = UDim2.new(1, -76, 1, -27)
	report.Text = "Report"
	report.TextSize = 11
	report.TextColor3 = Color3.fromRGB(255, 255, 255)
	report.BackgroundColor3 = Color3.fromRGB(210, 70, 86)
	report.Parent = card
	local reportCorner = Instance.new("UICorner")
	reportCorner.CornerRadius = UDim.new(0, 8)
	reportCorner.Parent = report
	report.MouseButton1Click:Connect(function()
		self.remotes.ReportDrawingBubble:FireServer(payload.id, payload.userId)
		gui:Destroy()
	end)
	self.active[payload.userId] = gui
	task.delay(payload.lifetime or 10, function()
		renderer:destroy()
		if gui.Parent then gui:Destroy() end
		if self.active[payload.userId] == gui then self.active[payload.userId] = nil end
	end)
end

function DrawingBubbleController:bind()
	self.remotes.DrawingBubbleBroadcast.OnClientEvent:Connect(function(payload)
		self:show(payload)
	end)
end

return DrawingBubbleController
