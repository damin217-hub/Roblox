# Art Academy Guess

한국어·영어를 지원하는 Roblox 전체연령 그림 추측 파티게임입니다. 서버 권한 라운드,
필터링된 정답 채팅, PC·모바일 캔버스, 데이터 저장, 신고·숨김, NPC 로비를 포함합니다.

- 전체연령 단일 Experience만 개발·배포합니다.
- 승인 팔레트와 서버 검증 좌표를 사용하는 연속 브러시를 제공합니다.
- 세밀·마커·굵게·부드럽게 프리셋, 굵기, 불투명도, 원형·사각형 펜촉, 지우개와 실행 취소를 지원합니다.
- 그림판은 시작 시 열리며 접은 뒤 언제든 다시 열 수 있습니다.
- 운영자 승인 갤러리, 일일·주간 미션, 비경쟁 꾸미기 상점을 제공합니다.

## 빌드와 검증

```powershell
.\scripts\verify.ps1
```

기본 명령은 Selene 검사와 All Ages Rojo 빌드를 수행합니다. Studio 작업을 모두 닫은 뒤
숨김 런타임 테스트까지 실행하려면 다음 명령을 사용합니다.

```powershell
.\scripts\verify.ps1 -RunStudio
```

## 단일 로컬 플레이테스트

```powershell
.\scripts\open-playtest.ps1
```

Studio에서 Play를 누른 뒤 `docs/MANUAL_PLAYTEST.md` 순서로 확인합니다.

## Open Cloud 배포

Creator Dashboard에서 비공개 Experience와 `universe-places:write` 권한 API 키를 만든 뒤
다음 환경변수를 설정합니다. 키는 파일이나 Git에 저장하지 않습니다.

```powershell
$env:ROBLOX_API_KEY = "..."
$env:ROBLOX_ALL_AGES_UNIVERSE_ID = "..."
$env:ROBLOX_ALL_AGES_PLACE_ID = "..."

.\scripts\publish.ps1 -VersionType Saved
.\scripts\publish.ps1 -VersionType Published
```

사용자 그림 기능은 Creator Dashboard 콘텐츠 성숙도 설문에 정확히 신고하고,
신고·숨김·차단·운영자 승인 갤러리 정책을 유지해야 합니다.
