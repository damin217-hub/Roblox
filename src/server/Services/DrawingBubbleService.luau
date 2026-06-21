local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.ArtAcademy.Config)
local StrokeCodec = require(ReplicatedStorage.ArtAcademy.StrokeCodec)
local ArtPalette = require(ReplicatedStorage.ArtAcademy.ArtPalette)
local ModerationService = require(script.Parent.ModerationService)

local DrawingBubbleService = {}
local active = {}
local nextId = 0

local function finite(value)
	return type(value) == "number" and value == value and math.abs(value) < 100000
end

local function nearestColor(color)
	if type(color) ~= "table" or not finite(color.r) or not finite(color.g) or not finite(color.b) then
		return nil
	end
	return ArtPalette.nearest(color)
end

function DrawingBubbleService.submit(player: Player, submitted)
	if type(submitted) ~= "table" or #submitted < 1 then return nil end
	if not ModerationService.allow(player, "drawing_bubble", 1, Config.BUBBLE_SHARE_COOLDOWN_SECONDS) then return nil end
	local strokes = {}
	for index = 1, math.min(#submitted, Config.BUBBLE_MAX_STROKES) do
		local candidate = submitted[index]
		if type(candidate) == "table"
			and finite(candidate.x) and finite(candidate.y)
			and finite(candidate.px) and finite(candidate.py) then
			local values = { candidate.x, candidate.y, candidate.px, candidate.py }
			local valid = true
			for _, value in values do
				if value < 0 or value > 1 then valid = false end
			end
			local color = nearestColor(candidate.color)
			local segment = Vector2.new(candidate.x - candidate.px, candidate.y - candidate.py)
			if valid and color and segment.Magnitude <= Config.MAX_STROKE_SEGMENT then
				table.insert(strokes, {
					id = #strokes + 1,
					userId = player.UserId,
					x = candidate.x,
					y = candidate.y,
					px = candidate.px,
					py = candidate.py,
					size = math.clamp(tonumber(candidate.size) or 10, Config.MIN_BRUSH_SIZE, Config.MAX_BRUSH_SIZE),
					color = color,
					erase = candidate.erase == true,
					opacity = candidate.erase == true and 1 or math.clamp(tonumber(candidate.opacity) or 1, 0.4, 1),
					kind = "line",
					stampType = candidate.stampType == "square" and "square" or "circle",
					brushStyle = "classic",
					toolType = "marker",
				})
			end
		end
	end
	if #strokes == 0 then return nil end
	nextId += 1
	local bubbleId = string.format("%d-%d", player.UserId, nextId)
	active[bubbleId] = {
		userId = player.UserId,
		strokeCount = #strokes,
		expiresAt = os.clock() + Config.BUBBLE_LIFETIME_SECONDS,
	}
	return {
		id = bubbleId,
		userId = player.UserId,
		strokes = StrokeCodec.encode(strokes, Config.BUBBLE_MAX_STROKES),
		lifetime = Config.BUBBLE_LIFETIME_SECONDS,
	}
end

function DrawingBubbleService.report(reporter: Player, bubbleId: string, owner: Player?)
	local record = active[bubbleId]
	if not record or record.expiresAt < os.clock() or reporter.UserId == record.userId then return false end
	return ModerationService.report(reporter, owner, "inappropriate", "bubble:" .. bubbleId, record.strokeCount)
end

return DrawingBubbleService
