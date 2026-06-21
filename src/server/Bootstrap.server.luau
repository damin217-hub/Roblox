local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local RemoteNames = require(ReplicatedStorage.ArtAcademy.RemoteNames)
local services = script.Parent.Services
local PlayerDataService = require(services.PlayerDataService)
local ModerationService = require(services.ModerationService)
local CanvasService = require(services.CanvasService)
local GuessService = require(services.GuessService)
local RoundService = require(services.RoundService)
local MapService = require(services.MapService)
local QuestService = require(services.QuestService)
local GalleryService = require(services.GalleryService)
local MonetizationService = require(services.MonetizationService)
local TelemetryService = require(services.TelemetryService)
local DrawingBubbleService = require(services.DrawingBubbleService)

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
			if descendant.Name == "MatchmakingPrompt" then
				local joined = RoundService.toggleReady(player)
				TelemetryService.log(player, joined and "queue_joined" or "queue_left", 1, {
					mode = experienceMode,
				})
				remotes.Toast:FireClient(
					player,
					joined and "Joined the next match queue! / 다음 게임 참가 완료"
						or "Left the match queue. / 참가 취소"
				)
			elseif string.find(objectText, "모모") then
				remotes.OpenPanel:FireClient(player, "tutorial")
			elseif string.find(objectText, "상인") then
				remotes.OpenPanel:FireClient(player, "shop")
			elseif string.find(objectText, "미션") then
				local data = PlayerDataService.get(player)
				if data then
					remotes.QuestData:FireClient(player, QuestService.getForData(data))
					remotes.OpenPanel:FireClient(player, "quests")
				end
			elseif string.find(objectText, "갤러리") then
				remotes.GalleryData:FireClient(player, {
					approved = GalleryService.getApproved(),
					pending = GalleryService.getPending(player),
					isAdmin = GalleryService.isAdmin(player),
				})
				remotes.OpenPanel:FireClient(player, "gallery")
			end
		end)
	end
end

local function pushData(player: Player)
	local data = PlayerDataService.get(player)
	if data then remotes.PlayerData:FireClient(player, data) end
end

MonetizationService.init(PlayerDataService, pushData)

Players.PlayerAdded:Connect(function(player)
	PlayerDataService.load(player)
	MonetizationService.onPlayerLoaded(player)
	task.defer(pushData, player)
end)

for _, player in Players:GetPlayers() do
	PlayerDataService.load(player)
	MonetizationService.onPlayerLoaded(player)
	task.defer(pushData, player)
end

Players.PlayerRemoving:Connect(function(player)
	RoundService.removePlayer(player)
	PlayerDataService.remove(player)
	ModerationService.removePlayer(player)
end)

remotes.ChoosePrompt.OnServerEvent:Connect(function(player, promptId)
	RoundService.choosePrompt(player, tostring(promptId))
end)

remotes.SubmitStroke.OnServerEvent:Connect(function(player, payload)
	local state, artist = RoundService.getState()
	local data = PlayerDataService.get(player)
	local cosmetics = data and data.equipped or nil
	local stroke = CanvasService.submit(player, payload, state == "Drawing" and player == artist, experienceMode, cosmetics)
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

remotes.FinishDrawing.OnServerEvent:Connect(function(player)
	local ok, message = RoundService.finishDrawing(player)
	remotes.Toast:FireClient(player, message)
	if ok then
		TelemetryService.log(player, "drawing_submitted_early", CanvasService.getCount(), {
			mode = experienceMode,
		})
	end
end)

remotes.SubmitGuess.OnServerEvent:Connect(function(player, raw)
	local state, artist, prompt = RoundService.getState()
	if state ~= "Drawing" or not RoundService.isParticipant(player) or player == artist or not prompt then return end
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
	local state, artist, _, roundId = RoundService.getState()
	if state ~= "Drawing" and state ~= "Reveal" then
		return
	end
	if not RoundService.isParticipant(player) or not artist or player == artist then
		return
	end
	if ModerationService.allow(player, "report", 2, 30) then
		ModerationService.report(player, artist, tostring(reason), roundId, CanvasService.getCount())
		GalleryService.markReported()
		TelemetryService.log(player, "drawing_reported", 1, { mode = experienceMode })
		remotes.Toast:FireClient(player, "Report received. The canvas is hidden for you.")
	end
end)

remotes.ReactToDrawing.OnServerEvent:Connect(function(player, reaction)
	local state, artist = RoundService.getState()
	if state ~= "Reveal" then
		return
	end
	if not RoundService.isParticipant(player) or not artist or player == artist then
		return
	end
	if ModerationService.allow(player, "reaction", 4, 5) then
		local allowed = { heart = true, laugh = true, wow = true }
		if allowed[reaction] and GalleryService.react(player, reaction) then
			remotes.Toast:FireAllClients(player.DisplayName .. " reacted: " .. reaction)
		end
	end
end)

remotes.PurchaseItem.OnServerEvent:Connect(function(player, itemId)
	if not ModerationService.allow(player, "purchase", 4, 5) then
		return
	end
	local ok, message = PlayerDataService.purchase(player, tostring(itemId))
	remotes.Toast:FireClient(player, message)
	if ok then
		TelemetryService.log(player, "cosmetic_purchased", 1, { item = tostring(itemId) })
		pushData(player)
	end
end)

remotes.EquipItem.OnServerEvent:Connect(function(player, itemId)
	if not ModerationService.allow(player, "equip", 6, 5) then
		return
	end
	local ok, message = PlayerDataService.equip(player, tostring(itemId))
	remotes.Toast:FireClient(player, message)
	if ok then
		pushData(player)
	end
end)

remotes.RequestGallery.OnServerEvent:Connect(function(player, requestType, requestId)
	if not ModerationService.allow(player, "panel_request", 4, 5) then
		return
	end
	if requestType == "gallery" then
		remotes.GalleryData:FireClient(player, {
			approved = GalleryService.getApproved(),
			pending = GalleryService.getPending(player),
			isAdmin = GalleryService.isAdmin(player),
		})
	elseif requestType == "playerData" then
		pushData(player)
	elseif requestType == "quests" then
		local data = PlayerDataService.get(player)
		if data then
			local quest = QuestService.find(tostring(requestId))
			if quest then
				local ok, message = PlayerDataService.claimQuest(
					player,
					quest.id,
					quest.requirement,
					quest.field,
					quest.reward,
					quest.scope
				)
				remotes.Toast:FireClient(player, message)
				if ok then
					pushData(player)
				end
			end
			remotes.QuestData:FireClient(player, QuestService.getForData(data))
		end
	end
end)

remotes.ModerateGallery.OnServerEvent:Connect(function(player, artworkId, decision)
	if not ModerationService.allow(player, "gallery_moderation", 5, 10) then
		return
	end
	local ok, message = GalleryService.moderate(player, tostring(artworkId), tostring(decision))
	remotes.Toast:FireClient(player, message)
	if ok then
		remotes.GalleryData:FireClient(player, {
			approved = GalleryService.getApproved(),
			pending = GalleryService.getPending(player),
			isAdmin = true,
		})
	end
end)

remotes.PurchasePremium.OnServerEvent:Connect(function(player, productType)
	if not ModerationService.allow(player, "premium_prompt", 2, 10) then
		return
	end
	if not MonetizationService.prompt(player, tostring(productType)) then
		remotes.Toast:FireClient(player, "Premium product is not configured yet.")
	end
end)

remotes.ShareDrawingBubble.OnServerEvent:Connect(function(player, strokes)
	local payload = DrawingBubbleService.submit(player, strokes)
	if payload then
		remotes.DrawingBubbleBroadcast:FireAllClients(payload)
		TelemetryService.log(player, "drawing_bubble_shared", 1, { strokes = #payload.strokes })
	else
		remotes.Toast:FireClient(player, "Please wait before sharing another drawing. / 잠시 후 다시 공유하세요.")
	end
end)

remotes.ReportDrawingBubble.OnServerEvent:Connect(function(player, bubbleId, ownerUserId)
	local owner = Players:GetPlayerByUserId(tonumber(ownerUserId) or 0)
	if DrawingBubbleService.report(player, tostring(bubbleId), owner) then
		remotes.Toast:FireClient(player, "Drawing bubble reported and hidden. / 그림 말풍선을 신고했습니다.")
	end
end)

task.spawn(RoundService.run)

game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		PlayerDataService.save(player)
	end
	for _ = 1, 3 do
		if PlayerDataService.getPendingSaveCount() == 0 then
			break
		end
		task.wait(1)
		PlayerDataService.retryPending()
	end
end)
