local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.ArtAcademy.Config)
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

function CanvasService.submit(player: Player, payload, isArtist: boolean, mode: string)
	if not isArtist or type(payload) ~= "table" then return nil end
	if #strokes >= Config.MAX_STROKES_PER_ROUND then return nil end
	if not ModerationService.allow(player, "stroke", Config.MAX_STROKES_PER_SECOND, 1) then return nil end
	if not (finite(payload.x) and finite(payload.y) and finite(payload.px) and finite(payload.py)) then return nil end
	for _, value in { payload.x, payload.y, payload.px, payload.py } do
		if value < 0 or value > 1 then return nil end
	end
	if not validColor(payload.color) then return nil end
	local size = math.clamp(tonumber(payload.size) or 8, 2, Config.MAX_BRUSH_SIZE)
	if mode == "ALL_AGES" and payload.kind ~= "stamp" then return nil end
	if mode == "ALL_AGES" then
		payload.px = payload.x
		payload.py = payload.y
		size = math.clamp(size, 18, 28)
	end
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
		kind = mode == "ALL_AGES" and "stamp" or "line",
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
