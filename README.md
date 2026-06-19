# Art Academy Guess

한국어/영어 Roblox 그림 추측 파티게임 MVP입니다. 서버 권한 라운드, 필터링된 정답 채팅,
PC/모바일 캔버스, 연령별 제한 모드, 데이터 저장, 신고/숨김, NPC 로비를 포함합니다.

## 빌드

```powershell
tools\rojo.exe build all-ages.project.json -o build\ArtAcademy-AllAges.rbxlx
tools\rojo.exe build free-draw.project.json -o build\ArtAcademy-FreeDraw16Plus.rbxlx
```

Studio에서 생성된 파일을 열고 각기 다른 Experience로 `Publish to Roblox` 하세요.
로컬 테스트는 최소 2명, 공개 서버 권장 인원은 8–12명입니다.

## 운영 설정

- `src/shared/Config.luau`: 라운드 시간, 최소 인원, 획 제한
- `src/shared/Prompts.luau`: 한/영 단어장
- `all-ages.project.json`: 승인된 스탬프/도형 전용
- `free-draw.project.json`: 16+ 자유 드로잉

## 주의

자유 드로잉 Experience는 Roblox Creator Dashboard에서 Free-form User Creation을
정확히 신고하고 현재 연령 정책에 맞게 공개해야 합니다.

