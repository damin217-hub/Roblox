local TextService = game:GetService("TextService")
local PromptService = require(script.Parent.PromptService)
local ModerationService = require(script.Parent.ModerationService)

local GuessService = {}

function GuessService.process(player: Player, raw: string, prompt)
	if type(raw) ~= "string" or #raw < 1 or #raw > 80 then return nil end
	if not ModerationService.allow(player, "guess", 5, 3) then return nil end
	local filtered = "[Content unavailable]"
	local ok, result = pcall(function()
		local filterResult = TextService:FilterStringAsync(raw, player.UserId)
		return filterResult:GetNonChatStringForBroadcastAsync()
	end)
	if ok then filtered = result end
	return {
		text = filtered,
		correct = PromptService.matches(prompt, raw),
	}
end

return GuessService

