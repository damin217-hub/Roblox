local QuestService = {}

local QUESTS = table.freeze({
	{
		id = "daily_guesses",
		scope = "daily",
		field = "guesses",
		requirement = 5,
		reward = 75,
		nameKo = "정답 5번 맞히기",
		nameEn = "Guess correctly 5 times",
	},
	{
		id = "daily_rounds",
		scope = "daily",
		field = "rounds",
		requirement = 3,
		reward = 50,
		nameKo = "그림 라운드 3번 참여",
		nameEn = "Play 3 drawing rounds",
	},
	{
		id = "weekly_guesses",
		scope = "weekly",
		field = "guesses",
		requirement = 25,
		reward = 300,
		nameKo = "이번 주 정답 25번 맞히기",
		nameEn = "Guess correctly 25 times this week",
	},
	{
		id = "weekly_wins",
		scope = "weekly",
		field = "wins",
		requirement = 3,
		reward = 250,
		nameKo = "이번 주 게임 3번 우승",
		nameEn = "Win 3 matches this week",
	},
})

function QuestService.getForData(data)
	local result = {}
	for _, quest in QUESTS do
		local progressSource = quest.scope == "weekly" and data.weekly or data.daily
		local claimSource = data.claims and data.claims[quest.scope] or data.claimedQuests
		table.insert(result, {
			id = quest.id,
			scope = quest.scope,
			nameKo = quest.nameKo,
			nameEn = quest.nameEn,
			progress = math.min(progressSource[quest.field] or 0, quest.requirement),
			requirement = quest.requirement,
			reward = quest.reward,
			claimed = claimSource and claimSource[quest.id] == true,
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
