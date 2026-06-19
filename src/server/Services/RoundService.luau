local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage.ArtAcademy.Config)
local PromptService = require(script.Parent.PromptService)
local CanvasService = require(script.Parent.CanvasService)
local PlayerDataService = require(script.Parent.PlayerDataService)
local ModerationService = require(script.Parent.ModerationService)
local GalleryService = require(script.Parent.GalleryService)

local RoundService = {}
local remotes
local mode = "ALL_AGES"
local state = "Waiting"
local artist: Player? = nil
local choices = {}
local prompt = nil
local roundId = ""
local correctPlayers = {}
local scores = {}
local endDrawingEarly = false

local function roster()
	local list = {}
	for _, player in Players:GetPlayers() do
		local data = PlayerDataService.get(player)
		local titleId = data and data.equipped and data.equipped.title or ""
		table.insert(list, {
			userId = player.UserId,
			name = player.DisplayName,
			score = scores[player] or 0,
			title = titleId == "title_quick_thinker" and "Quick Thinker" or "",
		})
	end
	table.sort(list, function(a, b) return a.score > b.score end)
	return list
end

local function broadcast(seconds: number, extra)
	local payload = {
		state = state,
		seconds = seconds,
		artistUserId = artist and artist.UserId or 0,
		artistName = artist and artist.DisplayName or "",
		roundId = roundId,
		mode = mode,
		scores = roster(),
	}
	if extra then
		for key, value in extra do payload[key] = value end
	end
	remotes.RoundState:FireAllClients(payload)
end

local function countdown(seconds: number, extra, breaker)
	for remaining = seconds, 0, -1 do
		broadcast(remaining, extra)
		if breaker and breaker() then break end
		task.wait(1)
	end
end

local function chooseArtist(roundNumber: number)
	local players = Players:GetPlayers()
	if #players == 0 then return nil end
	return players[((roundNumber - 1) % #players) + 1]
end

function RoundService.init(remoteTable, experienceMode: string)
	remotes = remoteTable
	mode = experienceMode
end

function RoundService.getState()
	return state, artist, prompt, roundId
end

function RoundService.choosePrompt(player: Player, promptId: string)
	if state ~= "Choosing" or player ~= artist then return end
	for _, candidate in choices do
		if candidate.id == promptId then
			prompt = candidate
			return
		end
	end
end

function RoundService.submitGuess(player: Player, correct: boolean)
	if state ~= "Drawing" or player == artist or correctPlayers[player] then return false, 0 end
	if not correct then return false, 0 end
	correctPlayers[player] = true
	local position = 0
	for _ in correctPlayers do position += 1 end
	local points = math.max(25, 110 - (position - 1) * 15)
	scores[player] = (scores[player] or 0) + points
	scores[artist] = (scores[artist] or 0) + 15
	PlayerDataService.add(player, "correctGuesses", 1)
	PlayerDataService.incrementProgress(player, "guesses", 1)
	PlayerDataService.add(player, "xp", points)
	PlayerDataService.add(player, "coins", math.floor(points / 5))
	if position >= math.max(1, #Players:GetPlayers() - 1) then endDrawingEarly = true end
	return true, points
end

function RoundService.voteSkip(player: Player)
	if state ~= "Drawing" or player == artist then return false end
	if ModerationService.voteSkip(player, roundId, #Players:GetPlayers() - 1) then
		endDrawingEarly = true
		return true
	end
	return false
end

function RoundService.run()
	while true do
		state = "Waiting"
		local requiredPlayers = RunService:IsStudio() and 1 or Config.MIN_PLAYERS
		while #Players:GetPlayers() < requiredPlayers do
			broadcast(0, { needed = requiredPlayers - #Players:GetPlayers() })
			task.wait(2)
		end

		table.clear(scores)
		for _, player in Players:GetPlayers() do scores[player] = 0 end
		state = "Intermission"
		countdown(Config.INTERMISSION_SECONDS)

		for roundNumber = 1, Config.ROUNDS_PER_MATCH do
			if #Players:GetPlayers() < requiredPlayers then break end
			artist = chooseArtist(roundNumber)
			roundId = string.format("%d-%d-%d", os.time(), roundNumber, math.random(1000, 9999))
			choices = PromptService.getChoices(3)
			prompt = nil
			table.clear(correctPlayers)
			CanvasService.reset()
			ModerationService.clearRound(roundId)
			remotes.CanvasCommand:FireAllClients({ command = "clear" })

			state = "Choosing"
			local publicChoices = {}
			for _, choice in choices do
				table.insert(publicChoices, { id = choice.id, ko = choice.ko, en = choice.en })
			end
			countdown(Config.CHOOSING_SECONDS, { choices = publicChoices }, function() return prompt ~= nil end)
			prompt = prompt or choices[1]

			state = "Drawing"
			endDrawingEarly = false
			PlayerDataService.add(artist, "drawings", 1)
			for _, participant in Players:GetPlayers() do
				PlayerDataService.incrementProgress(participant, "rounds", 1)
			end
			GalleryService.beginRound(roundId, artist, prompt)
			countdown(Config.DRAWING_SECONDS, {
				prompt = { ko = prompt.ko, en = prompt.en },
			}, function() return endDrawingEarly or artist.Parent ~= Players end)

			state = "Reveal"
			countdown(Config.REVEAL_SECONDS, {
				prompt = { ko = prompt.ko, en = prompt.en },
				strokeCount = CanvasService.getCount(),
			})
			GalleryService.submitPending(CanvasService.getSnapshot())
		end

		state = "Results"
		local ranking = roster()
		if ranking[1] then
			local winner = Players:GetPlayerByUserId(ranking[1].userId)
			if winner then
				PlayerDataService.add(winner, "wins", 1)
				PlayerDataService.incrementProgress(winner, "wins", 1)
				PlayerDataService.add(winner, "coins", 50)
			end
		end
		countdown(Config.RESULTS_SECONDS, { ranking = ranking })
	end
end

return RoundService
