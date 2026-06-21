local StrokeCodec = {}

local function quantizeUnit(value: number): number
	return math.clamp(math.floor(value * 1000 + 0.5), 0, 1000)
end

local function quantizeColor(value: number): number
	return math.clamp(math.floor(value * 255 + 0.5), 0, 255)
end

function StrokeCodec.encode(strokes, maxStrokes: number?)
	local result = {}
	local limit = math.min(#strokes, maxStrokes or #strokes)
	for index = 1, limit do
		local stroke = strokes[index]
		table.insert(result, {
			stroke.id,
			quantizeUnit(stroke.x),
			quantizeUnit(stroke.y),
			quantizeUnit(stroke.px),
			quantizeUnit(stroke.py),
			math.floor(stroke.size + 0.5),
			quantizeColor(stroke.color.r),
			quantizeColor(stroke.color.g),
			quantizeColor(stroke.color.b),
			stroke.erase and 1 or 0,
			stroke.kind == "stamp" and 1 or 0,
			stroke.stampType == "square" and 1 or 0,
			stroke.brushStyle == "neon" and 1 or 0,
			math.clamp(math.floor((stroke.opacity or 1) * 100 + 0.5), 25, 100),
		})
	end
	return result
end

function StrokeCodec.decode(encoded)
	local result = {}
	for _, item in encoded or {} do
		table.insert(result, {
			id = item[1],
			x = item[2] / 1000,
			y = item[3] / 1000,
			px = item[4] / 1000,
			py = item[5] / 1000,
			size = item[6],
			color = {
				r = item[7] / 255,
				g = item[8] / 255,
				b = item[9] / 255,
			},
			erase = item[10] == 1,
			kind = item[11] == 1 and "stamp" or "line",
			stampType = item[12] == 1 and "square" or "circle",
			brushStyle = item[13] == 1 and "neon" or "classic",
			opacity = (item[14] or 100) / 100,
		})
	end
	return result
end

return StrokeCodec
