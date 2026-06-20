local strings = {
	ko = {
		title = "모모의 아트 아카데미",
		waiting = "플레이어를 기다리는 중...",
		intermission = "다음 게임 준비!",
		choosing = "출제자가 단어를 고르는 중",
		drawing = "그림을 보고 정답을 맞혀보세요!",
		yourTurn = "그림을 그려주세요!",
		reveal = "정답 공개",
		results = "최종 결과",
		round = "라운드",
		tutorialTitle = "모모의 첫 수업",
		playAgain = "다시 플레이하려면 중앙 포털로!",
		guessPlaceholder = "정답을 입력하세요",
		submit = "보내기",
		hide = "캔버스 숨기기",
		report = "신고",
		skip = "건너뛰기 투표",
		undo = "실행 취소",
		clear = "전체 지우기",
		points = "점",
		coins = "코인",
	},
	en = {
		title = "Momo's Art Academy",
		waiting = "Waiting for players...",
		intermission = "Get ready for the next game!",
		choosing = "The artist is choosing a prompt",
		drawing = "Guess the drawing!",
		yourTurn = "Draw the prompt!",
		reveal = "The answer was",
		results = "Final Results",
		round = "Round",
		tutorialTitle = "Momo's First Lesson",
		playAgain = "Return to the center portal to play again!",
		guessPlaceholder = "Type your guess",
		submit = "Send",
		hide = "Hide Canvas",
		report = "Report",
		skip = "Vote Skip",
		undo = "Undo",
		clear = "Clear",
		points = "pts",
		coins = "coins",
	},
}

return function(locale: string)
	if string.sub(string.lower(locale), 1, 2) == "ko" then
		return strings.ko
	end
	return strings.en
end
