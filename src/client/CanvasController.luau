local UserInputService = game:GetService("UserInputService")

local CanvasController = {}
CanvasController.__index = CanvasController

local COLORS = {
	Color3.fromRGB(30, 34, 48),
	Color3.fromRGB(244, 67, 86),
	Color3.fromRGB(255, 153, 51),
	Color3.fromRGB(255, 220, 66),
	Color3.fromRGB(74, 190, 108),
	Color3.fromRGB(64, 150, 255),
	Color3.fromRGB(146, 92, 255),
	Color3.fromRGB(255, 255, 255),
}

function CanvasController.new(canvas: GuiObject, remotes)
	local self = setmetatable({}, CanvasController)
	self.canvas = canvas
	self.remotes = remotes
	self.enabled = false
	self.mode = "ALL_AGES"
	self.color = COLORS[1]
	self.size = 10
	self.erase = false
	self.drawing = false
	self.last = nil
	self.objects = {}
	self.byId = {}
	return self
end

function CanvasController:setEnabled(enabled: boolean, mode: string)
	self.enabled = enabled
	self.mode = mode
end

function CanvasController:setColor(color: Color3)
	self.color = color
	self.erase = false
end

function CanvasController:setSize(size: number)
	self.size = size
end

function CanvasController:setErase(erase: boolean)
	self.erase = erase
end

function CanvasController:_normalized(inputPosition: Vector2)
	local absolute = self.canvas.AbsolutePosition
	local size = self.canvas.AbsoluteSize
	return Vector2.new(
		math.clamp((inputPosition.X - absolute.X) / size.X, 0, 1),
		math.clamp((inputPosition.Y - absolute.Y) / size.Y, 0, 1)
	)
end

function CanvasController:_render(stroke)
	local a = Vector2.new(stroke.px, stroke.py) * self.canvas.AbsoluteSize
	local b = Vector2.new(stroke.x, stroke.y) * self.canvas.AbsoluteSize
	local delta = b - a
	local length = math.max(delta.Magnitude, stroke.size)
	local line = Instance.new("Frame")
	line.Name = "Stroke_" .. tostring(stroke.id)
	line.AnchorPoint = Vector2.new(0.5, 0.5)
	line.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2)
	line.Size = UDim2.fromOffset(length, stroke.size)
	line.Rotation = math.deg(math.atan2(delta.Y, delta.X))
	line.BackgroundColor3 = stroke.erase and Color3.fromRGB(255, 255, 255)
		or Color3.new(stroke.color.r, stroke.color.g, stroke.color.b)
	line.BorderSizePixel = 0
	line.ZIndex = 4
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = line
	line.Parent = self.canvas
	table.insert(self.objects, line)
	self.byId[stroke.id] = line
end

function CanvasController:clear()
	for _, object in self.objects do object:Destroy() end
	table.clear(self.objects)
	table.clear(self.byId)
end

function CanvasController:undo(id)
	local object = self.byId[id]
	if object then
		object:Destroy()
		self.byId[id] = nil
		for index, candidate in self.objects do
			if candidate == object then table.remove(self.objects, index) break end
		end
	end
end

function CanvasController:_submit(point: Vector2)
	if not self.last then self.last = point end
	local color = self.color
	local payload = {
		x = point.X, y = point.Y,
		px = self.last.X, py = self.last.Y,
		size = self.mode == "ALL_AGES" and math.max(self.size, 18) or self.size,
		color = { r = color.R, g = color.G, b = color.B },
		erase = self.erase,
		kind = self.mode == "ALL_AGES" and "stamp" or "line",
	}
	self.remotes.SubmitStroke:FireServer(payload)
	self.last = point
end

function CanvasController:bind()
	self.canvas.InputBegan:Connect(function(input)
		if not self.enabled then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			self.drawing = true
			self.last = nil
			self:_submit(self:_normalized(input.Position))
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if not self.enabled or not self.drawing then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			self:_submit(self:_normalized(input.Position))
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			self.drawing = false
			self.last = nil
		end
	end)

	self.remotes.StrokeBroadcast.OnClientEvent:Connect(function(stroke)
		self:_render(stroke)
	end)
	self.remotes.CanvasCommand.OnClientEvent:Connect(function(command)
		if command.command == "clear" then self:clear() end
		if command.command == "undo" then self:undo(command.id) end
	end)
end

CanvasController.COLORS = COLORS
return CanvasController

