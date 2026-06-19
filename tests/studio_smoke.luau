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
check(CanvasService.submit(fakeArtist, stamp, true, "ALL_AGES") ~= nil, "all-ages mode accepts approved stamp")

local questData = QuestService.getForData({
	daily = { guesses = 3, rounds = 1 },
	claimedQuests = {},
})
check(#questData == 2, "daily quest definitions load")
check(questData[1].progress == 3, "daily quest progress is calculated")

MapService.build()
local map = workspace:FindFirstChild("ArtAcademyMap")
check(map ~= nil, "Art Academy map builds")
check(map:FindFirstChild("MatchPortal") ~= nil, "match portal exists")

local npcCount = 0
for _, descendant in map:GetDescendants() do
	if descendant:IsA("ProximityPrompt") then
		npcCount += 1
	end
end
check(npcCount == 4, "four interactive NPCs exist")

local clientFolder = StarterPlayer.StarterPlayerScripts:FindFirstChild("ArtAcademyClient")
check(clientFolder ~= nil, "client controller folder exists")
local CanvasController = require(clientFolder.CanvasController)
local testCanvas = Instance.new("Frame")
testCanvas.Size = UDim2.fromOffset(900, 600)
local canvasController = CanvasController.new(testCanvas, {})
check(canvasController.editableImage ~= nil, "EditableImage renderer initializes")
check(canvasController.imageLabel ~= nil, "EditableImage is bound to an ImageLabel")
canvasController.editableImage:Destroy()
testCanvas:Destroy()

print("[SMOKE COMPLETE] Art Academy project structure and core modules validated")
