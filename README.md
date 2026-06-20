# Art Academy Guess

한국어/영어 Roblox 그림 추측 파티게임 MVP입니다. 서버 권한 라운드, 필터링된 정답 채팅,
PC/모바일 캔버스, 연령별 제한 모드, 데이터 저장, 신고/숨김, NPC 로비를 포함합니다.

- 전체 연령판은 드래그 선을 허용하지 않고 승인된 색상·원/사각형 스탬프를 격자에 탭으로 배치합니다.
- 16+판은 EditableImage 자유 브러시, 지우개, 굵기, 실행 취소를 제공합니다.
- 일일·주간 미션, 꾸미기 상점, 운영자 승인 갤러리와 작품 재생을 제공합니다.
- 로비 매칭 포털에서 다음 게임 참가를 선택하며 한 매치에는 최대 12명이 들어갑니다.

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

기본 명령은 Studio를 실행하지 않는 정적 검사와 두 빌드만 수행합니다. 숨김 Studio 프로세스를 사용하는
전체 런타임 검사는 Studio 작업을 모두 닫은 뒤 명시적으로 실행합니다. 각 Experience마다 구조 스모크,
서버 부팅, 5라운드 전체 매치 시나리오를 검증합니다.

```powershell
.\scripts\verify.ps1 -RunStudio
```

## Open Cloud 배포

Creator Dashboard에서 두 개의 비공개 Experience와 `universe-places:write` 권한 API 키를 만든 뒤
키와 ID를 환경변수로 설정합니다. 키를 파일에 저장하거나 Git에 커밋하지 마세요.

```powershell
$env:ROBLOX_API_KEY = "..."
$env:ROBLOX_ALL_AGES_UNIVERSE_ID = "..."
$env:ROBLOX_ALL_AGES_PLACE_ID = "..."
$env:ROBLOX_FREE_DRAW_UNIVERSE_ID = "..."
$env:ROBLOX_FREE_DRAW_PLACE_ID = "..."

# QA용 저장 버전 업로드
.\scripts\publish.ps1 -VersionType Saved

# QA 승인 후 실제 게시 버전 업로드
.\scripts\publish.ps1 -VersionType Published
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
