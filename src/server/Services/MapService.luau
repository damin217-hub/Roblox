local Lighting = game:GetService("Lighting")

local MapService = {}

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

local function label(partInstance, text, color)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(260, 70)
	gui.StudsOffset = Vector3.new(0, 4.8, 0)
	gui.AlwaysOnTop = true
	gui.Parent = partInstance
	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(1, 1)
	title.BackgroundTransparency = 1
	title.Text = text
	title.TextColor3 = color
	title.TextStrokeTransparency = 0.5
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.Parent = gui
end

local function npc(parent, name, position, color, actionText)
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	local body = part(model, "Body", Vector3.new(3, 4, 2), CFrame.new(position + Vector3.new(0, 2, 0)), color)
	local head = part(model, "Head", Vector3.new(2.4, 2.4, 2.4), CFrame.new(position + Vector3.new(0, 5, 0)), Color3.fromRGB(255, 220, 184))
	head.Shape = Enum.PartType.Ball
	label(head, name, Color3.new(1, 1, 1))
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = name
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.Parent = body
	return model
end

function MapService.build()
	if workspace:FindFirstChild("ArtAcademyMap") then return end
	Lighting.ClockTime = 14
	Lighting.Brightness = 2.5
	Lighting.Ambient = Color3.fromRGB(155, 160, 190)
	Lighting.OutdoorAmbient = Color3.fromRGB(180, 185, 210)

	local map = Instance.new("Folder")
	map.Name = "ArtAcademyMap"
	map.Parent = workspace
	part(map, "Floor", Vector3.new(120, 2, 120), CFrame.new(0, -1, 0), Color3.fromRGB(245, 238, 220), Enum.Material.Sand)
	part(map, "Academy", Vector3.new(62, 1, 62), CFrame.new(0, 0.1, 0), Color3.fromRGB(255, 253, 246), Enum.Material.Marble)

	for i = 1, 16 do
		local angle = math.rad((i - 1) * 22.5)
		local position = Vector3.new(math.cos(angle) * 31, 7, math.sin(angle) * 31)
		part(map, "Column", Vector3.new(2.5, 14, 2.5), CFrame.new(position), Color3.fromRGB(244, 205, 103), Enum.Material.Marble)
	end

	local center = part(map, "MatchPortal", Vector3.new(16, 1, 16), CFrame.new(0, 0.8, 0), Color3.fromRGB(117, 87, 255), Enum.Material.Neon)
	center.Shape = Enum.PartType.Cylinder
	center.Orientation = Vector3.new(0, 0, 90)
	label(center, "PLAY  •  게임 시작", Color3.fromRGB(255, 255, 255))

	npc(map, "큐레이터 모모 / Curator Momo", Vector3.new(-18, 1, -8), Color3.fromRGB(255, 116, 139), "튜토리얼 / Tutorial")
	npc(map, "팔레트 상인 / Palette Merchant", Vector3.new(18, 1, -8), Color3.fromRGB(104, 190, 255), "상점 / Shop")
	npc(map, "미션 선생님 / Mission Teacher", Vector3.new(-18, 1, 14), Color3.fromRGB(130, 212, 132), "미션 / Missions")
	npc(map, "갤러리 관리자 / Gallery Keeper", Vector3.new(18, 1, 14), Color3.fromRGB(187, 130, 255), "갤러리 / Gallery")

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "AcademySpawn"
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.CFrame = CFrame.new(0, 1, 22)
	spawn.Transparency = 0.5
	spawn.Color = Color3.fromRGB(255, 255, 255)
	spawn.Neutral = true
	spawn.Parent = map
end

return MapService
