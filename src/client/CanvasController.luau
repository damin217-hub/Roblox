local UserInputService = game:GetService("UserInputService")
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.ArtAcademy.Config)

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
local CANDY_COLORS = {
	Color3.fromRGB(62, 32, 82),
	Color3.fromRGB(255, 93, 143),
	Color3.fromRGB(255, 153, 204),
	Color3.fromRGB(255, 218, 121),
	Color3.fromRGB(121, 239, 196),
	Color3.fromRGB(91, 205, 255),
	Color3.fromRGB(180, 125, 255),
	Color3.fromRGB(255, 255, 255),
}
local BRUSH_PRESETS = {
	fine = { size = 6, opacity = 1 },
	marker = { size = 14, opacity = 0.8 },
	bold = { size = 24, opacity = 1 },
	soft = { size = 18, opacity = 0.45 },
}

function CanvasController.new(canvas: GuiObject, remotes)
	local self = setmetatable({}, CanvasController)
	self.canvas = canvas
	self.remotes = remotes
	self.enabled = false
	self.mode = "ALL_AGES"
	self.color = COLORS[1]
	self.size = 10
	self.opacity = 1
	self.erase = false
	self.stampType = "circle"
	self.palette = COLORS
	self.brushStyle = "classic"
	self.drawing = false
	self.activeTouch = nil
	self.last = nil
	self.lastSubmitAt = 0
	self.objects = {}
	self.byId = {}
	self.strokes = {}
	self.editableImage = nil
	self.imageLabel = nil
	self:_initializeEditableImage()
	return self
end

function CanvasController:_initializeEditableImage()
	local ok, editable = pcall(function()
		return AssetService:CreateEditableImage({ Size = Config.CANVAS_SIZE })
	end)
	if not ok or not editable then
		return
	end

	local imageLabel = Instance.new("ImageLabel")
	imageLabel.Name = "EditableCanvas"
	imageLabel.Size = UDim2.fromScale(1, 1)
	imageLabel.BackgroundTransparency = 1
	imageLabel.ScaleType = Enum.ScaleType.Stretch
	imageLabel.ZIndex = 3
	local assigned = pcall(function()
		imageLabel.ImageContent = Content.fromObject(editable)
	end)
	if not assigned then
		editable:Destroy()
		imageLabel:Destroy()
		return
	end
	imageLabel.Parent = self.canvas
	self.editableImage = editable
	self.imageLabel = imageLabel
	self:_clearEditableImage()
end

function CanvasController:_clearEditableImage()
	if not self.editableImage then
		return
	end
	self.editableImage:DrawRectangle(
		Vector2.zero,
		self.editableImage.Size,
		Color3.fromRGB(255, 255, 255),
		0,
		Enum.ImageCombineType.Overwrite
	)
end

function CanvasController:setEnabled(enabled: boolean, mode: string)
	self.enabled = enabled
	self.mode = mode
	if not enabled then
		self.drawing = false
		self.activeTouch = nil
		self.last = nil
	end
end

function CanvasController:setColor(color: Color3)
	self.color = color
	self.erase = false
end

function CanvasController:setStampType(stampType: string)
	self.stampType = stampType == "square" and "square" or "circle"
end

function CanvasController:setCosmetics(equipped)
	equipped = equipped or {}
	self.palette = equipped.palette == "palette_candy" and CANDY_COLORS or COLORS
	self.brushStyle = equipped.brush == "brush_neon" and "neon" or "classic"
end

function CanvasController:getPalette()
	return self.palette
end

function CanvasController:setSize(size: number)
	self.size = math.clamp(size, Config.MIN_BRUSH_SIZE, Config.MAX_BRUSH_SIZE)
end

function CanvasController:setOpacity(opacity: number)
	self.opacity = math.clamp(opacity, 0.25, 1)
end

function CanvasController:applyPreset(name: string)
	local preset = BRUSH_PRESETS[name]
	if not preset then
		return false
	end
	self:setSize(preset.size)
	self:setOpacity(preset.opacity)
	self.erase = false
	return true
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
	table.insert(self.strokes, stroke)
	self.byId[stroke.id] = stroke
	if self.editableImage then
		self:_drawEditableStroke(stroke)
		return
	end
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
	line.BackgroundTransparency = stroke.erase and 0 or (1 - (stroke.opacity or 1))
	line.BorderSizePixel = 0
	line.ZIndex = 4
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = line
	line.Parent = self.canvas
	table.insert(self.objects, line)
	self.byId[stroke.id] = stroke
	stroke.fallbackObject = line
end

function CanvasController:_drawEditableStroke(stroke)
	local image = self.editableImage
	if not image then
		return
	end
	local a = Vector2.new(stroke.px, stroke.py) * image.Size
	local b = Vector2.new(stroke.x, stroke.y) * image.Size
	local delta = b - a
	local distance = delta.Magnitude
	local radius = math.max(1, math.floor(stroke.size / 2))
	local color = stroke.erase and Color3.fromRGB(255, 255, 255)
		or Color3.new(stroke.color.r, stroke.color.g, stroke.color.b)
	local steps = math.max(1, math.ceil(distance / math.max(1, radius * 0.65)))
	local transparency = stroke.erase and 0 or (1 - (stroke.opacity or 1))
	local combineType = stroke.erase and Enum.ImageCombineType.Overwrite or Enum.ImageCombineType.AlphaBlend
	for index = 0, steps do
		local alpha = index / steps
		local point = a:Lerp(b, alpha)
		if stroke.brushStyle == "neon" and not stroke.erase then
			image:DrawCircle(
				Vector2.new(math.floor(point.X), math.floor(point.Y)),
				radius + 3,
				Color3.fromRGB(80, 235, 255),
				0.45,
				Enum.ImageCombineType.AlphaBlend
			)
		end
		if stroke.stampType == "square" then
			local diameter = radius * 2
			image:DrawRectangle(
				Vector2.new(math.floor(point.X - radius), math.floor(point.Y - radius)),
				Vector2.new(diameter, diameter),
				color,
				transparency,
				combineType
			)
		else
			image:DrawCircle(
				Vector2.new(math.floor(point.X), math.floor(point.Y)),
				radius,
				color,
				transparency,
				combineType
			)
		end
	end
end

function CanvasController:_rebuild()
	if self.editableImage then
		self:_clearEditableImage()
		for _, stroke in self.strokes do
			self:_drawEditableStroke(stroke)
		end
		return
	end
	for _, object in self.objects do
		object:Destroy()
	end
	table.clear(self.objects)
	for _, stroke in self.strokes do
		local fallbackObject = stroke.fallbackObject
		stroke.fallbackObject = nil
		self:_renderFallback(stroke)
		if fallbackObject then
			fallbackObject:Destroy()
		end
	end
end

function CanvasController:_renderFallback(stroke)
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
	line.BackgroundTransparency = stroke.erase and 0 or (1 - (stroke.opacity or 1))
	line.BorderSizePixel = 0
	line.ZIndex = 4
	local lineCorner = Instance.new("UICorner")
	lineCorner.CornerRadius = UDim.new(1, 0)
	lineCorner.Parent = line
	line.Parent = self.canvas
	table.insert(self.objects, line)
	stroke.fallbackObject = line
end

function CanvasController:clear()
	for _, object in self.objects do object:Destroy() end
	table.clear(self.objects)
	table.clear(self.byId)
	table.clear(self.strokes)
	self:_clearEditableImage()
end

function CanvasController:renderSnapshot(strokes)
	self:clear()
	for _, stroke in strokes do
		self:_render(stroke)
	end
end

function CanvasController:destroy()
	self:clear()
	if self.editableImage then
		self.editableImage:Destroy()
		self.editableImage = nil
	end
	if self.imageLabel then
		self.imageLabel:Destroy()
		self.imageLabel = nil
	end
end

function CanvasController:undo(id)
	local stroke = self.byId[id]
	if stroke then
		if stroke.fallbackObject then
			stroke.fallbackObject:Destroy()
		end
		self.byId[id] = nil
		for index, candidate in self.strokes do
			if candidate.id == id then
				table.remove(self.strokes, index)
				break
			end
		end
		self:_rebuild()
	end
end

function CanvasController:_submit(point: Vector2)
	if not self.last then self.last = point end
	local color = self.color
	local payload = {
		x = point.X, y = point.Y,
		px = self.last.X, py = self.last.Y,
		size = self.size,
		opacity = self.opacity,
		color = { r = color.R, g = color.G, b = color.B },
		erase = self.erase,
		kind = "line",
		stampType = self.stampType,
		brushStyle = self.brushStyle,
	}
	self.remotes.SubmitStroke:FireServer(payload)
	self.last = point
	self.lastSubmitAt = os.clock()
end

function CanvasController:bind()
	self.canvas.InputBegan:Connect(function(input)
		if not self.enabled then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			self.drawing = true
			self.activeTouch = input.UserInputType == Enum.UserInputType.Touch and input or nil
			self.last = nil
			self:_submit(self:_normalized(Vector2.new(input.Position.X, input.Position.Y)))
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if not self.enabled or not self.drawing then return end
		local isMouse = input.UserInputType == Enum.UserInputType.MouseMovement and self.activeTouch == nil
		local isActiveTouch = input.UserInputType == Enum.UserInputType.Touch and input == self.activeTouch
		if isMouse or isActiveTouch then
			local point = self:_normalized(Vector2.new(input.Position.X, input.Position.Y))
			local pixelDistance = self.last and ((point - self.last) * self.canvas.AbsoluteSize).Magnitude or math.huge
			if pixelDistance >= math.max(2, self.size * 0.18) and os.clock() - self.lastSubmitAt >= 1 / 40 then
				self:_submit(point)
			end
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		local endedMouse = input.UserInputType == Enum.UserInputType.MouseButton1 and self.activeTouch == nil
		local endedTouch = input.UserInputType == Enum.UserInputType.Touch and input == self.activeTouch
		if endedMouse or endedTouch then
			if self.enabled and self.last then
				local finalPoint = self:_normalized(Vector2.new(input.Position.X, input.Position.Y))
				local finalDistance = ((finalPoint - self.last) * self.canvas.AbsoluteSize).Magnitude
				if finalDistance >= math.max(2, self.size * 0.18) then
					self:_submit(finalPoint)
				end
			end
			self.drawing = false
			self.activeTouch = nil
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
CanvasController.CANDY_COLORS = CANDY_COLORS
CanvasController.BRUSH_PRESETS = BRUSH_PRESETS
return CanvasController
