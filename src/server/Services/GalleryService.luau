local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Config = require(ReplicatedStorage.ArtAcademy.Config)
local StrokeCodec = require(ReplicatedStorage.ArtAcademy.StrokeCodec)

local GalleryService = {}
local galleryStore = nil
local current = nil
local reactionUsers = {}
local reported = false

local function getGalleryStore()
	if galleryStore then
		return galleryStore
	end
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.GALLERY_DATASTORE_NAME)
	end)
	if ok then
		galleryStore = result
	end
	return galleryStore
end

function GalleryService.beginRound(roundId: string, artist: Player?, prompt)
	current = {
		id = roundId,
		artistUserId = artist and artist.UserId or 0,
		artistName = artist and artist.DisplayName or "Unknown",
		promptKo = prompt and prompt.ko or "",
		promptEn = prompt and prompt.en or "",
		reactions = { heart = 0, laugh = 0, wow = 0 },
	}
	table.clear(reactionUsers)
	reported = false
end

function GalleryService.react(player: Player, reaction: string)
	if not current or reactionUsers[player.UserId] then
		return false
	end
	reactionUsers[player.UserId] = true
	current.reactions[reaction] = (current.reactions[reaction] or 0) + 1
	return true
end

function GalleryService.markReported()
	reported = true
end

function GalleryService.submitPending(strokes)
	if not current or reported or #strokes == 0 then
		return
	end
	local totalReactions = 0
	for _, count in current.reactions do
		totalReactions += count
	end
	if totalReactions < 1 then
		return
	end
	local record = table.clone(current)
	record.status = "pending"
	record.createdAt = os.time()
	record.strokes = StrokeCodec.encode(strokes, Config.GALLERY_MAX_STROKES)
	task.spawn(function()
		pcall(function()
			local activeStore = getGalleryStore()
			if activeStore then
				activeStore:SetAsync("pending_" .. record.id, record)
				activeStore:UpdateAsync("pending_index", function(index)
					index = type(index) == "table" and index or {}
					if not table.find(index, record.id) then
						table.insert(index, record.id)
					end
					while #index > 50 do
						table.remove(index, 1)
					end
					return index
				end)
			end
		end)
	end)
end

function GalleryService.getApproved()
	local ok, saved = pcall(function()
		local activeStore = getGalleryStore()
		return activeStore and activeStore:GetAsync("approved_featured") or nil
	end)
	if ok and type(saved) == "table" then
		local result = {}
		for index = 1, math.min(#saved, 10) do
			table.insert(result, saved[index])
		end
		return result
	end
	return {}
end

function GalleryService.isAdmin(player: Player): boolean
	return table.find(Config.ADMIN_USER_IDS, player.UserId) ~= nil
end

function GalleryService.getPending(player: Player)
	if not GalleryService.isAdmin(player) then
		return {}
	end
	local activeStore = getGalleryStore()
	if not activeStore then
		return {}
	end
	local ok, result = pcall(function()
		local index = activeStore:GetAsync("pending_index") or {}
		local pending = {}
		local first = math.max(1, #index - 9)
		for position = #index, first, -1 do
			local id = index[position]
			local record = activeStore:GetAsync("pending_" .. id)
			if type(record) == "table" then
				table.insert(pending, record)
			end
		end
		return pending
	end)
	return ok and result or {}
end

function GalleryService.moderate(player: Player, artworkId: string, decision: string)
	if not GalleryService.isAdmin(player) then
		return false, "Not authorized"
	end
	if decision ~= "approve" and decision ~= "reject" then
		return false, "Invalid decision"
	end
	local activeStore = getGalleryStore()
	if not activeStore then
		return false, "DataStore unavailable"
	end
	local ok, message = pcall(function()
		local key = "pending_" .. artworkId
		local record = activeStore:GetAsync(key)
		if type(record) ~= "table" then
			return "Artwork not found"
		end
		if decision == "approve" then
			record.status = "approved"
			record.approvedAt = os.time()
			activeStore:UpdateAsync("approved_featured", function(featured)
				featured = type(featured) == "table" and featured or {}
				table.insert(featured, 1, record)
				while #featured > 20 do
					table.remove(featured)
				end
				return featured
			end)
		end
		activeStore:RemoveAsync(key)
		activeStore:UpdateAsync("pending_index", function(index)
			index = type(index) == "table" and index or {}
			local position = table.find(index, artworkId)
			if position then
				table.remove(index, position)
			end
			return index
		end)
		return decision == "approve" and "Artwork approved" or "Artwork rejected"
	end)
	if not ok then
		return false, "Moderation failed"
	end
	return true, message
end

function GalleryService.exportPendingKey(): string
	return current and ("pending_" .. current.id) or HttpService:GenerateGUID(false)
end

return GalleryService
