local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Config = require(ReplicatedStorage.ArtAcademy.Config)

local ModerationService = {}
local rateBuckets = {}
local reports = {}
local skipVotes = {}
local reportStore = DataStoreService:GetDataStore("ArtAcademyModeration_v1")

function ModerationService.allow(player: Player, action: string, limit: number, window: number): boolean
	local now = os.clock()
	rateBuckets[player] = rateBuckets[player] or {}
	local bucket = rateBuckets[player][action]
	if not bucket or now - bucket.started >= window then
		rateBuckets[player][action] = { started = now, count = 1 }
		return true
	end
	if bucket.count >= limit then return false end
	bucket.count += 1
	return true
end

function ModerationService.report(reporter: Player, artist: Player?, reason: string, roundId: string, strokeCount: number)
	reason = string.sub(reason, 1, Config.MAX_REPORT_REASON_LENGTH)
	local record = {
		timestamp = os.time(),
		reporterUserId = reporter.UserId,
		artistUserId = artist and artist.UserId or 0,
		reason = reason,
		roundId = roundId,
		strokeCount = strokeCount,
		jobId = game.JobId,
	}
	table.insert(reports, record)
	if #reports > 200 then table.remove(reports, 1) end
	task.spawn(function()
		pcall(function()
			local key = string.format("report_%d_%d_%d", record.timestamp, reporter.UserId, math.random(1000, 9999))
			reportStore:SetAsync(key, record)
		end)
	end)
	return true
end

function ModerationService.voteSkip(player: Player, roundId: string, eligibleCount: number): boolean
	skipVotes[roundId] = skipVotes[roundId] or {}
	skipVotes[roundId][player.UserId] = true
	local count = 0
	for _ in skipVotes[roundId] do count += 1 end
	return eligibleCount >= 2 and count >= math.ceil(eligibleCount * 0.6)
end

function ModerationService.clearRound(roundId: string)
	skipVotes[roundId] = nil
end

function ModerationService.removePlayer(player: Player)
	rateBuckets[player] = nil
end

return ModerationService
