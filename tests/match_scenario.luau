local function check(condition, message)
	if not condition then
		error("[FAIL] " .. message)
	end
	print("[PASS] " .. message)
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

game:SetAttribute("ArtAcademyFastScenarioTest", true)
game:SetAttribute("ArtAcademySingleMatchTest", true)

local Config = require(ReplicatedStorage.ArtAcademy.Config)
local services = ServerScriptService.ArtAcademyServer.Services
local RoundService = require(services.RoundService)
local PlayerDataService = require(services.PlayerDataService)

local drawingArtists = {}
local sawResults = false
local finalRanking = nil
local returnedToWaiting = false

local remotes = {
	RoundState = {
		FireAllClients = function(_, payload)
			if payload.state == "Drawing" and payload.seconds == Config.DRAWING_SECONDS then
				table.insert(drawingArtists, payload.artistUserId)
			elseif payload.state == "Results" then
				sawResults = true
				finalRanking = payload.ranking
			elseif sawResults and payload.state == "Waiting" then
				returnedToWaiting = true
			end
		end,
	},
	CanvasCommand = {
		FireAllClients = function() end,
	},
}

local playerA = {
	UserId = 91001,
	DisplayName = "ScenarioArtistA",
	Parent = Players,
}
local playerB = {
	UserId = 91002,
	DisplayName = "ScenarioArtistB",
	Parent = Players,
}

PlayerDataService.load(playerA)
PlayerDataService.load(playerB)
RoundService.init(remotes, "ALL_AGES")

check(RoundService.toggleReady(playerA), "first player joins the queue")
check(RoundService.toggleReady(playerB), "second player joins the queue")
check(RoundService.isReady(playerA) and RoundService.isReady(playerB), "queued players are marked ready")

RoundService.run()

check(#drawingArtists == Config.ROUNDS_PER_MATCH, "all five drawing rounds start")
for roundNumber, artistUserId in drawingArtists do
	local expected = roundNumber % 2 == 1 and playerA.UserId or playerB.UserId
	check(artistUserId == expected, "artist rotates correctly in round " .. roundNumber)
end

check(sawResults, "match reaches the final results state")
check(type(finalRanking) == "table" and #finalRanking == 2, "results contain the full match ranking")
check(returnedToWaiting, "match returns to waiting after results")
check(not RoundService.isReady(playerA) and not RoundService.isReady(playerB), "players must opt in again for a replay")

local dataA = PlayerDataService.get(playerA)
local dataB = PlayerDataService.get(playerB)
check(dataA.daily.rounds == 5 and dataB.daily.rounds == 5, "all participants receive five rounds of quest progress")
check(dataA.drawings + dataB.drawings == 5, "exactly five artist drawing records are awarded")
check(dataA.wins + dataB.wins == 1, "exactly one match win is awarded")
check(dataA.coins + dataB.coins == 50, "winner bonus is awarded exactly once")

game:SetAttribute("ArtAcademyFastScenarioTest", nil)
game:SetAttribute("ArtAcademySingleMatchTest", nil)
print("[SCENARIO COMPLETE] Full five-round match lifecycle validated")
