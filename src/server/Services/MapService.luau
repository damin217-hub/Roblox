local Lighting = game:GetService("Lighting")

local MapService = {}

local COLORS = {
	ink = Color3.fromRGB(46, 42, 68),
	violet = Color3.fromRGB(112, 83, 245),
	deepViolet = Color3.fromRGB(73, 52, 178),
	coral = Color3.fromRGB(255, 116, 139),
	cyan = Color3.fromRGB(104, 190, 255),
	mint = Color3.fromRGB(130, 212, 153),
	lilac = Color3.fromRGB(187, 130, 255),
	gold = Color3.fromRGB(244, 205, 103),
	cream = Color3.fromRGB(218, 213, 226),
	white = Color3.fromRGB(242, 240, 247),
	grass = Color3.fromRGB(86, 126, 111),
	wood = Color3.fromRGB(165, 112, 78),
	plaza = Color3.fromRGB(119, 111, 143),
	plazaDark = Color3.fromRGB(72, 66, 96),
	ground = Color3.fromRGB(60, 72, 82),
}

local function part(parent, name, size, cf, color, material)
	local item = Instance.new("Part")
	item.Name = name
	item.Anchored = true
	item.Size = size
	item.CFrame = cf
	item.Color = color
	item.Material = material or Enum.Material.SmoothPlastic
	item.TopSurface = Enum.SurfaceType.Smooth
	item.BottomSurface = Enum.SurfaceType.Smooth
	item.Parent = parent
	return item
end

local function ball(parent, name, size, position, color, material)
	local item = part(parent, name, size, CFrame.new(position), color, material)
	item.Shape = Enum.PartType.Ball
	return item
end

local function cylinder(parent, name, size, cf, color, material)
	local item = part(parent, name, size, cf, color, material)
	item.Shape = Enum.PartType.Cylinder
	return item
end

local function cornerLight(parent, position, color, brightness, range)
	local orb = ball(parent, "AcademyLamp", Vector3.new(0.8, 0.8, 0.8), position, color, Enum.Material.Neon)
	orb.CanCollide = false
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = brightness or 1.2
	light.Range = range or 18
	light.Shadows = true
	light.Parent = orb
	return orb
end

local function label(partInstance, value, color, width, height, offset)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(width or 300, height or 72)
	gui.StudsOffset = offset or Vector3.new(0, 4.8, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 90
	gui.Parent = partInstance

	local shadow = Instance.new("TextLabel")
	shadow.Size = UDim2.fromScale(1, 1)
	shadow.Position = UDim2.fromOffset(2, 3)
	shadow.BackgroundTransparency = 1
	shadow.Text = value
	shadow.TextColor3 = COLORS.ink
	shadow.TextTransparency = 0.45
	shadow.Font = Enum.Font.GothamBlack
	shadow.TextScaled = true
	shadow.Parent = gui

	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(1, 1)
	title.BackgroundTransparency = 1
	title.Text = value
	title.TextColor3 = color
	title.TextStrokeTransparency = 0.7
	title.Font = Enum.Font.GothamBlack
	title.TextScaled = true
	title.Parent = gui
end

local function surfaceLabel(partInstance, value, color)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.Parent = partInstance
	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(1, 1)
	title.BackgroundTransparency = 1
	title.Text = value
	title.TextColor3 = color
	title.Font = Enum.Font.GothamBlack
	title.TextScaled = true
	title.Parent = gui
end

local function tree(parent, name, position, scale, leafColor)
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	local trunk = part(
		model,
		"Trunk",
		Vector3.new(1.8, 5.5, 1.8) * scale,
		CFrame.new(position + Vector3.new(0, 2.75 * scale, 0)),
		COLORS.wood,
		Enum.Material.Wood
	)
	trunk.CanCollide = true
	ball(
		model,
		"Crown",
		Vector3.new(7.2, 7.2, 7.2) * scale,
		position + Vector3.new(0, 7 * scale, 0),
		leafColor or COLORS.mint,
		Enum.Material.Grass
	)
	ball(
		model,
		"CrownAccent",
		Vector3.new(4.8, 4.8, 4.8) * scale,
		position + Vector3.new(2.4, 8.2, 0) * scale,
		Color3.fromRGB(190, 232, 172),
		Enum.Material.Grass
	)
	return model
end

local function planter(parent, name, position, accent)
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	part(model, "Box", Vector3.new(7, 1.8, 3), CFrame.new(position + Vector3.new(0, 0.9, 0)), COLORS.cream, Enum.Material.Marble)
	part(model, "Soil", Vector3.new(6.2, 0.25, 2.2), CFrame.new(position + Vector3.new(0, 1.85, 0)), Color3.fromRGB(92, 66, 55), Enum.Material.Ground)
	for index = -2, 2 do
		ball(
			model,
			"Flower",
			Vector3.new(1.15, 1.15, 1.15),
			position + Vector3.new(index * 1.15, 2.4 + math.abs(index) * 0.08, 0),
			index % 2 == 0 and accent or COLORS.gold,
			Enum.Material.SmoothPlastic
		)
	end
	return model
end

local function bench(parent, name, position, lookAtPosition, accent)
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	local cf = CFrame.lookAt(position, lookAtPosition)
	local seat = Instance.new("Seat")
	seat.Name = "Seat"
	seat.Anchored = true
	seat.Size = Vector3.new(6, 0.7, 2.3)
	seat.CFrame = cf * CFrame.new(0, 1.5, 0)
	seat.Color = COLORS.wood
	seat.Material = Enum.Material.WoodPlanks
	seat.TopSurface = Enum.SurfaceType.Smooth
	seat.BottomSurface = Enum.SurfaceType.Smooth
	seat.Parent = model
	part(model, "Back", Vector3.new(6, 2.4, 0.55), cf * CFrame.new(0, 2.8, 1), accent, Enum.Material.SmoothPlastic)
	part(model, "LeftLeg", Vector3.new(0.5, 1.3, 0.5), cf * CFrame.new(-2.3, 0.65, 0), COLORS.ink, Enum.Material.Metal)
	part(model, "RightLeg", Vector3.new(0.5, 1.3, 0.5), cf * CFrame.new(2.3, 0.65, 0), COLORS.ink, Enum.Material.Metal)
	return model
end

local function paintSculpture(parent, position)
	local model = Instance.new("Model")
	model.Name = "PaintbrushLandmark"
	model.Parent = parent
	local brushCf = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(-28))
	part(model, "Handle", Vector3.new(2, 18, 2), brushCf, COLORS.gold, Enum.Material.Wood)
	part(model, "Ferrule", Vector3.new(2.8, 4, 2.8), brushCf * CFrame.new(0, 10, 0), COLORS.ink, Enum.Material.Metal)
	local bristles = part(model, "Bristles", Vector3.new(3.6, 5, 3.6), brushCf * CFrame.new(0, 14.2, 0), COLORS.coral, Enum.Material.Neon)
	bristles.CanCollide = false
	cornerLight(model, position + Vector3.new(-6, 17, 0), COLORS.coral, 1.5, 22)
	return model
end

local function floorSign(parent, name, position, color, titleText)
	local pad = part(
		parent,
		name,
		Vector3.new(15, 0.4, 10),
		CFrame.new(position),
		color,
		Enum.Material.SmoothPlastic
	)
	pad.Transparency = 0.03
	label(pad, titleText, COLORS.white, 250, 58, Vector3.new(0, 3.8, 0))
	return pad
end

local function npc(parent, name, position, color, actionText)
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	local frontZ = position.Z < 0 and 1 or -1

	local body = part(model, "Body", Vector3.new(3.2, 4.2, 2.1), CFrame.new(position + Vector3.new(0, 3.1, 0)), color)
	part(model, "Apron", Vector3.new(2.7, 2.7, 0.25), CFrame.new(position + Vector3.new(0, 2.75, frontZ * 1.15)), COLORS.cream)
	part(model, "LeftArm", Vector3.new(1, 3.6, 1), CFrame.new(position + Vector3.new(-2.05, 3.25, 0)), Color3.fromRGB(255, 220, 184))
	part(model, "RightArm", Vector3.new(1, 3.6, 1), CFrame.new(position + Vector3.new(2.05, 3.25, 0)), Color3.fromRGB(255, 220, 184))
	part(model, "LeftLeg", Vector3.new(1.2, 2.4, 1.4), CFrame.new(position + Vector3.new(-0.85, 0.9, 0)), COLORS.ink)
	part(model, "RightLeg", Vector3.new(1.2, 2.4, 1.4), CFrame.new(position + Vector3.new(0.85, 0.9, 0)), COLORS.ink)

	local head = ball(model, "Head", Vector3.new(2.6, 2.6, 2.6), position + Vector3.new(0, 6.4, 0), Color3.fromRGB(255, 220, 184))
	local hat = cylinder(model, "Beret", Vector3.new(2.9, 0.65, 2.9), CFrame.new(position + Vector3.new(0, 7.65, 0)), color)
	hat.Orientation = Vector3.new(0, 0, 90)
	for _, x in { -0.48, 0.48 } do
		local eye = ball(model, "Eye", Vector3.new(0.24, 0.24, 0.24), position + Vector3.new(x, 6.55, frontZ * 1.28), COLORS.ink)
		eye.CanCollide = false
	end
	local smile = part(model, "Smile", Vector3.new(0.8, 0.12, 0.12), CFrame.new(position + Vector3.new(0, 5.95, frontZ * 1.32)), COLORS.coral)
	smile.CanCollide = false
	label(head, name, COLORS.white, 280, 64, Vector3.new(0, 4.5, 0))

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = name
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 11
	prompt.RequiresLineOfSight = false
	prompt.Parent = body
	return model
end

local function academyWing(parent, name, center, accent, titleText, lookAt)
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	local target = lookAt or Vector3.new(0, center.Y, 4)
	local cf = CFrame.lookAt(center, Vector3.new(target.X, center.Y, target.Z))
	part(model, "Foundation", Vector3.new(28, 1.2, 22), cf * CFrame.new(0, 0.6, 0), COLORS.cream, Enum.Material.Marble)
	part(model, "BackWall", Vector3.new(28, 12, 1.2), cf * CFrame.new(0, 6.5, 10.4), Color3.fromRGB(198, 194, 211), Enum.Material.SmoothPlastic)
	part(model, "LeftWall", Vector3.new(1.2, 9, 21), cf * CFrame.new(-13.4, 5, 0), Color3.fromRGB(198, 194, 211))
	part(model, "RightWall", Vector3.new(1.2, 9, 21), cf * CFrame.new(13.4, 5, 0), Color3.fromRGB(198, 194, 211))
	part(model, "Roof", Vector3.new(30, 1.2, 24), cf * CFrame.new(0, 13, 0), accent, Enum.Material.SmoothPlastic)
	part(model, "Canopy", Vector3.new(22, 0.75, 6), cf * CFrame.new(0, 9.7, -11), accent, Enum.Material.SmoothPlastic)
	for x = -10, 10, 5 do
		local stripe = part(
			model,
			"CanopyStripe",
			Vector3.new(2.5, 0.78, 6.1),
			cf * CFrame.new(x, 9.72, -11.05),
			COLORS.white,
			Enum.Material.SmoothPlastic
		)
		stripe.CanCollide = false
	end
	for x = -9, 9, 6 do
		local window = part(
			model,
			"Window",
			Vector3.new(4.2, 4.8, 0.25),
			cf * CFrame.new(x, 7, 9.72),
			Color3.fromRGB(190, 231, 255),
			Enum.Material.Glass
		)
		window.Transparency = 0.25
		window.CanCollide = false
	end
	local sign = part(model, "WingSign", Vector3.new(18, 3.4, 0.55), cf * CFrame.new(0, 11.2, -12.1), COLORS.ink)
	surfaceLabel(sign, titleText, COLORS.white)
	cornerLight(model, center + Vector3.new(-10, 10.5, -9.5), accent, 1.25, 18)
	cornerLight(model, center + Vector3.new(10, 10.5, -9.5), accent, 1.25, 18)
	return model
end

local function plazaFacingPoint(center, distance)
	local target = Vector3.new(0, center.Y, 4)
	local direction = target - center
	if direction.Magnitude == 0 then
		return center
	end
	return center + direction.Unit * distance
end

local function galleryFrames(parent, origin)
	local model = Instance.new("Model")
	model.Name = "OutdoorGalleryFrames"
	model.Parent = parent
	for index = 1, 5 do
		local x = (index - 3) * 6.2
		local frame = part(
			model,
			"GalleryFrame_" .. index,
			Vector3.new(5.4, 6.8, 0.45),
			CFrame.new(origin + Vector3.new(x, 4.4, 0)),
			index % 2 == 0 and COLORS.lilac or COLORS.gold,
			Enum.Material.Wood
		)
		local art = part(
			model,
			"GalleryCanvas_" .. index,
			Vector3.new(4.45, 5.8, 0.2),
			CFrame.new(origin + Vector3.new(x, 4.4, -0.35)),
			index == 1 and COLORS.coral
				or index == 2 and COLORS.cyan
				or index == 3 and COLORS.mint
				or index == 4 and COLORS.violet
				or COLORS.gold,
			Enum.Material.SmoothPlastic
		)
		art.CanCollide = false
		frame.CanCollide = false
	end
	return model
end

local function configureLighting()
	Lighting.ClockTime = 17.2
	Lighting.Brightness = 1.75
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.45
	Lighting.EnvironmentDiffuseScale = 0.32
	Lighting.EnvironmentSpecularScale = 0.28
	Lighting.Ambient = Color3.fromRGB(76, 73, 101)
	Lighting.OutdoorAmbient = Color3.fromRGB(105, 105, 132)

	for _, effectName in { "AcademyBloom", "AcademyColor", "AcademyAtmosphere", "AcademySunRays" } do
		local existing = Lighting:FindFirstChild(effectName)
		if existing then
			existing:Destroy()
		end
	end

	local bloom = Instance.new("BloomEffect")
	bloom.Name = "AcademyBloom"
	bloom.Intensity = 0.12
	bloom.Size = 12
	bloom.Threshold = 1.45
	bloom.Parent = Lighting

	local colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Name = "AcademyColor"
	colorCorrection.Saturation = -0.02
	colorCorrection.Contrast = 0.1
	colorCorrection.Brightness = -0.045
	colorCorrection.TintColor = Color3.fromRGB(224, 219, 238)
	colorCorrection.Parent = Lighting

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "AcademyAtmosphere"
	atmosphere.Density = 0.2
	atmosphere.Offset = 0.02
	atmosphere.Haze = 0.8
	atmosphere.Glare = 0.03
	atmosphere.Color = Color3.fromRGB(157, 166, 194)
	atmosphere.Decay = Color3.fromRGB(104, 91, 125)
	atmosphere.Parent = Lighting

	local sunRays = Instance.new("SunRaysEffect")
	sunRays.Name = "AcademySunRays"
	sunRays.Intensity = 0.015
	sunRays.Spread = 0.7
	sunRays.Parent = Lighting
end

function MapService.build()
	if workspace:FindFirstChild("ArtAcademyMap") then return end
	configureLighting()

	local map = Instance.new("Folder")
	map.Name = "ArtAcademyMap"
	map.Parent = workspace

	part(map, "WorldBase", Vector3.new(190, 3, 170), CFrame.new(0, -2.2, 2), COLORS.ground, Enum.Material.Grass)
	part(map, "Floor", Vector3.new(160, 2, 140), CFrame.new(0, -1, 0), Color3.fromRGB(82, 79, 101), Enum.Material.Slate)
	local academy = part(map, "Academy", Vector3.new(1.2, 120, 104), CFrame.new(0, 0.15, 0), COLORS.plaza, Enum.Material.Marble)
	academy.Shape = Enum.PartType.Cylinder
	academy.Orientation = Vector3.new(0, 0, 90)

	local mainPlaza = cylinder(
		map,
		"MainPlaza",
		Vector3.new(0.7, 76, 76),
		CFrame.new(0, 0.95, 4),
		COLORS.plazaDark,
		Enum.Material.Slate
	)
	mainPlaza.Orientation = Vector3.new(0, 0, 90)
	local plazaRing = cylinder(
		map,
		"MainPlazaRing",
		Vector3.new(0.28, 68, 68),
		CFrame.new(0, 1.33, 4),
		Color3.fromRGB(151, 137, 184),
		Enum.Material.Marble
	)
	plazaRing.Orientation = Vector3.new(0, 0, 90)
	local plazaCenter = cylinder(
		map,
		"MainPlazaCenter",
		Vector3.new(0.35, 55, 55),
		CFrame.new(0, 1.52, 4),
		Color3.fromRGB(93, 84, 122),
		Enum.Material.SmoothPlastic
	)
	plazaCenter.Orientation = Vector3.new(0, 0, 90)

	for index, pathData in {
		{ Vector3.new(-29, 1.08, -10), math.rad(-63) },
		{ Vector3.new(29, 1.08, -10), math.rad(63) },
		{ Vector3.new(-29, 1.08, 20), math.rad(63) },
		{ Vector3.new(29, 1.08, 20), math.rad(-63) },
	} do
		part(
			map,
			"PlazaSpoke_" .. index,
			Vector3.new(9, 0.24, 34),
			CFrame.new(pathData[1]) * CFrame.Angles(0, pathData[2], 0),
			Color3.fromRGB(135, 123, 165),
			Enum.Material.SmoothPlastic
		)
	end

	part(map, "WelcomePath", Vector3.new(12, 0.3, 52), CFrame.new(0, 0.88, 48), Color3.fromRGB(111, 95, 157), Enum.Material.SmoothPlastic)
	for index = 0, 8 do
		local z = 27 + index * 5.8
		part(
			map,
			"PathInlay",
			Vector3.new(11.4, 0.12, 1.1),
			CFrame.new(0, 1.08, z),
			index % 2 == 0 and COLORS.coral or COLORS.gold,
			Enum.Material.Neon
		).CanCollide = false
	end

	local welcomeArchTop = part(
		map,
		"WelcomeArchTop",
		Vector3.new(34, 3.2, 3),
		CFrame.new(0, 15.5, 61),
		COLORS.violet,
		Enum.Material.SmoothPlastic
	)
	label(welcomeArchTop, "MOMO'S ART ACADEMY  •  모모의 아트 아카데미", COLORS.white, 560, 90, Vector3.new(0, 4.6, 0))
	for _, x in { -15, 15 } do
		part(map, "WelcomeArchColumn", Vector3.new(3.3, 15, 3.3), CFrame.new(x, 7.5, 61), COLORS.deepViolet, Enum.Material.Marble)
		part(map, "WelcomeArchFoot", Vector3.new(6, 1.2, 6), CFrame.new(x, 0.65, 61), COLORS.gold, Enum.Material.Marble)
		cornerLight(map, Vector3.new(x, 13.3, 59.2), COLORS.gold, 1.4, 20)
	end
	part(map, "EntranceBrush", Vector3.new(22, 1.1, 1.1), CFrame.new(0, 18.5, 61) * CFrame.Angles(0, 0, math.rad(8)), COLORS.gold, Enum.Material.Wood)

	for index = 1, 24 do
		local angle = math.rad((index - 1) * 15)
		local x = math.cos(angle) * 59
		local z = math.sin(angle) * 51
		local position = Vector3.new(x, 7, z)
		part(map, "AcademyColumn_" .. index, Vector3.new(2.2, 14, 2.2), CFrame.new(position), COLORS.gold, Enum.Material.Marble)
		local nextAngle = math.rad(index * 15)
		local nextPosition = Vector3.new(math.cos(nextAngle) * 59, 14.2, math.sin(nextAngle) * 51)
		local currentTop = Vector3.new(x, 14.2, z)
		local midpoint = (currentTop + nextPosition) / 2
		local length = (nextPosition - currentTop).Magnitude
		part(
			map,
			"RoofArc_" .. index,
			Vector3.new(1.7, 1.5, length + 0.4),
			CFrame.lookAt(midpoint, nextPosition),
			index % 4 == 0 and COLORS.coral or COLORS.violet,
			Enum.Material.SmoothPlastic
		)
	end

	local center = cylinder(
		map,
		"MatchPortal",
		Vector3.new(1.4, 19, 19),
		CFrame.new(0, 1.4, 4),
		COLORS.violet,
		Enum.Material.Neon
	)
	center.Orientation = Vector3.new(0, 0, 90)
	label(center, "PLAY  •  게임 시작", COLORS.white, 310, 76, Vector3.new(0, 5.8, 0))
	local matchPrompt = Instance.new("ProximityPrompt")
	matchPrompt.Name = "MatchmakingPrompt"
	matchPrompt.ActionText = "Join / Leave Queue"
	matchPrompt.ObjectText = "Match Portal / 매칭 포털"
	matchPrompt.HoldDuration = 0
	matchPrompt.MaxActivationDistance = 14
	matchPrompt.RequiresLineOfSight = false
	matchPrompt.Parent = center

	for index = 1, 12 do
		local angle = math.rad((index - 1) * 30)
		local position = Vector3.new(math.cos(angle) * 12, 4.5, 4 + math.sin(angle) * 12)
		local glow = ball(
			map,
			"PortalGlow_" .. index,
			Vector3.new(1.25, 1.25, 1.25),
			position,
			index % 3 == 0 and COLORS.gold or index % 2 == 0 and COLORS.coral or COLORS.cyan,
			Enum.Material.Neon
		)
		glow.CanCollide = false
	end
	paintSculpture(map, Vector3.new(-7, 7, 4))
	cornerLight(map, Vector3.new(7, 5.5, 4), COLORS.violet, 2, 28)

	for index = 1, 8 do
		local angle = math.rad((index - 1) * 45 + 22.5)
		local position = Vector3.new(math.cos(angle) * 25, 0, 4 + math.sin(angle) * 22)
		bench(map, "WaitingBench_" .. index, position, Vector3.new(0, 1.5, 4), index % 2 == 0 and COLORS.cyan or COLORS.coral)
	end

	local tutorialCenter = Vector3.new(-40, 0.6, -22)
	local shopCenter = Vector3.new(40, 0.6, -22)
	local missionCenter = Vector3.new(-40, 0.6, 28)
	local galleryCenter = Vector3.new(40, 0.6, 28)
	local plazaTarget = Vector3.new(0, 0.6, 4)
	academyWing(map, "TutorialClassroom", tutorialCenter, COLORS.coral, "TUTORIAL  •  첫 수업", plazaTarget)
	academyWing(map, "PaletteShop", shopCenter, COLORS.cyan, "PALETTE SHOP  •  상점", plazaTarget)
	academyWing(map, "MissionStudio", missionCenter, COLORS.mint, "MISSIONS  •  미션", plazaTarget)
	academyWing(map, "GalleryHall", galleryCenter, COLORS.lilac, "GALLERY  •  갤러리", plazaTarget)

	floorSign(map, "TutorialZone", plazaFacingPoint(tutorialCenter, 12) + Vector3.new(0, 0.8, 0), COLORS.coral, "1  TUTORIAL / 튜토리얼")
	floorSign(map, "ShopZone", plazaFacingPoint(shopCenter, 12) + Vector3.new(0, 0.8, 0), COLORS.cyan, "SHOP / 상점")
	floorSign(map, "MissionZone", plazaFacingPoint(missionCenter, 12) + Vector3.new(0, 0.8, 0), COLORS.mint, "MISSIONS / 미션")
	floorSign(map, "GalleryZone", plazaFacingPoint(galleryCenter, 12) + Vector3.new(0, 0.8, 0), COLORS.lilac, "GALLERY / 갤러리")

	npc(map, "큐레이터 모모 / Curator Momo", plazaFacingPoint(tutorialCenter, 7) + Vector3.new(0, 0.7, 0), COLORS.coral, "튜토리얼 / Tutorial")
	npc(map, "팔레트 상인 / Palette Merchant", plazaFacingPoint(shopCenter, 7) + Vector3.new(0, 0.7, 0), COLORS.cyan, "상점 / Shop")
	npc(map, "미션 선생님 / Mission Teacher", plazaFacingPoint(missionCenter, 7) + Vector3.new(0, 0.7, 0), COLORS.mint, "미션 / Missions")
	npc(map, "갤러리 관리자 / Gallery Keeper", plazaFacingPoint(galleryCenter, 7) + Vector3.new(0, 0.7, 0), COLORS.lilac, "갤러리 / Gallery")

	galleryFrames(map, Vector3.new(40, 1, 38.8))

	for index, data in {
		{ Vector3.new(-72, 0, -45), COLORS.mint },
		{ Vector3.new(72, 0, -45), Color3.fromRGB(139, 203, 176) },
		{ Vector3.new(-76, 0, 20), Color3.fromRGB(173, 219, 145) },
		{ Vector3.new(76, 0, 20), COLORS.mint },
		{ Vector3.new(-66, 0, 58), Color3.fromRGB(149, 209, 173) },
		{ Vector3.new(66, 0, 58), Color3.fromRGB(186, 224, 155) },
	} do
		tree(map, "GardenTree_" .. index, data[1], 1 + (index % 2) * 0.12, data[2])
	end

	planter(map, "EntrancePlanterLeft", Vector3.new(-10, 1, 48), COLORS.coral)
	planter(map, "EntrancePlanterRight", Vector3.new(10, 1, 48), COLORS.cyan)
	planter(map, "CenterPlanterLeft", Vector3.new(-28, 1, 5), COLORS.lilac)
	planter(map, "CenterPlanterRight", Vector3.new(28, 1, 5), COLORS.mint)

	for index = 1, 8 do
		local angle = math.rad((index - 1) * 45)
		local splashPosition = Vector3.new(math.cos(angle) * 48, 1.05, 4 + math.sin(angle) * 39)
		local splash = cylinder(
			map,
			"PaintSplash_" .. index,
			Vector3.new(0.16, 5 + index % 3, 5 + (index + 1) % 3),
			CFrame.new(splashPosition),
			index % 4 == 0 and COLORS.coral
				or index % 4 == 1 and COLORS.cyan
				or index % 4 == 2 and COLORS.gold
				or COLORS.lilac,
			Enum.Material.Neon
		)
		splash.Orientation = Vector3.new(0, 0, 90)
		splash.Transparency = 0.12
		splash.CanCollide = false
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "AcademySpawn"
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.CFrame = CFrame.lookAt(Vector3.new(0, 1.2, 70), Vector3.new(0, 1.2, 0))
	spawn.Transparency = 0.75
	spawn.Color = COLORS.white
	spawn.Material = Enum.Material.Neon
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = map
end

return MapService
