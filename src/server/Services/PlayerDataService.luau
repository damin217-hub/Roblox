local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.ArtAcademy.Config)

local PlayerDataService = {}
local store = DataStoreService:GetDataStore(Config.DATASTORE_NAME)
local sessions = {}
local dirty = {}

local DEFAULT = {
	coins = 0,
	xp = 0,
	wins = 0,
	correctGuesses = 0,
	drawings = 0,
	owned = { "brush_classic", "palette_basic" },
	equipped = { brush = "brush_classic", palette = "palette_basic", title = "" },
	daily = { date = "", guesses = 0, rounds = 0 },
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
	}
end

function PlayerDataService.load(player: Player)
	local data = cloneDefault()
	local ok, saved = pcall(function()
		return store:GetAsync("player_" .. player.UserId)
	end)
	if ok and type(saved) == "table" then
		for key, value in saved do
			data[key] = value
		end
	end
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

function PlayerDataService.save(player: Player)
	local data = sessions[player]
	if not data then return end
	local ok = pcall(function()
		store:UpdateAsync("player_" .. player.UserId, function()
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

