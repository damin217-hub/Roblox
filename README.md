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

## Studio 스모크 테스트

Roblox Studio 공식 CLI의 `RunScript` 작업으로 핵심 모듈과 맵 구조를 검사합니다.

```powershell
RobloxStudioBeta.exe --task RunScript `
  --runScriptFile "$PWD\tests\studio_smoke.luau" `
  --outputFile "$PWD\build\studio-smoke.log" `
  --quitAfterExecution
```

생성된 두 `.rbxlx` 파일은 Studio에서 `--task EditFile --localPlaceFile <path>` 또는 파일 경로를
첫 번째 인수로 전달해 엽니다. `EditPlace`는 게시된 Place ID용이므로 로컬 파일에는 사용하지 않습니다.

전체 로컬 검증은 다음 한 줄로 실행할 수 있습니다.

```powershell
.\scripts\verify.ps1
```

## 운영 설정

- `src/shared/Config.luau`: 라운드 시간, 최소 인원, 획 제한
- `src/shared/Prompts.luau`: 한/영 단어장
- `src/shared/Config.luau`의 `ADMIN_USER_IDS`: 갤러리 승인 권한을 가진 Roblox UserId
- `all-ages.project.json`: 승인된 스탬프/도형 전용
- `free-draw.project.json`: 16+ 자유 드로잉

## 주의

자유 드로잉 Experience는 Roblox Creator Dashboard에서 Free-form User Creation을
정확히 신고하고 현재 연령 정책에 맞게 공개해야 합니다.
