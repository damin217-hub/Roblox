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
game:SetAttribute("ArtAcademyRequiredPlayersTest", 2)

local Config = require(ReplicatedStorage.ArtAcademy.Config)
local services = ServerScriptService.ArtAcademyServer.Services
local RoundService = require(services.RoundService)
local PlayerDataService = require(services.PlayerDataService)

local playerA = { UserId = 92001, DisplayName = "StaysA", Parent = Players }
local playerB = { UserId = 92002, DisplayName = "LeavesAsArtist", Parent = Players }
local playerC = { UserId = 92003, DisplayName = "StaysC", Parent = Players }
local departureTriggered = false
local sawRoundAfterDeparture = false
local finalRanking = nil
local returnedToWaiting = false
local sawResults = false

local remotes = {
	RoundState = {
		FireAllClients = function(_, payload)
			if payload.state == "Results" then
				sawResults = true
				finalRanking = payload.ranking
			elseif sawResults and payload.state == "Waiting" then
				returnedToWaiting = true
			end
		end,
		FireClient = function(_, _, payload)
			if payload.state == "Drawing" and payload.seconds == Config.DRAWING_SECONDS then
				if payload.roundNumber == 2 and not departureTriggered then
					check(payload.artistUserId == playerB.UserId, "departing player is the active artist")
					departureTriggered = true
					playerB.Parent = nil
					RoundService.removePlayer(playerB)
				elseif payload.roundNumber >= 3 then
					sawRoundAfterDeparture = true
				end
			end
		end,
	},
	CanvasCommand = { FireAllClients = function() end },
	PlayerData = { FireClient = function() end },
}

for _, player in { playerA, playerB, playerC } do
	PlayerDataService.load(player)
	check(RoundService.toggleReady(player), player.DisplayName .. " joins the queue")
end

RoundService.init(remotes, "FREE_DRAW_16_PLUS")
RoundService.run()

check(departureTriggered, "artist departure is simulated during drawing")
check(sawRoundAfterDeparture, "match continues while the minimum player count remains")
check(sawResults, "match still reaches results after an artist leaves")
check(type(finalRanking) == "table" and #finalRanking == 2, "departed player is excluded from final ranking")
for _, entry in finalRanking do
	check(entry.userId ~= playerB.UserId, "departed player does not appear in results")
end
check(returnedToWaiting, "departure scenario returns to waiting")
check(not RoundService.isReady(playerA) and not RoundService.isReady(playerC), "remaining players are removed from the completed queue")
check(PlayerDataService.get(playerA).daily.rounds == 5, "remaining player A keeps complete quest progress")
check(PlayerDataService.get(playerC).daily.rounds == 5, "remaining player C keeps complete quest progress")
check(PlayerDataService.get(playerB).daily.rounds == 2, "departed player receives only participated round progress")

game:SetAttribute("ArtAcademyFastScenarioTest", nil)
game:SetAttribute("ArtAcademySingleMatchTest", nil)
game:SetAttribute("ArtAcademyRequiredPlayersTest", nil)
print("[DEPARTURE COMPLETE] Mid-match artist departure recovery validated")
