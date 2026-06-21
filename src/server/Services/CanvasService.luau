local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.ArtAcademy.Config)
local ArtPalette = require(ReplicatedStorage.ArtAcademy.ArtPalette)
local ModerationService = require(script.Parent.ModerationService)

local CanvasService = {}
local strokes = {}
local perPlayerHistory = {}
local function finite(value): boolean
	return type(value) == "number" and value == value and math.abs(value) < 100000
end

local function validColor(color): boolean
	return type(color) == "table"
		and finite(color.r) and finite(color.g) and finite(color.b)
		and color.r >= 0 and color.r <= 1
		and color.g >= 0 and color.g <= 1
		and color.b >= 0 and color.b <= 1
end

function CanvasService.reset()
	table.clear(strokes)
	table.clear(perPlayerHistory)
end

function CanvasService.submit(player: Player, payload, isArtist: boolean, _mode: string, cosmetics)
	if not isArtist or type(payload) ~= "table" then return nil end
	if #strokes >= Config.MAX_STROKES_PER_ROUND then return nil end
	if not ModerationService.allow(player, "stroke", Config.MAX_STROKES_PER_SECOND, 1) then return nil end
	if not (finite(payload.x) and finite(payload.y) and finite(payload.px) and finite(payload.py)) then return nil end
	for _, value in { payload.x, payload.y, payload.px, payload.py } do
		if value < 0 or value > 1 then return nil end
	end
	if not validColor(payload.color) then return nil end
	local segment = Vector2.new(payload.x - payload.px, payload.y - payload.py)
	if segment.Magnitude > Config.MAX_STROKE_SEGMENT then return nil end
	local size = math.clamp(tonumber(payload.size) or 10, Config.MIN_BRUSH_SIZE, Config.MAX_BRUSH_SIZE)
	local opacity = math.clamp(tonumber(payload.opacity) or 1, 0.25, 1)
	local grid = Config.ALL_AGES_GRID
	local function snap(value, cells)
		return math.clamp(math.floor(value * cells + 0.5) / cells, 0, 1)
	end
	payload.x = snap(payload.x, grid.X)
	payload.y = snap(payload.y, grid.Y)
	payload.px = snap(payload.px, grid.X)
	payload.py = snap(payload.py, grid.Y)
	payload.color = ArtPalette.nearest(payload.color)
	local allowedTools = { pencil = true, marker = true, brush = true, crayon = true }
	local toolType = allowedTools[payload.toolType] and payload.toolType or "marker"
	local stroke = {
		id = #strokes + 1,
		userId = player.UserId,
		x = payload.x,
		y = payload.y,
		px = payload.px,
		py = payload.py,
		size = size,
		color = payload.color,
		erase = payload.erase == true,
		opacity = payload.erase == true and 1 or opacity,
		kind = "line",
		stampType = payload.stampType == "square" and "square" or "circle",
		brushStyle = cosmetics and cosmetics.brush == "brush_neon" and "neon" or "classic",
		toolType = toolType,
	}
	table.insert(strokes, stroke)
	perPlayerHistory[player] = perPlayerHistory[player] or {}
	table.insert(perPlayerHistory[player], stroke.id)
	return stroke
end

function CanvasService.undo(player: Player, isArtist: boolean)
	if not isArtist then return nil end
	local history = perPlayerHistory[player]
	if not history or #history == 0 then return nil end
	local id = table.remove(history)
	for index = #strokes, 1, -1 do
		if strokes[index].id == id then
			table.remove(strokes, index)
			break
		end
	end
	return id
end

function CanvasService.getCount(): number
	return #strokes
end

function CanvasService.getSnapshot()
	return table.clone(strokes)
end

return CanvasService
