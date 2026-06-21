# Release Manifest

전체연령 단일 빌드만 배포합니다.

| Experience | File | 상태 |
|---|---|---|
| All Ages | `build/ArtAcademy-AllAges.rbxlx` | `7D60CFA07C60896BFCBE8BF09DFB5D1BF8169F379A610F452D58C10E2A8AF5C4` |

릴리스 ZIP은 실제 PC·모바일·멀티플레이 QA가 모두 통과할 때만 다시 생성합니다.

## 자동 검증

- Selene: 오류 0, 경고 0, 파싱 오류 0
- Studio 스모크: 77개 통과
- 런타임 부팅: 28개 통과
- 12인 5라운드 전체 매치: 33개 통과
- 출제자 중도 이탈 복구: 15개 통과

## 배포 전 필수 설정

- All Ages Universe ID와 Place ID
- `universe-places:write` Open Cloud API 키
- 사용자 그림 기능을 포함한 콘텐츠 성숙도 설문
- 운영자 계정과 신고·갤러리 승인 절차
- 실제 기기 및 8–12인 비공개 서버 검증
