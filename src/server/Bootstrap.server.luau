local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local RemoteNames = require(ReplicatedStorage.ArtAcademy.RemoteNames)
local PlayerDataService = require(script.Services.PlayerDataService)
local ModerationService = require(script.Services.ModerationService)
local CanvasService = require(script.Services.CanvasService)
local GuessService = require(script.Services.GuessService)
local RoundService = require(script.Services.RoundService)
local MapService = require(script.Services.MapService)

local modeValue = ServerScriptService:FindFirstChild("ExperienceMode")
local experienceMode = modeValue and modeValue.Value or "ALL_AGES"
game:SetAttribute("ExperienceMode", experienceMode)

local remotesFolder = ReplicatedStorage:FindFirstChild("ArtAcademyRemotes") or Instance.new("Folder")
remotesFolder.Name = "ArtAcademyRemotes"
remotesFolder.Parent = ReplicatedStorage

local remotes = {}
for _, name in RemoteNames do
	local remote = remotesFolder:FindFirstChild(name) or Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotesFolder
	remotes[name] = remote
end

MapService.build()
RoundService.init(remotes, experienceMode)
PlayerDataService.startAutosave()

for _, descendant in workspace.ArtAcademyMap:GetDescendants() do
	if descendant:IsA("ProximityPrompt") then
		descendant.Triggered:Connect(function(player)
			local objectText = descendant.ObjectText
			if string.find(objectText, "모모") then
				remotes.Toast:FireClient(player, "Choose, draw, guess, and earn coins! / 단어를 고르고 그림으로 맞혀보세요!")
			elseif string.find(objectText, "상인") then
				remotes.Toast:FireClient(player, "Cosmetic shop opens after the first public beta.")
			elseif string.find(objectText, "미션") then
				local data = PlayerDataService.get(player)
				local guesses = data and data.correctGuesses or 0
				remotes.Toast:FireClient(player, string.format("Mission: 5 correct guesses (%d/5)", math.min(guesses, 5)))
			elseif string.find(objectText, "갤러리") then
				remotes.Toast:FireClient(player, "Only moderator-approved drawings appear in the gallery.")
			end
		end)
	end
end

local function pushData(player: Player)
	local data = PlayerDataService.get(player)
	if data then remotes.PlayerData:FireClient(player, data) end
end

Players.PlayerAdded:Connect(function(player)
	PlayerDataService.load(player)
	task.defer(pushData, player)
end)

for _, player in Players:GetPlayers() do
	PlayerDataService.load(player)
	task.defer(pushData, player)
end

Players.PlayerRemoving:Connect(function(player)
	PlayerDataService.remove(player)
	ModerationService.removePlayer(player)
end)

remotes.ChoosePrompt.OnServerEvent:Connect(function(player, promptId)
	RoundService.choosePrompt(player, tostring(promptId))
end)

remotes.SubmitStroke.OnServerEvent:Connect(function(player, payload)
	local state, artist = RoundService.getState()
	local stroke = CanvasService.submit(player, payload, state == "Drawing" and player == artist, experienceMode)
	if stroke then remotes.StrokeBroadcast:FireAllClients(stroke) end
end)

remotes.UndoStroke.OnServerEvent:Connect(function(player)
	local state, artist = RoundService.getState()
	local id = CanvasService.undo(player, state == "Drawing" and player == artist)
	if id then remotes.CanvasCommand:FireAllClients({ command = "undo", id = id }) end
end)

remotes.ClearCanvas.OnServerEvent:Connect(function(player)
	local state, artist = RoundService.getState()
	if state == "Drawing" and player == artist and ModerationService.allow(player, "clear", 2, 5) then
		CanvasService.reset()
		remotes.CanvasCommand:FireAllClients({ command = "clear" })
	end
end)

remotes.SubmitGuess.OnServerEvent:Connect(function(player, raw)
	local state, artist, prompt = RoundService.getState()
	if state ~= "Drawing" or player == artist or not prompt then return end
	local result = GuessService.process(player, tostring(raw), prompt)
	if not result then return end
	local correct, points = RoundService.submitGuess(player, result.correct)
	remotes.GuessBroadcast:FireAllClients({
		userId = player.UserId,
		name = player.DisplayName,
		text = correct and "✓ guessed correctly!" or result.text,
		correct = correct,
	})
	if correct then
		remotes.Toast:FireClient(player, string.format("+%d points!", points))
		pushData(player)
	end
end)

remotes.VoteSkip.OnServerEvent:Connect(function(player)
	if RoundService.voteSkip(player) then
		remotes.Toast:FireAllClients("The artist was skipped by vote.")
	end
end)

remotes.ReportDrawing.OnServerEvent:Connect(function(player, reason)
	local _, artist, _, roundId = RoundService.getState()
	if ModerationService.allow(player, "report", 2, 30) then
		ModerationService.report(player, artist, tostring(reason), roundId, CanvasService.getCount())
		remotes.Toast:FireClient(player, "Report received. The canvas is hidden for you.")
	end
end)

remotes.ReactToDrawing.OnServerEvent:Connect(function(player, reaction)
	if ModerationService.allow(player, "reaction", 4, 5) then
		local allowed = { heart = true, laugh = true, wow = true }
		if allowed[reaction] then
			remotes.Toast:FireAllClients(player.DisplayName .. " reacted: " .. reaction)
		end
	end
end)

task.spawn(RoundService.run)

game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		PlayerDataService.save(player)
	end
	task.wait(2)
end)
