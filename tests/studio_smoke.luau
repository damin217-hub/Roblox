local function check(condition, message)
	if not condition then
		error("[FAIL] " .. message)
	end
	print("[PASS] " .. message)
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")

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
check(CanvasService.submit(fakeArtist, validStroke, true, "FREE_DRAW_16_PLUS") ~= nil, "free draw accepts valid artist stroke")
check(CanvasService.submit(fakeArtist, validStroke, false, "FREE_DRAW_16_PLUS") == nil, "non-artist stroke is rejected")
local invalidStroke = table.clone(validStroke)
invalidStroke.x = 2
check(CanvasService.submit(fakeArtist, invalidStroke, true, "FREE_DRAW_16_PLUS") == nil, "out-of-bounds stroke is rejected")
check(CanvasService.submit(fakeArtist, validStroke, true, "ALL_AGES") == nil, "all-ages mode rejects freehand line")
local stamp = table.clone(validStroke)
stamp.kind = "stamp"
stamp.x = 0.51
stamp.y = 0.51
stamp.stampType = "square"
local originalStampX, originalStampY = stamp.x, stamp.y
local acceptedStamp = CanvasService.submit(fakeArtist, stamp, true, "ALL_AGES")
check(acceptedStamp ~= nil, "all-ages mode accepts approved stamp")
check(acceptedStamp.px == acceptedStamp.x and acceptedStamp.py == acceptedStamp.y, "all-ages stamp cannot form a freehand line")
check(acceptedStamp.x ~= originalStampX or acceptedStamp.y ~= originalStampY, "all-ages stamp position snaps to a safe grid")
check(acceptedStamp.stampType == "square", "approved stamp shape is preserved")

local encoded = StrokeCodec.encode({ acceptedStamp }, 1)
local decoded = StrokeCodec.decode(encoded)
check(#encoded == 1 and #decoded == 1, "gallery stroke codec round-trips")
check(decoded[1].kind == "stamp" and decoded[1].stampType == "square", "gallery codec preserves stamp metadata")
local manyStrokes = {}
for index = 1, 500 do
	local clone = table.clone(acceptedStamp)
	clone.id = index
	table.insert(manyStrokes, clone)
end
check(#StrokeCodec.encode(manyStrokes, Config.GALLERY_MAX_STROKES) == 400, "gallery codec enforces bounded snapshot size")

local floodArtist = { UserId = 202 }
local acceptedFlood = 0
for _ = 1, 20 do
	local floodStamp = table.clone(stamp)
	if CanvasService.submit(floodArtist, floodStamp, true, "ALL_AGES") then
		acceptedFlood += 1
	end
end
check(acceptedFlood <= Config.MAX_STAMPS_PER_SECOND, "all-ages stamp flood is rate limited")

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

MapService.build()
local map = workspace:FindFirstChild("ArtAcademyMap")
check(map ~= nil, "Art Academy map builds")
check(map:FindFirstChild("MatchPortal") ~= nil, "match portal exists")
check(map:FindFirstChild("WelcomeArchTop") ~= nil, "academy entrance arch guides new players")
check(map:FindFirstChild("WelcomePath") ~= nil, "spawn path guides players to the match portal")
check(map:FindFirstChild("TutorialZone") ~= nil, "tutorial station has a distinct visual zone")

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
check(type(UIController.new) == "function", "responsive UI controller module loads")
check(type(SoundController.new) == "function", "UI sound controller module loads")
local testCanvas = Instance.new("Frame")
testCanvas.Size = UDim2.fromOffset(900, 600)
local canvasController = CanvasController.new(testCanvas, {})
check(canvasController.editableImage ~= nil, "EditableImage renderer initializes")
check(canvasController.imageLabel ~= nil, "EditableImage is bound to an ImageLabel")
canvasController:setCosmetics({ brush = "brush_neon", palette = "palette_candy" })
check(canvasController.brushStyle == "neon", "equipped brush cosmetic changes renderer style")
check(canvasController:getPalette() == CanvasController.CANDY_COLORS, "equipped palette cosmetic changes colors")
canvasController:destroy()
testCanvas:Destroy()

print("[SMOKE COMPLETE] Art Academy project structure and core modules validated")
