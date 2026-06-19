local QuestService = {}

local QUESTS = table.freeze({
	{
		id = "daily_guesses",
		field = "guesses",
		requirement = 5,
		reward = 75,
		nameKo = "정답 5번 맞히기",
		nameEn = "Guess correctly 5 times",
	},
	{
		id = "daily_rounds",
		field = "rounds",
		requirement = 3,
		reward = 50,
		nameKo = "그림 라운드 3번 참여",
		nameEn = "Play 3 drawing rounds",
	},
})

function QuestService.getForData(data)
	local result = {}
	for _, quest in QUESTS do
		table.insert(result, {
			id = quest.id,
			nameKo = quest.nameKo,
			nameEn = quest.nameEn,
			progress = math.min(data.daily[quest.field] or 0, quest.requirement),
			requirement = quest.requirement,
			reward = quest.reward,
			claimed = data.claimedQuests[quest.id] == true,
		})
	end
	return result
end

function QuestService.find(questId: string)
	for _, quest in QUESTS do
		if quest.id == questId then
			return quest
		end
	end
	return nil
end

return QuestService

