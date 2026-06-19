local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.ArtAcademy.Config)
local Catalog = require(ReplicatedStorage.ArtAcademy.Catalog)

local PlayerDataService = {}
local store = nil
local sessions = {}
local dirty = {}

local function getStore()
	if store then
		return store
	end
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DATASTORE_NAME)
	end)
	if ok then
		store = result
	end
	return store
end

local DEFAULT = {
	coins = 0,
	xp = 0,
	wins = 0,
	correctGuesses = 0,
	drawings = 0,
	owned = { "brush_classic", "palette_basic" },
	equipped = { brush = "brush_classic", palette = "palette_basic", title = "" },
	daily = { date = "", guesses = 0, rounds = 0 },
	weekly = { week = "", guesses = 0, rounds = 0, wins = 0 },
	claimedQuests = {},
	claims = { daily = {}, weekly = {} },
	receipts = {},
}

local function cloneDefault()
	return {
		coins = DEFAULT.coins,
		xp = DEFAULT.xp,
		wins = DEFAULT.wins,
		correctGuesses = DEFAULT.correctGuesses,
		drawings = DEFAULT.drawings,
		owned = table.clone(DEFAULT.owned),
		equipped = table.clone(DEFAULT.equipped),
		daily = table.clone(DEFAULT.daily),
		weekly = table.clone(DEFAULT.weekly),
		claimedQuests = table.clone(DEFAULT.claimedQuests),
		claims = { daily = {}, weekly = {} },
		receipts = table.clone(DEFAULT.receipts),
	}
end

local function owns(data, itemId: string): boolean
	return table.find(data.owned, itemId) ~= nil
end

local function findCatalogItem(itemId: string)
	for _, item in Catalog do
		if item.id == itemId then
			return item
		end
	end
	return nil
end

function PlayerDataService.load(player: Player)
	local data = cloneDefault()
	local ok, saved = pcall(function()
		local activeStore = getStore()
		return activeStore and activeStore:GetAsync("player_" .. player.UserId) or nil
	end)
	if ok and type(saved) == "table" then
		for key, value in saved do
			data[key] = value
		end
	end
	data.owned = type(data.owned) == "table" and data.owned or table.clone(DEFAULT.owned)
	data.equipped = type(data.equipped) == "table" and data.equipped or table.clone(DEFAULT.equipped)
	data.daily = type(data.daily) == "table" and data.daily or table.clone(DEFAULT.daily)
	data.weekly = type(data.weekly) == "table" and data.weekly or table.clone(DEFAULT.weekly)
	data.claimedQuests = type(data.claimedQuests) == "table" and data.claimedQuests or {}
	data.claims = type(data.claims) == "table" and data.claims or { daily = {}, weekly = {} }
	data.claims.daily = type(data.claims.daily) == "table" and data.claims.daily or {}
	data.claims.weekly = type(data.claims.weekly) == "table" and data.claims.weekly or {}
	data.receipts = type(data.receipts) == "table" and data.receipts or {}
	sessions[player] = data
	return data
end

function PlayerDataService.markDirty(player: Player)
	if sessions[player] then
		dirty[player] = true
	end
end

function PlayerDataService.grantReceipt(player: Player, receiptKey: string, coinAmount: number): boolean
	local data = sessions[player]
	if not data then
		return false
	end
	local activeStore = getStore()
	if not activeStore then
		return false
	end
	local persistedData = nil
	local ok = pcall(function()
		persistedData = activeStore:UpdateAsync("player_" .. player.UserId, function(saved)
			local merged = table.clone(data)
			merged.owned = table.clone(data.owned)
			merged.equipped = table.clone(data.equipped)
			merged.daily = table.clone(data.daily)
			merged.weekly = table.clone(data.weekly)
			merged.claimedQuests = table.clone(data.claimedQuests)
			merged.claims = {
				daily = table.clone(data.claims.daily),
				weekly = table.clone(data.claims.weekly),
			}
			merged.receipts = table.clone(data.receipts)
			if type(saved) == "table" and type(saved.receipts) == "table" then
				for previousReceipt in saved.receipts do
					merged.receipts[previousReceipt] = true
				end
			end
			if not merged.receipts[receiptKey] then
				merged.coins = (merged.coins or 0) + coinAmount
				merged.receipts[receiptKey] = true
			end
			return merged
		end)
	end)
	if not ok or type(persistedData) ~= "table" then
		dirty[player] = true
		return false
	end
	sessions[player] = persistedData
	dirty[player] = nil
	return true
end

function PlayerDataService.get(player: Player)
	return sessions[player]
end

function PlayerDataService.add(player: Player, field: string, amount: number)
	local data = sessions[player]
	if data and type(data[field]) == "number" then
		data[field] += amount
		dirty[player] = true
	end
end

function PlayerDataService.purchase(player: Player, itemId: string)
	local data = sessions[player]
	local item = findCatalogItem(itemId)
	if not data or not item then
		return false, "Unknown item"
	end
	if owns(data, itemId) then
		return false, "Already owned"
	end
	if data.coins < item.price then
		return false, "Not enough coins"
	end
	data.coins -= item.price
	table.insert(data.owned, itemId)
	dirty[player] = true
	return true, "Purchased"
end

function PlayerDataService.equip(player: Player, itemId: string)
	local data = sessions[player]
	local item = findCatalogItem(itemId)
	if not data or not item or not owns(data, itemId) then
		return false, "Item not owned"
	end
	data.equipped[item.category] = itemId
	dirty[player] = true
	return true, "Equipped"
end

function PlayerDataService.incrementProgress(player: Player, field: string, amount: number)
	local data = sessions[player]
	if not data then
		return
	end
	local today = os.date("!%Y-%m-%d")
	if data.daily.date ~= today then
		data.daily = { date = today, guesses = 0, rounds = 0 }
		data.claims.daily = {}
	end
	local week = os.date("!%Y-W%W")
	if data.weekly.week ~= week then
		data.weekly = { week = week, guesses = 0, rounds = 0, wins = 0 }
		data.claims.weekly = {}
	end
	data.daily[field] = (data.daily[field] or 0) + amount
	data.weekly[field] = (data.weekly[field] or 0) + amount
	dirty[player] = true
end

function PlayerDataService.claimQuest(
	player: Player,
	questId: string,
	requirement: number,
	field: string,
	reward: number,
	scope: string
)
	local data = sessions[player]
	if not data then
		return false, "No data"
	end
	local questScope = scope == "weekly" and "weekly" or "daily"
	local progress = data[questScope]
	local claims = data.claims[questScope]
	if claims[questId] then
		return false, "Already claimed"
	end
	if (progress[field] or 0) < requirement then
		return false, "Not complete"
	end
	claims[questId] = true
	data.coins += reward
	dirty[player] = true
	return true, "Claimed"
end

function PlayerDataService.save(player: Player)
	local data = sessions[player]
	if not data then return end
	local persisted = false
	local ok = pcall(function()
		local activeStore = getStore()
		if not activeStore then
			return
		end
		activeStore:UpdateAsync("player_" .. player.UserId, function()
			return data
		end)
		persisted = true
	end)
	if ok and persisted then
		dirty[player] = nil
	else
		dirty[player] = true
	end
	return ok and persisted
end

function PlayerDataService.remove(player: Player)
	PlayerDataService.save(player)
	sessions[player] = nil
	dirty[player] = nil
end

function PlayerDataService.startAutosave()
	task.spawn(function()
		while true do
			task.wait(60)
			for player in dirty do
				if player.Parent == Players then
					PlayerDataService.save(player)
				end
			end
		end
	end)
end

return PlayerDataService
