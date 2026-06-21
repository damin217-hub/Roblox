local function check(condition, message)
	if not condition then
		error("[FAIL] " .. message)
	end
	print("[PASS] " .. message)
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local Lighting = game:GetService("Lighting")

local shared = ReplicatedStorage:FindFirstChild("ArtAcademy")
check(shared ~= nil, "ReplicatedStorage.ArtAcademy exists")
check(shared:FindFirstChild("Config") ~= nil, "Config module exists")
check(shared:FindFirstChild("Prompts") ~= nil, "Prompt catalog exists")
check(shared:FindFirstChild("Catalog") ~= nil, "Cosmetic catalog exists")
check(shared:FindFirstChild("StrokeCodec") ~= nil, "Stroke codec exists")

local server = ServerScriptService:FindFirstChild("ArtAcademyServer")
check(server ~= nil, "ArtAcademyServer exists")
local services = server:FindFirstChild("Services")
check(services ~= nil, "Server services folder exists")

for _, serviceName in {
	"RoundService",
	"PromptService",
	"GuessService",
	"CanvasService",
	"PlayerDataService",
	"ModerationService",
	"QuestService",
	"GalleryService",
	"MonetizationService",
	"TelemetryService",
	"MapService",
	"DrawingBubbleService",
} do
	check(services:FindFirstChild(serviceName) ~= nil, serviceName .. " exists")
end

local Config = require(shared.Config)
local Prompts = require(shared.Prompts)
local Catalog = require(shared.Catalog)
local PromptService = require(services.PromptService)
local MapService = require(services.MapService)
local CanvasService = require(services.CanvasService)
local QuestService = require(services.QuestService)
local StrokeCodec = require(shared.StrokeCodec)
local PlayerDataService = require(services.PlayerDataService)
local ModerationService = require(services.ModerationService)
local DrawingBubbleService = require(services.DrawingBubbleService)

check(Config.ROUNDS_PER_MATCH == 5, "match contains five rounds")
check(Config.DRAWING_SECONDS == 75, "drawing timer is 75 seconds")
check(#Prompts >= 15, "bilingual prompt catalog is populated")
check(#Catalog >= 5, "cosmetic catalog is populated")
check(PromptService.matches(Prompts[1], Prompts[1].ko), "Korean answer matching works")
check(PromptService.matches(Prompts[1], string.upper(Prompts[1].en)), "English case-insensitive matching works")

local fakeArtist = { UserId = 101 }
local validStroke = {
	x = 0.5,
	y = 0.5,
	px = 0.4,
	py = 0.4,
	size = 12,
	color = { r = 1, g = 0, b = 0 },
	erase = false,
	kind = "line",
}
CanvasService.reset()
validStroke.opacity = 0.7
validStroke.stampType = "circle"
local acceptedStroke = CanvasService.submit(fakeArtist, validStroke, true, "ALL_AGES")
check(acceptedStroke ~= nil, "all-ages mode accepts a validated continuous brush segment")
check(CanvasService.submit(fakeArtist, validStroke, false, "ALL_AGES") == nil, "non-artist stroke is rejected")
local invalidStroke = table.clone(validStroke)
invalidStroke.x = 2
check(CanvasService.submit(fakeArtist, invalidStroke, true, "ALL_AGES") == nil, "out-of-bounds stroke is rejected")
local longStroke = table.clone(validStroke)
longStroke.px = 0
longStroke.py = 0
check(CanvasService.submit(fakeArtist, longStroke, true, "ALL_AGES") == nil, "oversized stroke segment is rejected")
check(acceptedStroke.px ~= acceptedStroke.x and acceptedStroke.py ~= acceptedStroke.y, "continuous brush segment preserves its start point")
check(acceptedStroke.opacity == 0.7, "server preserves validated brush opacity")
check(acceptedStroke.stampType == "circle", "approved brush shape is preserved")

local encoded = StrokeCodec.encode({ acceptedStroke }, 1)
local decoded = StrokeCodec.decode(encoded)
check(#encoded == 1 and #decoded == 1, "gallery stroke codec round-trips")
check(decoded[1].kind == "line" and decoded[1].stampType == "circle", "gallery codec preserves brush metadata")
check(math.abs(decoded[1].opacity - 0.7) < 0.01, "gallery codec preserves opacity")
local manyStrokes = {}
for index = 1, 500 do
	local clone = table.clone(acceptedStroke)
	clone.id = index
	table.insert(manyStrokes, clone)
end
check(#StrokeCodec.encode(manyStrokes, Config.GALLERY_MAX_STROKES) == 400, "gallery codec enforces bounded snapshot size")

local floodArtist = { UserId = 202 }
local acceptedFlood = 0
for _ = 1, 60 do
	local floodStroke = table.clone(validStroke)
	if CanvasService.submit(floodArtist, floodStroke, true, "ALL_AGES") then
		acceptedFlood += 1
	end
end
check(acceptedFlood <= Config.MAX_STROKES_PER_SECOND, "all-ages stroke flood is rate limited")

local questData = QuestService.getForData({
	daily = { guesses = 3, rounds = 1 },
	weekly = { guesses = 10, rounds = 4, wins = 1 },
	claims = { daily = {}, weekly = {} },
	claimedQuests = {},
})
check(#questData == 4, "daily and weekly quest definitions load")
check(questData[1].progress == 3, "daily quest progress is calculated")
check(questData[3].scope == "weekly" and questData[3].progress == 10, "weekly quest progress is calculated")
check(type(PlayerDataService.retryPending) == "function", "failed DataStore writes have a retry queue")
check(type(PlayerDataService.getPendingSaveCount) == "function", "pending save queue is observable for shutdown flush")

local bubblePlayer = { UserId = 44001 }
local bubblePayload = DrawingBubbleService.submit(bubblePlayer, {
	{
		x = 0.3, y = 0.3, px = 0.2, py = 0.2, size = 8,
		color = { r = 1, g = 0, b = 0 }, opacity = 0.8, stampType = "circle",
	},
})
check(bubblePayload ~= nil and #bubblePayload.strokes == 1, "validated social drawing can become a drawing bubble")
check(DrawingBubbleService.submit(bubblePlayer, bubblePayload.strokes) == nil, "drawing bubble sharing is cooldown limited")

local reconnectA = { UserId = 88001 }
local reconnectB = { UserId = 88001 }
PlayerDataService.load(reconnectA)
PlayerDataService.add(reconnectA, "coins", 275)
PlayerDataService.remove(reconnectA)
PlayerDataService.load(reconnectB)
check(PlayerDataService.get(reconnectB).coins == 275, "same-server reconnect restores unsaved session rewards")
PlayerDataService.remove(reconnectB)

local economyPlayer = { UserId = 88002 }
local economyData = PlayerDataService.load(economyPlayer)
economyData.coins = 1000
PlayerDataService.incrementProgress(economyPlayer, "guesses", 5)
local firstClaim = PlayerDataService.claimQuest(economyPlayer, "daily_guesses", 5, "guesses", 75, "daily")
local coinsAfterClaim = economyData.coins
local duplicateClaim = PlayerDataService.claimQuest(economyPlayer, "daily_guesses", 5, "guesses", 75, "daily")
check(firstClaim and not duplicateClaim and economyData.coins == coinsAfterClaim, "quest reward cannot be claimed twice")
local firstPurchase = PlayerDataService.purchase(economyPlayer, "brush_neon")
local coinsAfterPurchase = economyData.coins
local duplicatePurchase = PlayerDataService.purchase(economyPlayer, "brush_neon")
check(firstPurchase and not duplicatePurchase and economyData.coins == coinsAfterPurchase, "owned cosmetic cannot charge coins twice")
PlayerDataService.remove(economyPlayer)

local voterA = { UserId = 77101 }
local voterB = { UserId = 77102 }
check(ModerationService.voteSkip(voterA, "two-player-round", 1), "single eligible guesser can unanimously skip in a two-player match")
check(not ModerationService.voteSkip(voterA, "three-player-round", 2), "one vote cannot skip when two guessers are eligible")
check(not ModerationService.voteSkip(voterA, "three-player-round", 2), "duplicate skip vote is not counted twice")
check(ModerationService.voteSkip(voterB, "three-player-round", 2), "skip succeeds after the required distinct votes")

MapService.build()
local map = workspace:FindFirstChild("ArtAcademyMap")
check(map ~= nil, "Art Academy map builds")
check(map:FindFirstChild("MatchPortal") ~= nil, "match portal exists")
check(map:FindFirstChild("WelcomeArchTop") ~= nil, "academy entrance arch guides new players")
check(map:FindFirstChild("WelcomePath") ~= nil, "spawn path guides players to the match portal")
check(map:FindFirstChild("TutorialZone") ~= nil, "tutorial station has a distinct visual zone")
check(map.Floor.Size.X >= 150 and map.Floor.Size.Z >= 130, "lobby footprint supports a spacious social environment")
check(map:FindFirstChild("PaintbrushLandmark") ~= nil, "central portal has a memorable art landmark")
check(map:FindFirstChild("TutorialClassroom") ~= nil, "tutorial has a dedicated academy building")
check(map:FindFirstChild("PaletteShop") ~= nil, "shop has a dedicated academy building")
check(map:FindFirstChild("MissionStudio") ~= nil, "missions have a dedicated academy building")
check(map:FindFirstChild("GalleryHall") ~= nil, "gallery has a dedicated academy building")
check(map:FindFirstChild("OutdoorGalleryFrames") ~= nil, "lobby includes gallery scenery for waiting players")
check(map:FindFirstChild("MainPlaza") ~= nil, "central play zone has a dedicated visual foundation")
check(map:FindFirstChild("MainPlazaRing") ~= nil, "central play zone is emphasized with a plaza ring")
check(map:FindFirstChild("DesignAxes") ~= nil, "map exposes a single shared design-axis system")
check(map.DesignAxes:FindFirstChild("PrimaryAxis") ~= nil, "spawn-to-portal primary axis is defined")
check(map.DesignAxes:FindFirstChild("CrossAxis") ~= nil, "plaza cross axis is defined")
check(map:GetAttribute("CenterX") == 0 and map:GetAttribute("CenterZ") == 4, "all map composition uses the portal world center")
check(Lighting.Brightness < 2, "lobby lighting avoids an over-bright global exposure")
check(Lighting.ClockTime >= 16, "lobby uses a calmer late-afternoon lighting direction")
for _, buildingName in { "TutorialClassroom", "PaletteShop", "MissionStudio", "GalleryHall" } do
	local building = map:FindFirstChild(buildingName)
	local canopy = building and building:FindFirstChild("Canopy")
	local toPlaza = canopy and (Vector3.new(0, canopy.Position.Y, 4) - canopy.Position).Unit or Vector3.zero
	check(canopy ~= nil and canopy.CFrame.LookVector:Dot(toPlaza) > 0.7, buildingName .. " entrance faces the central plaza")
end

local npcDefinitions = {
	{ "큐레이터 모모 / Curator Momo", "Sketchbook", "Paintbrush" },
	{ "팔레트 상인 / Palette Merchant", "Palette", "PaletteColor_1" },
	{ "미션 선생님 / Mission Teacher", "Clipboard", "MissionSheet" },
	{ "갤러리 관리자 / Gallery Keeper", "MiniFrame", "GalleryKey" },
}
for _, definition in npcDefinitions do
	local character = map:FindFirstChild(definition[1])
	local body = character and character:FindFirstChild("Body")
	local toCenter = body and (Vector3.new(0, body.Position.Y, 4) - body.Position).Unit or Vector3.zero
	check(body ~= nil and body.CFrame.LookVector:Dot(toCenter) > 0.92, definition[1] .. " faces the shared world center")
	check(character:FindFirstChild(definition[2]) ~= nil, definition[1] .. " has its first role prop")
	check(character:FindFirstChild(definition[3]) ~= nil, definition[1] .. " has its second role prop")
	check(character:FindFirstChild("NeckScarf") ~= nil, definition[1] .. " matches the thumbnail scarf silhouette")
	check(character:FindFirstChild("ApronBib") ~= nil, definition[1] .. " matches the thumbnail painter apron")
	check(character:FindFirstChild("HairCurl_1") ~= nil, definition[1] .. " uses the thumbnail-inspired layered hair")
	check(character:FindFirstChild("PaintSplatter_1") ~= nil, definition[1] .. " carries painted costume details")
end
local momo = map:FindFirstChild("큐레이터 모모 / Curator Momo")
check(momo and momo:FindFirstChild("Beret") and momo.Beret.Size.X >= 4, "Momo uses the thumbnail's oversized coral beret")
check(momo and momo.Head.Size.X >= 3.4, "Momo uses the thumbnail's large friendly head proportion")

local waitingSeatCount = 0
local academyColumnCount = 0
for _, child in map:GetChildren() do
	if string.find(child.Name, "WaitingBench_") == 1 then
		waitingSeatCount += 1
	elseif string.find(child.Name, "AcademyColumn_") == 1 then
		academyColumnCount += 1
	end
end
check(waitingSeatCount == 8, "central queue includes eight social waiting benches")
check(academyColumnCount == 24, "academy silhouette is defined by a complete colonnade")

local npcCount = 0
for _, descendant in map:GetDescendants() do
	if descendant:IsA("ProximityPrompt") then
		npcCount += 1
	end
end
check(npcCount == 5, "match portal and four interactive NPC prompts exist")
check(map.MatchPortal:FindFirstChild("MatchmakingPrompt") ~= nil, "match portal exposes queue interaction")

local clientFolder = StarterPlayer.StarterPlayerScripts:FindFirstChild("ArtAcademyClient")
check(clientFolder ~= nil, "client controller folder exists")
local CanvasController = require(clientFolder.CanvasController)
local UIController = require(clientFolder.UIController)
local SoundController = require(clientFolder.SoundController)
local DrawingBubbleController = require(clientFolder.DrawingBubbleController)
check(type(UIController.new) == "function", "responsive UI controller module loads")
check(type(SoundController.new) == "function", "UI sound controller module loads")
check(type(DrawingBubbleController.new) == "function", "drawing bubble controller module loads")
local testCanvas = Instance.new("Frame")
testCanvas.Size = UDim2.fromOffset(900, 600)
local canvasController = CanvasController.new(testCanvas, {})
check(canvasController.editableImage ~= nil, "EditableImage renderer initializes")
check(canvasController.imageLabel ~= nil, "EditableImage is bound to an ImageLabel")
canvasController:setCosmetics({ brush = "brush_neon", palette = "palette_candy" })
check(canvasController.brushStyle == "neon", "equipped brush cosmetic changes renderer style")
check(canvasController:getPalette() == CanvasController.CANDY_COLORS, "equipped palette cosmetic changes colors")
canvasController:renderSnapshot(decoded)
check(#canvasController.strokes == 1, "gallery renderer replays a decoded artwork")
canvasController:renderSnapshot(StrokeCodec.decode(StrokeCodec.encode(manyStrokes, Config.GALLERY_MAX_STROKES)))
check(#canvasController.strokes == Config.GALLERY_MAX_STROKES, "gallery renderer handles the full 400-stroke replay budget")
canvasController:destroy()
testCanvas:Destroy()

local submittedPayloads = {}
local inputCanvas = Instance.new("Frame")
inputCanvas.Size = UDim2.fromOffset(900, 600)
local inputController = CanvasController.new(inputCanvas, {
	SubmitStroke = {
		FireServer = function(_, payload)
			table.insert(submittedPayloads, payload)
		end,
	},
})
inputController:setEnabled(true, "ALL_AGES")
inputController:applyPreset("fine")
inputController:_submit(Vector2.new(0.25, 0.5))
check(submittedPayloads[1].kind == "line" and submittedPayloads[1].size == 6, "all-ages input emits a continuous fine brush command")
inputController:setOpacity(0.4)
inputController:_submit(Vector2.new(0.5, 0.5))
check(submittedPayloads[2].opacity == 0.4, "all-ages input emits the selected opacity")
inputController:destroy()
inputCanvas:Destroy()

local fakeSignals = {}
local fakeRemotes = {}
for _, remoteName in require(shared.RemoteNames) do
	local event = Instance.new("BindableEvent")
	table.insert(fakeSignals, event)
	fakeRemotes[remoteName] = {
		OnClientEvent = event.Event,
		FireServer = function() end,
	}
end
local fakePlayerGui = Instance.new("Folder")
local fakePlayer = {
	UserId = 99001,
	PlayerGui = fakePlayerGui,
}
local uiController = UIController.new(fakeRemotes, fakePlayer, "ko-kr")
uiController:build()
check(fakePlayerGui:FindFirstChild("ArtAcademyUI") ~= nil, "full game UI builds for a test player")
check(uiController.choiceFrame:FindFirstChildOfClass("UISizeConstraint") ~= nil, "prompt chooser has mobile-safe size constraints")
check(uiController.canvasPanel.Visible and not uiController.openCanvasButton.Visible, "canvas panel opens on game start")
uiController:setCanvasPanelOpen(false)
check(not uiController.canvasPanel.Visible and uiController.openCanvasButton.Visible, "canvas panel can be minimized without hiding the game")
uiController:setCanvasPanelOpen(true)
check(uiController.canvasPanel.Visible and not uiController.openCanvasButton.Visible, "canvas panel can be restored")
uiController:_openDrawingBubbleComposer()
check(uiController.bubbleComposerController ~= nil, "drawing bubble composer opens with a local canvas")
check(uiController.modal.Visible, "drawing bubble composer uses the modal workspace")
uiController.modal.Visible = false
uiController.applyResponsiveLayout(600)
check(not uiController.title.Visible, "mobile layout hides the wide title")
check(uiController.canvas.AbsoluteSize.X >= 0, "mobile layout keeps the canvas mounted")
uiController.applyResponsiveLayout(1280)
check(uiController.title.Visible, "desktop layout restores the academy title")
uiController:onState({
	state = "Drawing",
	seconds = 75,
	artistUserId = fakePlayer.UserId,
	artistName = "Test Artist",
	roundId = "ui-round-1",
	mode = "ALL_AGES",
	roundNumber = 3,
	totalRounds = 5,
	scores = {},
	prompt = { ko = "고양이", en = "Cat" },
})
check(uiController.roundBadge.Text == "라운드 3/5", "round progress is visible in Korean")
check(uiController.canvasController.enabled, "artist canvas is enabled during drawing")
uiController:onState({
	state = "Results",
	seconds = 10,
	artistUserId = 0,
	artistName = "",
	roundId = "ui-round-1",
	mode = "ALL_AGES",
	roundNumber = 5,
	totalRounds = 5,
	scores = {
		{ userId = fakePlayer.UserId, name = "Test Artist", score = 100, title = "" },
	},
	ranking = {
		{ userId = fakePlayer.UserId, name = "Test Artist", score = 100, title = "" },
	},
	winnerBonus = 50,
})
check(uiController.modal.Visible and string.find(uiController.modalTitle.Text, "최종 결과") ~= nil, "results modal opens after the match")
fakePlayerGui:Destroy()
for _, event in fakeSignals do event:Destroy() end

print("[SMOKE COMPLETE] Art Academy project structure and core modules validated")
