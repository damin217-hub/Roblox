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
game:SetAttribute("ArtAcademyRequiredPlayersTest", 12)

local Config = require(ReplicatedStorage.ArtAcademy.Config)
local services = ServerScriptService.ArtAcademyServer.Services
local RoundService = require(services.RoundService)
local PlayerDataService = require(services.PlayerDataService)

local drawingArtists = {}
local sawResults = false
local finalRanking = nil
local returnedToWaiting = false
local hiddenPromptDeliveries = 0
local artistAlwaysReceivedPrompt = true
local guesserNeverReceivedPrompt = true
local artistAlwaysReceivedChoices = true
local guesserNeverReceivedChoices = true
local playerDataSyncs = {}
local sawFirstHint = false
local sawSecondHint = false

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
		FireClient = function(_, recipient, payload)
			if payload.state == "Choosing" then
				if recipient.UserId == payload.artistUserId then
					if payload.choices == nil then
						artistAlwaysReceivedChoices = false
					end
				elseif payload.choices ~= nil then
					guesserNeverReceivedChoices = false
				end
				return
			elseif payload.state ~= "Drawing" then
				return
			end
			if recipient.UserId == payload.artistUserId then
				if payload.prompt == nil then
					artistAlwaysReceivedPrompt = false
				end
				if payload.seconds == Config.DRAWING_SECONDS then
					table.insert(drawingArtists, payload.artistUserId)
				end
			else
				if payload.prompt ~= nil then
					guesserNeverReceivedPrompt = false
				end
				if payload.seconds <= Config.DRAWING_HINT_FIRST_SECONDS and payload.hint then
					sawFirstHint = true
				end
				if payload.seconds <= Config.DRAWING_HINT_SECOND_SECONDS and payload.hint and string.find(payload.hint, "_") then
					sawSecondHint = true
				end
				hiddenPromptDeliveries += 1
			end
		end,
	},
	CanvasCommand = {
		FireAllClients = function() end,
	},
	PlayerData = {
		FireClient = function(_, recipient, data)
			playerDataSyncs[recipient.UserId] = data.coins
		end,
	},
}

local scenarioPlayers = {}
for index = 1, Config.MAX_PLAYERS do
	local player = {
		UserId = 91000 + index,
		DisplayName = "ScenarioPlayer" .. index,
		Parent = Players,
	}
	table.insert(scenarioPlayers, player)
	PlayerDataService.load(player)
	check(RoundService.toggleReady(player), "player " .. index .. " joins the 12-player queue")
end
RoundService.init(remotes, "ALL_AGES")

RoundService.run()

check(#drawingArtists == Config.ROUNDS_PER_MATCH, "all five drawing rounds start")
check(hiddenPromptDeliveries > 0, "drawing prompt privacy is exercised during the match")
check(artistAlwaysReceivedPrompt, "artist receives the private drawing prompt")
check(guesserNeverReceivedPrompt, "guesser never receives the private drawing prompt")
check(sawFirstHint, "guessers receive a progressive first-letter hint")
check(sawSecondHint, "guessers receive a stronger late-round hint")
check(artistAlwaysReceivedChoices, "artist receives private prompt choices")
check(guesserNeverReceivedChoices, "guesser never receives prompt choices")
for roundNumber, artistUserId in drawingArtists do
	local expected = scenarioPlayers[roundNumber].UserId
	check(artistUserId == expected, "artist rotates correctly in round " .. roundNumber)
end

check(sawResults, "match reaches the final results state")
check(type(finalRanking) == "table" and #finalRanking == Config.MAX_PLAYERS, "results contain all 12 participants")
check(returnedToWaiting, "match returns to waiting after results")

local totalRounds = 0
local totalDrawings = 0
local totalWins = 0
local totalCoins = 0
local syncedPlayers = 0
local allReadyCleared = true
for _, player in scenarioPlayers do
	local data = PlayerDataService.get(player)
	totalRounds += data.daily.rounds
	totalDrawings += data.drawings
	totalWins += data.wins
	totalCoins += data.coins
	if playerDataSyncs[player.UserId] ~= nil then
		syncedPlayers += 1
	end
	if RoundService.isReady(player) then
		allReadyCleared = false
	end
end
check(allReadyCleared, "all 12 players must opt in again for a replay")
check(totalRounds == Config.MAX_PLAYERS * Config.ROUNDS_PER_MATCH, "all 12 participants receive five rounds of quest progress")
check(totalDrawings == Config.ROUNDS_PER_MATCH, "exactly five artist drawing records are awarded")
check(totalWins == 1, "exactly one match win is awarded")
check(totalCoins == 50, "winner bonus is awarded exactly once")
check(syncedPlayers == Config.MAX_PLAYERS, "final player data sync reaches all 12 participants")
local syncedCoinTotal = 0
for _, coins in playerDataSyncs do syncedCoinTotal += coins end
check(syncedCoinTotal == 50, "synced balances include the winner bonus")

game:SetAttribute("ArtAcademyFastScenarioTest", nil)
game:SetAttribute("ArtAcademySingleMatchTest", nil)
game:SetAttribute("ArtAcademyRequiredPlayersTest", nil)
print("[SCENARIO COMPLETE] Full five-round match lifecycle validated")
