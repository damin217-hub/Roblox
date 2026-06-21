local ArtPalette = {}

local colors = {
	Color3.fromRGB(38, 42, 58),
	Color3.fromRGB(112, 117, 132),
	Color3.fromRGB(214, 216, 222),
	Color3.fromRGB(255, 255, 255),
}

for _, hue in { 0, 30, 55, 90, 130, 170, 200, 225, 260, 290, 325, 345 } do
	for _, tone in {
		{ saturation = 0.72, value = 0.98 },
		{ saturation = 0.58, value = 0.78 },
		{ saturation = 0.35, value = 0.96 },
	} do
		table.insert(colors, Color3.fromHSV(hue / 360, tone.saturation, tone.value))
	end
end

ArtPalette.COLORS = table.freeze(colors)

function ArtPalette.toTable(color: Color3)
	return { r = color.R, g = color.G, b = color.B }
end

function ArtPalette.nearest(color)
	local best = colors[1]
	local bestDistance = math.huge
	for _, approved in colors do
		local distance = (color.r - approved.R) ^ 2 + (color.g - approved.G) ^ 2 + (color.b - approved.B) ^ 2
		if distance < bestDistance then
			best = approved
			bestDistance = distance
		end
	end
	return ArtPalette.toTable(best)
end

return ArtPalette
