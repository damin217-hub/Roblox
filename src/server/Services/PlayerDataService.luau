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
	claimedQuests = {},
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
		claimedQuests = table.clone(DEFAULT.claimedQuests),
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
	data.claimedQuests = type(data.claimedQuests) == "table" and data.claimedQuests or {}
	sessions[player] = data
	return data
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

function PlayerDataService.incrementDaily(player: Player, field: string, amount: number)
	local data = sessions[player]
	if not data then
		return
	end
	local today = os.date("!%Y-%m-%d")
	if data.daily.date ~= today then
		data.daily = { date = today, guesses = 0, rounds = 0 }
		data.claimedQuests = {}
	end
	data.daily[field] = (data.daily[field] or 0) + amount
	dirty[player] = true
end

function PlayerDataService.claimQuest(player: Player, questId: string, requirement: number, field: string, reward: number)
	local data = sessions[player]
	if not data then
		return false, "No data"
	end
	if data.claimedQuests[questId] then
		return false, "Already claimed"
	end
	if (data.daily[field] or 0) < requirement then
		return false, "Not complete"
	end
	data.claimedQuests[questId] = true
	data.coins += reward
	dirty[player] = true
	return true, "Claimed"
end

function PlayerDataService.save(player: Player)
	local data = sessions[player]
	if not data then return end
	local ok = pcall(function()
		local activeStore = getStore()
		if not activeStore then
			return
		end
		activeStore:UpdateAsync("player_" .. player.UserId, function()
			return data
		end)
	end)
	if ok then dirty[player] = nil end
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
