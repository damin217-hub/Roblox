local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Prompts = require(ReplicatedStorage.ArtAcademy.Prompts)

local PromptService = {}
local rng = Random.new()

function PromptService.getChoices(count: number)
	local pool = table.clone(Prompts)
	local choices = {}
	for _ = 1, math.min(count, #pool) do
		local index = rng:NextInteger(1, #pool)
		table.insert(choices, table.remove(pool, index))
	end
	return choices
end

local function normalize(value: string): string
	value = string.lower(value)
	value = string.gsub(value, "[%s%p_]+", "")
	if string.sub(value, -1) == "s" and #value > 3 then
		value = string.sub(value, 1, -2)
	end
	return value
end

function PromptService.matches(prompt, guess: string): boolean
	local target = normalize(prompt.en)
	local korean = normalize(prompt.ko)
	local candidate = normalize(guess)
	if candidate == target or candidate == korean then
		return true
	end
	for _, alias in prompt.aliases do
		if candidate == normalize(alias) then
			return true
		end
	end
	return false
end

return PromptService

